
module sync_reset(
	input 	clk,
	input 	reset_in_, 
	output	reset_out_
	);

	wire	reset_in_;
	reg	reset_in_p1_;
	reg	reset_in_p2_;
	wire	reset_out_;

	always @(posedge clk or negedge reset_in_)
	begin
		if (!reset_in_) begin
			reset_in_p1_ 	<= 1'b0;
			reset_in_p2_ 	<= 1'b0;
		end
		else begin
			reset_in_p1_ 	<= reset_in_;
			reset_in_p2_ 	<= reset_in_p1_;
		end
	end

	assign reset_out_ = reset_in_p2_;

endmodule
