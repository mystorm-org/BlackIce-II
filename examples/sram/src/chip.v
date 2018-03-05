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

	assign QSPIDQ[3:0] = {4{1'bz}};

	// Set unused pmod pins to default
	assign PMOD[55] 	= led1;
	assign PMOD[54] 	= led2;
	assign PMOD[53] 	= led3;
	assign PMOD[52] 	= led4;
	assign PMOD[51:4] 	= {48{1'bz}};
	assign UART_TX 		= 1'bz;
	assign PMOD1 		= 1'bz;
	assign PMOD0 		= 1'bz;

	wire reset_;

	sync_reset u_sync_reset(
		.clk(clk),
		.reset_in_(!greset),
		.reset_out_(reset_)
	);


	wire led1;
	wire led2;
	reg led3;
	reg led4;

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
	assign led2 = 1'b0;

	wire 		sram_req;
	wire 		sram_ready;
	wire 		sram_rd;
	wire [17:0] 	sram_addr;
	wire [1:0] 	sram_be;
	wire [15:0] 	sram_wr_data;
	wire 		sram_rd_data_vld;
	wire [15:0] 	sram_rd_data;

	wire 		sram_mismatch;
	wire 		sram_match;

	ram_test u_ram_test(
		.clk(clk),
		.reset_(reset_),

		.ram_req(sram_req),
		.ram_ready(sram_ready),
		.ram_rd(sram_rd),
		.ram_addr(sram_addr),
		.ram_be(sram_be),
		.ram_wr_data(sram_wr_data),
		.ram_rd_data_vld(sram_rd_data_vld),
		.ram_rd_data(sram_rd_data ^ { 15'd0, !B2} ),

		.ram_mismatch(sram_mismatch),
		.ram_match(sram_match)
	);

	always @(posedge clk)
	begin
		if (!reset_) begin
			led3 	<= 1'b0;
			led4 	<= 1'b0;
		end
		else begin 
			if (sram_mismatch) begin
				led3 	<= 1'b1;
			end

			if (sram_match) begin
				led4 	<= 1'b1;
			end

			if (!B1) begin
				led3 	<= 1'b0;
				led4 	<= 1'b0;
			end
		end
	end

	sram_top u_sram_top(
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

		.RAMCS(RAMCS),
		.RAMWE(RAMWE),
		.RAMOE(RAMOE),
		.RAMLB(RAMLB),
		.RAMUB(RAMUB),
		.ADR(ADR),
		.DAT(DAT)
	);

endmodule
