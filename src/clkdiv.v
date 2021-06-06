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

