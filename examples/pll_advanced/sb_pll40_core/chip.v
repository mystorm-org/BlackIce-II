
module chip (
	// 100MHz clock input
	input  CLK_OSC100,

	output LED1,
	output LED2,
	output LED3,
	output LED4
	);

	assign LED2 = 0;
	assign LED3 = 0;
	assign LED4 = 0;

	wire clk;
	
	pll u_pll(
		.clock_in(CLK_OSC100),
		.clock_out(clk),
		.locked()
	);


	blink u_blink_pll (
		.clk(clk),
		.rst(0),
		.led(LED1)
	);

endmodule
