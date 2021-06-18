// SPDX-FileCopyrightText: 2021 Konrad Rzeszutek Wilk
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0
always @(posedge wb_clk_i) begin
    if(active) begin
        // active properties here
	_active_io_out_:assert(io_out[16:14] == buf_io_out[16:14]);
	_active_wbs_ack: assert(wbs_ack_o == buf_wbs_ack_o );
	_active_wbs_dat_o: assert(wbs_dat_o == buf_wbs_dat_o);
	_active_la_data_out_ :assert(la_data_out == buf_la_data_out);
	_irq_buf_ : assert(irq == buf_irq);
    end
    if(!active) begin
        // inactive properties here
	_io_out_: assert(io_out[16:14] == 7'b0000000);
	_wbs_ack_o: assert(wbs_ack_o == 1'b0);
	_wbs_dat_o: assert(wbs_dat_o == 32'b0);
	_la_data_out: assert(la_data_out == 32'b0);
	_io_oeb: assert(io_oeb == 32'b0);
	_irq_ : assert(irq == 3'b0);
    end
end
