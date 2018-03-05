/*
 * sram_io_ice40
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

module sram_io_ice40 (
	input		clk,

	input		sram_ce_to_pad_,
	input 		sram_we_to_pad_f_,
	input 		sram_oe_to_pad_f_,
	input 		sram_lb_to_pad_,
	input 		sram_ub_to_pad_,
	input [17:0] 	sram_addr_to_pad,
	input		sram_data_pad_ena,
	input [15:0]	sram_data_to_pad,
	output		sram_data_from_pad_vld,
	output [15:0]	sram_data_from_pad,

	inout 		RAMCS,
	inout 		RAMWE,
	inout 		RAMOE,
	inout 		RAMLB,
	inout 		RAMUB,
	inout [17:0]	ADR,
	inout [15:0]    DAT
	);

	/* verilator lint_off PINMISSING */

	//============================================================
	// CE_ : posedge registered output
	//============================================================
	SB_IO #( 
		.PIN_TYPE(6'b0101_01), 
		.PULLUP(1'b0), 
		.NEG_TRIGGER(1'b0)
	       ) 
	u_sram_io_ce_
		(
		.PACKAGE_PIN(RAMCS),
		.CLOCK_ENABLE(1'b1),
		.OUTPUT_CLK(clk),
		.OUTPUT_ENABLE(),
		.D_OUT_0(sram_ce_to_pad_)
	);

	//============================================================
	// WE_ : negedge registered output 
	//============================================================

	reg sram_we_to_pad_f_p1_;
	reg sram_we_to_pad_f_p2_;
	wire [1:0] sram_we_to_pad_ddr;

	always @(posedge clk)
		sram_we_to_pad_f_p1_ <= sram_we_to_pad_f_;

	always @(negedge clk)
		sram_we_to_pad_f_p2_ <= sram_we_to_pad_f_p1_;

	assign sram_we_to_pad_ddr = {sram_we_to_pad_f_p2_, sram_we_to_pad_f_p1_};

	SB_IO #( 
		.PIN_TYPE(6'b0100_01), 
		.PULLUP(1'b0), 
		.NEG_TRIGGER(1'b0) 
	       ) 
	u_sram_io_we_
		(
		.PACKAGE_PIN(RAMWE),
		.CLOCK_ENABLE(1'b1),
		.OUTPUT_CLK(clk),
		.D_OUT_0(sram_we_to_pad_ddr[1]),
		.D_OUT_1(sram_we_to_pad_ddr[0])
	);

	//============================================================
	// OE_ : negedge registered output => Need DDR output
	//============================================================

	reg sram_oe_to_pad_f_p1_;
	reg sram_oe_to_pad_f_p2_;
	wire [1:0] sram_oe_to_pad_ddr;

	always @(posedge clk)
		sram_oe_to_pad_f_p1_ <= sram_oe_to_pad_f_;

	always @(negedge clk)
		sram_oe_to_pad_f_p2_ <= sram_oe_to_pad_f_p1_;

	assign sram_oe_to_pad_ddr = {sram_oe_to_pad_f_p2_, sram_oe_to_pad_f_p1_};

	SB_IO #( 
		.PIN_TYPE(6'b0100_01), 
		.PULLUP(1'b0), 
		.NEG_TRIGGER(1'b0) 
	       ) 
	u_sram_io_oe_
		(
		.PACKAGE_PIN(RAMOE),
		.CLOCK_ENABLE(1'b1),
		.OUTPUT_CLK(clk),
		.D_OUT_0(sram_oe_to_pad_ddr[1]),
		.D_OUT_1(sram_oe_to_pad_ddr[0])
	);


	//============================================================
	// UL_ / BL_ : posedge registered output
	//============================================================

	SB_IO #( 
		.PIN_TYPE(6'b0101_01), 
		.PULLUP(1'b0), 
		.NEG_TRIGGER(1'b0) 
	       ) 
	u_sram_io_lb_
		(
		.PACKAGE_PIN(RAMLB),
		.CLOCK_ENABLE(1'b1),
		.OUTPUT_CLK(clk),
		.OUTPUT_ENABLE(),
		.D_OUT_0(sram_lb_to_pad_),
		.D_OUT_1(),
		.D_IN_0(),
		.D_IN_1()
	);

	SB_IO #( 
		.PIN_TYPE(6'b0101_01), 
		.PULLUP(1'b0), 
		.NEG_TRIGGER(1'b0) 
	       ) 
	u_sram_io_ub_
		(
		.PACKAGE_PIN(RAMUB),
		.CLOCK_ENABLE(1'b1),
		.OUTPUT_CLK(clk),
		.OUTPUT_ENABLE(),
		.D_OUT_0(sram_ub_to_pad_),
		.D_OUT_1(),
		.D_IN_0(),
		.D_IN_1()
	);

	//============================================================
	// ADDR : posedge registered output
	//============================================================

	SB_IO #( 
		.PIN_TYPE(6'b0101_01), 
		.PULLUP(1'b0), 
		.NEG_TRIGGER(1'b0) 
	       ) 
	u_sram_io_addr [17:0]
		(
		.PACKAGE_PIN(ADR),
		.CLOCK_ENABLE(1'b1),
		.OUTPUT_CLK(clk),
		.D_OUT_0(sram_addr_to_pad)
	);

	//============================================================
	// DATA : posedge output / negedge input => bidir DDR
	//============================================================

//	wire [15:0] sram_data_from_pad_0;
	wire [15:0] sram_data_from_pad_1;

	SB_IO #( 
		.PIN_TYPE(6'b1101_00), 
		.PULLUP(1'b0), 
		.NEG_TRIGGER(1'b0) 
	       ) 
	u_sram_io_data [15:0]
		(
		.PACKAGE_PIN(DAT),
		.LATCH_INPUT_VALUE(1'b1),
		.CLOCK_ENABLE(1'b1),
		.INPUT_CLK(clk),
		.OUTPUT_CLK(clk),
		.OUTPUT_ENABLE(sram_data_pad_ena),
		.D_OUT_0(sram_data_to_pad),
		.D_OUT_1(sram_data_to_pad),
		//.D_IN_0(sram_data_from_pad_0),
		.D_IN_1(sram_data_from_pad_1)
	);

	reg 		sram_oe_p2;
	reg  [15:0] 	sram_data_from_pad;
	reg		sram_data_from_pad_vld;

	always @(posedge clk) begin
		if (sram_oe_p2) begin
			sram_data_from_pad <= sram_data_from_pad_1;
		end

		sram_oe_p2 <= !sram_oe_to_pad_f_p1_;
		sram_data_from_pad_vld <= sram_oe_p2;
	end

endmodule
