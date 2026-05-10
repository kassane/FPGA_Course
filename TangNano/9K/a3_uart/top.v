`timescale 1ns/1ps
module top #(
  parameter CLK_HZ = 27_000_000,
  parameter BAUD   =    115_200
) (
  input  SYS_CLK,
  input  SYS_RSTn,
  input  UART_RX,
  output UART_TX,
  output LED_R,   // active-low: lit while TX busy
  output LED_G,   // active-low: flashes ~10 ms on each received byte
  output LED_B
);
  wire [7:0] rx_data;
  wire       rx_valid, tx_ready;

  uart_rx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) u_rx (
    .clk  (SYS_CLK),
    .rst_n(SYS_RSTn),
    .rx   (UART_RX),
    .data (rx_data),
    .valid(rx_valid)
  );

  uart_tx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) u_tx (
    .clk  (SYS_CLK),
    .rst_n(SYS_RSTn),
    .data (rx_data),
    .valid(rx_valid & tx_ready),
    .tx   (UART_TX),
    .ready(tx_ready)
  );

  // Stretch rx_valid to ~10 ms so the LED is visibly lit on each received byte
  localparam STRETCH = CLK_HZ / 100;  // 10 ms worth of cycles
  reg [19:0] rx_stretch;             // 20 bits: covers up to ~1M cycles
  always @(posedge SYS_CLK or negedge SYS_RSTn)
    if (!SYS_RSTn)    rx_stretch <= 0;
    else if (rx_valid) rx_stretch <= STRETCH[19:0];
    else if (|rx_stretch) rx_stretch <= rx_stretch - 1;

  assign LED_R = tx_ready;         // low (lit) while TX busy
  assign LED_G = ~(|rx_stretch);   // low (lit) for 10 ms after each byte
  assign LED_B = 1'b1;             // off
endmodule
