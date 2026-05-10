`timescale 1ns/1ps
// PWM generator: counter resets at period-1, output high while cnt < duty.
module pwm #(parameter WIDTH = 12) (
  input                  clk,
  input                  rst_n,
  input  [WIDTH-1:0]     period,
  input  [WIDTH-1:0]     duty,
  output reg             out
);
  reg [WIDTH-1:0] cnt;
  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin cnt <= 0; out <= 0; end
    else begin
      if (cnt >= period - 1) cnt <= 0; else cnt <= cnt + 1;
      out <= (cnt < duty);
    end
endmodule
