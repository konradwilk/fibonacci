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
`timescale 1ns / 1ps

module clkdiv #(parameter WIDTH=32) (
    input wire reset,
    input wire clk,
    output wire clkout
);

    reg [WIDTH-1:0] counter;

    always @(posedge clk) begin
        if (reset) begin
            counter <= 0;
        end else begin
            counter <= counter + 1'b1;
        end
    end

    assign clkout = counter[WIDTH-1];
endmodule

