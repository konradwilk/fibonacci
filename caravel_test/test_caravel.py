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
    await RisingEdge(dut.uut.mprj.wrapper_fibonacci.active)
    print(" - Active ON");

async def test_wb(dut, i):

    addr = int(dut.uut.mprj.wrapper_fibonacci.wbs_adr_i.value);
    data = int(dut.uut.mprj.wrapper_fibonacci.wbs_dat_i.value);
    ack = int(dut.uut.mprj.wrapper_fibonacci.wbs_ack_o.value);
    if (addr >= int(hex(0x30000000))):
        print("%2d wb_rst_i = %s" % (i, dut.uut.mprj.wrapper_fibonacci.wb_rst_i.value));
        print("%2d wbs_stb_i = %s" % (i, dut.uut.mprj.wrapper_fibonacci.wbs_stb_i.value));
        print("%2d wbs_we_i = %s" % (i, dut.uut.mprj.wrapper_fibonacci.wbs_we_i.value));
        print("%2d wbs_sel_i = %s" % (i, dut.uut.mprj.wrapper_fibonacci.wbs_sel_i.value));
        print("%2d wbs_dat_i = %s" % (i, hex(data)));
        print("%2d wbs_adr_i = %s" % (i, hex(addr)));
        print("%2d wbs_dat_o = %s" % (i, hex(int(dut.uut.mprj.wrapper_fibonacci.wbs_dat_o.value))));
        print("%2d wbs_ack_o = %d" % (i, ack));
        if (ack == 0):
            return;

        if (addr == int(hex(0x30000004))): # CTRL_GET_NR
            assert(data == 9);

        if (addr == int(hex(0x30000004))): # CTRL_GET_ID 
            assert(str(data) == 'Fibo');

        if (addr == int(hex(0x30000020))): # CTRL_PANIC
            if (data == int(hex(0x0badf00d))):
                raise TestComplete("Done = %h %h" % (hex(int(dut.uut.mprj.wrapper_fibonacci.wbs_dat_i.value)), hex(int(dut.uut.mprj.wrapper_fibonacci.wbs_dat_o.value))));

        if (addr == int(hex(0x30000024))):
            raise TestComplete("Done = %h %h" % (hex(int(dut.uut.mprj.wrapper_fibonacci.wbs_dat_i.value)), hex(int(dut.uut.mprj.wrapper_fibonacci.wbs_dat_o.value))));


@cocotb.test()
async def test_values(dut):
    clock = Clock(dut.clock, 10, units="ns")
    cocotb.fork(clock.start())

    # wait for the reset (
    print(" - Waiting for reset");

    #         /* .reset(la_data_in[0]) */
    # reg_la0_ena = 0; /* 0x2500,0010 */
    # reg_la0_data = 1; /* RST on 0x2500,0000*/

    await RisingEdge(dut.uut.mprj.wrapper_fibonacci.Fibonacci.reset)
    await FallingEdge(dut.uut.mprj.wrapper_fibonacci.Fibonacci.reset)
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

        if (i == 0) or ((i > 0) and ((i % 44) == 0)):
            prio_value = 0;
            p_prio_value = 0;
        if (i == 1) or ((i > 1) and ((i % 45) == 0)):
            p_prio_value = 0;
            prio_value = 1;

        #print("i = %d p_prio_value=%d,prio_value=%d,current_value=%d" % (i, p_prio_value, prio_value, current_value));
        assert (current_value == (prio_value + p_prio_value));
        if (i >= 2) and ((i % 44) and (i % 45)):
            p_prio_value = prio_value;
            prio_value = current_value;

        await ClockCycles(dut.clock,1)

    for i in range(30000):

        await ClockCycles(dut.clock,1)
        await test_wb(dut, i);

