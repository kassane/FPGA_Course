`timescale 1ns/1ps
// A3 UART echo testbench. CPB=10 for fast simulation (CLK_HZ=10, BAUD=1).
module a3_tb;

  localparam CLK_HZ = 10;
  localparam BAUD   = 1;
  localparam CPB    = 10;  // clocks per bit at sim params

  reg clk = 0, rst_n = 0, rx_line = 1;
  wire tx_line, led_r, led_g, led_b;

  always #5 clk = ~clk;

  top #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) u_top (
    .SYS_CLK  (clk),
    .SYS_RSTn (rst_n),
    .UART_RX  (rx_line),
    .UART_TX  (tx_line),
    .LED_R    (led_r),
    .LED_G    (led_g),
    .LED_B    (led_b)
  );

  integer fail = 0;
  task check; input cond; input integer id;
    if (!cond) begin $display("FAIL: test %0d", id); fail = fail + 1; end
  endtask

  // Drive 8N1 UART frame on rx_line. Changes happen 1 ns after posedge to avoid DUT race.
  task send_byte;
    input [7:0] b;
    integer i;
    begin
      rx_line = 1'b0;
      repeat(CPB) @(posedge clk); #1;  // start bit
      for (i = 0; i < 8; i = i + 1) begin
        rx_line = b[i];
        repeat(CPB) @(posedge clk); #1;
      end
      rx_line = 1'b1;
      repeat(CPB) @(posedge clk); #1;  // stop bit
    end
  endtask

  // Sample 8N1 frame from tx_line, mid-bit aligned (HALF = CPB/2 = 5).
  task recv_byte;
    output [7:0] b;
    integer i;
    reg [7:0] tmp;
    begin
      @(negedge tx_line);
      repeat(CPB/2) @(posedge clk); #1;  // centre on start bit
      for (i = 0; i < 8; i = i + 1) begin
        repeat(CPB) @(posedge clk); #1;
        tmp[i] = tx_line;
      end
      b = tmp;
      repeat(CPB) @(posedge clk);  // stop bit
    end
  endtask

  reg [7:0] rxd;

  initial begin
    rst_n = 0; repeat(4) @(posedge clk); #1;
    rst_n = 1; repeat(2) @(posedge clk); #1;
    check(tx_line === 1'b1, 1);  // TX idle-high after reset

    // Test A: alternating bits 0x55 ('U')
    fork send_byte(8'h55); recv_byte(rxd); join
    check(rxd === 8'h55, 2);

    // Test B: inverted alternating bits 0xAA
    fork send_byte(8'hAA); recv_byte(rxd); join
    check(rxd === 8'hAA, 3);

    // Test C: 0x0D (CR)
    fork send_byte(8'h0D); recv_byte(rxd); join
    check(rxd === 8'h0D, 4);

    repeat(4) @(posedge clk);

    if (fail == 0) $display("PASS: all A3 UART tests passed");
    else           $display("FAIL: %0d test(s) failed", fail);
    $finish;
  end

endmodule
