`default_nettype none
`timescale 1ns/1ns
`ifdef FORMAL
    `define MPRJ_IO_PADS 38
`endif
`ifdef VERILATOR
    `define MPRJ_IO_PADS 38
`endif
module wrapper #(
    parameter    [27:0] BASE_ADDRESS   = 28'h0300000
    ) (
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
    input wire [32:0] wbs_adr_i,
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

    wire wb_active = wbs_stb_i & wbs_cyc_i;
    reg fibonacci_switch;
    reg [31:0] buffer;
    reg [31:0] buffer_o;

    // instantiate your module here, connecting what you need of the above signals

    /* CTRL_GET parameters. */
    localparam CTRL_GET_NR		= 'h00; /* How many */
    localparam CTRL_NR 			= 'h8;

    localparam CTRL_GET_ID		= 'h04;
    localparam CTRL_ID			= 32'h4669626f; /* Fibo */

    /* CTRL_SET parameters */
    localparam CTRL_SET_IRQ		= 'h08;
    localparam ACK_OK			= 32'h0000001;
    localparam ACK_OFF			= 32'h0000000;
    localparam CTRL_FIBONACCI_ON 	= 'h0C;
    localparam CTRL_FIBONACCI_OFF	= 'h10;
    localparam CTRL_FIBONACCI_VAL	= 'h14;
    localparam CTRL_WRITE	  	= 'h18;
    localparam CTRL_READ	  	= 'h1C;
    localparam CTRL_PANIC	  	= 'h20;

    always @(posedge wb_clk_i) begin
	    if (reset) begin
		    fibonacci_switch <= 1'b1;
		    buffer <= ACK_OFF;
		    buffer_o <= ACK_OFF;
	    end else begin
		    /* Read case */
		    if (wb_active && !wbs_we_i && (wbs_adr_i[32:5] == BASE_ADDRESS)) begin
			    case (wbs_adr_i[4:0])
				    CTRL_GET_NR:
					    buffer_o <= CTRL_NR;
				    CTRL_GET_ID:
					    buffer_o <= CTRL_ID;
				    CTRL_SET_IRQ:
					    buffer_o <= ACK_OK;
				    CTRL_FIBONACCI_ON:
				    begin
					    buffer_o <= ACK_OK;
					    fibonacci_switch <= 1'b1;
				    end
				    CTRL_FIBONACCI_OFF:
				    begin
					    buffer_o <= ACK_OK;
					    fibonacci_switch <= 1'b0;
				    end
				    CTRL_FIBONACCI_VAL:
					    buffer_o <= {2'h0, buf_io_out[37:8]};
				    CTRL_READ:
					    buffer_o <= buffer;
			             default:
					    buffer_o <= ACK_OFF;
				endcase
		     end
	     end
     end

     always @(posedge wb_clk_i) begin
	     /* Write case */
	     if (wb_active && wbs_we_i && &wbs_sel_i) begin
		     case (wbs_adr_i)
			     CTRL_WRITE:
				     buffer <= wbs_dat_i;
			     CTRL_PANIC:
				     buffer <= wbs_dat_i;
			     default:
				     buffer <= ACK_OFF;
		     endcase
	     end
     end

    assign buf_wbs_dat_o = reset ? 32'b0 : buffer_o;

    fibonacci #(.WIDTH(30)) Fibonacci(
            .clk(wb_clk_i),
            .reset(reset),
	    .on(fibonacci_switch),
            .value(buf_io_out[37:8]));

endmodule
`default_nettype wire
