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
bmp_ptr:      .res    2       ; the current bitmap
bmp_ptr2:     .res    2       ; the oppposite bitmap for scroll copy
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
        SET_LITERAL16 bmp_ptr, BMP1
        SET_LITERAL16 color_ptr, BMP1_COLOR
        SET_LITERAL16 bmp_ptr2, BMP0
        SET_LITERAL16 color_ptr2, BMP0_COLOR
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
    
    SET_LITERAL16 bmp_ptr, BMP0
    SET_LITERAL16 color_ptr, BMP0_COLOR
    SET_LITERAL16 bmp_ptr2, BMP1
    SET_LITERAL16 color_ptr2, BMP1_COLOR
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

    jsr flip_page

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
        SET_LITERAL16 lchar_mod1 + 1, (pattern2 - 248)
        SET_LITERAL16 rchar_mod1 + 1, (pattern2 - 248)
        SET_LITERAL16 uchar_src1 + 1, (pattern2 - 248)
        SET_LITERAL16 uchar_mod3 + 1, (pattern2 - 248)
        SET_LITERAL16 dchar_mod1 + 1, (pattern2 - 248)
        SET_LITERAL16 dchar_mod3 + 1, (pattern2 - 248)
        rts

use_pattern2:
; rewind starting address by x
    SET_LITERAL16 lchar_mod1 + 1, (pattern1 - 248)
    SET_LITERAL16 rchar_mod1 + 1, (pattern1 - 248)
    SET_LITERAL16 uchar_src1 + 1, (pattern1 - 248)
    SET_LITERAL16 uchar_mod3 + 1, (pattern1 - 248)
    SET_LITERAL16 dchar_mod1 + 1, (pattern1 - 248)
    SET_LITERAL16 dchar_mod3 + 1, (pattern1 - 248)
    rts


scroll_up:
    ldx #0
    ldy #256 - 24
; set self modifying code for bitmap addresses
    ADD_LITERAL16 urow_src1 + 1, bmp_ptr2, 320 ; src
    COPY_REG16 urow_dst1 + 1, bmp_ptr          ; dst
    
urow_loop1:
urow_src1:
    lda BMP1 + 320,x
urow_dst1:
    sta BMP1,x
    inx
    bne urow_loop1
        ADD_LITERAL16 urow_src2 + 1, urow_src1 + 1, 64 ; copy src address + 64
        ADD_LITERAL16 urow_dst2 + 1, urow_dst1 + 1, 64 ; copy dst address + 64
; offset X to avoid a compare
        ldx #192
urow_loop2:
urow_src2:
        lda BMP1 + 320,x
urow_dst2:
        sta BMP1,x
        inx
        bne urow_loop2
; add 320 to address to advance the row
            ADD_LITERAL16 urow_src1 + 1, urow_src1 + 1, 320 ; src
            ADD_LITERAL16 urow_dst1 + 1, urow_dst1 + 1, 320 ; dst
            ldx #0 ; reset the column pointer
            iny ; wrap row around to 0 to symbolize completion
            bne urow_loop1

; draw new row
; copy dst address
            COPY_REG16 uchar_dst1 + 1, urow_dst1 + 1
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

; advance to last 64 bytes - 192
            ADD_LITERAL16 uchar_mod4 + 1, urow_dst1 + 1, 64
; offset X to avoid a compare
            ldx #192
; use Y as src index.  Offset it to avoid a compare
            ldy #248
uchar_mod3:
            lda pattern1 - 248,y
uchar_mod4:
            sta BMP1,x
            iny
            bne uchar_loop3
                ldy #248
uchar_loop3:
                inx
                bne uchar_mod3
                    rts  ; donechak




scroll_down:
    ldx #0
    ldy #256 - 24
; set self modifying code for bitmap addresses
    ADD_LITERAL16 drow_src1 + 1, bmp_ptr2, (320 * 23) ; src
    ADD_LITERAL16 drow_dst1 + 1, bmp_ptr, (320 * 24)  ; dst
    
drow_loop1:
drow_src1:
    lda BMP1,x
drow_dst1:
    sta BMP1 + 320,x
    inx
    bne drow_loop1
        ADD_LITERAL16 drow_src2 + 1, drow_src1 + 1, 64 ; copy src address + 64
        ADD_LITERAL16 drow_dst2 + 1, drow_dst1 + 1, 64 ; copy dst address + 64
; offset X to avoid a compare
        ldx #192
drow_loop2:
drow_src2:
        lda BMP1,x
drow_dst2:
        sta BMP1 + 320,x
        inx
        bne drow_loop2
