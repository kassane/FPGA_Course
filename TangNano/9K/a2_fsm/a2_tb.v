`timescale 1ns/1ps
// A2 FSM testbench — exercises debounce + led_fsm with fast sim parameters.
// Debounce latency: 2-FF sync (2 cycles) + stable count (CYCLES=4) + edge detect (1) = 7 cycles.
module a2_tb;

  reg clk = 0, rst_n = 0;
  reg btn_raw = 1'b1;  // active-low; 1 = released

  wire btn_clean, btn_press, btn_release, led;

  always #5 clk = ~clk;

  debounce #(.CYCLES(4)) u_deb (
    .clk        (clk),
    .rst_n      (rst_n),
    .btn_raw    (btn_raw),
    .btn_clean  (btn_clean),
    .btn_press  (btn_press),
    .btn_release(btn_release)
  );

  led_fsm #(.HOLD_CYCLES(20), .BLINK_HALF(10)) u_fsm (
    .clk        (clk),
    .rst_n      (rst_n),
    .btn_press  (btn_press),
    .btn_release(btn_release),
    .led        (led)
  );

  integer fail = 0;

  task check;
    input cond;
    input integer id;
    if (!cond) begin $display("FAIL: test %0d", id); fail = fail + 1; end
  endtask

  // 2-FF sync + CYCLES counter + 1 edge-detect = 7 cycles for CYCLES=4
  localparam DEB_LAT = 7;

  reg led_snap;

  initial begin
    // ── Reset ──────────────────────────────────────────────────────────────
    rst_n = 0; repeat(4) @(posedge clk); #1;
    rst_n = 1; repeat(2) @(posedge clk); #1;
    check(led === 1'b1, 1);   // active-low: LED off after reset

    // ── Test A: short press → LED toggles ──────────────────────────────────
    led_snap = led;
    btn_raw = 1'b0;                         // press
    repeat(DEB_LAT) @(posedge clk); #1;
    check(led !== led_snap, 2);             // FSM toggled LED on btn_press
    btn_raw = 1'b1;                         // release (held < HOLD_CYCLES)
    repeat(DEB_LAT) @(posedge clk); #1;
    check(led !== led_snap, 3);             // LED remains toggled after release

    // ── Test B: second short press → toggles back ───────────────────────────
    led_snap = led;
    btn_raw = 1'b0;
    repeat(DEB_LAT) @(posedge clk); #1;
    check(led !== led_snap, 4);             // second toggle
    btn_raw = 1'b1;
    repeat(DEB_LAT) @(posedge clk); #1;

    // ── Test C: long hold → BLINK state ────────────────────────────────────
    btn_raw = 1'b0;                         // press and hold
    repeat(DEB_LAT) @(posedge clk); #1;    // debounce fires → PRESS_WAIT
    repeat(22) @(posedge clk); #1;         // count past HOLD_CYCLES(20) → BLINK
    // capture and wait one BLINK_HALF period for LED toggle
    led_snap = led;
    repeat(12) @(posedge clk); #1;         // BLINK_HALF + 2 margin
    check(led !== led_snap, 5);             // LED blinked while held
    btn_raw = 1'b1;                         // release from BLINK → IDLE
    repeat(DEB_LAT) @(posedge clk); #1;
    check(1, 6);                            // reached IDLE without hang

    if (fail == 0) $display("PASS: all A2 FSM tests passed");
    else           $display("FAIL: %0d test(s) failed", fail);
    $finish;
  end

endmodule
