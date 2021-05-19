import cocotb
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_wrapper(dut):
    clock = Clock(dut.wb_clk_i, 10, units="ns")
    cocotb.fork(clock.start())

    clocks_per_phase = 5

    dut.active <= 0
    dut.wb_rst_i <= 1
    await ClockCycles(dut.wb_clk_i, 5)
    dut.wb_rst_i <= 0
    dut.la_data_in <= 0

    assert(str(dut.io_out.value) == "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz");

    await ClockCycles(dut.wb_clk_i, 100)

    dut.active <= 1
    # Reset pin is hooked up to la_data_in[0].
    dut.la_data_in <= 1 << 0
    await ClockCycles(dut.wb_clk_i,1) 
    
    dut.la_data_in <= 0 << 0
    await ClockCycles(dut.wb_clk_i,1) 

    assert (int(dut.io_out.value) == 0);

    prio_value = 0;
    p_prio_value = 0;
    
    for i in range(50):

        # assert still low
        assert dut.la_data_in == 0

        current_value  = int(dut.io_out);

        if (i == 0) or (i == 47):
            prio_value = 0;
            p_prio_value = 0;
        if (i == 1) or (i == 48):
            p_prio_value = 0;
            prio_value = 1;

        #print("i = %d p_prio_value=%d,prio_value=%d,current_value=%d" % (i, p_prio_value, prio_value, current_value));
        assert (current_value == (prio_value + p_prio_value));
        if (i >= 2) and ((i != 47) and (i != 48)):
            p_prio_value = prio_value;
            prio_value = current_value;

        await ClockCycles(dut.wb_clk_i,1) 

