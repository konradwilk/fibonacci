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
