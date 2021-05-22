module dump();
    initial begin
        $dumpfile ("wrapper.vcd");
        $dumpvars (0, wrapper_fibonacci);
        #1;
    end
endmodule
