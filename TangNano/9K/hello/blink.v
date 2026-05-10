`timescale 1ns/1ps
module top (
  input  SYS_CLK,
  input  SYS_RSTn,
  output LED_R,
  output LED_G,
  output LED_B
);

reg [25:0] counter;

always @(posedge SYS_CLK or negedge SYS_RSTn)
  if (!SYS_RSTn) counter <= 0;
  else           counter <= counter + 1;

// TangNano 9K LEDs are active-low
assign LED_R = ~counter[25];
assign LED_G = ~counter[24];
assign LED_B = ~counter[23];

endmodule
