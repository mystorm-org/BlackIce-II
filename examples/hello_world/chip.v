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
	// Global internal reset connected to RTS on ch340 and also PMOD[1]
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
	output [55:0] PMOD,
	input B1,
	input B2, 
	// QUAD SPI pins
	input QSPICSN,
	input QSPICK,
	output [3:0] QSPIDQ
	);

	wire uart_tx;
	wire led;

	// SRAM signals are not use in this design, lets set them to default values
	assign ADR[17:0] = {18{1'bz}};
	assign DAT[15:0] = {16{1'bz}};
	assign RAMOE = 1'b1;
	assign RAMWE = 1'b1;
	assign RAMCS = 1'b1;
	assign RAMLB = 1'bz;
	assign RAMUB = 1'bz;

	assign QSPIDQ[3:0] = {4{1'bz}};

	// Set unused pmod pins to default
	assign PMOD[55:0] = { led, {51{1'bz}}, uart_tx, {3{1'bz}}};

	wire reset;

	reg [26:0]	count;
	
	always @(posedge clk)
	begin
		if (reset) begin
			count 	<= 0;
		end
		else begin
			count	<= count + 1;
		end
	end

	assign led = count[26];

	reg [7:0] 	text[0:13];
	reg [3:0]	text_cntr;

	reg 		tx_req;
	reg [7:0]	tx_data;
	wire		tx_ready;

	always @(posedge clk) begin
		if (reset) begin
			text[0]  <= "H";
			text[1]  <= "e";
			text[2]  <= "l";
			text[3]  <= "l";
			text[4]  <= "o";
			text[5]  <= " ";
			text[6]  <= "W";
			text[7]  <= "o";
			text[8]  <= "r";
			text[9]  <= "l";
			text[10] <= "d";
			text[11] <= "!";
			text[12] <= "\n";
			text[13] <= 'h0d;
			
			text_cntr	<= 0;
			tx_req		<= 1'b0;
		end
		else if (text_cntr == 0) begin
			tx_req		<= 1'b0;

			if (count == 26'h50000) begin
				tx_req		<= 1'b1;
				tx_data		<= text[text_cntr];
				text_cntr	<= text_cntr + 1;
			end
		end
		else if (tx_ready) begin
			tx_req		<= 1'b1;
			tx_data		<= text[text_cntr];
			text_cntr	<= text_cntr + 1;

			if (text_cntr == 13) begin
				text_cntr	<= 0;
			end
			else begin
				text_cntr	<= text_cntr + 1;
			end
		end
	end


	sync_reset u_sync_reset(
		.clk(clk),
		.reset_in(greset),
		.reset_out(reset)
	);

	uart_tx u_uart_tx (
		.clk (clk),
		.reset (reset),
		.tx_req(tx_req),
		.tx_ready(tx_ready),
		.tx_data(tx_data),
		.uart_tx(uart_tx)
	);

endmodule
