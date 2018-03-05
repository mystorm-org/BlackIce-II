
`timescale 1ns/100ps

module tb();

	initial begin
		$dumpfile("waves.vcd");
		$dumpvars(0);
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

		repeat(1000) @(posedge clk);

		$finish;
	end

	always begin
		#5 clk = !clk;
	end

	wire RAMCS, RAMWE, RAMOE, RAMUB, RAMLB;
	wire [15:0] DAT;
	wire [17:0] ADR;
	wire B1;
	wire B2;

	assign B1 = 1'b1;
	assign B2 = 1'b1;

	chip u_chip(
		.clk(clk),
		.greset(reset),
		.B1(B1),
		.B2(B2),
		.RAMCS(RAMCS),
		.RAMWE(RAMWE),
		.RAMOE(RAMOE),
		.RAMLB(RAMLB),
		.RAMUB(RAMUB),
		.ADR(ADR),
		.DAT(DAT)
	);

	// Lamest SRAM simulation model ever: for read operations, return the address...
	assign DAT[7:0]  = (!RAMCS && !RAMOE && RAMWE && !RAMLB) ? ADR[7:0] : {8{1'bz}};
	assign DAT[15:8] = (!RAMCS && !RAMOE && RAMWE && !RAMUB) ? ADR[15:8] : {8{1'bz}};


endmodule

