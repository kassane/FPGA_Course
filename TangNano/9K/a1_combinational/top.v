`timescale 1ns/1ps
// A1 demo: walking LED — one of six lights at a time, cycling 0→5 via decoder.
module top (
  input  SYS_CLK,
  input  SYS_RSTn,
  output LED_R,   // LED[0]
  output LED_G,   // LED[1]
  output LED_B,   // LED[2]
  output LED3,
  output LED4,
  output LED5
);

reg [22:0] clk_div;
reg [2:0]  led_sel;   // 0..5

always @(posedge SYS_CLK or negedge SYS_RSTn) begin
  if (!SYS_RSTn) begin
    clk_div <= 0;
    led_sel <= 0;
  end else begin
    clk_div <= clk_div + 1;
    if (clk_div == 23'h7FFFFF) begin   // tick every ~0.31 s
      led_sel <= (led_sel == 3'd5) ? 3'd0 : led_sel + 1;
    end
  end
end

wire [7:0] decoded;
decoder3 dec (.in(led_sel), .en(1'b1), .out(decoded));

// Active-low LEDs
assign LED_R = ~decoded[0];
assign LED_G = ~decoded[1];
assign LED_B = ~decoded[2];
assign LED3  = ~decoded[3];
assign LED4  = ~decoded[4];
assign LED5  = ~decoded[5];

endmodule
