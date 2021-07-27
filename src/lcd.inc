DDRB = $6002
DDRA = $6003
E  = %10000000
RW = %01000000
RS = %00100000

lcd_init:
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
  rts

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
  lda #%11111111        ; Set Port B to output
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

; print message to the lcd
lcd_printm:
  php                   ; save processor state
  pha                   ; save accumulator
  phy                   ; save y register

  ldy #0
lcd_printm_nextchar:
  lda (pm_textAddress),y
  beq lcd_printm_end    ; stop when we reach the null terminator
  jsr lcd_printc
  iny
  jmp lcd_printm_nextchar

lcd_printm_end:
  ply                   ; restore y register
  pla                   ; restore accumulator
  plp                   ; restore processor status
  rts
; end lcd_printm

lcd_printc:
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
; end lcd_printc
