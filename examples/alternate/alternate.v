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

module alternate(input clk, input rst, output [3:0] leds);

    reg [24:0] count;

    // LEDs alternately follow 24th bit of counter
    assign leds = {~count[24],count[24],~count[24],count[24]};

    always @(posedge clk) 
        if(rst)
            count = 0;
        else
            count <= count + 1;

endmodule
