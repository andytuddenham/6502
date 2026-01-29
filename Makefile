SRC_DIR := src
BIN_DIR := bin

SRC := $(wildcard $(SRC_DIR)/*.s)
ROMFILES := $(SRC:$(SRC_DIR)/%.s=$(BIN_DIR)/%.rom)

AS := ./vasm6502_oldstyle
ASFLAGS := -Fbin -dotdir -wdc02

DUMP := hexdump
DUMPFLAGS := -C

all: $(ROMFILES) $(BIN_DIR)/blink_led.rom $(BIN_DIR)/rotate_led.rom

$(BIN_DIR)/%.rom: $(SRC_DIR)/%.s $(SRC_DIR)/lcd.inc | $(BIN_DIR)
	$(AS) $(ASFLAGS) -o $@ $<
	$(DUMP) $(DUMPFLAGS) $@

$(BIN_DIR)/%.rom: $(SRC_DIR)/rom.py | $(BIN_DIR)
	$(SRC_DIR)/rom.py -o$@ -c$*
	$(DUMP) $(DUMPFLAGS) $@

$(BIN_DIR):
	mkdir $@

install:
#	minipro -p AT28C256 -w $(BIN_DIR)/HelloWorld.rom
	minipro -p AT28C256 -w $(BIN_DIR)/fibonacci.rom

test:
	minipro -z -p AT28C256

clean:
	$(RM) -r $(BIN_DIR)

.PHONY: all clean
