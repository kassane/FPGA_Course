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
