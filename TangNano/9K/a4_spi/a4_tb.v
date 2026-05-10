`timescale 1ns/1ps
// A4 SPI testbench. MISO=MOSI loopback verifies round-trip byte integrity.
// CLK_HZ=20, SCK_HZ=1 → HALF=10; one 8-bit transfer = 2 + 16*10 = 162 cycles.
module a4_tb;

  localparam CLK_HZ = 20;
  localparam SCK_HZ = 1;

  reg clk = 0, rst_n = 0;
  always #5 clk = ~clk;

  reg  [7:0] tx_data;
  reg        start = 0;
  wire       busy, done;
  wire [7:0] rx_data;
  wire       sck, mosi, cs_n;

  spi_master #(.CLK_HZ(CLK_HZ), .SCK_HZ(SCK_HZ)) u_spi (
    .clk    (clk),    .rst_n  (rst_n),
    .tx_data(tx_data), .start (start),
    .busy   (busy),   .rx_data(rx_data), .done(done),
    .sck    (sck),    .mosi   (mosi),    .miso(mosi),  // loopback
    .cs_n   (cs_n)
  );

  integer fail = 0;
  task check; input cond; input integer id;
    if (!cond) begin $display("FAIL: test %0d", id); fail = fail + 1; end
  endtask

  task send_and_check;
    input [7:0] b;
    input integer id;
    begin
      @(posedge clk); #1;
      tx_data = b; start = 1;
      @(posedge clk); #1;
      start = 0;
      @(posedge done);
      @(posedge clk); #1;
      check(rx_data === b, id);
      check(cs_n === 1'b1, id + 100);
    end
  endtask

  initial begin
    rst_n = 0; repeat(4) @(posedge clk); #1;
    rst_n = 1; repeat(2) @(posedge clk); #1;
    check(cs_n === 1'b1, 1);

    send_and_check(8'hA5, 2);  // alternating 10100101
    send_and_check(8'h5A, 3);  // alternating 01011010
    send_and_check(8'h00, 4);  // all zeros
    send_and_check(8'hFF, 5);  // all ones

    repeat(4) @(posedge clk);
    if (fail == 0) $display("PASS: all A4 SPI tests passed");
    else           $display("FAIL: %0d test(s) failed", fail);
    $finish;
  end

endmodule
