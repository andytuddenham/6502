#!/usr/bin/python3

import sys, getopt

def main(argv):
    outfile = 'blink_led.rom'

    code = {}
    code['blink_led'] = bytearray([
        0xa9, 0xff,         # lda #$ff
        0x8d, 0x02, 0x60,   # sta $6002

        0xa9, 0x55,         # lda #$55
        0x8d, 0x00, 0x60,   # sta $6000

        0xa9, 0xaa,         # lda #$aa
        0x8d, 0x00, 0x60,   # sta #6000

        0x4c, 0x05, 0x80,   # jmp $8005
        ])

    code['rotate_led'] = bytearray([
        0xa9, 0xff,         # lda #$ff
        0x8d, 0x02, 0x60,   # sta $6002

        0xa9, 0x50,         # lda #$50
        0x8d, 0x00, 0x60,   # sta $6000

        0x6a,               # ror
        0x8d, 0x00, 0x60,   # sta #6000

        0x4c, 0x0a, 0x80,   # jmp $8005
        ])

    try:
        opts, args = getopt.getopt(argv,"ho:c:",["ofile=","code="])
    except getopt.GetoptError:
        print ('Usage rom.py -o <outputfile> -c <codename>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print ('rom.py -o <outputfile>')
            sys.exit()
        elif opt in ("-o", "--ofile"):
            outfile = arg
        elif opt in ("-c", "--code"):
            print ('Code is ', arg)
            rom = code[arg]
    print ('Output file is ', outfile)

    rom = rom + bytearray([0xea] * (32768 - len(rom)))

    rom[0x7ffc] = 0x00
    rom[0x7ffd] = 0x80

    with open(outfile, "wb") as out_file:
        out_file.write(rom)

if __name__ == "__main__":
    main(sys.argv[1:])
