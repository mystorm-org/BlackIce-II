
module chip (
	// 100MHz clock input
	input  CLK_OSC100,

	output LED1,
	output LED2,
	output LED3,
	output LED4
	);

	wire clk_a, clk_b;

	assign LED3 = 0;
	assign LED4 = 0;

	pll u_pll(
		.clock_in(CLK_OSC100),
		.clock_out_a(clk_a),
		.clock_out_b(clk_b),
		.locked()
	);

	blink u_blink_pll_a (
		.clk(clk_a),
		.rst(0),
		.led(LED1)
	);

	blink u_blink_pll_b (
		.clk(clk_b),
		.rst(0),
		.led(LED2)
	);

endmodule
