`timescale 1ns/1ps
// A4 demo: continuous SPI transfers of an incrementing byte counter.
module top #(
  parameter CLK_HZ = 27_000_000,
  parameter SCK_HZ =  1_000_000
) (
  input  SYS_CLK,
  input  SYS_RSTn,
  output SPI_SCK,
  output SPI_MOSI,
  input  SPI_MISO,
  output SPI_CS_N,
  output LED_R,   // active-low: lit while CS asserted
  output LED_G,   // active-low: flashes 10 ms on each done pulse
  output LED_B
);
  wire       busy, done;
  wire [7:0] rx_data;
  reg  [7:0] tx_byte;
  reg        start;

  spi_master #(.CLK_HZ(CLK_HZ), .SCK_HZ(SCK_HZ)) u_spi (
    .clk    (SYS_CLK),  .rst_n  (SYS_RSTn),
    .tx_data(tx_byte),  .start  (start),
    .busy   (busy),     .rx_data(rx_data),  .done(done),
    .sck    (SPI_SCK),  .mosi   (SPI_MOSI), .miso(SPI_MISO), .cs_n(SPI_CS_N)
  );

  always @(posedge SYS_CLK or negedge SYS_RSTn) begin
    if (!SYS_RSTn) begin
      tx_byte <= 8'hA5;
      start   <= 0;
    end else begin
      start <= 0;
      if (done) begin
        tx_byte <= tx_byte + 1;
        start   <= 1;
      end else if (!busy) begin
        start <= 1;  // kick first transfer
      end
    end
  end

  localparam STRETCH = CLK_HZ / 100;
  reg [19:0] done_stretch;
  always @(posedge SYS_CLK or negedge SYS_RSTn)
    if (!SYS_RSTn)          done_stretch <= 0;
    else if (done)           done_stretch <= STRETCH[19:0];
    else if (|done_stretch)  done_stretch <= done_stretch - 1;

  assign LED_R = SPI_CS_N;
  assign LED_G = ~(|done_stretch);
  assign LED_B = 1'b1;
endmodule
