/*
 * ram_test
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

module ram_test(
	input 		clk,
	input 		reset_, 

	output 		ram_req,
	input 		ram_ready,
	output 		ram_rd,
	output [17:0] 	ram_addr,
	output [1:0] 	ram_be,
	output [15:0] 	ram_wr_data,

	input 		ram_rd_data_vld,
	input [15:0] 	ram_rd_data,

	output		ram_match,
	output		ram_mismatch
	);

	reg 		ram_req, ram_req_nxt;
	wire 		ram_ready;
	reg 		ram_rd, ram_rd_nxt;
	reg [17:0] 	ram_addr, ram_addr_nxt;
	reg [1:0] 	ram_be, ram_be_nxt;
	reg [15:0] 	ram_wr_data, ram_wr_data_nxt;
	wire 		ram_rd_data_vld;
	wire [15:0] 	ram_rd_data;

	reg		ram_match, ram_mismatch;

`define RAM_TEST_INIT 		2'd0 
`define RAM_TEST_INIT_WAIT 	2'd1 
`define RAM_TEST_WR 		2'd2 
`define RAM_TEST_RD 		2'd3 

`ifdef SYNTHESIS
	parameter MAX_ADDR = (2**18)-1;
`else
	parameter MAX_ADDR = 15;
`endif

	reg [1:0] cur_state, nxt_state;

	reg [15:0] exp_rd_data, exp_rd_data_nxt;

	always @*
	begin
		nxt_state 	= cur_state;

		ram_req_nxt 	= ram_req;
		ram_rd_nxt	= ram_rd;
		ram_be_nxt	= ram_be;
		ram_addr_nxt	= ram_addr;
		ram_wr_data_nxt	= ram_wr_data;

		exp_rd_data_nxt	= exp_rd_data;

		case(cur_state)
			`RAM_TEST_INIT: begin
				ram_req_nxt	= 1'b1;
				ram_rd_nxt 	= 1'b0;
				ram_be_nxt	= 2'b11;

				if (ram_ready) begin
					ram_req_nxt	= 1'b0;

					if (ram_addr == MAX_ADDR) begin
						nxt_state 	= `RAM_TEST_WR;

						ram_req_nxt	= 1'b0;
						ram_addr_nxt	= 0;
						ram_wr_data_nxt	= 0;
					end
					else if (ram_addr[2:0] == 3'b111) begin
						ram_addr_nxt	= ram_addr_pl1;
						ram_wr_data_nxt	= ram_addr_pl1[15:0];

						// Every 8 transactions, insert a wait cycle to make sure non-burst requests
						// work too...
						nxt_state	= `RAM_TEST_INIT_WAIT;
					end
					else begin
						ram_addr_nxt	= ram_addr_pl1;
						ram_wr_data_nxt	= ram_addr_pl1[15:0];
					end
				end
			end
			`RAM_TEST_INIT_WAIT: begin
				nxt_state 	= `RAM_TEST_INIT;
			end

			`RAM_TEST_WR: begin
				ram_req_nxt		= 1'b1;
				ram_rd_nxt 		= 1'b0;

				if (ram_ready) begin
					nxt_state 		= `RAM_TEST_RD;
					
					ram_req_nxt		= 1'b1;
					ram_rd_nxt 		= 1'b1;
					ram_addr_nxt 		= ram_addr ^ MAX_ADDR;
				end
			end
			`RAM_TEST_RD: begin
				ram_req_nxt		= 1'b1;
				ram_rd_nxt 		= 1'b1;

				if (ram_ready) begin
					nxt_state 		= `RAM_TEST_WR;

					exp_rd_data_nxt 	= ram_addr[15:0];

					ram_rd_nxt 		= 1'b0;

					if (ram_addr == 0) begin
						ram_req_nxt		= 1'b0;
						ram_addr_nxt 		= 0;
						ram_wr_data_nxt 	= 0;
					end
					else begin
						ram_req_nxt		= 1'b1;
						ram_addr_nxt 		= ram_addr_inv_pl1;
						ram_wr_data_nxt 	= ram_addr_inv_pl1[15:0];
					end
					
				end
			end
		endcase
	end

	wire [17:0] ram_addr_pl1;
	assign ram_addr_pl1 = ram_addr + 1;

	wire [17:0] ram_addr_inv_pl1;
	assign ram_addr_inv_pl1 = (ram_addr ^ MAX_ADDR) + 1;

	always @(posedge clk)
	begin
		if (!reset_) begin
			cur_state	<= `RAM_TEST_INIT;
			
			ram_req		<= 1'b0;
			ram_rd		<= 1'b0;
			ram_be 		<= 2'b00;
			ram_addr	<= 0;
			ram_wr_data	<= 0;

			exp_rd_data	<= 0;
		end
		else begin
			cur_state	<= nxt_state;

			ram_req		<= ram_req_nxt;
			ram_rd		<= ram_rd_nxt;
			ram_be 		<= ram_be_nxt;
			ram_addr	<= ram_addr_nxt;
			ram_wr_data	<= ram_wr_data_nxt;

			exp_rd_data	<= exp_rd_data_nxt;
		end
	end

	always @(posedge clk)
	begin
		if (!reset_) begin
			ram_match	<= 1'b0;
			ram_mismatch	<= 1'b0;
		end
		else if (ram_rd_data_vld) begin
			ram_mismatch	<= !rd_data_equal;
			ram_match	<= rd_data_equal;
		end
	end

	wire rd_data_equal;
	assign rd_data_equal = (exp_rd_data == ram_rd_data);

endmodule
