        .asciiz "Slcd"
LCD_LED = %10000000
LCD_E   = %01000000     ; Enable
LCD_RW  = %00100000     ; Read/Write
LCD_RS  = %00010000     ; Register Select

; work area for lcd_print_msg
pm_textAddress = $0080  ; 2 bytes
; last byte of lcd_print_msg work area is $0081

lcd_init:
  php                   ; save processor state
  pha                   ; save accumulator
  lda #$ff              ; Set all pins on LCD port to output
  sta LCD_DDR

  lda #%00000010        ; Set 4 bit mode
  sta LCD_PORT
  ora #LCD_E
  sta LCD_PORT
  and #%00001111
  sta LCD_PORT

  lda #%00101000        ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001110        ; Display on; cursor on; blink off
  jsr lcd_instruction
  lda #%00000110        ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001        ; Clear display
  jsr lcd_instruction
  pla                   ; restore accumulator
  plp                   ; restore processor status
  rts
; end lcd_init

lcd_wait:
  php                   ; save processor state
  pha                   ; save accumulator

  lda #%11110000        ; Set LCD Port to input
  sta LCD_DDR
lcd_busy:
  lda #LCD_RW
  sta LCD_PORT
  lda #(LCD_RW | LCD_E)
  sta LCD_PORT
  lda LCD_PORT          ; Read high nibble
  pha                   ; and put on the stack since it has the LCD busy flag
  lda #LCD_RW
  sta LCD_PORT
  lda #(LCD_RW | LCD_E)
  sta LCD_PORT
  lda LCD_PORT          ; Read low nibble
  pla                   ; Get high nibble off the stack
  and #%00001000
  bne lcd_busy

  lda #LCD_RW
  sta LCD_PORT
  lda #%11111111        ; Set LCD Port to output
  sta LCD_DDR

  pla                   ; restore accumulator
  plp                   ; restore processor status
  rts
; end lcd_wait

lcd_instruction:
  php                   ; save processor state
  pha                   ; save accumulator

  jsr lcd_wait
  lsr
  lsr
  lsr
  lsr                   ; Send high 4 bits
  sta LCD_PORT
  ora #LCD_E            ; Set E bit to send instruction
  sta LCD_PORT
  eor #LCD_E            ; Clear E bit
  sta LCD_PORT
  pla
  pha
  and #%00001111        ; Send low 4 bits
  sta LCD_PORT
  ora #LCD_E            ; Set E bit to send instruction
  sta LCD_PORT
  eor #LCD_E            ; Clear E bit
  sta LCD_PORT

  pla                   ; restore accumulator
  plp                   ; restore processor status
  rts
; end lcd_instruction

; send a character to the LCD
lcd_print_char:
  jsr lcd_wait
  pha
  lsr
  lsr
  lsr
  lsr                   ; Send high 4 bits
  ora #LCD_RS           ; Set RS
  sta LCD_PORT
  ora #LCD_E            ; Set E bit to send instruction
  sta LCD_PORT
  eor #LCD_E            ; Clear E bit
  sta LCD_PORT
  pla
  pha
  and #%00001111        ; Send low 4 bits
  ora #LCD_RS           ; Set RS
  sta LCD_PORT
  ora #LCD_E            ; Set E bit to send instruction
  sta LCD_PORT
  eor #LCD_E            ; Clear E bit
  sta LCD_PORT
  pla                   ; restore accumulator
  rts
; end lcd_print_char

; print message to the lcd
lcd_print_msg:
  php                   ; save processor state
  pha                   ; save accumulator
  phy                   ; save y register

  ldy #0
lcd_print_msg_nextchar:
  lda (pm_textAddress),y
  beq lcd_print_msg_end    ; stop when we reach the null terminator
  jsr lcd_print_char
  iny
  jmp lcd_print_msg_nextchar

lcd_print_msg_end:
  ply                   ; restore y register
  pla                   ; restore accumulator
  plp                   ; restore processor status
  rts
; end lcd_print_msg
        .asciiz "Elcd"
