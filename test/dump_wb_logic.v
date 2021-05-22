module dump();
    initial begin
        $dumpfile ("wb_logic.vcd");
        $dumpvars (0, wb_logic);
        #1;
    end
endmodule
