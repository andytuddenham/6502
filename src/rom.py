#!/usr/bin/python3

import sys, getopt

def main(argv):
    outfile = 'blink_led.rom'
    codename = 'blink_led'

    blink_led = bytearray([
        0xa9, 0xff,         # lda #$ff
        0x8d, 0x02, 0x60,   # sta $6002

        0xa9, 0x55,         # lda #$55
        0x8d, 0x00, 0x60,   # sta $6000

        0xa9, 0xaa,         # lda #$aa
        0x8d, 0x00, 0x60,   # sta #6000

        0x4c, 0x05, 0x80,   # jmp $8005
        ])

    rotate_led = bytearray([
        0xa9, 0xff,         # lda #$ff
        0x8d, 0x02, 0x60,   # sta $6002

        0xa9, 0x50,         # lda #$50
        0x8d, 0x00, 0x60,   # sta $6000

        0x6a,               # ror
        0x8d, 0x00, 0x60,   # sta #6000

        0x4c, 0x0a, 0x80,   # jmp $8005
        ])

    code = blink_led

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
            codename = arg
            if codename == 'rotate_led':
                code = rotate_led
            else:
                code = blink_led
    print ('Output file is ', outfile)
    print ('Code is ', codename)

    rom = code + bytearray([0xea] * (32768 - len(code)))

    rom[0x7ffc] = 0x00
    rom[0x7ffd] = 0x80

    with open(outfile, "wb") as out_file:
        out_file.write(rom)

if __name__ == "__main__":
    main(sys.argv[1:])
