# TangNano 9K — FPGA Course

Board: Sipeed TangNano 9K (GW1NR-9C, QN88P)  
Toolchain: Yosys · nextpnr-himbaechel · apicula · openFPGALoader · Verilator

---

## Prerequisites

| Tool | Package / Build |
|------|-----------------|
| `yosys` | `pacman -S yosys` |
| `nextpnr-himbaechel` | build from `vendor/nextpnr/` (see below) |
| `gowin_pack` | `vendor/apicula/` (PYTHONPATH set by Makefile) |
| `openFPGALoader` | `pacman -S openfpgaloader` |
| `verilator` | `pacman -S verilator` |

**Build nextpnr once** (from repo root):
```sh
cmake -B vendor/nextpnr/build vendor/nextpnr \
  -DARCH=himbaechel -DHIMBAECHEL_UARCH=gowin \
  -DHIMBAECHEL_GOWIN_DEVICES=GW1N-9C \
  -DBUILD_GUI=OFF -DBUILD_PYTHON=ON \
  -DBoost_NO_BOOST_CMAKE=ON -DBOOST_ROOT=/usr \
  -DEigen3_DIR=/usr/share/eigen3/cmake
cmake --build vendor/nextpnr/build -j$(nproc)
```

---

## Makefile targets

All commands run from `TangNano/`:

```sh
make sim       MODULE=9K/<module>   # simulate with Verilator
make host-all  MODULE=9K/<module>   # synth + PnR + pack
make host-prog MODULE=9K/<module>   # flash to board
```

---

## Modules

### hello — A0 Blink

Three LEDs blink at different rates driven by a free-running counter.

```sh
make sim       MODULE=9K/hello
make host-all  MODULE=9K/hello
make host-prog MODULE=9K/hello
```

**Files:** `blink.v`, `blink_tb.v`

---

### a1_combinational — Combinational Logic

Walking LED using a 3-to-8 decoder. One of six LEDs lights at a time, cycling every ~0.3 s.

Includes standalone `mux2` and `decoder3` modules exercised by the testbench.

```sh
make sim       MODULE=9K/a1_combinational
make host-all  MODULE=9K/a1_combinational
make host-prog MODULE=9K/a1_combinational
```

**Files:** `mux2.v`, `decoder3.v`, `top.v`, `a1_tb.v`

---

### a2_fsm — Finite State Machine + Debounce

Button-driven LED FSM with hardware debounce.

- Short press: toggles LED_R
- Hold >1 s: LED_R blinks at 10 Hz
- Release: returns to stable state
- LED_G: lit while button is physically held

```sh
make sim       MODULE=9K/a2_fsm
make host-all  MODULE=9K/a2_fsm
make host-prog MODULE=9K/a2_fsm
```

**Files:** `debounce.v`, `led_fsm.v`, `top.v`, `a2_tb.v`

---

### a3_uart — UART Echo

8N1 UART echo at 115200 baud. Every byte received on RX is echoed back on TX.

- LED_R: lit while TX active
- LED_G: flashes 10 ms on each received byte

```sh
make sim       MODULE=9K/a3_uart
make host-all  MODULE=9K/a3_uart
make host-prog MODULE=9K/a3_uart
```

Test on host after flashing:
```sh
picocom -b 115200 /dev/ttyUSB0
```

**Files:** `uart_rx.v`, `uart_tx.v`, `top.v`, `a3_tb.v`

---

### a4_spi — SPI Master

SPI master (mode 0, 8-bit, MSB-first) sending a continuous incrementing byte stream.

- LED_R: lit while CS asserted
- LED_G: flashes 10 ms on each completed transfer

```sh
make sim       MODULE=9K/a4_spi
make host-all  MODULE=9K/a4_spi
make host-prog MODULE=9K/a4_spi
```

> **Note:** SPI pin assignments in `tangnano9k.cst` should be verified against the
> [Sipeed schematic](https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K.html)
> before flashing.

**Files:** `spi_master.v`, `top.v`, `a4_tb.v`

---

### a5_pwm — PWM LED Brightness

Button cycles all three LEDs through 5 brightness levels (0 → 25 → 50 → 75 → 100%) using a PWM carrier at 10 kHz. Inline debounce via a power-of-2 counter (~10 ms at 27 MHz).

```sh
make sim       MODULE=9K/a5_pwm
make host-all  MODULE=9K/a5_pwm
make host-prog MODULE=9K/a5_pwm
```

**Files:** `pwm.v`, `top.v`, `a5_tb.v`

---

---

## Track B — Soft CPU (PicoRV32 / RV32I)

### b0_picorv32 — PicoRV32 SoC

Minimal SoC: PicoRV32 (RV32I) + 1 KB BRAM + GPIO.

**Memory map:**

| Address | Size | Description |
|---------|------|-------------|
| `0x00000000` | 1 KB | BRAM (256 × 32-bit words) |
| `0x20000000` | 4 B | GPIO write-only (bits[2:0] = LED_R/G/B, active-low) |

