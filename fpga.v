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
            .reset(reset),
            .value(value));
endmodule
