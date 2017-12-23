module rdx (
	input clk,
	input LD1,
	input LD2,
	output LD3,
	input LD4,
	input QD0
);

reg led;
assign LD3 = led;

always @(posedge clk)
	led = QD0;

endmodule

