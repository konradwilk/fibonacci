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

module fibonacci #(parameter WIDTH=32)
   (
    input wire clk,
    input wire reset,
    input wire on,
    output wire [WIDTH-1:0] value
);

    reg [WIDTH-1:0] current;
    reg [WIDTH-1:0] previous;
    wire msb;

    always @(posedge clk) begin
        if (reset) begin
            current <= 1;
            previous <= 0;
        end else begin
            if (msb) begin
                current <= 1;
                previous <= 0;
            end else begin
                if (on)
                    current <= current + previous;
                previous <= current;
            end
        end
    end

    assign value = reset ? {WIDTH{1'b0}}: previous;
    assign msb = current[WIDTH-1+0];

endmodule
