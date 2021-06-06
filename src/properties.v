always @(posedge wb_clk_i) begin
    if (fib_activate && !sha1_activate) begin
        if(active) begin
        // active properties here
            _active_io_out_:assert(io_out[16:14] == buf_io_out[16:14]);
            _active_wbs_ack: assert(wbs_ack_o == buf_wbs_ack_o );
            _active_wbs_dat_o: assert(wbs_dat_o == buf_wbs_dat_o);
            _active_la_data_out_ :assert(la_data_out == buf_la_data_out);
            _irq_buf_ : assert(irq == buf_irq);
        end
        if(!active) begin
        // inactive properties here
            _io_out_: assert(io_out[16:14] == 7'b0000000);
            _wbs_ack_o: assert(wbs_ack_o == 1'b0);
            _wbs_dat_o: assert(wbs_dat_o == 32'b0);
            _la_data_out: assert(la_data_out == 32'b0);
            _io_oeb: assert(io_oeb == 32'b0);
            _irq_ : assert(irq == 3'b0);
        end
    end
end
