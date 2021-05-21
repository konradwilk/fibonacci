import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

async def reset(dut):

    dut.reset <= 1 
    await ClockCycles(dut.clk, 5)
    dut.reset <= 0 

@cocotb.test()
async def test_fibonacci(dut):

    clock = Clock(dut.clk, 10, units="us")
    cocotb.fork(clock.start())

    await reset(dut)
    dut.on <= 1;

    prio_value = int(dut.value);
    p_prio_value = int(dut.value);

    assert dut.value == 0;
    
    for i in range(50):

        await ClockCycles(dut.clk,1) 

        # assert still low
        assert dut.reset == 0

        current_value  = int(dut.value);

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
