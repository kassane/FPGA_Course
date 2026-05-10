`timescale 1ns/1ps
module a1_tb;

  // ── mux2 ──────────────────────────────────────────────────────────────────
  reg  [3:0] m_a = 4'hA, m_b = 4'hB;
  reg        m_sel = 0;
  wire [3:0] m_y;
  mux2 #(.WIDTH(4)) u_mux(.a(m_a), .b(m_b), .sel(m_sel), .y(m_y));

  // ── decoder3 ──────────────────────────────────────────────────────────────
  reg  [2:0] d_in = 0;
  reg        d_en = 0;
  wire [7:0] d_out;
  decoder3 u_dec(.in(d_in), .en(d_en), .out(d_out));

  // ── top (walking LED) smoke test ──────────────────────────────────────────
  reg  SYS_CLK = 0, SYS_RSTn = 0;
  wire LED_R, LED_G, LED_B, LED3, LED4, LED5;
  top u_top(
    .SYS_CLK(SYS_CLK), .SYS_RSTn(SYS_RSTn),
    .LED_R(LED_R), .LED_G(LED_G), .LED_B(LED_B),
    .LED3(LED3), .LED4(LED4), .LED5(LED5)
  );
  always #5 SYS_CLK = ~SYS_CLK;

  integer i, fail = 0;

  task check(input cond, input integer id);
    if (!cond) begin $display("FAIL: test %0d", id); fail = fail + 1; end
  endtask

  initial begin
    // mux2: sel=0 → a, sel=1 → b
    m_sel = 0; #1; check(m_y === 4'hA, 1);
    m_sel = 1; #1; check(m_y === 4'hB, 2);

    // decoder3: disabled → all zeros
    d_en = 0; d_in = 3; #1; check(d_out === 8'b0, 3);

    // decoder3: each input lights exactly one bit
    d_en = 1;
    for (i = 0; i < 8; i = i + 1) begin
      d_in = i[2:0]; #1;
      check(d_out === (8'b1 << i), 10 + i);
    end

    // top: after reset, exactly one LED is low (one decoder bit active)
    SYS_RSTn = 1; #20;
    check($countones({~LED_R,~LED_G,~LED_B,~LED3,~LED4,~LED5}) == 1, 20);

    if (fail == 0) $display("PASS: all A1 combinational tests passed");
    else           $display("FAIL: %0d test(s) failed", fail);
    $finish;
  end
endmodule
