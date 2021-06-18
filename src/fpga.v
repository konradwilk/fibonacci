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
`ifdef FPGA
`define WIDTH 8
`else
`define WIDTH 32
`endif

module fpga #(parameter WIDTH=`WIDTH) (
    input wire clk,
    input wire reset_n,
    output wire [WIDTH-1:0] value
);
    wire reset;
    wire clock;

`ifdef FPGA
    assign reset = !reset_n;

    clkdiv SlowClock(.clk(clk),
        .clkout(clock));
`else
    assign reset = reset_n;
    assign clock = clk;
`endif

    fibonacci #(.WIDTH(`WIDTH)) Fibonacci(.clk(clock),
        .on(1),
        .reset(reset),
        .value(value));
endmodule
