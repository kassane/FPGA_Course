`timescale 1ns/1ps
// SPI master, mode 0 (CPOL=0 CPHA=0), 8-bit MSB-first. Assert start one cycle to send.
module spi_master #(
  parameter CLK_HZ = 27_000_000,
  parameter SCK_HZ =  1_000_000
) (
  input        clk,
  input        rst_n,
  input  [7:0] tx_data,
  input        start,
  output       busy,
  output reg [7:0] rx_data,
  output reg   done,
  output reg   sck,
  output reg   mosi,
  input        miso,
  output reg   cs_n
);
  localparam HALF = CLK_HZ / (2 * SCK_HZ);

  localparam IDLE   = 2'd0;
  localparam ACTIVE = 2'd1;
  localparam FINISH = 2'd2;

  reg [1:0]  state;
  reg [8:0]  cnt;
  reg [2:0]  bit_cnt;
  reg        sck_phase;  // 0=low, 1=high
  reg [7:0]  shift_tx;
  reg [7:0]  shift_rx;

  assign busy = (state != IDLE);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state     <= IDLE;
      done      <= 0;
      cs_n      <= 1;
      sck       <= 0;
      mosi      <= 0;
      cnt       <= 0;
      bit_cnt   <= 0;
      sck_phase <= 0;
      shift_tx  <= 0;
      shift_rx  <= 0;
      rx_data   <= 0;
    end else begin
      done <= 0;
      case (state)

        IDLE: begin
          cs_n <= 1; sck <= 0;
          if (start) begin
            shift_tx  <= tx_data;
            mosi      <= tx_data[7];
            cs_n      <= 0;
            cnt       <= 0;
            bit_cnt   <= 0;
            sck_phase <= 0;
            state     <= ACTIVE;
          end
        end

        ACTIVE: begin
          if (cnt == HALF - 1) begin
            cnt <= 0;
            if (!sck_phase) begin
              // rising edge: sample MISO
              sck       <= 1;
              shift_rx  <= {shift_rx[6:0], miso};
              sck_phase <= 1;
            end else begin
              // falling edge
              sck       <= 0;
              sck_phase <= 0;
              if (bit_cnt == 7) begin
                rx_data <= shift_rx;  // all 8 bits already captured on rising edges
                state   <= FINISH;
              end else begin
                bit_cnt  <= bit_cnt + 1;
                shift_tx <= shift_tx << 1;
                mosi     <= shift_tx[6];  // next MSB (reads pre-shift value)
              end
            end
          end else
            cnt <= cnt + 1;
        end

        FINISH: begin
          cs_n  <= 1;
          done  <= 1;
          state <= IDLE;
        end

        default: state <= IDLE;

      endcase
    end
  end
endmodule
