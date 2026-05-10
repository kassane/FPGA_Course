# FPGA Course

Hands-on FPGA curriculum using open-source toolchains.

## Boards

| Board | Dir | Device | Toolchain |
|-------|-----|--------|-----------|
| Sipeed TangNano 9K | `TangNano/` | GW1NR-9C (QN88P) | Yosys · nextpnr-himbaechel · apicula · openFPGALoader |
| Intel DE10 *(TODO/WIP)* | `DE10/` | Cyclone V | Quartus |

## Curriculum

Two parallel tracks, each building on the previous module:

### Track A — HDL (TangNano 9K)

| Module | Topic | Key concepts |
|--------|-------|--------------|
| A0 `hello` | Blink | Toolchain setup, counter, clock divider |
| A1 `a1_combinational` | Combinational logic | Mux, decoder, walking LED |
| A2 `a2_fsm` | FSM + Debounce | State machines, button input, timing |
| A3 `a3_uart` | UART | Serial protocol, 8N1, echo loopback |
| A4 `a4_spi` | SPI master | SPI mode 0, shift register, CS |
| A5 `a5_pwm` | PWM brightness | PWM, duty cycle, button-driven steps |

### Track B — Soft CPU (TangNano 9K)

| Module | Topic | Key concepts |
|--------|-------|--------------|
| B0 `b0_picorv32` | PicoRV32 SoC | RV32I CPU, BRAM, memory-mapped GPIO, Zig inline asm firmware |
| B1 `b1_cpu` | C firmware | `zig cc`, libc-free C, 3-bit binary counter on LEDs |
| B2 `b2_zig` | Zig firmware | Native Zig, comptime patterns, type-safe MMIO, knight-rider LEDs |
## Toolchain setup

### TangNano 9K

```sh
# Arch Linux packages
pacman -S yosys verilator openfpgaloader python

# Build nextpnr-himbaechel once from vendor/
cmake -B vendor/nextpnr/build vendor/nextpnr \
  -DARCH=himbaechel -DHIMBAECHEL_UARCH=gowin \
  -DHIMBAECHEL_GOWIN_DEVICES=GW1N-9C \
  -DBUILD_GUI=OFF -DBUILD_PYTHON=ON \
  -DBoost_NO_BOOST_CMAKE=ON -DBOOST_ROOT=/usr \
  -DEigen3_DIR=/usr/share/eigen3/cmake
cmake --build vendor/nextpnr/build -j$(nproc)
```

### Zig (Track B firmware)

Track B firmware uses [Zig](https://ziglang.org/) 0.16.0 or master. The `build.zig` in each firmware directory is self-contained.

```sh
cd TangNano/9K/b0_picorv32/firmware && zig build
```

## Makefile quick reference

All commands run from `TangNano/`:

```sh
make sim       MODULE=9K/<module>   # Verilator simulation
make host-all  MODULE=9K/<module>   # synth + PnR + pack (→ top.fs)
make host-prog MODULE=9K/<module>   # flash via openFPGALoader
make clean                          # remove build artefacts
```

See `TangNano/README.md` for full module documentation and pin assignments.
