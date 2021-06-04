import cocotb
import inspect
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
    dut._log.info("%s <= Writing %s" % (hex(cmd), hex(val)));
    wbRes = await wbs.send_cycle([WBOp(cmd, dat=val)]);
    val = wbRes[0].datrd.integer
    dut._log.info("%s <= (ret=%s)" % (hex(cmd),  hex(val)));
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
        cmd = CTRL_GET_NR;
        # First version has only 9 commands
        if (exp == 0x4669626f):
            exp = 9;

        val = await read_val(dut, wbs, cmd, exp);
        assert (val == exp);

async def test_irq(dut, wbs, wrapper):

    if wrapper:
        name = dut.irq
    else:
        name = dut.irq_out;

    name <= 0;
    await ClockCycles(dut.wb_clk_i, 5)
    assert name == 0

    val = await write_val(dut, wbs, CTRL_SET_IRQ, 1);
    assert(val == 1);

    await ClockCycles(dut.wb_clk_i, 5)
    assert (name == 1)

    val = await write_val(dut, wbs, CTRL_SET_IRQ, 0);
    assert(val == 1);

    await ClockCycles(dut.wb_clk_i, 5)
    dut._log.info("IRQ=%s" % (name.value));

    assert(str(name.value) == 'zzz' or str(name.value) == 'xxx');

async def test_read_write(dut, wbs):

    for i in range(10):
        cmd = CTRL_WRITE;
        exp = i;
        val = await write_val(dut, wbs, cmd, exp);
        assert (val == 1);

        cmd = CTRL_READ;
        val = await read_val(dut, wbs, cmd, exp);
        assert (val == exp);

async def test_ctrl(dut, wbs, wrapper, gl):

    if gl:
        dut._log.info("Skipping %s" % (inspect.currentframe().f_code.co_name));
        return

    name = dut.fibonacci_switch

    assert (name == 1);
    exp = 1;
    val = await read_val(dut, wbs, CTRL_FIBONACCI_CTRL, exp);
    assert (val == exp);

    val = await write_val(dut, wbs, CTRL_FIBONACCI_CTRL, 0);
    assert(val == 1);

    await ClockCycles(dut.wb_clk_i, 5)
    assert name == 0

    val = await write_val(dut, wbs, CTRL_FIBONACCI_CTRL, 1);
    assert(val == 1);

    await ClockCycles(dut.wb_clk_i, 5)
    assert name == 1

async def test_values(dut, wbs, wrapper):

    if wrapper:
        exp = 0;
    else:
        dut.buf_io_out <= 0xFFF;
        exp = 0xF;

    val = await read_val(dut, wbs, CTRL_FIBONACCI_VAL, exp);

    if wrapper:
        exp = int(BinaryValue(str(dut.io_out.value)[:-8]));
    else:
        exp = 0xF;

    # It resets to zero when MSB is high, so in that case add an extra cycle.
    if (val > exp) and wrapper:
        await ClockCycles(dut.wb_clk_i, 5)
        val = await read_val(dut, wbs, CTRL_FIBONACCI_VAL, exp);
        exp = int(BinaryValue(str(dut.io_out.value)[:-8]));

    dut._log.info("val %s <= exp %s" % (hex(val), hex(exp)));
    assert (val <= exp);

    exp = 0;
    # Write should fail.
    val = await write_val(dut, wbs, CTRL_FIBONACCI_VAL, exp);
    assert (val == exp)

async def test_clock_op(dut, wbs, wrapper, gl):

    if gl:
        dut._log.info("Skipping %s" % (inspect.currentframe().f_code.co_name));
        return

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

async def test_panic(dut, wbs, wrapper, gl):

    if gl:
        dut._log.info("Skipping %s" % (inspect.currentframe().f_code.co_name));
        return
    if wrapper:
        name = dut.WishBone.panic;
    else:
        name = dut.panic;

    exp = 0;
    assert (name == exp);

    val = await read_val(dut, wbs, CTRL_PANIC, exp);
    assert (val == exp);

    exp = 0xdeadbeef;
    val = await write_val(dut, wbs, CTRL_PANIC, exp);
    assert (val == 1);

    val = await read_val(dut, wbs, CTRL_PANIC, 1);
    assert (val == 1);

async def test_unknown(dut, wbs):

    cmd = CTRL_GET_ID;
    exp = 0x4669626f;
    val = await read_val(dut, wbs, cmd, exp);

    # First version
    if (exp == 0x4669626f):
        exp = 9

    nr = CTRL_GET_NR
    val = await read_val(dut, wbs, nr, exp);

    cmd = CTRL_GET_NR + (val * 4);
    exp = 0;

    # Should fail.
    val = await write_val(dut, wbs, cmd, exp);
    assert (val == 0);

    # Should fail.
    val = await read_val(dut, wbs, cmd, exp);
    assert (val == 0);

async def activate_wrapper(dut):

    await ClockCycles(dut.wb_clk_i, 5)

    dut.active <= 0
    dut.wb_rst_i <= 1
    await ClockCycles(dut.wb_clk_i, 5)
    dut.wb_rst_i <= 0
    dut.la_data_in <= 0

    dut._log.info("io_out=%s" % (dut.io_out.value));
    # We get these annoying 'ZZ' in there, so we do this dance to get rid of it.
    value = BinaryValue(str(dut.io_out.value)[:-8].replace('z','').replace('x',''));

    assert(str(value) == "");

    await ClockCycles(dut.wb_clk_i, 100)

    dut.active <= 1
    # Reset pin is hooked up to la_data_in[0].
    dut.la_data_in <= 1 << 0
    await ClockCycles(dut.wb_clk_i,2)

    dut.la_data_in <= 0 << 0
    await ClockCycles(dut.wb_clk_i,1)

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
    gl = False
    try:
        dut.vssd1 <= 0
        dut.vccd1 <= 1
        gl = True
    except:
        pass
    # This exists in WishBone code only.
    try:
        dut.reset <= 1
        await ClockCycles(dut.wb_clk_i, 5)
        dut.reset <= 0
    except:
        pass

    wrapper = False
    # While this is for for wrapper
    try:
        await activate_wrapper(dut);
        wrapper = True
    except:
        pass

    await ClockCycles(dut.wb_clk_i, 100)

    await test_id(dut, wbs);

    await test_irq(dut, wbs, wrapper);

    await test_read_write(dut, wbs);

    await test_ctrl(dut, wbs, wrapper, gl);

    await test_values(dut, wbs, wrapper);

    await test_clock_op(dut, wbs, wrapper, gl);

    await test_panic(dut, wbs, wrapper, gl);

    await test_unknown(dut, wbs);
