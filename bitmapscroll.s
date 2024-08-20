; demo of scrolling bitmap



.autoimport	on              ; imports C library functions
.forceimport	__STARTUP__ ; imports STARTUP, INIT, ONCE
.export		_main           ; expose mane to the C library
.include        "zeropage.inc"
.include        "cbm_kernal.inc"

; starting addresses of bitmaps
BMP0 = $6000
BMP0_COLOR = $5c00
BMP1 = $a000
BMP1_COLOR = $8400
; logical printer fd
PRINTER = $1

.segment "DATA"
; zero page aliases
byteaddr := tmp1		; 2 bytes

temp16:       .res    2       ; 2 bytes
bmp_dst:      .res    2       ; the current bitmap
bmp_src:      .res    2       ; the oppposite bitmap for scroll copy
color_ptr:    .res    2       ; the current color map
color_ptr2:   .res    2       ; the oppposite color map for scroll copy
step:         .res    1       ; count the number of loops
current_page: .res    1

; macros
.macro SET_LITERAL16 address, value
    lda #<value
    sta address
    lda #>value
    sta address + 1
.endmacro

.macro COPY_REG16 dst, src
    lda src
    sta dst
    lda src + 1
    sta dst + 1
.endmacro

; dst = a + b
.macro ADD_REG16 a_hi, a_lo, b_hi, b_lo, dst_hi, dst_lo
    clc
    lda a_lo
    adc b_lo
    sta dst_lo
    lda a_hi
    adc b_hi
    sta dst_hi
.endmacro

; dst = literal + src
.macro ADD_LITERAL16 dst, src, literal
    clc
    lda #<literal ; low
    adc src
    sta dst
    lda #>literal ; high
    adc src + 1
    sta dst + 1
.endmacro

; dst = src - literal
.macro SUB_LITERAL16 dst, src, literal
    sec
    lda src
    sbc #<literal ; low
    sta dst
    lda src + 1
    sbc #>literal ; high
    sta dst + 1
.endmacro

    

.macro PRINT_TEXT string
    SET_LITERAL16 printmod + 1, string ; self modifying code
    jsr print
.endmacro

.macro PRINT_HEX16 address
    ldy address + 1
    jsr print_hex8
    ldy address
    jsr print_hex8
    lda #$20 ; space
    jsr CHROUT
.endmacro

.macro PRINT_HEX8 address
    ldy address
    jsr print_hex8
    lda #$20 ; space
    jsr CHROUT
.endmacro


.segment	"CODE"

welcome:
    .byte "welcome to bitmap scroller"
    .byte $0a, $00    ; null terminator for the message

loop_text:
    .byte "loop"
    .byte $0a, $00

pattern1:
    .byte $55, $aa, $55, $aa, $55, $aa, $55, $aa

pattern2:
    .byte $00, $00, $00, $00, $00, $00, $00, $00

print:
    ldx #$00          ; initialize X register for indexing
printmod:
    lda $ffff,x       ; load the character from the message
    beq print2        ; if character is zero, we are done
        jsr CHROUT    ; call CHROUT routine to send the character to the serial port
        inx           ; increment X register
        jmp printmod  ; repeat the loop
print2:
    rts


; print the value of Y
hex_table:
    .byte "0123456789abcdef"
print_hex8:
    tya
    and #$f0
    clc
    ror A
    ror A
    ror A
    ror A
    tax
    lda hex_table,x
    jsr CHROUT
    tya
    and #$0f
    tax
    lda hex_table,x
    jsr CHROUT
    rts

; set up the page based on the current value of A
flip_page:
; wait for raster line >= 256
    lda $d011
    bpl flip_page
    

    lda #1
    eor current_page
    sta current_page
    cmp #0
    bne flip_page2

; display BMP0, draw BMP1
	    lda $d018
	    and	#%00001111  ; set color memory relative to VIC bank
	    ora	#%01110000  ; vic bank + $1c00
	    sta	$d018

        lda	$dd00		; set the VIC bank
	    and	#%11111100
	    ora	#%00000010  ; $4000
	    sta	$dd00
        SET_LITERAL16 bmp_src, BMP0
        SET_LITERAL16 color_ptr, BMP0_COLOR
        SET_LITERAL16 bmp_dst, BMP1
        SET_LITERAL16 color_ptr2, BMP1_COLOR
        rts

flip_page2:
; display BMP1, draw BMP0
	lda $d018           ; set color memory relative to VIC bank
	and	#%00001111
	ora	#%00010000      ; only vic bank + $0400 works
	sta	$d018

	lda	$dd00		    ; set the VIC bank
	and	#%11111100
	ora	#%00000001      ; $8000
	sta	$dd00
    
    SET_LITERAL16 bmp_src, BMP1
    SET_LITERAL16 color_ptr, BMP1_COLOR
    SET_LITERAL16 bmp_dst, BMP0
    SET_LITERAL16 color_ptr2, BMP0_COLOR
    rts




.proc	_main: near

; open the printer page 338
    lda #PRINTER ; logical number
    ldx #4 ; device number
    ldy #7 ; secondary address
    jsr SETLFS

    jsr OPEN

; direct CHROUT to the printer
    ldx #PRINTER ; logical number
    jsr CHKOUT

; print something
    PRINT_TEXT welcome
; test
;    SET_LITERAL16 temp16, $1234
;    PRINT_HEX16 temp16
;    lda #$0a
;    jsr CHROUT
;    rts

; bitmap mode
    ldy	#187
	sty	$d011		

	lda	$DD02
	ora	#3
	sta	$DD02		;CIA-2 I/O default value 		

    jsr flip_page ; set up the bitmap
    jsr update_pattern ; set up the pattern

	lda	$d018       ; set bitmap memory relative to VIC bank
	and	#%11110000
	ora	#%00001000  ; vic bank + $2000
	sta	$d018	

; set color memory to white pen on dark blue paper (also clears sprite pointers) on screen 1
	lda	#$16
	ldx	#$00
loopcol2:
    sta	BMP1_COLOR,x	
	sta	BMP1_COLOR+$100,x
	sta	BMP1_COLOR+$200,x
	sta	BMP1_COLOR+$300,x
    sta	BMP0_COLOR,x	
	sta	BMP0_COLOR+$100,x
	sta	BMP0_COLOR+$200,x
	sta	BMP0_COLOR+$300,x
	inx
	bne	loopcol2


