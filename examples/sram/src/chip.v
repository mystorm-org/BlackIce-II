/******************************************************************************
*                                                                             *
* Copyright 2016 myStorm Copyright and related                                *
* rights are licensed under the Solderpad Hardware License, Version 0.51      *
* (the “License”); you may not use this file except in compliance with        *
* the License. You may obtain a copy of the License at                        *
* http://solderpad.org/licenses/SHL-0.51. Unless required by applicable       *
* law or agreed to in writing, software, hardware and materials               *
* distributed under this License is distributed on an “AS IS” BASIS,          *
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or             *
* implied. See the License for the specific language governing                *
* permissions and limitations under the License.                              *
*                                                                             *
******************************************************************************/
module chip (
	// 100MHz clock input
	input  clk,
	// Global internal reset connected to RTS on ch340 and also PMOD[1]
	input greset,
	// Input lines from STM32/Done can be used to signal to Ice40 logic
	input DONE, // could be used as interupt in post programming
	input DBG1, // Could be used to select coms via STM32 or RPi etc..
	// SRAM Memory lines
	inout [17:0] ADR,
	inout [15:0] DAT,
	inout RAMOE,
	inout RAMWE,
	inout RAMCS,
	inout RAMLB,
	inout RAMUB,
	// All PMOD outputs
	output PMOD0,
	output PMOD1,
	input  UART_RX,
	output UART_TX,
	output [55:4] PMOD,
	input B1,
	input B2, 
	// QUAD SPI pins
	input QSPICSN,
	input QSPICK,
	output [3:0] QSPIDQ
	);

	wire UART_TX;
	wire UART_RX;

	assign QSPIDQ[3:0] = {4{1'bz}};

	// Set unused pmod pins to default
	assign PMOD[55] 	= led1;
	assign PMOD[54] 	= led2;
	assign PMOD[53] 	= led3;
	assign PMOD[52:4] 	= {51{1'bz}};
	assign PMOD1 		= 1'bz;
	assign PMOD0 		= 1'bz;

	wire reset_;

	wire led1;
	wire led2;
	reg led3;

	reg [26:0]	count;
	
	always @(posedge clk)
	begin
		if (!reset_) begin
			count 	<= 0;
		end
		else begin
			count	<= count + 1;
		end
	end

	assign led1 = count[26];
	assign led2 = !UART_TX;

	wire 		rx2tx_req;
	wire 		rx2tx_ready;
	wire [7:0]	rx2tx_data;

	sync_reset u_sync_reset(
		.clk(clk),
		.reset_in_(!greset),
		.reset_out_(reset_)
	);

	uart_rx #(.BAUD(115200)) u_uart_rx (
		.clk (clk),
		.reset_(reset_),
		.rx_req(rx2tx_req),
		.rx_ready(rx2tx_ready),
		.rx_error(),
		.rx_data(rx2tx_data),
		.uart_rx(UART_RX)
	);

	// The uart_tx baud rate is slightly higher than 115200.
	// This is to avoid dropping bytes when the PC sends data at a rate that's a bit faster
	// than 115200. 
	// In a normal design, one typically wouldn't use immediate loopback, so 115200 would be the 
	// right value.
	uart_tx #(.BAUD(116000)) u_uart_tx (
		.clk (clk),
		.reset_(reset_),
		.tx_req(rx2tx_req),
		.tx_ready(rx2tx_ready),
		.tx_data(rx2tx_data),
		.uart_tx(UART_TX)
	);

	reg 		sram_req, sram_req_nxt;
	wire 		sram_ready;
	reg 		sram_rd, sram_rd_nxt;
	reg [17:0] 	sram_addr, sram_addr_nxt;
	reg [1:0] 	sram_be, sram_be_nxt;
	reg [15:0] 	sram_wr_data, sram_wr_data_nxt;
	wire 		sram_rd_data_vld;
	wire [15:0] 	sram_rd_data;


`define SRAM_TEST_INIT 		3'd0 
`define SRAM_TEST_INIT_WAIT 	3'd1 
`define SRAM_TEST_WR 		3'd2 
`define SRAM_TEST_RD 		3'd3 

`ifdef SYNTHESIS
	parameter MAX_ADDR = (2**18)-1;
`else
	parameter MAX_ADDR = 15;
`endif

	reg [2:0] cur_state, nxt_state;

	reg [15:0] exp_rd_data, exp_rd_data_nxt;

	always @*
	begin
		nxt_state 		= cur_state;

		sram_req_nxt 		= sram_req;
		sram_rd_nxt		= sram_rd;
		sram_be_nxt		= sram_be;
		sram_addr_nxt		= sram_addr;
		sram_wr_data_nxt	= sram_wr_data;

		exp_rd_data_nxt		= exp_rd_data;

		case(cur_state)
			`SRAM_TEST_INIT: begin
				sram_req_nxt	= 1'b1;
				sram_rd_nxt 	= 1'b0;
				sram_be_nxt	= 2'b11;

				if (sram_ready) begin
					sram_req_nxt	= 1'b0;

					if (sram_addr == MAX_ADDR) begin
						nxt_state 	= `SRAM_TEST_WR;

						sram_req_nxt	= 1'b0;
						sram_addr_nxt	= 0;
						sram_wr_data_nxt= 0;
					end
					else if (sram_addr[2:0] == 3'b111) begin
						sram_addr_nxt		= sram_addr_pl1;
						sram_wr_data_nxt	= sram_addr_pl1;

						nxt_state	= `SRAM_TEST_INIT_WAIT;
					end
					else begin
						sram_addr_nxt		= sram_addr_pl1;
						sram_wr_data_nxt	= sram_addr_pl1;
					end
				end
			end
			`SRAM_TEST_INIT_WAIT: begin
				nxt_state 	= `SRAM_TEST_INIT;
			end

			`SRAM_TEST_WR: begin
				sram_req_nxt		= 1'b1;
				sram_rd_nxt 		= 1'b0;

				if (sram_ready) begin
					nxt_state 		= `SRAM_TEST_RD;
					
					sram_req_nxt		= 1'b1;
					sram_rd_nxt 		= 1'b1;
					sram_addr_nxt 		= sram_addr ^ MAX_ADDR;
				end
			end
			`SRAM_TEST_RD: begin
				sram_req_nxt		= 1'b1;
				sram_rd_nxt 		= 1'b1;

				if (sram_ready) begin
					nxt_state 		= `SRAM_TEST_WR;

					exp_rd_data_nxt 	= sram_addr;

					sram_rd_nxt 		= 1'b0;

					if (sram_addr == 0) begin
						sram_req_nxt		= 1'b0;
						sram_addr_nxt 		= 0;
						sram_wr_data_nxt 	= 0;
					end
					else begin
						sram_req_nxt		= 1'b1;
						sram_addr_nxt 		= sram_addr_inv_pl1;
						sram_wr_data_nxt 	= sram_addr_inv_pl1;
					end
					
				end
			end
		endcase
	end

	wire [17:0] sram_addr_pl1;
	assign sram_addr_pl1 = sram_addr + 1;

	wire [17:0] sram_addr_inv_pl1;
	assign sram_addr_inv_pl1 = (sram_addr ^ MAX_ADDR) + 1;

	always @(posedge clk)
	begin
		if (!reset_) begin
			cur_state		<= `SRAM_TEST_INIT;
			
			sram_req		<= 1'b0;
			sram_rd			<= 1'b0;
			sram_be 		<= 2'b00;
			sram_addr		<= 0;
			sram_wr_data		<= 0;

			exp_rd_data		<= 0;
		end
		else begin
			cur_state		<= nxt_state;

			sram_req		<= sram_req_nxt;
			sram_rd			<= sram_rd_nxt;
			sram_be 		<= sram_be_nxt;
			sram_addr		<= sram_addr_nxt;
			sram_wr_data		<= sram_wr_data_nxt;

			exp_rd_data		<= exp_rd_data_nxt;
		end
	end

	always @(posedge clk)
	begin
		if (!reset_) begin
			led3	<= 1'b0;
		end
		else if (sram_rd_data_vld) begin
			led3	<= (exp_rd_data != sram_rd_data) ^ !B1;
		end
	end


	wire		sram_ce_to_pad_;
	wire 		sram_we_to_pad_f_;
	wire 		sram_oe_to_pad_f_;
	wire 		sram_lb_to_pad_;
	wire 		sram_ub_to_pad_;
	wire [17:0] 	sram_addr_to_pad;
	wire		sram_data_pad_ena;
	wire [15:0]	sram_data_to_pad;
	wire 		sram_data_from_pad_vld;
	wire [15:0]	sram_data_from_pad;

	sram_ctrl u_sram_ctrl (
		.clk(clk),
		.reset_(reset_),

		.sram_req(sram_req),
		.sram_ready(sram_ready),
		.sram_rd(sram_rd),
		.sram_addr(sram_addr),
		.sram_be(sram_be),
		.sram_wr_data(sram_wr_data),
		.sram_rd_data_vld(sram_rd_data_vld),
		.sram_rd_data(sram_rd_data),

		.sram_ce_to_pad_(sram_ce_to_pad_),
		.sram_we_to_pad_f_(sram_we_to_pad_f_),
		.sram_oe_to_pad_f_(sram_oe_to_pad_f_),
		.sram_lb_to_pad_(sram_lb_to_pad_),
		.sram_ub_to_pad_(sram_ub_to_pad_),
		.sram_addr_to_pad(sram_addr_to_pad),
		.sram_data_to_pad(sram_data_to_pad),
		.sram_data_pad_ena(sram_data_pad_ena),
		.sram_data_from_pad_vld(sram_data_from_pad_vld),
		.sram_data_from_pad(sram_data_from_pad)
	);

	sram_io_ice40 u_sram_io_ice40 (
		.clk(clk),
		.sram_ce_to_pad_(sram_ce_to_pad_),
		.sram_we_to_pad_f_(sram_we_to_pad_f_),
		.sram_oe_to_pad_f_(sram_oe_to_pad_f_),
		.sram_lb_to_pad_(sram_lb_to_pad_),
		.sram_ub_to_pad_(sram_ub_to_pad_),
		.sram_addr_to_pad(sram_addr_to_pad),
		.sram_data_to_pad(sram_data_to_pad),
		.sram_data_pad_ena(sram_data_pad_ena),
		.sram_data_from_pad_vld(sram_data_from_pad_vld),
		.sram_data_from_pad(sram_data_from_pad),
		.RAMCS(RAMCS),
		.RAMWE(RAMWE),
		.RAMOE(RAMOE),
		.RAMLB(RAMLB),
		.RAMUB(RAMUB),
		.ADR(ADR),
		.DAT(DAT)
	);


endmodule
