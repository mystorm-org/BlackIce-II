/**
 * PLL configuration
 *
 * This Verilog module was generated automatically
 * using the icepll tool from the IceStorm project.
 * Use at your own risk.
 *
 * Given input frequency:       100.000 MHz
 * Requested output frequency:   30.000 MHz
 * Achieved output frequency:    30.000 MHz
 */

module pll(
	input  clock_in,
	output clock_out_a,
	output clock_out_b,
	output locked
	);

SB_PLL40_2_PAD #(
		.FEEDBACK_PATH("SIMPLE"),
		.DIVR(4'b0100),		// DIVR =  4
		.DIVF(7'b0101111),	// DIVF = 47
		.DIVQ(3'b101),		// DIVQ =  5
		.FILTER_RANGE(3'b010)	// FILTER_RANGE = 2
	) uut (
		.LOCK(locked),
		.RESETB(1'b1),
		.BYPASS(1'b0),
		.PACKAGEPIN(clock_in),
//		.PLLOUTGLOBALA(clock_out_a),
		.PLLOUTGLOBALB(clock_out_b),
		.PLLOUTCOREA(clock_out_a)
//		.PLLOUTCOREB(clock_out_b)
		);

endmodule
