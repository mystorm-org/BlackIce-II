###############################################################################
#                                                                             #
# Copyright 2016 myStorm Copyright and related                                #
# rights are licensed under the Solderpad Hardware License, Version 0.51      #
# (the “License”); you may not use this file except in compliance with        #
# the License. You may obtain a copy of the License at                        #
# http://solderpad.org/licenses/SHL-0.51. Unless required by applicable       #
# law or agreed to in writing, software, hardware and materials               #
# distributed under this License is distributed on an “AS IS” BASIS,          #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or             #
# implied. See the License for the specific language governing                #
# permissions and limitations under the License.                              #
#                                                                             #
###############################################################################

VERILOG_SRC = chip.v blink.v pll.v 

INPUT_FREQ = 100
OUTPUT_FREQ = 30

chip.bin: $(VERILOG_SRC) blackice-ii.pcf
	yosys -q -p "synth_ice40 -blif chip.blif" $(VERILOG_SRC)
	arachne-pnr -d 8k -P tq144:4k -p blackice-ii.pcf chip.blif -o chip.txt
	icepack chip.txt chip.bin

pll.v: Makefile
	icepll -i $(INPUT_FREQ) -o $(OUTPUT_FREQ) -m -f $@

pll1.v: Makefile
	icepll -i $(INPUT_FREQ) -o 25 -m -f $@

.PHONY: upload
upload:
	cat chip.bin >/dev/ttyACM0

.PHONY: clean
clean:
	$(RM) -f chip.blif chip.txt chip.ex chip.bin pll.v