loop1:
    jsr GETIN
    bne get_key
        jmp loop1

get_key:
    cmp #$91     ; up
    bne get_key2
        jsr scroll_up
        jsr flip_page
        jsr update_pattern
        jmp loop1
get_key2:
    cmp #$11     ; down
    bne get_key3
        jsr scroll_down
        jsr flip_page
        jsr update_pattern
        jmp loop1
get_key3:
    cmp #$9d     ; left
    bne get_key4
        jsr scroll_left
        jsr flip_page
        jsr update_pattern
        jmp loop1
get_key4:
    cmp #$1d     ; right
    bne get_key5
        jsr scroll_right
        jsr flip_page
        jsr update_pattern
        jmp loop1
get_key5:
    jmp loop1

;    PRINT_HEX8 current_page
;    lda #$0a
;    jsr CHROUT
;    PRINT_HEX8 step
;    lda #$0a
;    jsr CHROUT

;    jsr scroll_left
;    jsr scroll_right
;    jsr scroll_up
    jsr scroll_down


update_pattern:
; change test pattern every 8 steps
    inc step
    lda step
    and #2
    beq use_pattern2
; rewind starting address by x
        SET_LITERAL16 rcolumn_src + 1, (pattern2 - 248)
        SET_LITERAL16 lcolumn_src + 1, (pattern2 - 248)
        SET_LITERAL16 uchar_src1 + 1, (pattern2 - 248)
        SET_LITERAL16 uchar_src2 + 1, (pattern2 - 248)
        SET_LITERAL16 dchar_src1 + 1, (pattern2 - 248)
        SET_LITERAL16 dchar_src2 + 1, (pattern2 - 248)
        rts

use_pattern2:
; rewind starting address by x
    SET_LITERAL16 rcolumn_src + 1, (pattern1 - 248)
    SET_LITERAL16 lcolumn_src + 1, (pattern1 - 248)
    SET_LITERAL16 uchar_src1 + 1, (pattern1 - 248)
    SET_LITERAL16 uchar_src2 + 1, (pattern1 - 248)
    SET_LITERAL16 dchar_src1 + 1, (pattern1 - 248)
    SET_LITERAL16 dchar_src2 + 1, (pattern1 - 248)
    rts

left_BMP0_to_BMP1_256:
    lda BMP0 + 8,x
    sta BMP1,x
    lda BMP0 + 320 * 1 + 8,x
    sta BMP1 + 320 * 1,x
    lda BMP0 + 320 * 2 + 8,x
    sta BMP1 + 320 * 2,x
    lda BMP0 + 320 * 3 + 8,x
    sta BMP1 + 320 * 3,x
    lda BMP0 + 320 * 4 + 8,x
    sta BMP1 + 320 * 4,x
    lda BMP0 + 320 * 5 + 8,x
    sta BMP1 + 320 * 5,x
    lda BMP0 + 320 * 6 + 8,x
    sta BMP1 + 320 * 6,x
    lda BMP0 + 320 * 7 + 8,x
    sta BMP1 + 320 * 7,x
    lda BMP0 + 320 * 8 + 8,x
    sta BMP1 + 320 * 8,x
    lda BMP0 + 320 * 9 + 8,x
    sta BMP1 + 320 * 9,x
    lda BMP0 + 320 * 10 + 8,x
    sta BMP1 + 320 * 10,x
    lda BMP0 + 320 * 11 + 8,x
    sta BMP1 + 320 * 11,x
    lda BMP0 + 320 * 12 + 8,x
    sta BMP1 + 320 * 12,x
    lda BMP0 + 320 * 13 + 8,x
    sta BMP1 + 320 * 13,x
    lda BMP0 + 320 * 14 + 8,x
    sta BMP1 + 320 * 14,x
    lda BMP0 + 320 * 15 + 8,x
    sta BMP1 + 320 * 15,x
    lda BMP0 + 320 * 16 + 8,x
    sta BMP1 + 320 * 16,x
    lda BMP0 + 320 * 17 + 8,x
    sta BMP1 + 320 * 17,x
    lda BMP0 + 320 * 18 + 8,x
    sta BMP1 + 320 * 18,x
    lda BMP0 + 320 * 19 + 8,x
    sta BMP1 + 320 * 19,x
    lda BMP0 + 320 * 20 + 8,x
    sta BMP1 + 320 * 20,x
    lda BMP0 + 320 * 21 + 8,x
    sta BMP1 + 320 * 21,x
    lda BMP0 + 320 * 22 + 8,x
    sta BMP1 + 320 * 22,x
    lda BMP0 + 320 * 23 + 8,x
    sta BMP1 + 320 * 23,x
    lda BMP0 + 320 * 24 + 8,x
    sta BMP1 + 320 * 24,x
    inx
    bne left_BMP0_to_BMP1_256b
        rts
left_BMP0_to_BMP1_256b:
    jmp left_BMP0_to_BMP1_256

