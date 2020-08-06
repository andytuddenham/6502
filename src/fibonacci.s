PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

; work area for fibonacci
fib_temp = $1000        ; 2 bytes
fib_1 = $1002           ; 2 bytes
fib_2 = $1004           ; 2 bytes
; last byte of fibonacci work area is $1005

; work are for print_value
pv_value = $1006        ; 2 bytes
pv_strNumber = $1008    ; 10 bytes (inc null terminator)
; last byte of print_value work area is $1011

; work area for divide
div_numerator = $1012   ; 2 bytes
div_remainder = $1014   ; 2 bytes
div_denominator = $1016 ; 1 byte
; last byte of divide work area is $1016

E  = %10000000
RW = %01000000
RS = %00100000

  .org $8000

reset:
  ldx #$ff
  txs                   ; Set stack pointer to top of stack
  jsr init

fibonacci:
  lda #0
  sta fib_1
  sta fib_1 + 1
  sta fib_temp
  sta fib_temp + 1
  sta fib_2 + 1
  lda #1
  sta fib_2

fib_loop:
  lda fib_1
  sta pv_value
  lda fib_1 + 1
  sta pv_value + 1
  jsr print_value       ; print the current value
  bcs stop              ; if adc caused the carry bit to be set, we've printed the last value
  jsr delay

  ; transfer fib_2 -> fib_temp
  lda fib_2
  sta fib_temp
  lda fib_2 + 1
  sta fib_temp + 1

  ; fib_1 += fib_temp
  lda fib_1
  clc
  adc fib_temp
  tay
  lda fib_1 + 1
  adc fib_temp + 1      ; if this causes a carry then we should stop after the next print
  sty fib_1
  sta fib_1 + 1

  ; transfer fib_1 -> fib_temp
  lda fib_1
  sta fib_temp
  lda fib_1 + 1
  sta fib_temp + 1

  ; transfer fib_2 -> fib_1
  lda fib_2
  sta fib_1
  lda fib_2 + 1
  sta fib_1 + 1

  ; transfer fib_temp -> fib_2
  lda fib_temp
  sta fib_2
  lda fib_temp + 1
  sta fib_2 + 1

  jmp fib_loop
; end fibonacci

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

; Input
;   pv_value: the 16 bit value to be printed
print_value:
  php                   ; save processor status
  pha                   ; save accumulator

  lda #%00000001        ; clear display
  jsr lcd_instruction
  lda #%10000010        ; set display address to line 1 column 2
  jsr lcd_instruction

  lda #0
  sta pv_strNumber      ; set string to zero length
  lda pv_value
  sta div_numerator
  lda pv_value + 1
  sta div_numerator + 1
  lda #10
  sta div_denominator
pv_nextchar
  jsr divide
  lda div_remainder
  clc
  adc char_zero
  jsr push_char
  lda div_numerator
  ora div_numerator + 1
  bne pv_nextchar       ; if there are any bits in the numerator then we're not done yet
  ; print pv_strNumber
  ldx #0
pv_print:
  lda pv_strNumber,x
  beq pv_end
  jsr print_char
  inx
  jmp pv_print
pv_end:
  pla                   ; restore accumulator
  plp                   ; restore processor status
  rts
; end print_value

; input:
;   div_numerator contains the numerator
;   div_denominator contains the denominator
; output
;   div_numerator contains the quotient
;   div_remainder contains the remainder
divide:
  php                   ; save processor status
  pha                   ; save accumulator
  txa
  pha                   ; save x register
  lda #0
  sta div_remainder
  sta div_remainder + 1
  clc

  ldx #16
div_loop:
  rol div_numerator
  rol div_numerator + 1
  rol div_remainder
  rol div_remainder + 1

  ; a, y = dividend - divisor
  sec
  lda div_remainder
  sbc div_denominator   ; subtract denominator ffrom ow byte of remainder
  tay                   ; save low byte in y
  lda div_remainder + 1
  sbc #0
  bcc div_ignore_result ; branch if dividend < divisor
  sty div_remainder
  sta div_remainder + 1

div_ignore_result:
  dex
  bne div_loop
  rol div_numerator
  rol div_numerator + 1
  pla
  tax                   ; restore x register
  pla                   ; restore accumulator
  plp                   ; restore processor status
  rts
; end divide

; Function
;   Add a character to the beginning of the null terminated string pv_strNumber
; Input
;   char to be added in the accumulator
push_char:
  php                   ; save processor state
  phx                   ; save x register
  phy                   ; save y register
  pha                   ; save accumulator

  pha                   ; save input char
  ldy #0
pc_loop:
  lda pv_strNumber,y    ; get next char from string
  tax                   ;   and put it in the x register
  pla                   ; pull the character off the stack
  sta pv_strNumber,y    ;   and add it to the string
  iny
  txa
  pha                   ; push char from the string onto the stack
  bne pc_loop
  pla
  sta pv_strNumber,y    ; add the null terminator to the end of the string

  pla                   ; restore accumulator
  ply                   ; restore y register
  plx                   ; restore x register
  plp                   ; restore processor status
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
  tax                   ; restore x register
  pla                   ; restore accumulator
  plp                   ; restore processor status
  rts
; end delay

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
; end lcd_wait

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
; end lcd_instruction

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
; end print_char

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

  pla                   ; restore accumulator
  rts                   ; return from subroutine
; end init

end_message:    .asciiz "End"
char_zero:      .byte '0'

  .org $fffc
  .word reset
  .word $0000
