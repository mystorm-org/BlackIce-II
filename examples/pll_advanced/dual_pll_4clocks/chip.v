
module chip (
	// 100MHz clock input
	input  CLK_OSC100,

	output LED1,
	output LED2,
	output LED3,
	output LED4
	);

	wire clk_100, clk_top_b, clk_bottom_a, clk_bottom_b;

	pll_top u_pll_top(
		.clock_in(CLK_OSC100),
		.clock_out_a(clk_100),
		.clock_out_b(clk_top_b),
		.locked()
	);

	blink u_blink_pll_top_a (
		.clk(clk_100),
		.rst(0),
		.led(LED1)
	);

	blink u_blink_pll_top_b (
		.clk(clk_top_b),
		.rst(0),
		.led(LED2)
	);


	pll_bottom u_pll_bottom(
		.clock_in(clk_100),
		.clock_out_a(clk_bottom_a),
		.clock_out_b(clk_bottom_b),
		.locked()
	);

	blink u_blink_pll_bottom_a (
		.clk(clk_bottom_a),
		.rst(0),
		.led(LED3)
	);


	blink u_blink_pll_bottom_b (
		.clk(clk_bottom_b),
		.rst(0),
		.led(LED4)
	);

endmodule
