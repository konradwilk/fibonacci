# FPGA variables
PROJECT = fpga/fibonacci
SOURCES= src/fibonacci.v src/clkdiv.v src/wb_logic.v src/fpga.v src/wrapper.v
ICEBREAKER_DEVICE = up5k
ICEBREAKER_PIN_DEF = fpga/icebreaker.pcf
ICEBREAKER_PACKAGE = sg48
SEED = 1

# COCOTB variables
export COCOTB_REDUCED_LOG_FMT=1

all: test_fibonacci test_wb_logic prove_fibonacci test_wrapper

test_fibonacci:
	rm -rf sim_build/
	mkdir sim_build/
	iverilog -o sim_build/sim.vvp -s fibonacci -s dump -g2012 src/fibonacci.v test/dump_fibonacci.v
	PYTHONOPTIMIZE=${NOASSERT} MODULE=test.test_fibonacci vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp

prove_fibonacci:
	sby -f properties.sby

test_wrapper:
	rm -rf sim_build/
	mkdir sim_build/
	iverilog -o sim_build/sim.vvp -DMPRJ_IO_PADS=38 -s wrapper_fibonacci -s dump -g2012 $(SOURCES) test/dump_wrapper.v
	PYTHONOPTIMIZE=${NOASSERT} MODULE=test.test_wrapper vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp

test_wb_logic:
	rm -rf sim_build/
	mkdir sim_build/
	iverilog -o sim_build/sim.vvp -DMPRJ_IO_PADS=38  -s wb_logic -s dump -g2012 src/wb_logic.v test/dump_wb_logic.v
	PYTHONOPTIMIZE=${NOASSERT} MODULE=test.test_wb_logic vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp

show_%: %.vcd %.gtkw
	gtkwave $^

lint:
	verilator --lint-only ${SOURCES} --top-module wrapper_fibonacci
	verible-verilog-lint $(SOURCES) --rules_config verible.rules

.PHONY: clean
clean:
	rm -rf *vcd sim_build fpga/*log fpga/*bin test/__pycache__

# FPGA recipes

show_synth_%: src/%.v
	yosys -p "read_verilog $<; proc; opt; show -colors 2 -width -signed"

%.json: $(SOURCES)
	yosys -l fpga/yosys.log -DFPGA=1 -DWIDTH=8 -p 'synth_ice40 -top fpga -json $(PROJECT).json' $(SOURCES)

%.asc: %.json $(ICEBREAKER_PIN_DEF)
	nextpnr-ice40 -l fpga/nextpnr.log --seed $(SEED) --freq 20 --package $(ICEBREAKER_PACKAGE) --$(ICEBREAKER_DEVICE) --asc $@ --pcf $(ICEBREAKER_PIN_DEF) --json $<

%.bin: %.asc
	icepack $< $@

prog: $(PROJECT).bin
	iceprog $<
