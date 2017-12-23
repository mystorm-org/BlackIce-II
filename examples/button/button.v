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

module button(input clk, input rst, input [1:0] buttons, output [3:0] led);

	assign led = leds;

	reg [3:0] leds = 4'b0;
	wire on;
	wire off;

	debounce dbon(.clk(clk),.button(buttons[0]),.state(on));
	debounce dboff(.clk(clk),.button(buttons[1]),.state(off));

	always @*
		if(rst)
			leds = 4'b0;
		else
		 leds <= (on) ? 4'b1111 :
					(off) ? 4'b0000 : leds;

endmodule

module debounce(input clk, input button, output reg state);
	wire idle;
	reg sync;
	reg [15:0] count;

	assign idle = (state == sync);

	always @(posedge clk) begin
		sync <= ~button;
		count <= (idle) ? 0 : count + 16'b1;
		if(&count) 
			state <= ~state;
	end
endmodule
