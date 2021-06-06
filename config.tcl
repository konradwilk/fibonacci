# User config
set script_dir [file dirname [file normalize [info script]]]

set ::env(DESIGN_NAME) wrapper_fibonacci

# Change if needed
set ::env(VERILOG_FILES) "/work/src/wrapper.v \
	/work/src/fibonacci.v \
	/work/src/wb_logic.v \
	/work/src/clkdiv.v \
	/work/src/sha1/sha1.v \
	/work/src/sha1/sha1_wb.v"

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

set ::env(VDD_NETS) [list {vccd1} {vccd2} {vdda1} {vdda2}]
set ::env(GND_NETS) [list {vssd1} {vssd2} {vssa1} {vssa2}]

set ::env(FP_PIN_ORDER_CFG) $script_dir/pin_order.cfg

set ::env(RUN_CVC) 0

#set ::env(RUN_KLAYOUT_XOR) 0
#set ::env(RUN_KLAYOUT_DRC) 0