left_BMP0_to_BMP1_64:
    lda BMP0 + 56 + 8,x
    sta BMP1 + 56,x
    lda BMP0 + 56 + 320 * 1 + 8,x
    sta BMP1 + 56 + 320 * 1,x
    lda BMP0 + 56 + 320 * 2 + 8,x
    sta BMP1 + 56 + 320 * 2,x
    lda BMP0 + 56 + 320 * 3 + 8,x
    sta BMP1 + 56 + 320 * 3,x
    lda BMP0 + 56 + 320 * 4 + 8,x
    sta BMP1 + 56 + 320 * 4,x
    lda BMP0 + 56 + 320 * 5 + 8,x
    sta BMP1 + 56 + 320 * 5,x
    lda BMP0 + 56 + 320 * 6 + 8,x
    sta BMP1 + 56 + 320 * 6,x
    lda BMP0 + 56 + 320 * 7 + 8,x
    sta BMP1 + 56 + 320 * 7,x
    lda BMP0 + 56 + 320 * 8 + 8,x
    sta BMP1 + 56 + 320 * 8,x
    lda BMP0 + 56 + 320 * 9 + 8,x
    sta BMP1 + 56 + 320 * 9,x
    lda BMP0 + 56 + 320 * 10 + 8,x
    sta BMP1 + 56 + 320 * 10,x
    lda BMP0 + 56 + 320 * 11 + 8,x
    sta BMP1 + 56 + 320 * 11,x
    lda BMP0 + 56 + 320 * 12 + 8,x
    sta BMP1 + 56 + 320 * 12,x
    lda BMP0 + 56 + 320 * 13 + 8,x
    sta BMP1 + 56 + 320 * 13,x
    lda BMP0 + 56 + 320 * 14 + 8,x
    sta BMP1 + 56 + 320 * 14,x
    lda BMP0 + 56 + 320 * 15 + 8,x
    sta BMP1 + 56 + 320 * 15,x
    lda BMP0 + 56 + 320 * 16 + 8,x
    sta BMP1 + 56 + 320 * 16,x
    lda BMP0 + 56 + 320 * 17 + 8,x
    sta BMP1 + 56 + 320 * 17,x
    lda BMP0 + 56 + 320 * 18 + 8,x
    sta BMP1 + 56 + 320 * 18,x
    lda BMP0 + 56 + 320 * 19 + 8,x
    sta BMP1 + 56 + 320 * 19,x
    lda BMP0 + 56 + 320 * 20 + 8,x
    sta BMP1 + 56 + 320 * 20,x
    lda BMP0 + 56 + 320 * 21 + 8,x
    sta BMP1 + 56 + 320 * 21,x
    lda BMP0 + 56 + 320 * 22 + 8,x
    sta BMP1 + 56 + 320 * 22,x
    lda BMP0 + 56 + 320 * 23 + 8,x
    sta BMP1 + 56 + 320 * 23,x
    lda BMP0 + 56 + 320 * 24 + 8,x
    sta BMP1 + 56 + 320 * 24,x
    inx
    bne left_BMP0_to_BMP1_64b
        rts
left_BMP0_to_BMP1_64b:
    jmp left_BMP0_to_BMP1_64




left_BMP1_to_BMP0_256:
    lda BMP1 + 8,x
    sta BMP0,x
    lda BMP1 + 320 * 1 + 8,x
    sta BMP0 + 320 * 1,x
    lda BMP1 + 320 * 2 + 8,x
    sta BMP0 + 320 * 2,x
    lda BMP1 + 320 * 3 + 8,x
    sta BMP0 + 320 * 3,x
    lda BMP1 + 320 * 4 + 8,x
    sta BMP0 + 320 * 4,x
    lda BMP1 + 320 * 5 + 8,x
    sta BMP0 + 320 * 5,x
    lda BMP1 + 320 * 6 + 8,x
    sta BMP0 + 320 * 6,x
    lda BMP1 + 320 * 7 + 8,x
    sta BMP0 + 320 * 7,x
    lda BMP1 + 320 * 8 + 8,x
    sta BMP0 + 320 * 8,x
    lda BMP1 + 320 * 9 + 8,x
    sta BMP0 + 320 * 9,x
    lda BMP1 + 320 * 10 + 8,x
    sta BMP0 + 320 * 10,x
    lda BMP1 + 320 * 11 + 8,x
    sta BMP0 + 320 * 11,x
    lda BMP1 + 320 * 12 + 8,x
    sta BMP0 + 320 * 12,x
    lda BMP1 + 320 * 13 + 8,x
    sta BMP0 + 320 * 13,x
    lda BMP1 + 320 * 14 + 8,x
    sta BMP0 + 320 * 14,x
    lda BMP1 + 320 * 15 + 8,x
    sta BMP0 + 320 * 15,x
    lda BMP1 + 320 * 16 + 8,x
    sta BMP0 + 320 * 16,x
    lda BMP1 + 320 * 17 + 8,x
    sta BMP0 + 320 * 17,x
    lda BMP1 + 320 * 18 + 8,x
    sta BMP0 + 320 * 18,x
    lda BMP1 + 320 * 19 + 8,x
    sta BMP0 + 320 * 19,x
    lda BMP1 + 320 * 20 + 8,x
    sta BMP0 + 320 * 20,x
    lda BMP1 + 320 * 21 + 8,x
    sta BMP0 + 320 * 21,x
    lda BMP1 + 320 * 22 + 8,x
    sta BMP0 + 320 * 22,x
    lda BMP1 + 320 * 23 + 8,x
    sta BMP0 + 320 * 23,x
    lda BMP1 + 320 * 24 + 8,x
    sta BMP0 + 320 * 24,x
    inx
    bne left_BMP1_to_BMP0_256b
        rts
left_BMP1_to_BMP0_256b:
    jmp left_BMP1_to_BMP0_256
    rts

left_BMP1_to_BMP0_64:
    lda BMP1 + 56 + 8,x
    sta BMP0 + 56,x
    lda BMP1 + 56 + 320 * 1 + 8,x
    sta BMP0 + 56 + 320 * 1,x
    lda BMP1 + 56 + 320 * 2 + 8,x
    sta BMP0 + 56 + 320 * 2,x
    lda BMP1 + 56 + 320 * 3 + 8,x
    sta BMP0 + 56 + 320 * 3,x
    lda BMP1 + 56 + 320 * 4 + 8,x
    sta BMP0 + 56 + 320 * 4,x
    lda BMP1 + 56 + 320 * 5 + 8,x
    sta BMP0 + 56 + 320 * 5,x
    lda BMP1 + 56 + 320 * 6 + 8,x
    sta BMP0 + 56 + 320 * 6,x
    lda BMP1 + 56 + 320 * 7 + 8,x
    sta BMP0 + 56 + 320 * 7,x
    lda BMP1 + 56 + 320 * 8 + 8,x
    sta BMP0 + 56 + 320 * 8,x
    lda BMP1 + 56 + 320 * 9 + 8,x
    sta BMP0 + 56 + 320 * 9,x
    lda BMP1 + 56 + 320 * 10 + 8,x
    sta BMP0 + 56 + 320 * 10,x
    lda BMP1 + 56 + 320 * 11 + 8,x
    sta BMP0 + 56 + 320 * 11,x
    lda BMP1 + 56 + 320 * 12 + 8,x
    sta BMP0 + 56 + 320 * 12,x
    lda BMP1 + 56 + 320 * 13 + 8,x
    sta BMP0 + 56 + 320 * 13,x
    lda BMP1 + 56 + 320 * 14 + 8,x
    sta BMP0 + 56 + 320 * 14,x
    lda BMP1 + 56 + 320 * 15 + 8,x
    sta BMP0 + 56 + 320 * 15,x
    lda BMP1 + 56 + 320 * 16 + 8,x
    sta BMP0 + 56 + 320 * 16,x
    lda BMP1 + 56 + 320 * 17 + 8,x
    sta BMP0 + 56 + 320 * 17,x
    lda BMP1 + 56 + 320 * 18 + 8,x
    sta BMP0 + 56 + 320 * 18,x
    lda BMP1 + 56 + 320 * 19 + 8,x
    sta BMP0 + 56 + 320 * 19,x
    lda BMP1 + 56 + 320 * 20 + 8,x
    sta BMP0 + 56 + 320 * 20,x
    lda BMP1 + 56 + 320 * 21 + 8,x
    sta BMP0 + 56 + 320 * 21,x
    lda BMP1 + 56 + 320 * 22 + 8,x
    sta BMP0 + 56 + 320 * 22,x
    lda BMP1 + 56 + 320 * 23 + 8,x
    sta BMP0 + 56 + 320 * 23,x
    lda BMP1 + 56 + 320 * 24 + 8,x
    sta BMP0 + 56 + 320 * 24,x
    inx
    bne left_BMP1_to_BMP0_64b
        rts
