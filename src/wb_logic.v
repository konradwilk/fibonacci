`default_nettype none
`timescale 1ns/1ns
`ifdef FORMAL
    `define MPRJ_IO_PADS 38
`endif
`ifdef VERILATOR
    `define MPRJ_IO_PADS 38
`endif

module wb_logic #(
    parameter    [31:0] BASE_ADDRESS   = 32'h30000000,
    parameter CLOCK_WIDTH = 6
    ) (
    input wire [`MPRJ_IO_PADS-1:0] buf_io_out,
    input wire reset,
    output wire [2:0] irq,

    output wire [CLOCK_WIDTH-1:0] clock_sel,
    output wire switch,
    /* WishBone logic */

    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wbs_stb_i, /* strobe */
    input wire wbs_cyc_i,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [31:0] wbs_dat_i,
    input wire [32:0] wbs_adr_i,
    output wire wbs_ack_o,
    output wire [31:0] wbs_dat_o

    );

    wire wb_active = wbs_stb_i & wbs_cyc_i;

    reg [31:0] buffer;
    reg [31:0] buffer_o;
    reg fibonacci_switch;
    reg [CLOCK_WIDTH-1:0] clock_op;

    /* CTRL_GET parameters. */
    localparam CTRL_GET_NR		= BASE_ADDRESS;
    localparam CTRL_NR 			= 9;

    localparam CTRL_GET_ID		= BASE_ADDRESS + 'h4;
    localparam CTRL_ID			= 32'h4669626f; /* Fibo */

    /* CTRL_SET parameters */
    localparam CTRL_SET_IRQ		= BASE_ADDRESS + 'h8;
    localparam ACK_OK			= 32'h0000001;
    localparam ACK_OFF			= 32'h0000000;
    localparam CTRL_CLOCK		= BASE_ADDRESS + 'h10;
    localparam CTRL_FIBONACCI_CTRL 	= BASE_ADDRESS + 'h0C;
    localparam TURN_ON			= 1'b1;
    localparam TURN_OFF			= 1'b0;
    localparam CTRL_FIBONACCI_VAL	= BASE_ADDRESS + 'h14;
    localparam CTRL_WRITE	  	= BASE_ADDRESS + 'h18;
    localparam CTRL_READ	  	= BASE_ADDRESS + 'h1C;
    localparam CTRL_PANIC	  	= BASE_ADDRESS + 'h20;

    always @(posedge wb_clk_i) begin
	    if (reset) begin
		    fibonacci_switch <= 1'b1;
		    buffer_o <= ACK_OFF;
		    clock_op <= 6'b000001; /* TODO: Move this out? */
	    end else begin
		    /* Read case */
		    if (wb_active && !wbs_we_i) begin
			    case (wbs_adr_i)
				    CTRL_GET_NR:
					    buffer_o <= CTRL_NR;
				    CTRL_GET_ID:
					    buffer_o <= CTRL_ID;
				    CTRL_SET_IRQ:
					    buffer_o <= ACK_OK;
				    CTRL_CLOCK:
					    clock_op <= wbs_dat_i[CLOCK_WIDTH-1:0];
				    CTRL_FIBONACCI_CTRL:
					    fibonacci_switch <= wbs_dat_i[0];
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
	     if (reset) begin
		     buffer <= ACK_OFF;
	     end else begin
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
     end

     assign wbs_ack_o = reset ? 1'b0 : (wb_active &&
					   (wbs_adr_i >= BASE_ADDRESS));

    assign wbs_dat_o = reset ? 32'b0 : buffer_o;

    assign switch = reset ? 1'b0 : fibonacci_switch;

    assign clock_sel = reset ? {CLOCK_WIDTH{1'b0}} : clock_op;

endmodule

