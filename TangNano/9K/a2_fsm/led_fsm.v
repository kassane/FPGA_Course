`timescale 1ns/1ps
// 3-state FSM: IDLE → PRESS_WAIT (counting hold) → BLINK → IDLE. Short press toggles LED.
module led_fsm #(
  parameter HOLD_CYCLES  = 27_000_000,  // 1 s at 27 MHz
  parameter BLINK_HALF   =  1_350_000   // 0.05 s half-period → 10 Hz blink
) (
  input      clk,
  input      rst_n,
  input      btn_press,
  input      btn_release,
  output reg led            // active-low output
);
  localparam IDLE       = 2'd0;
  localparam PRESS_WAIT = 2'd1;
  localparam BLINK      = 2'd2;

  reg [1:0]  state;
  reg [24:0] hold_cnt;
  reg [20:0] blink_cnt;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state     <= IDLE;
      led       <= 1'b1;   // off (active-low)
      hold_cnt  <= 0;
      blink_cnt <= 0;
    end else case (state)

      IDLE: begin
        if (btn_press) begin
          led      <= ~led;  // toggle
          hold_cnt <= 0;
          state    <= PRESS_WAIT;
        end
      end

      PRESS_WAIT: begin
        if (btn_release)
          state <= IDLE;
        else begin
          hold_cnt <= hold_cnt + 1;
          if (hold_cnt == HOLD_CYCLES - 1) begin
            blink_cnt <= 0;
            state     <= BLINK;
          end
        end
      end

      BLINK: begin
        blink_cnt <= blink_cnt + 1;
        if (blink_cnt == BLINK_HALF - 1) begin
          blink_cnt <= 0;
          led       <= ~led;
        end
        if (btn_release) state <= IDLE;
      end

      default: state <= IDLE;

    endcase
  end
endmodule
