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
    input B2
  );

  // SRAM signals are not use in this design, lets set them to default values
  assign ADR[17:0] = {18{1'bz}};
  assign DAT[15:0] = {16{1'bz}};
  assign RAMOE = 1'b1;
  assign RAMWE = 1'b1;
  assign RAMCS = 1'b1;
  assign RAMLB = 1'bz;
  assign RAMUB = 1'bz;


  // Set unused pmod pins to default
  assign PMOD[51:0] = {51{1'bz}};


  // Set unused pmod pins to default
  assign PMOD[51:0] = {52{1'bz}};

  rotate my_rotate (
    .clk   (clk),
    .rst (greset),
    .leds (PMOD[55:52])
  );

endmodule
