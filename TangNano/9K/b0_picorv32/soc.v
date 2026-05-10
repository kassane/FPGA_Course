`timescale 1ns/1ps
// B0 minimal SoC: PicoRV32 (RV32I) + 1 KB BRAM + GPIO.
// Memory map:
//   0x00000000 - 0x000003FF : BRAM (256 x 32-bit words, 1 KB)
//   0x20000000              : GPIO write-only (bit0=LED_R, bit1=LED_G, bit2=LED_B, active-low)
`ifndef FIRMWARE_HEX
`define FIRMWARE_HEX "9K/b0_picorv32/firmware/firmware.hex"
`endif

module soc (
  input        clk,
  input        resetn,
  output [2:0] leds      // active-low
);
  localparam MEM_WORDS = 256;
  localparam MEM_BITS  = 8;   // log2(256)

  // ── PicoRV32 memory bus ─────────────────────────────────────────────────────
  wire        mem_valid, mem_instr, mem_ready;
  wire [31:0] mem_addr, mem_wdata, mem_rdata;
  wire [3:0]  mem_wstrb;

  // ── BRAM (synchronous read, 1-cycle latency) ─────────────────────────────────
  reg [31:0] ram [0:MEM_WORDS-1];
  initial $readmemh(`FIRMWARE_HEX, ram);

  wire [MEM_BITS-1:0] word_addr = mem_addr[MEM_BITS+1:2];
  wire ram_sel = mem_valid && (mem_addr[31:MEM_BITS+2] == 0);

  reg [31:0] ram_rdata;
  reg        ram_ready;

  always @(posedge clk) begin
    if (ram_sel) begin
      if (mem_wstrb[0]) ram[word_addr][ 7: 0] <= mem_wdata[ 7: 0];
      if (mem_wstrb[1]) ram[word_addr][15: 8] <= mem_wdata[15: 8];
      if (mem_wstrb[2]) ram[word_addr][23:16] <= mem_wdata[23:16];
      if (mem_wstrb[3]) ram[word_addr][31:24] <= mem_wdata[31:24];
      ram_rdata <= ram[word_addr];
    end
  end

  always @(posedge clk or negedge resetn)
    if (!resetn) ram_ready <= 0;
    else         ram_ready <= ram_sel && !ram_ready;

  // ── GPIO ────────────────────────────────────────────────────────────────────
  wire gpio_sel = mem_valid && (mem_addr[31:28] == 4'h2);
  reg [2:0] led_reg;

  always @(posedge clk or negedge resetn)
    if (!resetn) led_reg <= 3'b111;
    else if (gpio_sel && mem_wstrb[0]) led_reg <= mem_wdata[2:0];

  assign leds = led_reg;

  // ── Bus arbiter ─────────────────────────────────────────────────────────────
  assign mem_ready = (ram_sel && ram_ready) || gpio_sel;
  assign mem_rdata = ram_rdata;

  // ── PicoRV32 ────────────────────────────────────────────────────────────────
  picorv32 #(
    .PROGADDR_RESET (32'h0000_0000),
    .STACKADDR      (MEM_WORDS * 4),
    .BARREL_SHIFTER (0),
    .COMPRESSED_ISA (0),
    .ENABLE_MUL     (0),
    .ENABLE_DIV     (0),
    .ENABLE_IRQ     (0),
    .ENABLE_IRQ_QREGS(0),
    .ENABLE_TRACE   (0)
  ) cpu (
    .clk           (clk),       .resetn        (resetn),
    .mem_valid     (mem_valid), .mem_instr     (mem_instr),
    .mem_ready     (mem_ready), .mem_addr      (mem_addr),
    .mem_wdata     (mem_wdata), .mem_wstrb     (mem_wstrb),
    .mem_rdata     (mem_rdata), .trap          (),
    // Look-ahead interface (unused)
    .mem_la_read   (),          .mem_la_write  (),
    .mem_la_addr   (),          .mem_la_wdata  (),
    .mem_la_wstrb  (),
    // Co-processor interface (ENABLE_PCPI=0)
    .pcpi_valid    (),          .pcpi_insn     (),
    .pcpi_rs1      (),          .pcpi_rs2      (),
    .pcpi_wr       (1'b0),      .pcpi_rd       (32'h0),
    .pcpi_wait     (1'b0),      .pcpi_ready    (1'b0),
    // IRQ (ENABLE_IRQ=0)
    .irq           (32'h0),     .eoi           (),
    // Trace (ENABLE_TRACE=0)
    .trace_valid   (),          .trace_data    ()
  );
endmodule
