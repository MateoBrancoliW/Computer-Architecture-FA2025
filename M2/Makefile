# ===========================================================
# Simple IceBlinkPico Makefile + Simulation (Icarus/GTKWave)
# ===========================================================

filename  = top
pcf_file  = ../common/iceBlinkPico.pcf

# HDL sources
rtl       = top.sv state_timebase.sv pwm_duty_engine.sv pwm_state_lookup.sv
tb        = tb_min
sim_src   = $(rtl) $(tb).sv

# Toolchain (OSS-CAD-Suite tools expected on PATH)
YOSYS     = yosys
NEXTPNR   = nextpnr-ice40
ICEPACK   = icepack
DFUUTIL   = dfu-util
IVERILOG  = iverilog
VVP       = vvp
GTKWAVE   = gtkwave

# -----------------------------------------------------------
#  FPGA BUILD FLOW
# -----------------------------------------------------------
.PHONY: all build prog simv run view clean
all: build

build:
	$(YOSYS) -p "synth_ice40 -top $(filename) -json $(filename).json" $(rtl)
	$(NEXTPNR) --up5k --package sg48 --json $(filename).json --pcf $(pcf_file) --asc $(filename).asc --pcf-allow-unconstrained
	$(ICEPACK) $(filename).asc $(filename).bin
	@echo "✅ Build complete: $(filename).bin ready"

prog:  # Flash to IceBlink Pico (SRAM)
	$(DFUUTIL) --device 1d50:6146 --alt 0 -D $(filename).bin -R
	@echo "✅ Bitstream programmed to FPGA"

# -----------------------------------------------------------
#  SIMULATION FLOW
# -----------------------------------------------------------
simv: $(sim_src)
	@echo "[Compiling Verilog sources]"
	$(IVERILOG) -g2012 -Wall -Wno-timescale -o simv -s $(tb) $(sim_src)

run: simv
	@echo "[Running simulation]"
	$(VVP) simv

view:
	@echo "[Opening GTKWave]"
	$(GTKWAVE) wave.vcd &

# -----------------------------------------------------------
#  CLEANUP (Windows-friendly + Unix fallback)
# -----------------------------------------------------------
clean:
	@echo "[Cleaning build + simulation artifacts]"
	- del /q /f $(filename).blif $(filename).asc $(filename).json $(filename).bin simv wave.vcd 2>nul || true
	- rm  -f    $(filename).blif $(filename).asc $(filename).json $(filename).bin simv wave.vcd 2>/dev/null || true