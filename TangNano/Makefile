MODULE        ?= 9K/hello
SOURCES       := $(shell find $(MODULE) -name '*.v' -not -name '*_tb.v')

# ── Host-native toolchain (TangNano 9K / GW1NR-9C) ───────────────────────────
# Build nextpnr first (from repo root vendor/nextpnr/):
#   cmake -B build -DARCH=himbaechel -DHIMBAECHEL_UARCH=gowin \
#     -DHIMBAECHEL_GOWIN_DEVICES=GW1N-9C -DBUILD_GUI=OFF -DBUILD_PYTHON=ON \
#     -DBoost_NO_BOOST_CMAKE=ON -DBOOST_ROOT=/usr -DEigen3_DIR=/usr/share/eigen3/cmake
#   cmake --build build -j$(nproc)
VENDOR      := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))../vendor)
NEXTPNR_H   := $(VENDOR)/nextpnr/build/nextpnr-himbaechel
GOWIN_PACK  := PYTHONPATH=$(VENDOR)/apicula python3 -m apycula.gowin_pack
DEVICE_FAM  := GW1N-9C
DEVICE_PART := GW1NR-LV9QN88PC6/I5

# ── Track B (soft CPU): add PicoRV32 source + firmware build ─────────────────
PICORV32_V    := $(VENDOR)/nextpnr/ice40/smoketest/attosoc/picorv32.v
ifneq (,$(filter 9K/b%,$(MODULE)))
SOURCES       += $(PICORV32_V)
FW_HEX        := $(MODULE)/firmware/firmware.hex
$(FW_HEX):
	cd $(MODULE)/firmware && zig build
host-synth: $(FW_HEX)
sim: $(FW_HEX)
endif

SIM_TB      := $(wildcard $(MODULE)/*_tb.v)
SIM_VLT     := $(wildcard $(MODULE)/*.vlt)
SIM_SOURCES := $(SOURCES) $(SIM_TB) $(SIM_VLT)
SIM_TOP     := $(basename $(notdir $(SIM_TB)))

host-synth: $(SOURCES)
	yosys -p "synth_gowin -json top.json -top top" $(SOURCES)

host-pnr: top.json
	$(NEXTPNR_H) --json top.json --write top.pack \
	  --device $(DEVICE_PART) \
	  --vopt family=$(DEVICE_FAM) \
	  --vopt cst=tangnano9k.cst

host-pack: top.pack
	$(GOWIN_PACK) -d $(DEVICE_FAM) -o top.fs top.pack

host-prog: top.fs
	openFPGALoader -b tangnano9k top.fs

host-all: host-synth host-pnr host-pack

sim: $(SIM_SOURCES)
	verilator --binary --top-module $(SIM_TOP) $(SIM_SOURCES) \
	  -o $(SIM_TOP) && ./obj_dir/$(SIM_TOP)

clean:
	rm -f *.json *.fs *.pack
	rm -rf obj_dir

.PHONY: host-synth host-pnr host-pack host-prog host-all sim clean
