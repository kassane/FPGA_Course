`timescale 1ns/1ps
// B0 testbench: verify CPU writes to GPIO (LED toggles) within timeout.
module b0_tb;
  reg clk, resetn;
  wire [2:0] leds;

  soc dut (.clk(clk), .resetn(resetn), .leds(leds));

  always #5 clk = ~clk;

  integer transitions;
  integer cycle;
  reg [2:0] prev_leds;
  integer pass;

  initial begin
    clk      = 0;
    resetn   = 0;
    transitions = 0;
    pass     = 0;

    repeat (8) @(posedge clk);
    resetn = 1;

    // Sample leds after reset; initial state is 3'b111 (all off, active-low)
    @(posedge clk); #1;
    prev_leds = leds;

    for (cycle = 0; cycle < 2000; cycle = cycle + 1) begin
      @(posedge clk); #1;
      if (leds !== prev_leds) begin
        transitions = transitions + 1;
        $display("t=%0t leds %03b → %03b (transition %0d)", $time, prev_leds, leds, transitions);
        prev_leds = leds;
        if (transitions >= 4) begin
          pass = 1;
          cycle = 2000;  // exit loop
        end
      end
    end

    if (pass !== 0)
      $display("PASS: CPU executed firmware, GPIO toggled %0d times", transitions);
    else
      $display("FAIL: only %0d GPIO transitions in 2000 cycles", transitions);

    $finish;
  end
endmodule
