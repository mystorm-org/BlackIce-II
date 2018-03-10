
module chip (
	// 100MHz clock input
	input  CLK_OSC100,

	output LED1,
	output LED2
	);

	wire clk;
	
	blink u_blink_osc (
		.clk(CLK_OSC100),
		.rst(0),
		.led(LED1)
	);


	pll u_pll(
		.clock_in(CLK_OSC100),
		.clock_out(clk),
		.locked()
	);


	blink u_blink_pll (
		.clk(clk),
		.rst(0),
		.led(LED2)
	);

endmodule
