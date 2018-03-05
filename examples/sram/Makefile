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

VERILOG_FILES = src/chip.v src/uart_rx.v src/uart_tx.v src/sync_reset.v src/sync_dd_c.v src/sram_ctrl.v src/sram_io_ice40.v
PCF_FILE = blackice-ii.pcf
CELLS_SIM := $(shell yosys-config --datdir/ice40/cells_sim.v)

chip.bin: chip.blif $(PCF_FILE)
	../../../arachne-pnr-tv/bin/arachne-pnr -d 8k -P tq144:4k -p $(PCF_FILE) chip.blif -o chip.asc
	icepack chip.asc chip.bin

chip.blif: $(VERILOG_FILES) 
	yosys -q -p "synth_ice40 -blif chip.blif" $(VERILOG_FILES)

time: chip.bin
	icetime -tmd hx8k chip.asc

.PHONY: upload
upload:
	stty -F /dev/ttyACM0 115200 raw
	cat chip.bin >/dev/ttyACM0

.PHONY: clean
clean:
	$(RM) -f chip.blif chip.asc chip.ex chip.bin waves.vcd tb


flash: 
	dfu-util -d 0483:df11 --alt 0 --dfuse-address 0x0801F000 -D chip.bin

run:
	stty -F /dev/ttyUSB0 115200 raw -echo
	cat /dev/ttyUSB0

tb: src/tb.v $(VERILOG_FILES) $(CELLS_SIM)
	iverilog -o tb src/tb.v $(VERILOG_FILES) $(CELLS_SIM)

sim: tb
	./tb

help:
	@echo "Makefile options:"
	@echo "    chip.bin (default): Create iCE40 bitstream"
	@echo "    upload:             Upload chip.bin as volatible bitstream to FPGA. Run as root."
	@echo "    flash:              Flash chip.bin into STM32 internal flash. STM32 must be in DFU mode. Run as root."
	@echo "    sim:                Simulate the design. Create .vcd file to use with GTKwave."
	@echo "    run:                Check results on USB2 port."
	@echo "    clean:              Clean up directory"

lint:
	verilator_bin --lint-only -I $(CELLS_SIM) $(VERILOG_FILES) --top-module chip
