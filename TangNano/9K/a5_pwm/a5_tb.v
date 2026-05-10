`timescale 1ns/1ps
// A5 testbench: verify PWM duty steps and button-driven cycling.
module a5_tb;
  // Fast params: CLK_HZ=100, PWM_HZ=10 → PERIOD=10, DEB_BITS=4 (div overflows every 16)
  parameter CLK_HZ   = 100;
  parameter PWM_HZ   = 10;
  parameter DEB_BITS = 4;
  parameter PERIOD   = CLK_HZ / PWM_HZ;   // 10
  parameter HALF_DIV = (1 << DEB_BITS);    // 16 cycles per debounce tick

  reg clk, rst_n, btn;
  wire led_r, led_g, led_b;

  top #(
    .CLK_HZ(CLK_HZ),
    .PWM_HZ(PWM_HZ),
    .DEB_BITS(DEB_BITS)
  ) dut (
    .SYS_CLK(clk),
    .SYS_RSTn(rst_n),
    .BTN_S1(btn),
    .LED_R(led_r),
    .LED_G(led_g),
    .LED_B(led_b)
  );

  always #5 clk = ~clk;   // 100 MHz → 10 ns period (scaled)

  // Count PWM high cycles over one PERIOD window; return duty count.
  task automatic measure_duty;
    output integer high_cnt;
    integer i;
    begin
      high_cnt = 0;
      // Align to next PWM cycle start: wait until led_r goes high (active-low → low means out=1)
      // LED is ~pwm_out, so LED=0 when pwm_out=1 (on). Measure pwm_out directly via led_r inversion.
      for (i = 0; i < PERIOD; i = i + 1) begin
        @(posedge clk); #1;
        if (!led_r) high_cnt = high_cnt + 1;  // led=0 means pwm_out=1
      end
    end
  endtask

  // Press button (active-low) for enough cycles to pass debounce.
  task press_btn;
    integer i;
    begin
      btn = 0;  // assert (active-low)
      repeat (HALF_DIV * 2) @(posedge clk);
      btn = 1;  // release
      repeat (HALF_DIV * 2) @(posedge clk);
    end
  endtask

  integer high_cnt;
  integer step;
  integer expected;
  integer pass;

  integer expected_duties [0:4];

  initial begin
    $dumpfile("a5_tb.vcd");
    $dumpvars(0, a5_tb);

    clk   = 0;
    rst_n = 0;
    btn   = 1;   // idle (active-low, unpressed)

    repeat (4) @(posedge clk);
    rst_n = 1;
    repeat (8) @(posedge clk);

    // Expected duty counts per step (out of PERIOD=10 cycles):
    // step0=0%, step1=25%=2, step2=50%=5, step3=75%=7, step4=100%=10
    // (D1=PERIOD/4=2, D2=PERIOD/2=5, D3=PERIOD*3/4=7, D4=PERIOD=10)
    expected_duties[0] = 0;
    expected_duties[1] = PERIOD / 4;
    expected_duties[2] = PERIOD / 2;
    expected_duties[3] = PERIOD * 3 / 4;
    expected_duties[4] = PERIOD;

    pass = 1;

    // Step 0 on reset: duty = 0 (all off)
    measure_duty(high_cnt);
    if (high_cnt !== expected_duties[0]) begin
      $display("FAIL step0: duty=%0d expected=%0d", high_cnt, expected_duties[0]);
      pass = 0;
    end else $display("PASS step0: duty=%0d", high_cnt);

    // Cycle through steps 1..4
    for (step = 1; step <= 4; step = step + 1) begin
      press_btn;
      measure_duty(high_cnt);
      expected = expected_duties[step];
      if (high_cnt !== expected) begin
        $display("FAIL step%0d: duty=%0d expected=%0d", step, high_cnt, expected);
        pass = 0;
      end else $display("PASS step%0d: duty=%0d", step, high_cnt);
    end

    // Wrap back to step 0 (5th press)
    press_btn;
    measure_duty(high_cnt);
    if (high_cnt !== expected_duties[0]) begin
      $display("FAIL wrap step0: duty=%0d expected=%0d", high_cnt, expected_duties[0]);
      pass = 0;
    end else $display("PASS wrap step0: duty=%0d", high_cnt);

    if (pass !== 0) $display("ALL PASS");
    $finish;
  end
endmodule
