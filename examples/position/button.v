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

module button(input clk, input rst, input button1, input button2, output [3:0] led);

	assign led = leds;

	reg [3:0] leds = 4'b1;
	wire left;
	wire right;
	reg right_r;
	reg left_r;

	debounce dbleft(.clk(clk),.button(button1),.state(left));
	debounce dbright(.clk(clk),.button(button2),.state(right));

	always @(posedge clk) begin
		if(rst)
			leds = 4'b1;
		else
			begin
				leds <= (!right_r && right) ? {leds[0],leds[3:1]} :
					(!left_r && left) ? {leds[2:0],leds[3]} : leds;
				right_r <= right;
				left_r <= left;
			end
	end

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
