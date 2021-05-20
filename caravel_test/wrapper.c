/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

#include "../../defs.h"
#include "../../stub.c"

void configure_gpio(void)
{
        reg_mprj_io_31 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_30 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_29 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_28 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_27 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_26 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_25 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_24 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_23 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_22 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_21 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_20 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_19 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_18 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_17 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_16 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_15 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_14 = GPIO_MODE_USER_STD_OUTPUT;

        reg_mprj_io_13 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_12 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_11 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_10 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_9 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_8 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_7 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_6 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_5 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_4 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_3 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_2 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_1 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_0 = GPIO_MODE_USER_STD_OUTPUT;
}

void activate(void)
{
	/* [31:0] is	reg_la0_ena, 0x2500,0010
	 * [63:32] is	reg_la1_ena, 0x2500,0014
	 * [95:64] is	reg_la2_ena  0x2500,0018
	 * [127:96] is	reg_la3_ena  0x2500,001C
	 *
	 * All data go on la_data_in[127:0] , which starts
	 * at 0x2500,0000
	 */
	reg_la1_ena = 0; /* 32th, corresponds to active */
	/* .active() HIGH */
	reg_la1_data = 1; /* 0x2500,0004 */
}

void reset(void)
{
	/* .reset(la_data_in[0]) */
	reg_la0_ena = 0; /* 0x2500,0010 */

	reg_la0_data = 1; /* RST on 0x2500,0000*/
	reg_la0_data = 0; /* RST off */
}

void main()
{
	// All GPIO pins are configured to be output
	configure_gpio();

        /* Apply configuration */
        reg_mprj_xfer = 1;
        while (reg_mprj_xfer == 1);

	activate();

	reset();
	/* There it goes .. */
}

