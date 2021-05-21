`timescale 1ns / 1ps

module clkdiv #(parameter WIDTH=32) (
    input clk,
    output clkout
    );

   reg [WIDTH-1:0] counter;

   assign clkout = counter[WIDTH-1];

   always @(posedge clk)
     counter <= counter+1;

endmodule

