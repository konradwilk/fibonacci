# FPGA variables
PROJECT = fpga/fibonacci
SOURCES = src/fibonacci.v

# COCOTB variables
export COCOTB_REDUCED_LOG_FMT=1

all: test_fibonacci

test_fibonacci:
	rm -rf sim_build/
	mkdir sim_build/
	iverilog -o sim_build/sim.vvp -s fibonacci -s dump -g2012 src/fibonacci.v test/dump_fibonacci.v
	PYTHONOPTIMIZE=${NOASSERT} MODULE=test.test_fibonacci vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp

show_%: %.vcd %.gtkw
	gtkwave $^

lint:
	verilator --lint-only src/*.v
	#verible-verilog-lint src/*v --rules_config verible.rules

.PHONY: clean
clean:
	rm -rf *vcd sim_build fpga/*log fpga/*bin test/__pycache__
