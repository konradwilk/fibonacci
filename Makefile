# FPGA variables
PROJECT = fpga/fibonacci
SOURCES= src/fibonacci.v src/clkdiv.v src/wb_logic.v src/fpga.v src/wrapper.v
ICEBREAKER_DEVICE = up5k
ICEBREAKER_PIN_DEF = fpga/icebreaker.pcf
ICEBREAKER_PACKAGE = sg48
SEED = 1
MULTI_PROJECT_DIR ?= $(PWD)/../multi_project_tools

# COCOTB variables
export COCOTB_REDUCED_LOG_FMT=1

all: test_fibonacci test_wb_logic prove_fibonacci test_wrapper test_gds

test_gds: gds/wrapper_fibonacci.lvs.powered.v
	$(MAKE) -C gds

.PHONY: gds
gds:
	docker run -it \
		-v $(CURDIR):/work \
		-v $(OPENLANE_ROOT):/openLANE_flow \
		-v $(PDK_ROOT):$(PDK_ROOT) \
		-v $(PDK_PATH):$(PDK_PATH) \
		-v $(CURDIR):/out \
		-e PDK_ROOT=$(PDK_ROOT) \
		-e PDK_PATH=$(PDK_PATH) \
		-u $(shell id -u $$USER):$(shell id -g $$USER) \
		efabless/openlane:v0.15 \
		/bin/bash -c "./flow.tcl -overwrite -design /work/ -run_path /out/ -tag done"
	cp -f done/results/lvs/wrapper_fibonacci.lvs.powered.v gds/
	cp -f done/results/magic/wrapper_fibonacci.gds gds/
	cp -f done/results/magic/wrapper_fibonacci.gds.png gds/
	cp -f done/results/magic/.magicrc gds/
	cp -f done/results/magic/wrapper_fibonacci.lef gds/

gds_modify: done/results/lvs/wrapper_fibonacci.lvs.powered.v
	awk '1;/wbs_sel_i);/{ print "`ifdef COCOTB_SIM"; print "initial begin"; print "$$dumpfile (\"wrapper.vcd\");"; print "$$dumpvars (0, wrapper_fibonacci);"; print "#1;"; print "end"; print "`endif"}' done/results/lvs/wrapper_fibonacci.lvs.powered.v > gds/v
	cat gds/header gds/v > gds/wrapper_fibonacci.lvs.powered.v

test_lvs_wrapper:
	rm -rf sim_build/
	mkdir sim_build/
	iverilog -o sim_build/sim.vvp -DMPRJ_IO_PADS=38 -I $(PDK_ROOT)/sky130A/ -s wrapper_fibonacci -s dump -g2012 gds/wrapper_fibonacci.lvs.powered.v  test/dump_wrapper.v
	PYTHONOPTIMIZE=${NOASSERT} MODULE=test.test_wrapper vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp

multi_project:
	cd $(MULTI_PROJECT_DIR); \
		./multi_tool.py --config projects.yaml --test-tristate --force-delete

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
