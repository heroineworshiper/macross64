
; starting addresses of bitmaps
; VIC II only sees character ROM at $1000 & $9000
BMP0 = $6000
BMP0_SCREEN = $5c00
BMP1 = $a000
BMP1_SCREEN = $8000
COLOR_DST = $d800
COLOR_SRC = $c000

pattern1:
    .byte $55, $aa, $55, $aa, $55, $aa, $55, $aa

pattern2:
    .byte $00, $00, $00, $00, $00, $00, $00, $00

.include        "bitmapunroll.s"

; set up the page based on the current value of A
flip_page:
; wait for raster line >= 256
    lda $d011
    bpl flip_page
    
;    PRINT_HEX8 current_page
;    lda #$0a
;    jsr CIOUT

    lda #1
    eor current_page
    sta current_page
    cmp #0
    bne flip_page2

; display BMP0, draw BMP1
; https://sta.c64.org/cbm64mem.html
	    lda $d018
	    and	#%00001111  ; set color memory relative to VIC bank
	    ora	#%01110000  ; vic bank + $1c00
	    sta	$d018

        lda	$dd00		; set the VIC bank
	    and	#%11111100
	    ora	#%00000010  ; $4000
	    sta	$dd00
        SET_LITERAL16 bmp_src, BMP0
        SET_LITERAL16 color_ptr, BMP0_SCREEN
        SET_LITERAL16 bmp_dst, BMP1
        SET_LITERAL16 color_ptr2, BMP1_SCREEN
        rts

flip_page2:
; display BMP1, draw BMP0
	lda $d018           ; set color memory relative to VIC bank
	and	#%00001111
	ora	#%00000000      ; VIC II only sees character ROM at $9000
	sta	$d018

	lda	$dd00		    ; set the VIC bank
	and	#%11111100
	ora	#%00000001      ; $8000
	sta	$dd00
    
    SET_LITERAL16 bmp_src, BMP1
    SET_LITERAL16 color_ptr, BMP1_SCREEN
    SET_LITERAL16 bmp_dst, BMP0
    SET_LITERAL16 color_ptr2, BMP0_SCREEN
    rts



init_graphics:
; bitmap mode https://sta.c64.org/cbm64mem.html
    lda	#$bb
	sta	$d011		

; multicolor mode https://sta.c64.org/cbm64mem.html
    lda #$d8
    sta $d016

; background color
    lda #0
    sta $d021

	lda	$DD02
	ora	#3
	sta	$DD02		;CIA-2 I/O default value 		

    lda #0
    sta current_page
    jsr flip_page ; set up the bitmap
    jsr update_pattern ; set up the pattern

	lda	$d018       ; set bitmap memory relative to VIC bank
	and	#%11110000
	ora	#%00001000  ; vic bank + $2000
	sta	$d018	


; set color memory to white pen on black paper (also clears sprite pointers) on screen 1
	ldx	#$00
loopcol2:
	lda	#$10
    sta	BMP1_SCREEN,x	
	sta	BMP1_SCREEN+$100,x
	sta	BMP1_SCREEN+$200,x
	sta	BMP1_SCREEN+$300,x
    sta	BMP0_SCREEN,x	
	sta	BMP0_SCREEN+$100,x
	sta	BMP0_SCREEN+$200,x
	sta	BMP0_SCREEN+$300,x
    lda #$02
    sta	COLOR_DST,x	
	sta	COLOR_DST+$100,x
	sta	COLOR_DST+$200,x
	sta	COLOR_DST+$300,x
	inx
	bne	loopcol2




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



