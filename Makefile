AS = ./vasm6502_oldstyle
ASFLAGS = -Fbin -dotdir -wdc02
DUMP = hexdump
DUMPFLAGS = -C
PY = python3
BINFILES = rom.bin blink.bin HelloWorld.bin fibonacci.bin
.SUFFIXES: .py .s .bin

all: $(BINFILES)

install:
#	minipro -p AT28C256 -w HelloWorld.bin
	minipro -p AT28C256 -w fibonacci.bin

clean:
	-rm $(BINFILES)

.s.bin:
	$(AS) $(ASFLAGS) -o $@ $*.s
	$(DUMP) $(DUMPFLAGS) $@

.py.bin:
	$(PY) $<
