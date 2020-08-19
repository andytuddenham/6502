PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

; work area for print_message
pm_textAddress = $0080  ; 2 bytes
; last byte of print_message work area is $0081

; work area for fibonacci
fib_temp = $1000        ; 2 bytes
fib_1    = $1002        ; 2 bytes
fib_2    = $1004        ; 2 bytes
; last byte of fibonacci work area is $1005

; work area for print_number
pn_value     = $1006    ; 2 bytes
pn_strNumber = $1008    ; 10 bytes (inc null terminator)
; last byte of print_number work area is $1011

; work area for divide
div_numerator   = $1012 ; 2 bytes
div_remainder   = $1014 ; 2 bytes
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
  stz fib_1
  stz fib_1 + 1
  stz fib_temp
  stz fib_temp + 1
  lda #1
  sta fib_2
  stz fib_2 + 1
 
fib_loop:
  lda fib_1
  sta pn_value
  lda fib_1 + 1
  sta pn_value + 1
  jsr print_number       ; print the current number
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

; set address of end_messsage into pm_textAddress then call print_message
  lda #(end_message&$00ff)
  sta pm_textAddress
  lda #(end_message>>8)
  sta pm_textAddress + 1
  jsr print_message
end:
  stp                   ; execution ends here

; Input
;   pn_value: the 16 bit value to be printed
print_number:
  php                   ; save processor status
  pha                   ; save accumulator

  lda #%00000001        ; clear display
  jsr lcd_instruction
  lda #%10000010        ; set display address to line 1 column 2
  jsr lcd_instruction

  stz pn_strNumber      ; set string to zero length
  lda pn_value
  sta div_numerator
  lda pn_value + 1
  sta div_numerator + 1
  lda #10
  sta div_denominator
pn_nextchar
  jsr divide
  lda div_remainder
  clc
  adc char_zero
  jsr push_char         ; push the latest characer onto the front of pn_strNumber
  lda div_numerator
  ora div_numerator + 1
  bne pn_nextchar       ; if there are any bits in the numerator then we're not done yet

; set address of pn_strNumber into pm_textAddress then call print_message
  lda #(pn_strNumber&$00ff)
  sta pm_textAddress
  lda #(pn_strNumber>>8)
  sta pm_textAddress + 1
  jsr print_message

pn_end:
  pla                   ; restore accumulator
  plp                   ; restore processor status
  rts
; end print_number

; input:
;   div_numerator contains the numerator
;   div_denominator contains the denominator
; output
;   div_numerator contains the quotient
;   div_remainder contains the remainder
divide:
  php                   ; save processor status
  pha                   ; save accumulator
  phx                   ; save x register
  stz div_remainder
  stz div_remainder + 1
  clc

  ldx #16
div_loop:
  rol div_numerator
  rol div_numerator + 1
  rol div_remainder
  rol div_remainder + 1

  ; a, y = dividend - divisor
  sec                   ; set the carry bit so that we have something to borrow from
  lda div_remainder
  sbc div_denominator   ; subtract denominator from low byte of remainder
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
  plx                   ; restore x register
  pla                   ; restore accumulator
  plp                   ; restore processor status
  rts
; end divide

; Function
;   Add a character to the beginning of the null terminated string pn_strNumber
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
  lda pn_strNumber,y    ; get next char from string
  tax                   ;   and put it in the x register
  pla                   ; pull the character off the stack
  sta pn_strNumber,y    ;   and add it to the string
  iny
  txa
  pha                   ; push char from the string onto the stack
  bne pc_loop
  pla
  sta pn_strNumber,y    ; add the null terminator to the end of the string

  pla                   ; restore accumulator
  ply                   ; restore y register
  plx                   ; restore x register
  plp                   ; restore processor status
  rts
; end push_char

delay:
  php                   ; save processor state
  pha                   ; save accumulator
  phx                   ; save x register
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
  plx                   ; restore x register
  pla                   ; restore accumulator
  plp                   ; restore processor status
  rts
; end delay

lcd_wait:
  php                   ; save processor state
  pha                   ; save accumulator

  lda #%00000000        ; Set Port B to input
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

  pla                   ; restore accumulator
  plp                   ; restore processor status
  rts
; end lcd_wait

lcd_instruction:
  php                   ; save processor state
  pha                   ; save accumulator

  jsr lcd_wait
  sta PORTB
  lda #0                ; Clear RS/RW/E bits
  sta PORTA
  lda #E                ; Set E bit to send instruction
  sta PORTA
  lda #0                ; Clear RS/RW/E bits
  sta PORTA

  pla                   ; restore accumulator
  plp                   ; restore processor status
  rts
; end lcd_instruction

print_message:
  php                   ; save processor state
  pha                   ; save accumulator
  phy                   ; save y register

 ldy #0
pm_nextchar:
  lda (pm_textAddress),y
  beq pm_end            ; stop when we reach the null terminator
  jsr print_char
  iny
  jmp pm_nextchar

pm_end:
  ply                   ; restore y register
  pla                   ; restore accumulator
  plp                   ; restore processor status
  rts
; end print_message

print_char:
  php                   ; save processor state
  pha                   ; save accumulator
  jsr lcd_wait
  sta PORTB
  lda #RS               ; Set RS; clear RW/E bits
  sta PORTA
  lda #(RS | E)         ; Set E bit to send instruction
  sta PORTA
  lda #0                ; Clear E bit
  sta PORTA
  pla                   ; restore accumulator
  plp                   ; restore processor status
  rts
; end print_char

init:
  pha                   ; save accumulator
  clc                   ; clear carry
  cld                   ;       decimal
  clv                   ;       overflow

  lda #$ff              ; Set all pins on port B to output
  sta DDRB

  lda #$e0              ; Set top 3 pins on port A to output
  sta DDRA

  lda #%00111000        ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001100        ; Display on; cursor off; blink off
  jsr lcd_instruction
  lda #%00000110        ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001        ; Clear display
  jsr lcd_instruction

  pla                   ; restore accumulator
  rts                   ; return from subroutine
; end init

end_message:    .asciiz "End"
char_zero:      .byte '0'

  .org $fffc
  .word reset
  .word $0000
