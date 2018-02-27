
module sync_dd_c(
	input 	clk,
	input 	reset_, 
	input 	sync_in, 
	output	sync_out
	);

	wire	sync_in;
	reg	sync_in_p1;
	reg	sync_in_p2;
	wire	sync_out;

	always @(posedge clk)
	begin
		if (!reset_) begin
			sync_in_p1 	<= 1'b0;
			sync_in_p2 	<= 1'b0;
		end
		else begin
			sync_in_p1 	<= sync_in;
			sync_in_p2 	<= sync_in_p1;
		end
	end

	assign sync_out = sync_in_p2;

endmodule
