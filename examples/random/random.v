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

module random(input clk, input rst, output [3:0] leds);

	reg [3:0] led;
	assign leds = led;

	reg [24:0] count;
	reg  [10:1] lfsr = 10'b1;

	always @(posedge clk) begin
	    if(rst) begin
		count = 0;
		lfsr = 10'b1;
	    end
	    else begin
	        count <= count + 1;
	        lfsr <= {lfsr[9:1], lfsr[10] ^ lfsr[7]};
	        if (count[24]) 
	        	led <= lfsr[4:1];
	    end
	end

endmodule
