SRC_DIR = src
BIN_DIR = bin

AS = ./vasm6502_oldstyle
ASFLAGS = -Fbin -dotdir -wdc02
DUMP = hexdump
DUMPFLAGS = -C
PY = python3
BINFILES = rom.bin blink.bin HelloWorld.bin fibonacci.bin
.SUFFIXES: .py .s .bin

all: $(BINFILES)

$(BIN_DIR):
	mkdir $@

install:
#	minipro -p AT28C256 -w HelloWorld.bin
	minipro -p AT28C256 -w fibonacci.bin

clean:
	-rm $(BIN_DIR)/*

.s.bin:
	$(AS) $(ASFLAGS) -o $(BIN_DIR)/$@ $(SRC_DIR)/$*.s
	$(DUMP) $(DUMPFLAGS) $(BIN_DIR)/$@

.py.bin:
	$(PY) $< $(BIN_DIR)