left_BMP1_to_BMP0_64b:
    jmp left_BMP1_to_BMP0_64















right_BMP0_to_BMP1_256:
    lda BMP0,x
    sta BMP1 + 8,x
    lda BMP0 + 320 * 1,x
    sta BMP1 + 320 * 1 + 8,x
    lda BMP0 + 320 * 2,x
    sta BMP1 + 320 * 2 + 8,x
    lda BMP0 + 320 * 3,x
    sta BMP1 + 320 * 3 + 8,x
    lda BMP0 + 320 * 4,x
    sta BMP1 + 320 * 4 + 8,x
    lda BMP0 + 320 * 5,x
    sta BMP1 + 320 * 5 + 8,x
    lda BMP0 + 320 * 6,x
    sta BMP1 + 320 * 6 + 8,x
    lda BMP0 + 320 * 7,x
    sta BMP1 + 320 * 7 + 8,x
    lda BMP0 + 320 * 8,x
    sta BMP1 + 320 * 8 + 8,x
    lda BMP0 + 320 * 9,x
    sta BMP1 + 320 * 9 + 8,x
    lda BMP0 + 320 * 10,x
    sta BMP1 + 320 * 10 + 8,x
    lda BMP0 + 320 * 11,x
    sta BMP1 + 320 * 11 + 8,x
    lda BMP0 + 320 * 12,x
    sta BMP1 + 320 * 12 + 8,x
    lda BMP0 + 320 * 13,x
    sta BMP1 + 320 * 13 + 8,x
    lda BMP0 + 320 * 14,x
    sta BMP1 + 320 * 14 + 8,x
    lda BMP0 + 320 * 15,x
    sta BMP1 + 320 * 15 + 8,x
    lda BMP0 + 320 * 16,x
    sta BMP1 + 320 * 16 + 8,x
    lda BMP0 + 320 * 17,x
    sta BMP1 + 320 * 17 + 8,x
    lda BMP0 + 320 * 18,x
    sta BMP1 + 320 * 18 + 8,x
    lda BMP0 + 320 * 19,x
    sta BMP1 + 320 * 19 + 8,x
    lda BMP0 + 320 * 20,x
    sta BMP1 + 320 * 20 + 8,x
    lda BMP0 + 320 * 21,x
    sta BMP1 + 320 * 21 + 8,x
    lda BMP0 + 320 * 22,x
    sta BMP1 + 320 * 22 + 8,x
    lda BMP0 + 320 * 23,x
    sta BMP1 + 320 * 23 + 8,x
    lda BMP0 + 320 * 24,x
    sta BMP1 + 320 * 24 + 8,x
    inx
    bne right_BMP0_to_BMP1_256b
        rts
right_BMP0_to_BMP1_256b:
    jmp right_BMP0_to_BMP1_256

right_BMP0_to_BMP1_64:
    lda BMP0 + 56,x
    sta BMP1 + 56 + 8,x
    lda BMP0 + 56 + 320 * 1,x
    sta BMP1 + 56 + 320 * 1 + 8,x
    lda BMP0 + 56 + 320 * 2,x
    sta BMP1 + 56 + 320 * 2 + 8,x
    lda BMP0 + 56 + 320 * 3,x
    sta BMP1 + 56 + 320 * 3 + 8,x
    lda BMP0 + 56 + 320 * 4,x
    sta BMP1 + 56 + 320 * 4 + 8,x
    lda BMP0 + 56 + 320 * 5,x
    sta BMP1 + 56 + 320 * 5 + 8,x
    lda BMP0 + 56 + 320 * 6,x
    sta BMP1 + 56 + 320 * 6 + 8,x
    lda BMP0 + 56 + 320 * 7,x
    sta BMP1 + 56 + 320 * 7 + 8,x
    lda BMP0 + 56 + 320 * 8,x
    sta BMP1 + 56 + 320 * 8 + 8,x
    lda BMP0 + 56 + 320 * 9,x
    sta BMP1 + 56 + 320 * 9 + 8,x
    lda BMP0 + 56 + 320 * 10,x
    sta BMP1 + 56 + 320 * 10 + 8,x
    lda BMP0 + 56 + 320 * 11,x
    sta BMP1 + 56 + 320 * 11 + 8,x
    lda BMP0 + 56 + 320 * 12,x
    sta BMP1 + 56 + 320 * 12 + 8,x
    lda BMP0 + 56 + 320 * 13,x
    sta BMP1 + 56 + 320 * 13 + 8,x
    lda BMP0 + 56 + 320 * 14,x
    sta BMP1 + 56 + 320 * 14 + 8,x
    lda BMP0 + 56 + 320 * 15,x
    sta BMP1 + 56 + 320 * 15 + 8,x
    lda BMP0 + 56 + 320 * 16,x
    sta BMP1 + 56 + 320 * 16 + 8,x
    lda BMP0 + 56 + 320 * 17,x
    sta BMP1 + 56 + 320 * 17 + 8,x
    lda BMP0 + 56 + 320 * 18,x
    sta BMP1 + 56 + 320 * 18 + 8,x
    lda BMP0 + 56 + 320 * 19,x
    sta BMP1 + 56 + 320 * 19 + 8,x
    lda BMP0 + 56 + 320 * 20,x
    sta BMP1 + 56 + 320 * 20 + 8,x
    lda BMP0 + 56 + 320 * 21,x
    sta BMP1 + 56 + 320 * 21 + 8,x
    lda BMP0 + 56 + 320 * 22,x
    sta BMP1 + 56 + 320 * 22 + 8,x
    lda BMP0 + 56 + 320 * 23,x
    sta BMP1 + 56 + 320 * 23 + 8,x
    lda BMP0 + 56 + 320 * 24,x
    sta BMP1 + 56 + 320 * 24 + 8,x
    inx
    bne right_BMP0_to_BMP1_64b
        rts
