`timescale 1ns/1ps
module blink_tb;
  reg SYS_CLK = 0, SYS_RSTn = 0;
  wire LED_R, LED_G, LED_B;

  top dut(
    .SYS_CLK(SYS_CLK),
    .SYS_RSTn(SYS_RSTn),
    .LED_R(LED_R),
    .LED_G(LED_G),
    .LED_B(LED_B)
  );

  always #5 SYS_CLK = ~SYS_CLK;

  initial begin
    #20 SYS_RSTn = 1;
    #2000 $display("PASS: simulation completed");
    $finish;
  end
endmodule