; subtract 320 from address to advance the row
            SUB_LITERAL16 drow_src1 + 1, drow_src1 + 1, 320 ; src
            SUB_LITERAL16 drow_dst1 + 1, drow_dst1 + 1, 320 ; dst
            ldx #0 ; reset the column pointer
            iny ; wrap row around to 0 to symbolize completion
            bne drow_loop1


; draw new row
; copy dst address
            COPY_REG16 dchar_mod2 + 1, drow_dst1 + 1
; use Y as src index.  Offset it to avoid a compare
            ldy #248
dchar_mod1:
            lda pattern1 - 248,y
dchar_mod2:
            sta BMP1,x
            iny
            bne dchar_loop2
                ldy #248
dchar_loop2:
            inx
            bne dchar_mod1

; advance to last 64 bytes - 192
            ADD_LITERAL16 dchar_mod4 + 1, drow_dst1 + 1, 64
; offset X to avoid a compare
            ldx #192
; use Y as src index.  Offset it to avoid a compare
            ldy #248
dchar_mod3:
            lda pattern1 - 248,y
dchar_mod4:
            sta BMP1,x
            iny
            bne dchar_loop3
                ldy #248
dchar_loop3:
                inx
                bne dchar_mod3
                    rts  ; donechak





scroll_left:
; shift bitmap left 8 pixels
    ldx #0
    ldy #256 - 25 ; -25
; set self modifying code for bitmap addresses
    ADD_LITERAL16 lcolumn_src1 + 1, bmp_ptr2, 8 ; src
    COPY_REG16 lcolumn_dst1 + 1, bmp_ptr        ; dst
lcolumn_loop1:
lcolumn_src1:
    lda BMP1 + 8,x
lcolumn_dst1:
    sta BMP1,x
    inx
    bne lcolumn_loop1
        ADD_LITERAL16 lcolumn_src2 + 1, lcolumn_src1 + 1, 56 ; copy src address + 56
        ADD_LITERAL16 lcolumn_dst2 + 1, lcolumn_dst1 + 1, 56 ; copy dst address + 56
; offset X to avoid a compare
        ldx #200
lcolumn_loop2:
lcolumn_src2:
        lda BMP1 + 8,x
lcolumn_dst2:
        sta BMP1,x
        inx
        bne lcolumn_loop2

; copy dst address + 320 - 8 - 248
            ADD_LITERAL16 lcolumn_mod5 + 1, lcolumn_dst1 + 1, 64
; offset X to avoid a compare
            ldx #248
; copy the new character into the last column
lchar_loop:
lchar_mod1:
; rewind starting address by x
            lda pattern1 - 248,x
lcolumn_mod5:
            sta BMP1,x
            inx
            bne lchar_loop

; add 320 to address to advance the row
                ADD_LITERAL16 lcolumn_src1 + 1, lcolumn_src1 + 1, 320
                ADD_LITERAL16 lcolumn_dst1 + 1, lcolumn_dst1 + 1, 320
                ldx #0 ; reset the column pointer
                iny ; wrap row around to 0 to symbolize completion
                bne lcolumn_loop1
                    rts  ; donechak


scroll_right:
; shift bitmap right 8 pixels
    ldx #0
    ldy #256 - 25 ; -25
; set self modifying code for bitmap addresses
    COPY_REG16 rcolumn_mod1 + 1, bmp_ptr2         ; src
    ADD_LITERAL16 rcolumn_mod2 + 1, bmp_ptr, 8    ; dst
rcolumn_loop1:
rcolumn_mod1:
    lda BMP1,x
rcolumn_mod2:
    sta BMP1 + 8,x
    inx
    bne rcolumn_loop1
        ADD_LITERAL16 rcolumn_mod3 + 1, rcolumn_mod1 + 1, 56 ; copy src address + 56
        ADD_LITERAL16 rcolumn_mod4 + 1, rcolumn_mod2 + 1, 56 ; copy dst address + 56
; offset X to avoid a compare
        ldx #200
rcolumn_loop2:
rcolumn_mod3:
        lda BMP0,x
rcolumn_mod4:
        sta BMP1 + 8,x
        inx
        bne rcolumn_loop2

; copy destination - 248 - 8
            SUB_LITERAL16 rcolumn_mod5 + 1, rcolumn_mod2 + 1, 256
; copy the new character into the 1st column
; offset X to avoid a compare
            ldx #248
rchar_loop:
rchar_mod1:
            lda pattern1 - 248,x
rcolumn_mod5:
            sta BMP1,x
            inx
            bne rchar_loop

; add 320 to address to advance the row
                ADD_LITERAL16 rcolumn_mod1 + 1, rcolumn_mod1 + 1, 320
                ADD_LITERAL16 rcolumn_mod2 + 1, rcolumn_mod2 + 1, 320
                ldx #0 ; reset the column pointer
                iny ; wrap row around to 0 to symbolize completion
                bne rcolumn_loop1
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