right_BMP0_to_BMP1_64b:
    jmp right_BMP0_to_BMP1_64




right_BMP1_to_BMP0_256:
    lda BMP1,x
    sta BMP0 + 8,x
    lda BMP1 + 320 * 1,x
    sta BMP0 + 320 * 1 + 8,x
    lda BMP1 + 320 * 2,x
    sta BMP0 + 320 * 2 + 8,x
    lda BMP1 + 320 * 3,x
    sta BMP0 + 320 * 3 + 8,x
    lda BMP1 + 320 * 4,x
    sta BMP0 + 320 * 4 + 8,x
    lda BMP1 + 320 * 5,x
    sta BMP0 + 320 * 5 + 8,x
    lda BMP1 + 320 * 6,x
    sta BMP0 + 320 * 6 + 8,x
    lda BMP1 + 320 * 7,x
    sta BMP0 + 320 * 7 + 8,x
    lda BMP1 + 320 * 8,x
    sta BMP0 + 320 * 8 + 8,x
    lda BMP1 + 320 * 9,x
    sta BMP0 + 320 * 9 + 8,x
    lda BMP1 + 320 * 10,x
    sta BMP0 + 320 * 10 + 8,x
    lda BMP1 + 320 * 11,x
    sta BMP0 + 320 * 11 + 8,x
    lda BMP1 + 320 * 12,x
    sta BMP0 + 320 * 12 + 8,x
    lda BMP1 + 320 * 13,x
    sta BMP0 + 320 * 13 + 8,x
    lda BMP1 + 320 * 14,x
    sta BMP0 + 320 * 14 + 8,x
    lda BMP1 + 320 * 15,x
    sta BMP0 + 320 * 15 + 8,x
    lda BMP1 + 320 * 16,x
    sta BMP0 + 320 * 16 + 8,x
    lda BMP1 + 320 * 17,x
    sta BMP0 + 320 * 17 + 8,x
    lda BMP1 + 320 * 18,x
    sta BMP0 + 320 * 18 + 8,x
    lda BMP1 + 320 * 19,x
    sta BMP0 + 320 * 19 + 8,x
    lda BMP1 + 320 * 20,x
    sta BMP0 + 320 * 20 + 8,x
    lda BMP1 + 320 * 21,x
    sta BMP0 + 320 * 21 + 8,x
    lda BMP1 + 320 * 22,x
    sta BMP0 + 320 * 22 + 8,x
    lda BMP1 + 320 * 23,x
    sta BMP0 + 320 * 23 + 8,x
    lda BMP1 + 320 * 24,x
    sta BMP0 + 320 * 24 + 8,x
    inx
    bne right_BMP1_to_BMP0_256b
        rts
right_BMP1_to_BMP0_256b:
    jmp right_BMP1_to_BMP0_256
    rts

right_BMP1_to_BMP0_64:
    lda BMP1 + 56,x
    sta BMP0 + 56 + 8,x
    lda BMP1 + 56 + 320 * 1,x
    sta BMP0 + 56 + 320 * 1 + 8,x
    lda BMP1 + 56 + 320 * 2,x
    sta BMP0 + 56 + 320 * 2 + 8,x
    lda BMP1 + 56 + 320 * 3,x
    sta BMP0 + 56 + 320 * 3 + 8,x
    lda BMP1 + 56 + 320 * 4,x
    sta BMP0 + 56 + 320 * 4 + 8,x
    lda BMP1 + 56 + 320 * 5,x
    sta BMP0 + 56 + 320 * 5 + 8,x
    lda BMP1 + 56 + 320 * 6,x
    sta BMP0 + 56 + 320 * 6 + 8,x
    lda BMP1 + 56 + 320 * 7,x
    sta BMP0 + 56 + 320 * 7 + 8,x
    lda BMP1 + 56 + 320 * 8,x
    sta BMP0 + 56 + 320 * 8 + 8,x
    lda BMP1 + 56 + 320 * 9,x
    sta BMP0 + 56 + 320 * 9 + 8,x
    lda BMP1 + 56 + 320 * 10,x
    sta BMP0 + 56 + 320 * 10 + 8,x
    lda BMP1 + 56 + 320 * 11,x
    sta BMP0 + 56 + 320 * 11 + 8,x
    lda BMP1 + 56 + 320 * 12,x
    sta BMP0 + 56 + 320 * 12 + 8,x
    lda BMP1 + 56 + 320 * 13,x
    sta BMP0 + 56 + 320 * 13 + 8,x
    lda BMP1 + 56 + 320 * 14,x
    sta BMP0 + 56 + 320 * 14 + 8,x
    lda BMP1 + 56 + 320 * 15,x
    sta BMP0 + 56 + 320 * 15 + 8,x
    lda BMP1 + 56 + 320 * 16,x
    sta BMP0 + 56 + 320 * 16 + 8,x
    lda BMP1 + 56 + 320 * 17,x
    sta BMP0 + 56 + 320 * 17 + 8,x
    lda BMP1 + 56 + 320 * 18,x
    sta BMP0 + 56 + 320 * 18 + 8,x
    lda BMP1 + 56 + 320 * 19,x
    sta BMP0 + 56 + 320 * 19 + 8,x
    lda BMP1 + 56 + 320 * 20,x
    sta BMP0 + 56 + 320 * 20 + 8,x
    lda BMP1 + 56 + 320 * 21,x
    sta BMP0 + 56 + 320 * 21 + 8,x
    lda BMP1 + 56 + 320 * 22,x
    sta BMP0 + 56 + 320 * 22 + 8,x
    lda BMP1 + 56 + 320 * 23,x
    sta BMP0 + 56 + 320 * 23 + 8,x
    lda BMP1 + 56 + 320 * 24,x
    sta BMP0 + 56 + 320 * 24 + 8,x
    inx
    bne right_BMP1_to_BMP0_64b
        rts
