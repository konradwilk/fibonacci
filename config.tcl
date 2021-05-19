# User config
set ::env(DESIGN_NAME) wrapper

# Change if needed
set ::env(VERILOG_FILES) "./designs/fibonacci/wrapper.v ./designs/fibonacci/src/fibonacci.v"

# Fill this
set ::env(CLOCK_PERIOD) "10"
set ::env(CLOCK_PORT) "wb_clk_i"

set ::env(DIE_AREA) "0 0 300 300"
set ::env(FP_SIZING) absolute

set ::env(DESIGN_IS_CORE) 0
set ::env(GLB_RT_MAXLAYER) 5

set ::env(SYNTH_DEFINES) "MPRJ_IO_PADS=38"

set filename $::env(DESIGN_DIR)/$::env(PDK)_$::env(STD_CELL_LIBRARY)_config.tcl
if { [file exists $filename] == 1} {
	source $filename
}

