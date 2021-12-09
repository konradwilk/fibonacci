# User config
set script_dir [file dirname [file normalize [info script]]]

set ::env(DESIGN_NAME) wrapper_fibonacci

# Change if needed
set ::env(VERILOG_FILES) "$::env(DESIGN_DIR)/src/wrapper.v \
	$::env(DESIGN_DIR)/src/fibonacci.v \
	$::env(DESIGN_DIR)/src/wb_logic.v \
	$::env(DESIGN_DIR)/src/clkdiv.v"

# Fill this
set ::env(CLOCK_PERIOD) "50"
set ::env(CLOCK_PORT) "wb_clk_i"

set ::env(DIE_AREA) "0 0 350 350"
set ::env(FP_SIZING) absolute

set ::env(DESIGN_IS_CORE) 0
set ::env(GLB_RT_MAXLAYER) 5

set ::env(SYNTH_DEFINES) "MPRJ_IO_PADS=38"

set filename $::env(DESIGN_DIR)/$::env(PDK)_$::env(STD_CELL_LIBRARY)_config.tcl
if { [file exists $filename] == 1} {
	source $filename
}

set ::env(VDD_NETS) [list {vccd1}]
set ::env(GND_NETS) [list {vssd1}]

set ::env(FP_PIN_ORDER_CFG) $script_dir/pin_order.cfg

set ::env(RUN_CVC) 0

set ::env(PL_RESIZER_BUFFER_OUTPUT_PORTS) 0

set ::env(RUN_KLAYOUT_XOR) 0
set ::env(RUN_KLAYOUT_DRC) 0

set ::env(PL_RESIZER_HOLD_SLACK_MARGIN) 0.8
set ::env(GLB_RESIZER_HOLD_SLACK_MARGIN) 0.8

#set ::env(PL_RESIZER_SETUP_SLACK_MARGIN) 0.5
#set ::env(GLB_RESIZER_SETUP_SLACK_MARGIN) 0.5

set ::env(FP_IO_VTHICKNESS_MULT) 4
set ::env(FP_IO_HTHICKNESS_MULT) 4
