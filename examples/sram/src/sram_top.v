
module sram_top(
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

	// IO pins
	inout 		RAMCS,
	inout 		RAMWE,
	inout 		RAMOE,
	inout 		RAMLB,
	inout 		RAMUB,
	inout [17:0]	ADR,
	inout [15:0]    DAT
	);

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

