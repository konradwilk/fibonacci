import cocotb
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_wrapper(dut):
    clock = Clock(dut.wb_clk_i, 10, units="ns")
    cocotb.fork(clock.start())

    clocks_per_phase = 5
    try:
        dut.vssd1 <= 0
        dut.vccd1 <= 1
    except:
        pass

    dut.active <= 0
    dut.wb_rst_i <= 1
    await ClockCycles(dut.wb_clk_i, 5)
    dut.wb_rst_i <= 0
    dut.la_data_in <= 0

    dut._log.info("io_out=%s" % (dut.io_out.value));
    # We get these annoying 'ZZ' in there, so we do this dance to get rid of it.
    value = BinaryValue(str(dut.io_out.value).replace('z','').replace('x',''));

    assert(str(value) == "");

    await ClockCycles(dut.wb_clk_i, 100)

    dut.active <= 1
    # Reset pin is hooked up to la_data_in[0].
    dut.la_data_in <= 1 << 0
    await ClockCycles(dut.wb_clk_i,1) 
    
    dut.la_data_in <= 0 << 0
    await ClockCycles(dut.wb_clk_i,1) 

    dut._log.info("io_out=%s" % (dut.io_out.value));
    value = BinaryValue(str(dut.io_out.value).replace('z','').replace('x',''));
    #assert (int(value) == 0);

    prio_value = 0;
    p_prio_value = 0;
    
    for i in range(50):

        # assert still low
        assert dut.la_data_in == 0

        value = BinaryValue(str(dut.io_out.value).replace('z','').replace('x',''));
        dut._log.info("%2d: io_out = %s" % (i, dut.io_out.value));
        current_value  = int(value);

        if (i == 0) or ((i > 0) and ((i % 44) == 0)):
            prio_value = 0;
            p_prio_value = 0;
        if (i == 1) or ((i > 1) and ((i % 45) == 0)):
            p_prio_value = 0;
            prio_value = 1;

        dut._log.info("i = %d p_prio_value=%d,prio_value=%d,current_value=%d" % (i, p_prio_value, prio_value, current_value));
        assert (current_value == (prio_value + p_prio_value));
        if (i >= 2) and ((i % 44) and (i % 45)):
            p_prio_value = prio_value;
            prio_value = current_value;

        await ClockCycles(dut.wb_clk_i,1) 

