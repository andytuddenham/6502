PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

E  = %10000000
RW = %01000000
RS = %00100000

  .org $8000

reset:
  ldx #$ff
  txs            ; Set stack pointer to top of stack

  lda #$ff       ; Set all pins on port B to output
  sta DDRB

  lda #$e0       ; Set top 3 pins on port A to output
  sta DDRA

  lda #%00111000 ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001110 ; Display on; cursor on; blink off
  jsr lcd_instruction
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001 ; Clear display
  jsr lcd_instruction

  ldx #0
print:
  lda hello_message,x
  beq stop
  jsr print_char
  inx
  jmp print


stop:
  stp

lcd_wait:
  pha
  lda #%00000000    ; Set Port B to input
  sta DDRB
lcd_busy:
  lda #RW
  sta PORTA
  lda #(RW | E)
  sta PORTA
  lda PORTB
  and #%10000000
  bne lcd_busy
  lda #RW
  sta PORTA
  lda #%11111111    ; Set Port B to output
  sta DDRB
  pla
  rts

lcd_instruction:
  pha
  jsr lcd_wait
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  lda #E         ; Set E bit to send instruction
  sta PORTA
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  pla
  rts

print_char:
  pha
  jsr lcd_wait
  sta PORTB
  lda #RS        ; Set RS; clear RW/E bits
  sta PORTA
  lda #(RS | E)  ; Set E bit to send instruction
  sta PORTA
  lda #0         ; Clear E bit
  sta PORTA
  pla
  rts

hello_message:  .asciiz "   Hello Andy                           tudders.com/6502"

  .org $fffc
  .word reset
  .word $0000
