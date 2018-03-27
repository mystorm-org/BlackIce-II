/******************************************************************************
*                                                                             *
* Copyright 2016 myStorm Copyright and related                                *
* rights are licensed under the Solderpad Hardware License, Version 0.51      *
* (the “License”); you may not use this file except in compliance with        *
* the License. You may obtain a copy of the License at                        *
* http://solderpad.org/licenses/SHL-0.51. Unless required by applicable       *
* law or agreed to in writing, software, hardware and materials               *
* distributed under this License is distributed on an “AS IS” BASIS,          *
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or             *
* implied. See the License for the specific language governing                *
* permissions and limitations under the License.                              *
*                                                                             *
******************************************************************************/
module chip (
	// 100MHz clock input
	input  clk,
	// Global internal reset connected to RTS# on ch340 and also PMOD[1]
	input greset,
	// Input lines from STM32/Done can be used to signal to Ice40 logic
	input DONE, // could be used as interupt in post programming
	input DBG1, // Could be used to select coms via STM32 or RPi etc..
	// SRAM Memory lines
	output [17:0] ADR,
	output [15:0] DAT,
	output RAMOE,
	output RAMWE,
	output RAMCS,
	output RAMLB,
	output RAMUB,
	// All PMOD outputs
	output UART_CTS,
	input  UART_RTS,
	input  UART_RX,
	output UART_TX,
	output [55:4] PMOD,
	input B1,
	input B2, 
	// QUAD SPI pins
	input QSPICSN,
	input QSPICK,
	output [3:0] QSPIDQ
	);

	wire UART_CTS;
	wire UART_RTS;
	wire UART_TX;
	wire UART_RX;

	// SRAM signals are not use in this design, lets set them to default values
	assign ADR[17:0] = {18{1'bz}};
	assign DAT[15:0] = {16{1'bz}};
	assign RAMOE = 1'b1;
	assign RAMWE = 1'b1;
	assign RAMCS = 1'b1;
	assign RAMLB = 1'b1;
	assign RAMUB = 1'b1;

	assign QSPIDQ[3:0] = {4{1'bz}};

	// Set unused pmod pins to default
	assign PMOD[55] 	= led1;
	assign PMOD[54] 	= led2;
	assign PMOD[53] 	= led3;
	assign PMOD[52:4] 	= {49{1'bz}};

	sync_reset u_sync_reset(
		.clk(clk),
		.reset_in_(!greset),
		.reset_out_(reset_)
	);


	wire reset_;

	wire led1;
	wire led2;
	wire led3;

	reg [26:0]	count;
	
	always @(posedge clk)
	begin
		if (!reset_) begin
			count 	<= 0;
		end
		else begin
			count	<= count + 1;
		end
	end

	assign led1 = count[26];
	assign led2 = !UART_TX;

	wire 		rx2tx_req;
	wire 		rx2tx_ready;
	wire [7:0]	rx2tx_data;

	uart_rx #(.BAUD(115200)) u_uart_rx (
		.clk (clk),
		.reset_(reset_),
		.rx_req(rx2tx_req),
		.rx_ready(rx2tx_ready),
		.rx_data(rx2tx_data),
		.uart_rx(UART_RX)
	);

	assign UART_CTS		= !B1;
	assign led3 		= !B1;

	// The uart_tx baud rate is slightly higher than 115200.
	// This is to avoid dropping bytes when the PC sends data at a rate that's a bit faster
	// than 115200. 
	// In a normal design, one typically wouldn't use immediate loopback, so 115200 would be the 
	// right value.
	uart_tx #(.BAUD(116000)) u_uart_tx (
		.clk (clk),
		.reset_(reset_),
		.tx_req(rx2tx_req),
		.tx_ready(rx2tx_ready),
		.tx_data(rx2tx_data),
		.uart_tx(UART_TX)
	);


endmodule
