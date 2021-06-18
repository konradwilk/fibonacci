// SPDX-FileCopyrightText: 2021 Konrad Rzeszutek Wilk
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0
`default_nettype none
`timescale 1ns/1ns
`ifdef FORMAL
`define MPRJ_IO_PADS 38
`endif
`ifdef VERILATOR
`define MPRJ_IO_PADS 38
`endif
module wrapper_fibonacci  (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif
    // interface as user_proj_example.v
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wbs_stb_i, /* strobe */
    input wire wbs_cyc_i,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [31:0] wbs_dat_i,
    input wire [31:0] wbs_adr_i,
    output wire wbs_ack_o,
    output wire [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    // only provide first 32 bits to reduce wiring congestion
    input  wire [31:0] la_data_in,
    output wire [31:0] la_data_out,
    input  wire [31:0] la_oenb,

    // IOs
    input  wire [`MPRJ_IO_PADS-1:0] io_in,
    output wire [`MPRJ_IO_PADS-1:0] io_out,
    output wire [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output wire [2:0] irq,

    // extra user clock
    input wire user_clock2,

    // active input, only connect tristated outputs if this is high
    input wire active
);

    // all outputs must be tristated before being passed onto the project
    wire buf_wbs_ack_o;
    wire [31:0] buf_wbs_dat_o;
    wire [31:0] buf_la_data_out;
    wire [`MPRJ_IO_PADS-1:0] buf_io_out;
    wire [`MPRJ_IO_PADS-1:0] buf_io_oeb;
    wire [2:0] buf_irq;

`ifdef FORMAL
    // formal can't deal with z, so set all outputs to 0 if not active
    assign wbs_ack_o    = active ? buf_wbs_ack_o    : 1'b0;
    assign wbs_dat_o    = active ? buf_wbs_dat_o    : 32'b0;
    assign la_data_out  = active ? buf_la_data_out  : 32'b0;
    assign io_out       = active ? buf_io_out       : {`MPRJ_IO_PADS{1'b0}};
    assign io_oeb       = active ? buf_io_oeb       : {`MPRJ_IO_PADS{1'b0}};
    assign irq		= active ? buf_irq          : 3'b0;
`include "properties.v"
`else
    // tristate buffers
    assign wbs_ack_o    = active ? buf_wbs_ack_o    : 1'bz;
    assign wbs_dat_o    = active ? buf_wbs_dat_o    : 32'bz;
    assign la_data_out  = active ? buf_la_data_out  : 32'bz;
    assign io_out       = active ? buf_io_out       : {`MPRJ_IO_PADS{1'bz}};
    assign io_oeb       = active ? buf_io_oeb       : {`MPRJ_IO_PADS{1'bz}};
    assign irq		= active ? buf_irq          : 3'bz;
`endif

    // permanently set oeb so that outputs are always enabled: 0 is output, 1 is high-impedance
    assign buf_io_oeb = {`MPRJ_IO_PADS{1'b0}};

    wire reset = la_data_in[0];
    wire [5:0] clock_op;

    wire fibonacci_clock;
    wire fibonacci_switch;
    wire [5:0] clocks;

    clkdiv #(.WIDTH(8)) Clock_1 (
        .reset(reset),
        .clk(wb_clk_i),
        .clkout(clocks[1]));

    clkdiv #(.WIDTH(16)) Clock_2 (
        .reset(reset),
        .clk(wb_clk_i),
        .clkout(clocks[2]));

    clkdiv #(.WIDTH(24)) Clock_3 (
        .reset(reset),
        .clk(wb_clk_i),
        .clkout(clocks[3]));

    clkdiv #(.WIDTH(32)) Clock_4 (
        .reset(reset),
        .clk(wb_clk_i),
        .clkout(clocks[4]));

    clkdiv #(.WIDTH(36)) Clock_5 (
        .reset(reset),
        .clk(wb_clk_i),
        .clkout(clocks[5]));

    wb_logic WishBone (
        .buf_io_out(buf_io_out),
        .reset(reset),
        .irq_out(buf_irq),
        .clock_op(clock_op),
        .switch_out(fibonacci_switch),
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stb_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(buf_wbs_ack_o),
        .wbs_dat_o(buf_wbs_dat_o));

    assign clocks[0] = wb_clk_i;

    assign fibonacci_clock = clock_op[5] ? clocks[5] :
	    			(clock_op[4] ? clocks[4] :
				 (clock_op[3] ? clocks[3] :
				  (clock_op[2] ? clocks[2] :
				   (clock_op[1] ? clocks[1] :
				    clocks[0]))));

    fibonacci #(.WIDTH(30)) Fibonacci(
        .clk(fibonacci_clock),
        .reset(reset),
        .on(fibonacci_switch),
        .value(buf_io_out[37:8]));

endmodule
`default_nettype wire
