PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

temp = $1000
value = $1001
counter = $1002
numerator = $1003
denominator = $1004
remainder = $1005

E  = %10000000
RW = %01000000
RS = %00100000

  .org $8000

reset:
  ldx #$ff
  txs                   ; Set stack pointer to top of stack
  jsr init

  lda #0
  sta temp
  ldy #1
loop:
  jsr print_value       ; print the current value in the accumulator
  bcs stop              ; if adc caused the carry bit to be set, we've printed the last value
  jsr delay
  sty temp
  adc temp
  sta temp
  tya
  ldy temp
  jmp loop

stop:
  lda #%11000000        ; set display address to line 2 column 1
  jsr lcd_instruction
  ldx #0
stopm:
  lda end_message,x
  beq end
  jsr print_char
  inx
  jmp stopm
end:
  stp                   ; execution ends here

print_value:
  sta value             ; save the value to be printed
  php                   ; save processor status
  pha                   ; save accumulator
  lda #%00000001        ; clear display
  jsr lcd_instruction
  lda #%10000111        ; set display address to line 1 column 7
  jsr lcd_instruction
  lda value
  sta numerator
  lda #10
  sta denominator
  jsr divide
  lda remainder
  adc char_zero
  jsr print_char        ; print the units character
  lda numerator
  cmp #$0
  beq pv_end
  lda #%10000110        ; set display address to line 1 column 6
  jsr lcd_instruction
  jsr divide
  lda remainder
  adc char_zero
  jsr print_char        ; print the tens character
  lda numerator
  cmp #$0
  beq pv_end
  lda #%10000101        ; set display address to line 1 column 5
  jsr lcd_instruction
  jsr divide
  lda remainder
  adc char_zero
  jsr print_char        ; print the hundreds character
pv_end:
  pla                   ; reset accumulator
  plp                   ; reset processor status
  rts

; input:
;   numerator/denominator
; output
;   numerator contains the quotient
;   remainder contains the remainder
divide:
  pha                   ; save accumulator
  txa
  pha                   ; save x register
  lda #0
  ldx #8
  asl numerator
divide1:
  rol
  cmp denominator
  bcc divide2
  sbc denominator
divide2:
  rol numerator
  dex
  bne divide1
  sta remainder
  pla
  tax                   ; reset x register
  pla                   ; reset accumulator
  rts

delay:
  php                   ; save processor state
  pha                   ; save accumulator
  txa
  pha                   ; save x register
  lda #0
delay_inca:
  ldx #0
delay_incx:
  inx
  beq delay_endx
  nop
  nop
  nop
  nop
  nop
  jmp delay_incx
delay_endx:
  clc
  adc #1
  cmp #200
  bne delay_inca
  pla
  tax                   ; reset x register
  pla                   ; reset accumulator
  plp                   ; reset processor status
  rts

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

init:
  pha                   ; save accumulator
  clc                   ; clear carry
  cld                   ;       decimal
  clv                   ;       overflow

  lda #$ff       ; Set all pins on port B to output
  sta DDRB

  lda #$e0       ; Set top 3 pins on port A to output
  sta DDRA

  lda #%00111000 ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001100 ; Display on; cursor off; blink off
  jsr lcd_instruction
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001 ; Clear display
  jsr lcd_instruction

  pla
  rts

end_message:    .asciiz "End"
char_zero:      .byte '0'

  .org $fffc
  .word reset
  .word $0000
