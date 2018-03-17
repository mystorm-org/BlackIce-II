
#EXAMPLE = sb_pll40_core
#EXAMPLE = sb_pll40_core_global
#EXAMPLE = sb_pll40_pad
EXAMPLE = sb_pll40_pad_global
#EXAMPLE = sb_pll40_pad_global
#EXAMPLE = sb_pll40_pad_global

VERILOG_SRC = $(EXAMPLE)/chip.v $(EXAMPLE)/pll.v  blink.v

INPUT_FREQ = 100
OUTPUT_FREQ = 30

chip.bin: $(VERILOG_SRC) blackice-ii.pcf Makefile
	yosys -q -p "synth_ice40 -blif chip.blif" $(VERILOG_SRC)
	arachne-pnr -d 8k -P tq144:4k -p blackice-ii.pcf chip.blif -V post_place.v -o chip.txt
	icepack chip.txt chip.bin

.PHONY: upload
upload:
	cat chip.bin >/dev/ttyACM0

.PHONY: clean
clean:
	$(RM) -f chip.blif chip.txt chip.ex chip.bin post_place.v
