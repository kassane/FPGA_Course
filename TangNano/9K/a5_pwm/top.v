`timescale 1ns/1ps
// A5 demo: button cycles LED brightness through 5 PWM duty levels (0→25→50→75→100%).
// Inline debounce: 2-FF sync sampled every 2^DEB_BITS cycles (~10 ms at 27 MHz).
module top #(
  parameter CLK_HZ   = 27_000_000,
  parameter PWM_HZ   = 10_000,      // PWM carrier frequency
  parameter DEB_BITS = 18           // debounce tick = 2^DEB_BITS cycles
) (
  input  SYS_CLK,
  input  SYS_RSTn,
  input  BTN_S1,    // active-low
  output LED_R,
  output LED_G,
  output LED_B
);
  localparam PERIOD = CLK_HZ / PWM_HZ;
  localparam D0 = 0;
  localparam D1 = PERIOD / 4;
  localparam D2 = PERIOD / 2;
  localparam D3 = PERIOD * 3 / 4;
  localparam D4 = PERIOD;

  // Inline debounce
  reg [DEB_BITS-1:0] div;
  always @(posedge SYS_CLK or negedge SYS_RSTn)
    if (!SYS_RSTn) div <= 0; else div <= div + 1;

  reg bs0, bs1, bp;
  always @(posedge SYS_CLK or negedge SYS_RSTn)
    if (!SYS_RSTn) {bs1, bs0, bp} <= 3'b111;
    else begin
      {bs1, bs0} <= {bs0, BTN_S1};
      if (&div) bp <= bs1;
    end
  wire btn_press = (&div) & bp & ~bs1;

  // Step counter: 0..4
  reg [2:0] step;
  always @(posedge SYS_CLK or negedge SYS_RSTn)
    if (!SYS_RSTn) step <= 0;
    else if (btn_press)
      step <= (step == 3'd4) ? 3'd0 : step + 1;

  // Duty lookup (pure combinational, no multiplier)
  reg [11:0] duty;
  always @(*) case (step)
    3'd0: duty = D0[11:0];
    3'd1: duty = D1[11:0];
    3'd2: duty = D2[11:0];
    3'd3: duty = D3[11:0];
    default: duty = D4[11:0];
  endcase

  wire pwm_out;
  pwm #(.WIDTH(12)) u_pwm (
    .clk   (SYS_CLK),
    .rst_n (SYS_RSTn),
    .period(PERIOD[11:0]),
    .duty  (duty),
    .out   (pwm_out)
  );

  // Active-low LEDs — all three show the same brightness level
  assign LED_R = ~pwm_out;
  assign LED_G = ~pwm_out;
  assign LED_B = ~pwm_out;
endmodule
