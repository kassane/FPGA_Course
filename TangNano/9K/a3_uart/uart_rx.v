`timescale 1ns/1ps
// UART receiver, 8N1, LSB-first. 2-FF sync + mid-bit sampling. valid pulses one cycle per byte.
module uart_rx #(
  parameter CLK_HZ = 27_000_000,
  parameter BAUD   =    115_200
) (
  input        clk,
  input        rst_n,
  input        rx,
  output reg [7:0] data,
  output reg   valid
);
  localparam CPB  = CLK_HZ / BAUD;
  localparam HALF = CPB / 2;

  localparam IDLE  = 2'd0;
  localparam START = 2'd1;
  localparam DATA  = 2'd2;
  localparam STOP  = 2'd3;

  // 2-FF synchroniser
  reg rx_s0, rx_s1;
  always @(posedge clk or negedge rst_n)
    if (!rst_n) {rx_s1, rx_s0} <= 2'b11;
    else        {rx_s1, rx_s0} <= {rx_s0, rx};

  reg [1:0]  state;
  reg [8:0]  cnt;
  reg [2:0]  bit_idx;
  reg [7:0]  shift;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state   <= IDLE;
      valid   <= 0;
      data    <= 0;
      cnt     <= 0;
      bit_idx <= 0;
      shift   <= 0;
    end else begin
      valid <= 0;
      case (state)

        IDLE: begin
          if (!rx_s1) begin cnt <= 0; state <= START; end  // falling edge
        end

        START: begin
          // count to HALF to centre on start bit, then verify still low
          if (cnt == HALF - 1) begin
            cnt <= 0;
            state <= rx_s1 ? IDLE : DATA;  // glitch rejection
          end else
            cnt <= cnt + 1;
        end

        DATA: begin
          if (cnt == CPB - 1) begin
            cnt   <= 0;
            shift <= {rx_s1, shift[7:1]};  // LSB-first deserialise
            if (bit_idx == 7) begin bit_idx <= 0; state <= STOP; end
            else               bit_idx <= bit_idx + 1;
          end else
            cnt <= cnt + 1;
        end

        STOP: begin
          if (cnt == CPB - 1) begin
            cnt   <= 0;
            state <= IDLE;
            if (rx_s1) begin data <= shift; valid <= 1; end  // valid stop bit
          end else
            cnt <= cnt + 1;
        end

      endcase
    end
  end
endmodule
