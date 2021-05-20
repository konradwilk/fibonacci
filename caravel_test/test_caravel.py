import cocotb
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge;

@cocotb.test()
async def test_start(dut):
    clock = Clock(dut.clock, 10, units="ns")
    cocotb.fork(clock.start())

    dut.RSTB <= 0
    dut.power1 <= 0;
    dut.power2 <= 0;
    dut.power3 <= 0;
    dut.power4 <= 0;

    print("Cycling power");
    await ClockCycles(dut.clock, 8)
    dut.power1 <= 1;
    await ClockCycles(dut.clock, 8)
    dut.power2 <= 1;
    await ClockCycles(dut.clock, 8)
    dut.power3 <= 1;
    await ClockCycles(dut.clock, 8)
    dut.power4 <= 1;

    await ClockCycles(dut.clock, 80)
    dut.RSTB <= 1

    print(" - Waiting for active");
    # wait for the project to become active
    # wrapper.v has  .active     (la_data_in[32+0])
    # wrapper.c: reg_la1_ena = 0;
    #            reg_la1_data = 1; /* 0x2500,0004 */
    await RisingEdge(dut.uut.mprj.proj_0.active)
    print(" - Active ON");

@cocotb.test()
async def test_values(dut):
    clock = Clock(dut.clock, 10, units="ns")
    cocotb.fork(clock.start())

    # wait for the reset (
    print(" - Waiting for reset");

    #         /* .reset(la_data_in[0]) */
    # reg_la0_ena = 0; /* 0x2500,0010 */
    # reg_la0_data = 1; /* RST on 0x2500,0000*/

    await RisingEdge(dut.uut.mprj.proj_0.Fibonacci.reset)
    await FallingEdge(dut.uut.mprj.proj_0.Fibonacci.reset)
    print(" - Reset done");

    await ClockCycles(dut.clock,1)

    value = str(dut.mprj_io.value).replace('z','');

    print("dut.mprj_io=%d" % (int(value)));
    assert (int(value) == 0);

    prio_value = 0;
    p_prio_value = 0;

    for i in range(50):
        # We get these annoying 'ZZ' in there, so we do this dance to get rid of it.
        value = BinaryValue(str(dut.mprj_io.value).replace('z',''));

        current_value  = int(value);

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

        await ClockCycles(dut.clock,1)

