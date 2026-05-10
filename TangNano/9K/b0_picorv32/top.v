`timescale 1ns/1ps
// B0 top: TangNano 9K wrapper. Reset counter holds CPU in reset for 63 cycles.
module top (
  input  SYS_CLK,
  input  SYS_RSTn,
  output LED_R,
  output LED_G,
  output LED_B
);
  reg [5:0] rst_cnt;
  wire resetn = &rst_cnt;

  always @(posedge SYS_CLK or negedge SYS_RSTn)
    if (!SYS_RSTn) rst_cnt <= 0;
    else if (!resetn) rst_cnt <= rst_cnt + 1;

  wire [2:0] leds;
  soc u_soc (.clk(SYS_CLK), .resetn(resetn), .leds(leds));

  assign {LED_B, LED_G, LED_R} = leds;
endmodule
