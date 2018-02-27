
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

		repeat(1000000) @(posedge clk);

		$finish;
	end

	always begin
		#5 clk = !clk;
	end

	wire uart_rx;
	wire uart_tx;

	chip u_chip(
		.clk(clk),
		.greset(reset),
		.UART_RX(uart_rx),
		.UART_TX(uart_tx)
	);

	reg tb_tx_req;
	wire tb_tx_ready;
	reg [7:0] tb_tx_data;

	uart_tx u_uart_tx (
		.clk (clk),
		.reset_(!reset),
		.tx_req(tb_tx_req),
		.tx_ready(tb_tx_ready),
		.tx_data(tb_tx_data),
		.uart_tx(uart_rx)
	);

	initial begin
		tb_tx_req 	= 1'b0;
		@(negedge reset);

		repeat(1000) @(posedge clk);

		@(posedge clk);
		tb_tx_req 	= 1'b1;
		tb_tx_data 	= "H";

		@(posedge tb_tx_ready);
		@(posedge clk);

		tb_tx_data 	= "e";

		@(posedge tb_tx_ready);
		@(posedge clk);
		tb_tx_req 	= 1'b0;

		repeat(100000) @(posedge clk);

		$finish;
	end


endmodule

