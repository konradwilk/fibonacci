import cocotb
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
from cocotb.triggers import ClockCycles
from cocotbext.wishbone.driver import WishboneMaster
from cocotbext.wishbone.driver import WBOp

async def read_val(dut, wbs, cmd, exp):
    wbRes = await wbs.send_cycle([WBOp(cmd)]);
    dut._log.info("%s = Read %s expected %s" % (hex(cmd), hex(wbRes[0].datrd.integer), hex(exp)))
    return wbRes[0].datrd.integer

async def write_val(dut, wbs, cmd, val):
    wbRes = await wbs.send_cycle([WBOp(cmd, dat=val)]);
    val = wbRes[0].datrd.integer
    dut._log.info("%s <= Wrote %s (ret=%s)" % (hex(cmd), hex(val), hex(val)));
    return val

CTRL_GET_NR         = 0x30000000
CTRL_GET_ID         = 0x30000004
CTRL_SET_IRQ        = 0x30000008
CTRL_FIBONACCI_CTRL = 0x3000000c
CTRL_FIBONACCI_CLOCK= 0x30000010
CTRL_FIBONACCI_VAL  = 0x30000014
CTRL_WRITE          = 0x30000018
CTRL_READ           = 0x3000001C
CTRL_PANIC          = 0x30000020

async def test_id(dut, wbs):
    for i in range(10):
        cmd = CTRL_GET_ID;
        exp = 0x4669626f;
        val = await read_val(dut, wbs, cmd, exp);
        assert (val == exp);
        cmd = CTRL_GET_NR
        exp = 9;
        val = await read_val(dut, wbs, cmd, exp);
        assert (val == exp);

async def test_irq(dut, wbs):

    dut.irq_out <= 0;
    await ClockCycles(dut.wb_clk_i, 5)
    assert dut.irq_out == 0

    val = await write_val(dut, wbs, CTRL_SET_IRQ, 1);
    assert(val == 1);

    await ClockCycles(dut.wb_clk_i, 5)
    assert (dut.irq_out == 1)

    val = await write_val(dut, wbs, CTRL_SET_IRQ, 0);
    assert(val == 1);

    await ClockCycles(dut.wb_clk_i, 5)
    dut._log.info("%s" % (dut.irq_out.value));
    assert(str(dut.irq_out.value) == 'zzz');

async def test_read_write(dut, wbs):

    for i in range(10):
        cmd = CTRL_WRITE;
        exp = i;
        val = await write_val(dut, wbs, cmd, exp);
        assert (val == 1);

        cmd = CTRL_READ;
        val = await read_val(dut, wbs, cmd, exp);
        assert (val == exp);

async def test_ctrl(dut, wbs):

    assert (dut.fibonacci_switch == 1);
    exp = 1;
    val = await read_val(dut, wbs, CTRL_FIBONACCI_CTRL, exp);
    assert (val == exp);

    val = await write_val(dut, wbs, CTRL_FIBONACCI_CTRL, 0);
    assert(val == 1);

    await ClockCycles(dut.wb_clk_i, 5)
    assert dut.fibonacci_switch == 0

    val = await write_val(dut, wbs, CTRL_FIBONACCI_CTRL, 1);
    assert(val == 1);

    await ClockCycles(dut.wb_clk_i, 5)
    assert dut.fibonacci_switch == 1

async def test_values(dut, wbs):

    dut.buf_io_out <= 0xFFF;
    exp = 0xF;
    val = await read_val(dut, wbs, CTRL_FIBONACCI_VAL, exp);
    assert (val == exp)

    exp = 0;
    # Write should fail.
    val = await write_val(dut, wbs, CTRL_FIBONACCI_VAL, exp);
    assert (val == exp)

async def test_clock_op(dut, wbs):

    # Default clock is on 0th bit.
    assert (dut.clock_op == 0x1);

    # Lets reset it
    dut.clock_op <= 0x0;
    exp = 0x0;
    await ClockCycles(dut.wb_clk_i, 5)

    # We should get 0 
    val = await read_val(dut, wbs, CTRL_FIBONACCI_CLOCK, exp);
    assert (val == exp)

    # Now for different valu
    exp = 1<<1;
    val = await write_val(dut, wbs, CTRL_FIBONACCI_CLOCK, exp);
    assert (val == 1);

    val = await read_val(dut, wbs, CTRL_FIBONACCI_CLOCK, exp);
    assert (val == exp)

    assert(dut.clock_op == 1<<1);

async def test_panic(dut, wbs):

    exp = 0;
    assert (dut.panic == exp);

    val = await read_val(dut, wbs, CTRL_PANIC, exp);
    assert (val == exp);

    exp = 0xdeadbeef;
    val = await write_val(dut, wbs, CTRL_PANIC, exp);
    assert (val == 1);

    val = await read_val(dut, wbs, CTRL_PANIC, 1);
    assert (val == 1);

@cocotb.test()
async def test_wb_logic(dut):
    clock = Clock(dut.wb_clk_i, 10, units="ns")
    cocotb.fork(clock.start())
    wbs = WishboneMaster(dut, "wbs", dut.wb_clk_i,
                          width=32,   # size of data bus
                          timeout=10, # in clock cycle number
                          signals_dict={"cyc":  "cyc_i",
                                      "stb":  "stb_i",
                                      "we":   "we_i",
                                      "adr":  "adr_i",
                                      "datwr":"dat_i",
                                      "datrd":"dat_o",
                                      "ack":  "ack_o",
                                      "sel": "sel_i"})

    dut.reset <= 1
    await ClockCycles(dut.wb_clk_i, 5)
    dut.reset <= 0

    await ClockCycles(dut.wb_clk_i, 100)

    await test_id(dut, wbs);

    await test_irq(dut, wbs);

    await test_read_write(dut, wbs);

    await test_ctrl(dut, wbs);

    await test_values(dut, wbs);

    await test_clock_op(dut, wbs);

    await test_panic(dut, wbs);