right_BMP1_to_BMP0_64b:
    jmp right_BMP1_to_BMP0_64




; move 7680 bytes up 320
up_BMP0_to_BMP1:
    lda BMP0 + 320,x
    sta BMP1,x
    lda BMP0 + 256 * 1 + 320,x
    sta BMP1 + 256 * 1,x
    lda BMP0 + 256 * 2 + 320,x
    sta BMP1 + 256 * 2,x
    lda BMP0 + 256 * 3 + 320,x
    sta BMP1 + 256 * 3,x
    lda BMP0 + 256 * 4 + 320,x
    sta BMP1 + 256 * 4,x
    lda BMP0 + 256 * 5 + 320,x
    sta BMP1 + 256 * 5,x
    lda BMP0 + 256 * 6 + 320,x
    sta BMP1 + 256 * 6,x
    lda BMP0 + 256 * 7 + 320,x
    sta BMP1 + 256 * 7,x
    lda BMP0 + 256 * 8 + 320,x
    sta BMP1 + 256 * 8,x
    lda BMP0 + 256 * 9 + 320,x
    sta BMP1 + 256 * 9,x
    lda BMP0 + 256 * 10 + 320,x
    sta BMP1 + 256 * 10,x
    lda BMP0 + 256 * 11 + 320,x
    sta BMP1 + 256 * 11,x
    lda BMP0 + 256 * 12 + 320,x
    sta BMP1 + 256 * 12,x
    lda BMP0 + 256 * 13 + 320,x
    sta BMP1 + 256 * 13,x
    lda BMP0 + 256 * 14 + 320,x
    sta BMP1 + 256 * 14,x
    lda BMP0 + 256 * 15 + 320,x
    sta BMP1 + 256 * 15,x
    lda BMP0 + 256 * 16 + 320,x
    sta BMP1 + 256 * 16,x
    lda BMP0 + 256 * 17 + 320,x
    sta BMP1 + 256 * 17,x
    lda BMP0 + 256 * 18 + 320,x
    sta BMP1 + 256 * 18,x
    lda BMP0 + 256 * 19 + 320,x
    sta BMP1 + 256 * 19,x
    lda BMP0 + 256 * 20 + 320,x
    sta BMP1 + 256 * 20,x
    lda BMP0 + 256 * 21 + 320,x
    sta BMP1 + 256 * 21,x
    lda BMP0 + 256 * 22 + 320,x
    sta BMP1 + 256 * 22,x
    lda BMP0 + 256 * 23 + 320,x
    sta BMP1 + 256 * 23,x
    lda BMP0 + 256 * 24 + 320,x
    sta BMP1 + 256 * 24,x
    lda BMP0 + 256 * 25 + 320,x
    sta BMP1 + 256 * 25,x
    lda BMP0 + 256 * 26 + 320,x
    sta BMP1 + 256 * 26,x
    lda BMP0 + 256 * 27 + 320,x
    sta BMP1 + 256 * 27,x
    lda BMP0 + 256 * 28 + 320,x
    sta BMP1 + 256 * 28,x
    lda BMP0 + 256 * 29 + 320,x
    sta BMP1 + 256 * 29,x
    inx
    bne up_BMP0_to_BMP1b
        rts
up_BMP0_to_BMP1b:
    jmp up_BMP0_to_BMP1


up_BMP1_to_BMP0:
    lda BMP1 + 320,x
    sta BMP0,x
    lda BMP1 + 256 * 1 + 320,x
    sta BMP0 + 256 * 1,x
    lda BMP1 + 256 * 2 + 320,x
    sta BMP0 + 256 * 2,x
    lda BMP1 + 256 * 3 + 320,x
    sta BMP0 + 256 * 3,x
    lda BMP1 + 256 * 4 + 320,x
    sta BMP0 + 256 * 4,x
    lda BMP1 + 256 * 5 + 320,x
    sta BMP0 + 256 * 5,x
    lda BMP1 + 256 * 6 + 320,x
    sta BMP0 + 256 * 6,x
    lda BMP1 + 256 * 7 + 320,x
    sta BMP0 + 256 * 7,x
    lda BMP1 + 256 * 8 + 320,x
    sta BMP0 + 256 * 8,x
    lda BMP1 + 256 * 9 + 320,x
    sta BMP0 + 256 * 9,x
    lda BMP1 + 256 * 10 + 320,x
    sta BMP0 + 256 * 10,x
    lda BMP1 + 256 * 11 + 320,x
    sta BMP0 + 256 * 11,x
    lda BMP1 + 256 * 12 + 320,x
    sta BMP0 + 256 * 12,x
    lda BMP1 + 256 * 13 + 320,x
    sta BMP0 + 256 * 13,x
    lda BMP1 + 256 * 14 + 320,x
    sta BMP0 + 256 * 14,x
    lda BMP1 + 256 * 15 + 320,x
    sta BMP0 + 256 * 15,x
    lda BMP1 + 256 * 16 + 320,x
    sta BMP0 + 256 * 16,x
    lda BMP1 + 256 * 17 + 320,x
    sta BMP0 + 256 * 17,x
    lda BMP1 + 256 * 18 + 320,x
    sta BMP0 + 256 * 18,x
    lda BMP1 + 256 * 19 + 320,x
    sta BMP0 + 256 * 19,x
    lda BMP1 + 256 * 20 + 320,x
    sta BMP0 + 256 * 20,x
    lda BMP1 + 256 * 21 + 320,x
    sta BMP0 + 256 * 21,x
    lda BMP1 + 256 * 22 + 320,x
    sta BMP0 + 256 * 22,x
    lda BMP1 + 256 * 23 + 320,x
    sta BMP0 + 256 * 23,x
    lda BMP1 + 256 * 24 + 320,x
    sta BMP0 + 256 * 24,x
    lda BMP1 + 256 * 25 + 320,x
    sta BMP0 + 256 * 25,x
    lda BMP1 + 256 * 26 + 320,x
    sta BMP0 + 256 * 26,x
    lda BMP1 + 256 * 27 + 320,x
    sta BMP0 + 256 * 27,x
    lda BMP1 + 256 * 28 + 320,x
    sta BMP0 + 256 * 28,x
    lda BMP1 + 256 * 29 + 320,x
    sta BMP0 + 256 * 29,x
    inx
    bne up_BMP1_to_BMP0b
        rts
