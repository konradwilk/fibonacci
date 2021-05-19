module dump();
    initial begin
        $dumpfile ("fibonacci.vcd");
        $dumpvars (0, fibonacci);
        #1;
    end
endmodule