**Firmware** (`9K/b0_picorv32/firmware/`): written in Zig using `callconv(.naked)` inline assembly. No runtime, no libc. Build produces `firmware.hex` loaded into BRAM via `$readmemh`.

```sh
# Firmware only (regenerates firmware.hex)
cd 9K/b0_picorv32/firmware && zig build

# Adjust blink speed (default DELAY=5, use ~1000 for ~1 Hz visible blink)
cd 9K/b0_picorv32/firmware && zig build -Ddelay=1000

# Full flow
make sim       MODULE=9K/b0_picorv32
make host-all  MODULE=9K/b0_picorv32
make host-prog MODULE=9K/b0_picorv32
```

> With `DELAY=5` (default) the blink runs at ~200 Hz — LEDs appear dim but on.
> Use `-Ddelay=1000` for a visible ~1 Hz blink on hardware.

**Files:** `top.v`, `soc.v`, `b0_tb.v`, `picorv32.vlt`, `firmware/start.zig`, `firmware/build.zig`, `firmware/bin2hex.py`

---

### b1_cpu — C Firmware

Same PicoRV32 SoC as B0. Firmware written in C (`zig cc`, no libc). Demonstrates a binary counter on all three LEDs — counts 0–7, each step shown as 3-bit active-low pattern.

```sh
# Firmware only
cd 9K/b1_cpu/firmware && zig build

# Adjust step speed (default 50000 iterations ≈ visible on hardware)
cd 9K/b1_cpu/firmware && zig build -Ddelay=50000

# Full flow
make sim       MODULE=9K/b1_cpu
make host-all  MODULE=9K/b1_cpu
make host-prog MODULE=9K/b1_cpu
```

LED pattern (active-low, bit2=LED_B, bit1=LED_G, bit0=LED_R):

| Count | leds[2:0] | LED_R | LED_G | LED_B |
|-------|-----------|-------|-------|-------|
| 0 | 111 | on | on | on |
| 1 | 110 | off | on | on |
| 2 | 101 | on | off | on |
| 3 | 100 | off | off | on |
| 4 | 011 | on | on | off |
| 5 | 010 | off | on | off |
| 6 | 001 | on | off | off |
| 7 | 000 | off | off | off |

**Files:** `top.v`, `soc.v`, `b1_tb.v`, `picorv32.vlt`, `firmware/start.S`, `firmware/main.c`, `firmware/build.zig`, `firmware/bin2hex.py`

---

### b2_zig — Native Zig Firmware

Same PicoRV32 SoC. Firmware written entirely in Zig — no C, no assembly file. Demonstrates comptime pattern tables, type-safe MMIO via a `Gpio` struct, and wrapping `u3` arithmetic for index cycling.

Pattern: knight-rider / cylon scanner (active-low)

```
R on → G on → B on → G on → R on → all off → all on → all off → repeat
```

```sh
# Firmware only
cd 9K/b2_zig/firmware && zig build

# Adjust step speed (default 50000 iterations ≈ visible on hardware)
cd 9K/b2_zig/firmware && zig build -Ddelay=50000

# Full flow
make sim       MODULE=9K/b2_zig
make host-all  MODULE=9K/b2_zig
make host-prog MODULE=9K/b2_zig
```

Key Zig features used:

| Feature | Usage |
|---------|-------|
| `callconv(.naked)` | Zero-overhead entry point (`_start`) |
| `*volatile u32` | Memory-mapped GPIO register |
| `[8]u3` comptime array | Pattern table embedded in `.rodata` |
| `u3` wrapping index | `+%=` cycles 0–7 without division |
| `asm volatile` clobbers | Struct-based: `.{ .memory = true, .sp = true }` |

**Files:** `top.v`, `soc.v`, `b2_tb.v`, `picorv32.vlt`, `firmware/firmware.zig`, `firmware/build.zig`, `firmware/bin2hex.py`

**PicoRV32 configuration:**

| Parameter | Value |
|-----------|-------|
| `COMPRESSED_ISA` | 0 (pure RV32I) |
| `BARREL_SHIFTER` | 0 |
| `ENABLE_MUL/DIV` | 0 |
| `ENABLE_IRQ` | 0 |
| `PROGADDR_RESET` | `0x00000000` |
| `STACKADDR` | `0x00000400` |

---

## Pin assignments

See `tangnano9k.cst`. Always verify against the Sipeed schematic before programming.

| Signal | Pin |
|--------|-----|
| SYS_CLK | 52 |
| SYS_RSTn | 4 |
| LED_R / G / B | 10 / 11 / 13 |
| LED3 / 4 / 5 | 14 / 15 / 16 |
| BTN_S1 | 3 |
| UART_TX / RX | 17 / 18 |
| SPI_SCK / MOSI / MISO / CS_N | 36 / 37 / 38 / 39 |