up_BMP1_to_BMP0b:
    jmp up_BMP1_to_BMP0



; move 7680 bytes down 320
down_BMP0_to_BMP1:
    lda BMP0,x
    sta BMP1 + 320,x
    lda BMP0 + 256 * 1,x
    sta BMP1 + 256 * 1 + 320,x
    lda BMP0 + 256 * 2,x
    sta BMP1 + 256 * 2 + 320,x
    lda BMP0 + 256 * 3,x
    sta BMP1 + 256 * 3 + 320,x
    lda BMP0 + 256 * 4,x
    sta BMP1 + 256 * 4 + 320,x
    lda BMP0 + 256 * 5,x
    sta BMP1 + 256 * 5 + 320,x
    lda BMP0 + 256 * 6,x
    sta BMP1 + 256 * 6 + 320,x
    lda BMP0 + 256 * 7,x
    sta BMP1 + 256 * 7 + 320,x
    lda BMP0 + 256 * 8,x
    sta BMP1 + 256 * 8 + 320,x
    lda BMP0 + 256 * 9,x
    sta BMP1 + 256 * 9 + 320,x
    lda BMP0 + 256 * 10,x
    sta BMP1 + 256 * 10 + 320,x
    lda BMP0 + 256 * 11,x
    sta BMP1 + 256 * 11 + 320,x
    lda BMP0 + 256 * 12,x
    sta BMP1 + 256 * 12 + 320,x
    lda BMP0 + 256 * 13,x
    sta BMP1 + 256 * 13 + 320,x
    lda BMP0 + 256 * 14,x
    sta BMP1 + 256 * 14 + 320,x
    lda BMP0 + 256 * 15,x
    sta BMP1 + 256 * 15 + 320,x
    lda BMP0 + 256 * 16,x
    sta BMP1 + 256 * 16 + 320,x
    lda BMP0 + 256 * 17,x
    sta BMP1 + 256 * 17 + 320,x
    lda BMP0 + 256 * 18,x
    sta BMP1 + 256 * 18 + 320,x
    lda BMP0 + 256 * 19,x
    sta BMP1 + 256 * 19 + 320,x
    lda BMP0 + 256 * 20,x
    sta BMP1 + 256 * 20 + 320,x
    lda BMP0 + 256 * 21,x
    sta BMP1 + 256 * 21 + 320,x
    lda BMP0 + 256 * 22,x
    sta BMP1 + 256 * 22 + 320,x
    lda BMP0 + 256 * 23,x
    sta BMP1 + 256 * 23 + 320,x
    lda BMP0 + 256 * 24,x
    sta BMP1 + 256 * 24 + 320,x
    lda BMP0 + 256 * 25,x
    sta BMP1 + 256 * 25 + 320,x
    lda BMP0 + 256 * 26,x
    sta BMP1 + 256 * 26 + 320,x
    lda BMP0 + 256 * 27,x
    sta BMP1 + 256 * 27 + 320,x
    lda BMP0 + 256 * 28,x
    sta BMP1 + 256 * 28 + 320,x
    lda BMP0 + 256 * 29,x
    sta BMP1 + 256 * 29 + 320,x
    inx
    bne down_BMP0_to_BMP1b
        rts
down_BMP0_to_BMP1b:
    jmp down_BMP0_to_BMP1



; move 7680 bytes down 320
down_BMP1_to_BMP0:
    lda BMP1,x
    sta BMP0 + 320,x
    lda BMP1 + 256 * 1,x
    sta BMP0 + 256 * 1 + 320,x
    lda BMP1 + 256 * 2,x
    sta BMP0 + 256 * 2 + 320,x
    lda BMP1 + 256 * 3,x
    sta BMP0 + 256 * 3 + 320,x
    lda BMP1 + 256 * 4,x
    sta BMP0 + 256 * 4 + 320,x
    lda BMP1 + 256 * 5,x
    sta BMP0 + 256 * 5 + 320,x
    lda BMP1 + 256 * 6,x
    sta BMP0 + 256 * 6 + 320,x
    lda BMP1 + 256 * 7,x
    sta BMP0 + 256 * 7 + 320,x
    lda BMP1 + 256 * 8,x
    sta BMP0 + 256 * 8 + 320,x
    lda BMP1 + 256 * 9,x
    sta BMP0 + 256 * 9 + 320,x
    lda BMP1 + 256 * 10,x
    sta BMP0 + 256 * 10 + 320,x
    lda BMP1 + 256 * 11,x
    sta BMP0 + 256 * 11 + 320,x
    lda BMP1 + 256 * 12,x
    sta BMP0 + 256 * 12 + 320,x
    lda BMP1 + 256 * 13,x
    sta BMP0 + 256 * 13 + 320,x
    lda BMP1 + 256 * 14,x
    sta BMP0 + 256 * 14 + 320,x
    lda BMP1 + 256 * 15,x
    sta BMP0 + 256 * 15 + 320,x
    lda BMP1 + 256 * 16,x
    sta BMP0 + 256 * 16 + 320,x
    lda BMP1 + 256 * 17,x
    sta BMP0 + 256 * 17 + 320,x
    lda BMP1 + 256 * 18,x
    sta BMP0 + 256 * 18 + 320,x
    lda BMP1 + 256 * 19,x
    sta BMP0 + 256 * 19 + 320,x
    lda BMP1 + 256 * 20,x
    sta BMP0 + 256 * 20 + 320,x
    lda BMP1 + 256 * 21,x
    sta BMP0 + 256 * 21 + 320,x
    lda BMP1 + 256 * 22,x
    sta BMP0 + 256 * 22 + 320,x
    lda BMP1 + 256 * 23,x
    sta BMP0 + 256 * 23 + 320,x
    lda BMP1 + 256 * 24,x
    sta BMP0 + 256 * 24 + 320,x
    lda BMP1 + 256 * 25,x
    sta BMP0 + 256 * 25 + 320,x
    lda BMP1 + 256 * 26,x
    sta BMP0 + 256 * 26 + 320,x
    lda BMP1 + 256 * 27,x
    sta BMP0 + 256 * 27 + 320,x
    lda BMP1 + 256 * 28,x
    sta BMP0 + 256 * 28 + 320,x
    lda BMP1 + 256 * 29,x
    sta BMP0 + 256 * 29 + 320,x
    inx
    bne down_BMP1_to_BMP0b
        rts
