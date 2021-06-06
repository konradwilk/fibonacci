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
    output reg [CLOCK_WIDTH-1:0] clock_op,
    input wire reset,
    output wire [2:0] irq_out,

    output wire switch_out,
    /* WishBone logic */

    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wbs_stb_i, /* strobe */
    input wire wbs_cyc_i,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [31:0] wbs_dat_i,
    input wire [31:0] wbs_adr_i,
    output wire wbs_ack_o,
    output wire [31:0] wbs_dat_o

);
    wire wb_active = wbs_stb_i & wbs_cyc_i;

    reg [31:0] buffer;
    reg [31:0] buffer_o;
    reg fibonacci_switch;
    reg transmit;
    reg [2:0] tickle_irq;
    reg panic;

    /* CTRL_GET parameters. */
    localparam CTRL_GET_NR		= BASE_ADDRESS;
    localparam CTRL_NR 			= 9;

    localparam CTRL_GET_ID		= BASE_ADDRESS + 'h4;
    localparam CTRL_ID			= 32'h4669626f; /* Fibo */
    localparam DEFAULT			= 32'hf00df00d;
    /* CTRL_SET parameters */
    localparam CTRL_SET_IRQ		= BASE_ADDRESS + 'h8;
    localparam ACK			= 32'h0000001;
    localparam NACK			= 32'h0000000;
    localparam CTRL_FIBONACCI_CLOCK	= BASE_ADDRESS + 'h10;
    localparam CTRL_FIBONACCI_CTRL 	= BASE_ADDRESS + 'h0C;
    localparam TURN_ON			= 1'b1;
    localparam TURN_OFF			= 1'b0;
    localparam CTRL_FIBONACCI_VAL	= BASE_ADDRESS + 'h14;
    localparam CTRL_WRITE	  	= BASE_ADDRESS + 'h18;
    localparam CTRL_READ	  	= BASE_ADDRESS + 'h1C;
    localparam CTRL_PANIC	  	= BASE_ADDRESS + 'h20;

    always @(posedge wb_clk_i) begin
        if (reset) begin
            buffer_o <= DEFAULT;
            buffer <= DEFAULT;
            tickle_irq <= 3'b0;
            panic <= 1'b0;
            fibonacci_switch <= 1'b1;
            clock_op <= 6'b000001; /* TODO: Move this out? */
            transmit <= 1'b0;
        end else begin
            if (transmit)
                transmit <= 1'b0;

		    /* Read case */
            if (wb_active && !wbs_we_i) begin
                case (wbs_adr_i)
                    CTRL_GET_NR:
                    begin
                        buffer_o <= CTRL_NR;
                    end
                    CTRL_GET_ID:
                        buffer_o <= CTRL_ID;
                    CTRL_FIBONACCI_CLOCK:
                        buffer_o <= {26'b0, clock_op};
                    CTRL_FIBONACCI_CTRL:
                        buffer_o <= {31'b0, fibonacci_switch};
                    CTRL_FIBONACCI_VAL:
                        buffer_o <= {2'h0, buf_io_out[37:8]};
                    CTRL_READ:
                        buffer_o <= buffer;
                    CTRL_PANIC:
                        buffer_o <= {31'b0, panic};
                    default:
                        buffer_o <= NACK;
                endcase
                if (wbs_adr_i >= BASE_ADDRESS && wbs_adr_i <= CTRL_PANIC)
                    transmit <= 1'b1;
            end
		    /* Write case */
            if (wb_active && wbs_we_i && &wbs_sel_i) begin
                case (wbs_adr_i)
                    CTRL_SET_IRQ:
                    begin
                        tickle_irq <= wbs_dat_i[2:0];
                        buffer_o <= ACK;
                    end
                    CTRL_FIBONACCI_CTRL:
                    begin
                        fibonacci_switch <= wbs_dat_i[0];
                        buffer_o <= ACK;
                    end
                    CTRL_FIBONACCI_CLOCK:
                    begin
                        clock_op <= wbs_dat_i[CLOCK_WIDTH-1:0];
                        buffer_o <= ACK;
                    end
                    CTRL_WRITE:
                    begin
                        buffer <= wbs_dat_i;
                        buffer_o <= ACK;
                    end
                    CTRL_PANIC:
                    begin
                        panic <= 1'b1;
                        buffer <= wbs_dat_i;
                        buffer_o <= ACK;
                    end
                    default:
                        buffer_o <= NACK;
                endcase
                if (wbs_adr_i >= BASE_ADDRESS && wbs_adr_i <= CTRL_PANIC)
                    transmit <= 1'b1;
            end
        end
    end

    assign wbs_ack_o = reset ? 1'b0 : transmit;

    assign wbs_dat_o = reset ? 32'b0 : buffer_o;

    assign switch_out = reset ? 1'b0 : fibonacci_switch;

    assign irq_out = reset ? 3'b000 : (|tickle_irq ? tickle_irq : 3'b000);

endmodule
`default_nettype wire
