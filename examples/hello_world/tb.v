
`timescale 1ns/100ps

module tb();

	initial begin
		$dumpfile("waves.vcd");
		$dumpvars(0, u_chip);
	end
	
	reg clk;
	reg reset;

	initial begin
		clk = 1'b0;
	end

	initial begin
		reset = 1'b1;
		repeat(10) @(posedge clk)
			;
		reset = 1'b0;

		repeat(1000000) @(posedge clk);

		$finish;
	end

	always begin
		#5 clk = !clk;
	end


	chip u_chip(
		.clk(clk),
		.greset(reset)
	);

endmodule

