`timescale 1ns/1ps
// UART transmitter, 8N1, LSB-first. Assert valid for one cycle; check ready first.
module uart_tx #(
  parameter CLK_HZ = 27_000_000,
  parameter BAUD   =    115_200
) (
  input        clk,
  input        rst_n,
  input  [7:0] data,
  input        valid,
  output reg   tx,
  output       ready
);
  localparam CPB = CLK_HZ / BAUD;  // clocks per bit

  localparam IDLE  = 2'd0;
  localparam START = 2'd1;
  localparam DATA  = 2'd2;
  localparam STOP  = 2'd3;

  reg [1:0]  state;
  reg [8:0]  cnt;    // 9-bit: fits CPB ≤ 511
  reg [7:0]  shift;
  reg [2:0]  bit_idx;

  assign ready = (state == IDLE);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state   <= IDLE;
      tx      <= 1'b1;
      cnt     <= 0;
      shift   <= 0;
      bit_idx <= 0;
    end else case (state)

      IDLE: begin
        tx <= 1'b1;
        if (valid) begin
          shift   <= data;
          cnt     <= 0;
          state   <= START;
        end
      end

      START: begin
        tx <= 1'b0;
        if (cnt == CPB - 1) begin cnt <= 0; bit_idx <= 0; state <= DATA; end
        else                  cnt <= cnt + 1;
      end

      DATA: begin
        tx <= shift[0];
        if (cnt == CPB - 1) begin
          cnt   <= 0;
          shift <= {1'b0, shift[7:1]};
          if (bit_idx == 7) state <= STOP;
          else              bit_idx <= bit_idx + 1;
        end else
          cnt <= cnt + 1;
      end

      STOP: begin
        tx <= 1'b1;
        if (cnt == CPB - 1) begin cnt <= 0; state <= IDLE; end
        else                  cnt <= cnt + 1;
      end

    endcase
  end
endmodule
