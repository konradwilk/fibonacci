# SPDX-FileCopyrightText: 2021 Konrad Rzeszutek Wilk
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# SPDX-License-Identifier: Apache-2.0
import cocotb
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_wrapper(dut):
    clock = Clock(dut.wb_clk_i, 10, units="ns")
    cocotb.fork(clock.start())

    # Keep reset low
    dut.la_data_in <= 0 << 0

    clocks_per_phase = 5
    try:
        dut.RSTB <= 0
        dut.power1 <= 0;
        dut.power2 <= 0;
        dut.power3 <= 0;
        dut.power4 <= 0;

        dut.vssd1 <= 0
        dut.vccd1 <= 1
    except:
        pass

    dut._log.info("Cycling power");
    await ClockCycles(dut.wb_clk_i, 8)
    dut.power1 <= 1;
    await ClockCycles(dut.wb_clk_i, 8)
    dut.power2 <= 1;
    await ClockCycles(dut.wb_clk_i, 8)
    dut.power3 <= 1;
    await ClockCycles(dut.wb_clk_i, 8)
    dut.power4 <= 1;

    dut.status <= 0
    dut.wbs_dat_i <= 0
    dut.wbs_dat_o <= 0
    dut.wbs_sel_i <= 0
    dut.wbs_adr_i <= 0
    dut.wbs_we_i <= 0;
    dut.wbs_ack_o <= 0;
    dut.wb_rst_i <= 0
    dut.wbs_stb_i <= 0
    dut.wbs_cyc_i <= 0
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

    dut._log.info("io_out=%s" % (dut.io_out.value));
    value = BinaryValue(str(dut.io_out.value)[:-8].replace('z','').replace('x',''));
    #assert (int(value) == 0);

    prio_value = 0;
    p_prio_value = 0;
    
    for i in range(50):

        # assert still low
        assert dut.la_data_in == 0

        value = BinaryValue(str(dut.io_out.value)[:-8].replace('z','').replace('x',''));
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

