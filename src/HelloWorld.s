LCD_PORT = $6000
LCD_DDR  = $6002

  .org $8000
        .asciiz "SHelloWorld"

reset:
  ldx #$ff
  txs            ; Set stack pointer to top of stack
  jsr lcd_init

  ldx #0
print:
  lda hello_message,x
  beq stop
  jsr lcd_print_char
  inx
  jmp print

stop:
  stp
hello_message:  .asciiz "   Hello Andy                           tudders.com/6502"
        .asciiz "EHelloWorld"

  .include lcd.inc

  .org $fffc
  .word reset
  .word $0000
