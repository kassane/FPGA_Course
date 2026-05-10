`timescale 1ns/1ps
// B2 testbench: verify PicoRV32 runs Zig firmware and steps through all 8 knight-rider patterns.
`define FIRMWARE_HEX "9K/b2_zig/firmware/firmware.hex"

module b2_tb;
  reg clk = 0, resetn = 0;
  wire [2:0] leds;

  always #5 clk = ~clk;   // 100 MHz sim clock

  initial begin
    repeat (10) @(posedge clk);
    resetn = 1;
  end

  soc dut (
    .clk    (clk),
    .resetn (resetn),
    .leds   (leds)
  );

  reg  [2:0] prev_leds = 3'b111;
  integer    transitions = 0;

  always @(posedge clk) begin
    if (leds !== prev_leds) begin
      $display("t=%0t leds %03b → %03b (step %0d)", $time, prev_leds, leds, transitions + 1);
      prev_leds   <= leds;
      transitions <= transitions + 1;
    end
  end

  initial begin
    #500000;   // 50 000 cycles × 10 ns
    if (transitions >= 8)
      $display("PASS: knight-rider pattern ran %0d steps", transitions);
    else begin
      $display("FAIL: only %0d steps in timeout", transitions);
      $fatal(1);
    end
    $finish;
  end
endmodule
