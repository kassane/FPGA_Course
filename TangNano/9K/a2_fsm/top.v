`timescale 1ns/1ps
module top (
  input  SYS_CLK,
  input  SYS_RSTn,
  input  BTN_S1,   // active-low button (pin 3)
  output LED_R,
  output LED_G,
  output LED_B
);

wire btn_clean, btn_press, btn_release;

debounce #(.CYCLES(540_000)) u_deb (
  .clk        (SYS_CLK),
  .rst_n      (SYS_RSTn),
  .btn_raw    (BTN_S1),
  .btn_clean  (btn_clean),
  .btn_press  (btn_press),
  .btn_release(btn_release)
);

led_fsm #(.HOLD_CYCLES(27_000_000), .BLINK_HALF(1_350_000)) u_fsm (
  .clk        (SYS_CLK),
  .rst_n      (SYS_RSTn),
  .btn_press  (btn_press),
  .btn_release(btn_release),
  .led        (LED_R)
);

// Green: button currently held (debounced), Blue: blink state indicator
assign LED_G = btn_clean;   // low (lit) when button pressed
assign LED_B = 1'b1;        // off — repurpose in later modules

endmodule
