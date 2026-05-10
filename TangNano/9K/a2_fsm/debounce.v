`timescale 1ns/1ps
// Debounce: 2-FF sync + stable-count filter. btn_raw active-low. CYCLES stable samples required.
module debounce #(parameter CYCLES = 20'd540_000) ( // ~20 ms at 27 MHz
  input  clk,
  input  rst_n,
  input  btn_raw,
  output reg btn_clean,   // stable, synchronised button state (active-low)
  output     btn_press,   // 1-cycle pulse: clean fell (button pressed)
  output     btn_release  // 1-cycle pulse: clean rose (button released)
);
  reg btn_s0, btn_s1;          // 2-FF synchroniser
  reg [19:0] cnt;
  reg btn_prev;

  always @(posedge clk or negedge rst_n)
    if (!rst_n) {btn_s1, btn_s0} <= 2'b11;
    else        {btn_s1, btn_s0} <= {btn_s0, btn_raw};

  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      cnt <= 0; btn_clean <= 1'b1;
    end else if (btn_s1 != btn_clean) begin
      if (cnt == CYCLES - 1) begin cnt <= 0; btn_clean <= btn_s1; end
      else                         cnt <= cnt + 1;
    end else
      cnt <= 0;

  always @(posedge clk or negedge rst_n)
    if (!rst_n) btn_prev <= 1'b1;
    else        btn_prev <= btn_clean;

  assign btn_press   =  btn_prev & ~btn_clean; // falling edge = pressed
  assign btn_release = ~btn_prev &  btn_clean; // rising edge  = released
endmodule
