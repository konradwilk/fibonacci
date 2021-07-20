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
module dump;
    initial begin
        $dumpfile ("wrapper.vcd");
        $dumpvars (0, dump);
        #1;
    end
    reg [8191:0] status = "START";

    reg power1, power2, power3, power4;

    wire VDD3V3 = power1;
    wire VDD1V8 = power2;
    wire USER_VDD3V3 = power3;
    wire USER_VDD1V8 = power4;
    wire VSS = 1'b0;

    wire [37:0] io_in;
    wire [37:0] io_out;
    wire [37:0] io_oeb;

    wire wb_clk_i,wb_rst_i,wbs_stb_i,wbs_cyc_i,wbs_we_i;
    wire [3:0] wbs_sel_i;
    wire [31:0] wbs_dat_i;
    wire [31:0] wbs_adr_i;
    wire [31:0] wbs_dat_o;
    wire wbs_ack_o;

    wire [31:0] la_data_in;
    wire [31:0] la_data_out;
    wire [31:0] la_oenb;

    wire [2:0] irq;

    wire active;
    wrapper_fibonacci wrapper_fibonacci (
`ifdef USE_POWER_PINS
    .vdda1(USER_VDD3V3),	// User area 1 3.3V supply
    .vdda2(USER_VDD3V3),	// User area 2 3.3V supply
    .vssa1(VSS),	// User area 1 analog ground
    .vssa2(VSS),	// User area 2 analog ground
    .vccd1(USER_VDD1V8),	// User area 1 1.8V supply
    .vccd2(USER_VDD1V8),	// User area 2 1.8v supply
    .vssd1(VSS),	// User area 1 digital ground
    .vssd2(VSS),	// User area 2 digital ground
`endif
    // interface as user_proj_example.v
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stb_i), /* strobe */
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ack_o),
        .wbs_dat_o(wbs_dat_o),

    // Logic Analyzer Signals
    // only provide first 32 bits to reduce wiring congestion
        .la_data_in(la_data_in),
        .la_data_out(la_data_out),
        .la_oenb(la_oenb),

    // IOs
        .io_in(io_in),
        .io_out(io_out),
        .io_oeb(io_oeb),

    // IRQ
        .irq(irq),

    // extra user clock
        .user_clock2(wbs_clk_i),

    // active input, only connect tristated outputs if this is high
        .active(active)
    );
endmodule