down_BMP1_to_BMP0b:
    jmp down_BMP1_to_BMP0




scroll_up:
    ldx #0


; choose page flipping direction
    lda bmp_src + 1
    cmp #>BMP1
    beq scroll_up2
        jsr up_BMP0_to_BMP1
        jmp scroll_up3

scroll_up2:
        jsr up_BMP1_to_BMP0


scroll_up3:
; draw new row
; copy dst address
            ADD_LITERAL16 uchar_dst1 + 1, bmp_dst, (320 * 24)
; use Y as src index.  Offset it to avoid a compare
            ldy #248
uchar_src1:
            lda pattern1 - 248,y
uchar_dst1:
            sta BMP1,x
            iny
            bne uchar_loop2
                ldy #248
uchar_loop2:
            inx
            bne uchar_src1

; advance 256 bytes - 192
            ADD_LITERAL16 uchar_dst2 + 1, bmp_dst, (320 * 24 + 256 - 192)
; offset X to avoid a compare
            ldx #192
; use Y as src index.  Offset it to avoid a compare
            ldy #248
uchar_src2:
            lda pattern1 - 248,y
uchar_dst2:
            sta BMP1,x
            iny
            bne uchar_loop3
                ldy #248
uchar_loop3:
                inx
                bne uchar_src2
                    rts  ; donechak




scroll_down:
    ldx #0

; choose page flipping direction
    lda bmp_src + 1
    cmp #>BMP1
    beq scroll_down2
        jsr down_BMP0_to_BMP1
        jmp scroll_down3

scroll_down2:
        jsr down_BMP1_to_BMP0


scroll_down3:
; draw new row
; copy dst address
            COPY_REG16 dchar_dst1 + 1, bmp_dst
; use Y as src index.  Offset it to avoid a compare
            ldy #248
dchar_src1:
            lda pattern1 - 248,y
dchar_dst1:
            sta BMP1,x
            iny
            bne dchar_loop2
                ldy #248
dchar_loop2:
            inx
            bne dchar_src1

; advance 256 bytes - 192
            ADD_LITERAL16 dchar_dst2 + 1, bmp_dst, (256 - 192)
; offset X to avoid a compare
            ldx #192
; use Y as src index.  Offset it to avoid a compare
            ldy #248
dchar_src2:
            lda pattern1 - 248,y
dchar_dst2:
            sta BMP1,x
            iny
            bne dchar_loop3
                ldy #248
dchar_loop3:
                inx
                bne dchar_src2
                    rts  ; donechak




scroll_left:
; shift bitmap left 8 pixels

    ldx #0
; choose page flipping direction
    lda bmp_src + 1
    cmp #>BMP1
    beq scroll_left2
        jsr left_BMP0_to_BMP1_256
; offset X to avoid a compare
        ldx #200
        jsr left_BMP0_to_BMP1_64
        jmp scroll_left3

scroll_left2:
        jsr left_BMP1_to_BMP0_256
; offset X to avoid a compare
        ldx #200
        jsr left_BMP1_to_BMP0_64
        jmp scroll_left3


scroll_left3:
; right column
        ldy #256 - 25 ; -25
; copy dst address + 320 - 8 - 248
        ADD_LITERAL16 rcolumn_dst + 1, bmp_dst, 64
rcolumn_loop:
; offset X to avoid a compare
        ldx #248
; copy the new character into the last column
rcolumn_src:
; rewind starting address by x
        lda pattern1 - 248,x
rcolumn_dst:
        sta BMP1,x
        inx
        bne rcolumn_src

; add 320 to advance the row
            ADD_LITERAL16 rcolumn_dst + 1, rcolumn_dst + 1, 320
            iny ; wrap row around to 0 to detect completion
            bne rcolumn_loop
                rts ; donechak



scroll_right:
; shift bitmap right 8 pixels
    ldx #0

; choose page flipping direction
    lda bmp_src + 1
    cmp #>BMP1
    beq scroll_right2
        jsr right_BMP0_to_BMP1_256
; offset X to avoid a compare
        ldx #200
        jsr right_BMP0_to_BMP1_64
        jmp scroll_right3

scroll_right2:
        jsr right_BMP1_to_BMP0_256
; offset X to avoid a compare
        ldx #200
        jsr right_BMP1_to_BMP0_64
        jmp scroll_right3


scroll_right3:
; left column
        ldy #256 - 25 ; -25
; copy dst address - 248
        SUB_LITERAL16 lcolumn_dst + 1, bmp_dst, 248

lcolumn_loop:
; offset X to avoid a compare
            ldx #248
; copy the new character into the last column
lcolumn_src:
            lda pattern1 - 248,x
lcolumn_dst:
            sta BMP1,x
            inx
            bne lcolumn_src

; add 320 to address to advance the row
                ADD_LITERAL16 lcolumn_dst + 1, lcolumn_dst + 1, 320
                iny ; wrap row around to 0 to detect completion
                bne lcolumn_loop
                    rts  ; donechak



;print_column_mod:
;    PRINT_HEX16 column_mod1
;    PRINT_HEX16 column_mod2
;    lda #$0a ; line feed
;    jsr CHROUT
;    rts

done:
; direct CHROUT to the screen to print ready on the screen
    ldx SCREEN            ; logical number
    jsr CHKOUT
    rts               ; return from subroutine



.endproc
