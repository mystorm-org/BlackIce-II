/*
 * sram_ctrl
 *
 * Copyright 2018 Tom Verbeure
 * 
 * Copyright and related rights are licensed under the Solderpad Hardware License, 
 * Version 0.51 (the “License”); you may not use this file except in compliance with 
 * the License. 
 * You may obtain a copy of the License at *  http://solderpad.org/licenses/SHL-0.51. 
 * Unless required by applicable law or agreed to in writing, software, hardware and 
 * materials distributed under this License is distributed on an “AS IS” BASIS, WITHOUT 
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
 * See the License for the specific language governing permissions and limitations under the License.
 * 
 */

module sram_ctrl (
	input		clk,
	input 		reset_,
	// SRAM core issue interface
	input 		sram_req,
	output 		sram_ready,
	input 		sram_rd,
	input [17:0]	sram_addr,
	input [1:0]	sram_be,
	input [15:0]	sram_wr_data,
	// SRAM core read data interface
	output 		sram_rd_data_vld,
	output [15:0]	sram_rd_data,
	// 
	output 		sram_ce_to_pad_,
	output 		sram_we_to_pad_f_,
	output 		sram_oe_to_pad_f_,
	output 		sram_lb_to_pad_,
	output 		sram_ub_to_pad_,
	output [17:0] 	sram_addr_to_pad,
	output [15:0]	sram_data_to_pad,
	output		sram_data_pad_ena,
	input 		sram_data_from_pad_vld,
	input [15:0]	sram_data_from_pad
	);

	reg	sram_ready;

	reg 		sram_ce_to_pad_;
	reg 		sram_we_to_pad_f_;
	reg 		sram_oe_to_pad_f_;
	reg 		sram_lb_to_pad_;
	reg 		sram_ub_to_pad_;
	reg [17:0] 	sram_addr_to_pad;
	reg [15:0]	sram_data_to_pad;
	reg		sram_data_pad_ena;

`define SRAM_IDLE 	3'd0
`define SRAM_RD0 	3'd1
`define SRAM_RD1 	3'd2
`define SRAM_WR0 	3'd3
`define SRAM_WR1 	3'd4
	
	reg [2:0] cur_state, nxt_state;

	reg sram_ce_to_pad_nxt_;
	reg sram_we_to_pad_f_nxt_;
	reg sram_oe_to_pad_f_nxt_;
	reg sram_lb_to_pad_nxt_;
	reg sram_ub_to_pad_nxt_;
	reg sram_data_pad_ena_nxt;

	always @*
	begin
		nxt_state 	= cur_state;

		sram_ready	= 1'b0;

		sram_ce_to_pad_nxt_	= 1'b1;
		sram_we_to_pad_f_nxt_	= 1'b1;
		sram_oe_to_pad_f_nxt_	= 1'b1;
		sram_lb_to_pad_nxt_	= 1'b1;
		sram_ub_to_pad_nxt_	= 1'b1;
		sram_data_pad_ena_nxt	= 1'b0;

		case(cur_state)
			`SRAM_IDLE: begin
				if (sram_req) begin
					sram_ready = 1'b1;

					sram_ce_to_pad_nxt_		= 1'b0;
					sram_ub_to_pad_nxt_		= !sram_be[1];
					sram_lb_to_pad_nxt_		= !sram_be[0];

					if (sram_rd) begin
						nxt_state		= `SRAM_RD0;
						sram_oe_to_pad_f_nxt_	= 1'b0;
					end
					else begin
						nxt_state		= `SRAM_WR0;
						sram_we_to_pad_f_nxt_	= 1'b0;
						sram_data_pad_ena_nxt	= 1'b1;
					end
				end
			end

			`SRAM_RD0: begin
				sram_ce_to_pad_nxt_	= 1'b0;
				sram_ub_to_pad_nxt_	= sram_ub_to_pad_;
				sram_lb_to_pad_nxt_	= sram_lb_to_pad_;

				nxt_state 		= `SRAM_IDLE;
			end

			`SRAM_WR0: begin
				sram_ce_to_pad_nxt_	= 1'b0;
				sram_ub_to_pad_nxt_	= sram_ub_to_pad_;
				sram_lb_to_pad_nxt_	= sram_lb_to_pad_;
				sram_data_pad_ena_nxt	= 1'b1;

				nxt_state 		= `SRAM_IDLE;
			end

			default: begin
				nxt_state 	= cur_state;
			end
		endcase
	end

	always @(posedge clk)
	begin
		if (!reset_) begin
			cur_state 	<= `SRAM_IDLE;
		end
		else begin
			cur_state 	<= nxt_state;

			sram_ce_to_pad_		<= sram_ce_to_pad_nxt_;
			sram_we_to_pad_f_	<= sram_we_to_pad_f_nxt_;
			sram_oe_to_pad_f_	<= sram_oe_to_pad_f_nxt_;
			sram_lb_to_pad_		<= sram_lb_to_pad_nxt_;
			sram_ub_to_pad_		<= sram_ub_to_pad_nxt_;
			sram_data_pad_ena	<= sram_data_pad_ena_nxt; 
		end
	end

	always @(posedge clk)
	begin
		if (sram_ready) begin
	 		sram_addr_to_pad	<= sram_addr;

			if (!sram_rd) begin
				sram_data_to_pad	<= sram_wr_data;
			end
		end
	end

	assign sram_rd_data_vld	= sram_data_from_pad_vld;
	assign sram_rd_data	= sram_data_from_pad;


endmodule
