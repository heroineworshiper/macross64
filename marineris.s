.include "cbm_kernal.inc"
.include "common.inc"
.include "loader.inc"


; secondary & logical addresses for the world drive
CONTROL = 15
WORLD_DRIVE = 8
; starting addresses of bitmaps
; VIC II only sees character ROM at $1000 & $9000
BMP0 = $6000
BMP0_SCREEN = $5c00
BMP1 = $a000
BMP1_SCREEN = $8000
COLOR_DST = $d800
COLOR_SRC = $c000
; offscreen tiles. 9500 bytes each
TILE1 := $35e0
TILE2 := $dae0

; debug prints
ENABLE_DEBUG := 1

; vars
; number of the tile being loaded or 0xff if nothing to load
loading_tile := $02
current_track := $03
current_sector := $04
temp1 := $05
temp2 := $06
current_page := $09 ; Current bitmap id. 1 = draw on BMP1 0 = draw on BMP0
scroll_buffer := $0c ; 2 bytes. the tile buffer currently being scrolled in
load_buffer := $0e ; 2 bytes. the tile buffer currently being loaded
tiles_loaded := $10 ; number of tiles loaded
scroll_counter := $11 ; number of columns scrolled
draw_buffer := $12 ; 2 bytes. the tile buffer being scrolled in
pixel_counter := $14 ; debug by replacing scroll register
raster_counter2 := $15 ; 3 or 2 raster interrupts before the next pixel scroll
do_scroll := $16 ; do the next scroll copy in the mane loop
SCROLL_BITMAP := $01 ; regions to copy in do_scroll
SCROLL_COLOR := $02
raster_counter := $17 ; number of raster interrupts
SCROLL_SPEED := 2 ; alternates between 2 & 3
;debug_counter := $18

; self modifying code
.macro SET_IO_STATE func
    SET_LITERAL16 io_state + 1, func
.endmacro

.macro SET_IO_FINISHED_STATE func
    SET_LITERAL16 io_finished_state + 1, func
.endmacro

.macro TOGGLE_LOAD_BUFFER
    ldx #<TILE2
    ldy #>TILE2
    lda load_buffer + 1
    cmp #>TILE2
    bne :+ ; load_buffer != TILE2
        ldx #<TILE1
        ldy #>TILE1
: ; destination of bne :+
    stx load_buffer
    sty load_buffer + 1
.endmacro


.segment	"START"

    .byte $01, $08, $0b, $08, $13, $02, $9e, $32, $30, $36, $31, $00, $00, $00

.segment	"CODE"

mane:
    INIT_DEBUG
; switch out BASIC ROM
    lda #KERNAL_IN
    sta PORT_REG

; print something
    SELECT_PRINTER
    PRINT_TEXT welcome
    PRINT_TEXT loading_loader
; open control channel
    lda #CONTROL ; logical number
    ldx #WORLD_DRIVE       ; drive number
    ldy #CONTROL ; secondary address
    jsr SETLFS
    lda #0
    ldx #0
    ldy #0
    jsr SETNAM
    jsr OPEN

    jsr init_loader

; bitmap mode https://sta.c64.org/cbm64mem.html
    lda	#$bb
	sta	$d011		
; multicolor mode, 38 columns https://sta.c64.org/cbm64mem.html
D016_DEFAULT = $d0
    lda #(D016_DEFAULT + 7)
    sta $d016

; border color
	lda	#0
	sta	$d020
; background color
    lda #BG_COLOR
	sta	$d021

; starting values
    lda #0
;    sta debug_counter
    sta current_page
    sta loading_tile
    sta tiles_loaded
    sta scroll_counter
    lda #SCROLL_SPEED
    sta raster_counter2
    sta raster_counter
    lda #7
    sta pixel_counter
    SET_LITERAL16 scroll_buffer, TILE2
    SET_LITERAL16 load_buffer, TILE1


	lda	$d018       ; set bitmap memory relative to VIC bank
	and	#%11110000
	ora	#%00001000  ; vic bank + $2000
	sta	$d018	
; set up the bitmap
    jsr flip_page

; clear color RAM for testing
;    ldx #0
;clear_color:
;    lda #$12
;    sta BMP0_SCREEN,x
;    sta BMP0_SCREEN + 256,x
;    sta BMP0_SCREEN + 512,x
;    sta BMP0_SCREEN + 768,x
;    sta BMP1_SCREEN,x
;    sta BMP1_SCREEN + 256,x
;    sta BMP1_SCREEN + 512,x
;    sta BMP1_SCREEN + 768,x
;    lda #$11
;    sta COLOR_DST,x
;    sta COLOR_DST + 256,x
;    sta COLOR_DST + 512,x
;    sta COLOR_DST + 768,x
;    inx 
;    bne clear_color


; load the 1st tile
    SET_IO_STATE io_start_read
    SET_IO_FINISHED_STATE first_loaded

startup:
    jsr io_state
    lda tiles_loaded
; need 1 offscreen
    cmp #1
    bcc startup ; < 1 tiles loaded.

; start the scrolling
    lda #SCROLL_BITMAP
    sta do_scroll

; setup the raster interrupt
    sei                  ; set interrupt bit, make the CPU ignore interrupt requests
    lda #%01111111       ; switch off interrupt signals from CIA-1
    sta $dc0d

    and $d011            ; clear most significant bit of VIC's raster register
    sta $d011

    sta $dc0d            ; acknowledge pending interrupts from CIA-1
    sta $dd0d            ; acknowledge pending interrupts from CIA-2

    lda #210             ; set rasterline where interrupt shall occur
    sta $d012

    lda #<raster_interrupt ; set interrupt vectors, pointing to interrupt service routine below
    sta $0314
    lda #>raster_interrupt
    sta $0315

    lda #%00000001       ; enable raster interrupt signals from VIC
    sta $d01a

    cli                  ; clear interrupt flag, allowing the CPU to respond to interrupt requests


loop:
    jsr io_state

    lda do_scroll
    bne handle_scroll
        jmp loop

handle_scroll:
; copy previous color RAM?
    and #SCROLL_COLOR
    beq handle_scroll2

; debug
;        jsr flip_page
;        lda #1
;        eor current_page
;        sta current_page

; color RAM is the last step before we advance the counters
        jsr scroll_color

        inc scroll_counter
        lda scroll_counter
        cmp #40
        bne handle_scroll2
    ; start a new tile
            dec tiles_loaded
    ; assume the last tile finished loading before we get here
            jsr resume_tile_loading

            lda #0
            sta scroll_counter
; swap the source buffer
            ldx #<TILE1
            ldy #>TILE1
            lda scroll_buffer + 1
            cmp #>TILE2
            beq handle_scroll5
                ldx #<TILE2
                ldy #>TILE2
handle_scroll5:
            stx scroll_buffer
            sty scroll_buffer + 1

handle_scroll2:
; cancel the do_scroll
    lda #0
    sta do_scroll

; scroll it
;    PRINT_TEXT scrolling_t
;    PRINT_HEX8 tiles_loaded
;    PRINT_HEX8 scroll_counter
;    lda #$0a
;    jsr CIOUT
;    lda #0
;    jsr CIOUT

.ifdef ENABLE_DEBUG
    PRINT_TEXT scroll_left_t
;    PRINT_HEX16 $d018
;    PRINT_HEX16 $dd00

    PRINT_HEX16 scroll_buffer
    PRINT_HEX8 scroll_counter
    lda #$0a
    jsr CIOUT
    lda #0
    jsr CIOUT
.endif


; shift bitmap left 8 pixels
; choose page flipping direction
    lda current_page
    bne scroll_left2
; draw new frame in BMP1
        ldx #0 
        jsr left_BMP0_to_BMP1_256
; offset X to avoid a compare
        ldx #200
        jsr left_BMP0_to_BMP1_64
        ldx #217
        jsr left_BMP0SCREEN_to_BMP1SCREEN
        jmp scroll_left3

scroll_left2: 
; draw new frame in BMP0
        ldx #0
        jsr left_BMP1_to_BMP0_256
; offset X to avoid a compare
        ldx #200
        jsr left_BMP1_to_BMP0_64
        ldx #217
        jsr left_BMP1SCREEN_to_BMP0SCREEN

scroll_left3:
; draw new column
    COPY_REG16 draw_buffer, scroll_buffer
; add scroll column to bitmap source
    lda scroll_counter
    sta temp1
    lda #0
    sta temp2
    asl temp1 ; * 8
    rol temp2
    asl temp1
    rol temp2
    asl temp1
    rol temp2
    ADD_REG16 rcolumn_src + 1, draw_buffer, temp1
; calculate bitmap destination
    ldx #<(BMP0 + 312) ; draw into BMP0 if current page 1
    ldy #>(BMP0 + 312)
    lda current_page
    bne scroll_left5
        ldx #<(BMP1 + 312) ; draw into BMP1 if current page 0
        ldy #>(BMP1 + 312)
scroll_left5:
    stx rcolumn_dst + 1
    sty rcolumn_dst + 2


;    PRINT_TEXT scroll_left_t
;    PRINT_HEX16 draw_buffer
;    PRINT_HEX8 scroll_counter
;    PRINT_HEX16 rcolumn_src + 1
;    PRINT_HEX16 rcolumn_dst + 1
;    lda #$0a
;    jsr CIOUT
;    lda #0
;    jsr CIOUT

    sei ; no interrupts without kernal ROM
    lda #KERNAL_OUT
    sta PORT_REG
; copy a row
    ldy #24
; copy a cell
rcolumn_cell:
    ldx #7
rcolumn_src:
    lda $ffff,x
;    lda #$55 ; DEBUG
rcolumn_dst:
    sta $ffff,x
    dex
    bpl rcolumn_src
        ADD_LITERAL16 rcolumn_src + 1, rcolumn_src + 1, 320
        ADD_LITERAL16 rcolumn_dst + 1, rcolumn_dst + 1, 320
        dey
        bpl rcolumn_cell
; switch in kernal ROM
            lda #KERNAL_IN
            sta PORT_REG
            cli ; enable interrupts

; draw new screen column
    ADD_LITERAL16 draw_buffer, draw_buffer, 8000
    lda scroll_counter
    clc
    adc draw_buffer
    sta rcolumn_src2 + 1
    lda #0
    adc draw_buffer + 1
    sta rcolumn_src2 + 2
; calculate screen destination
    ldx #<(BMP0_SCREEN + 39) ; draw into BMP0 if current page 1
    ldy #>(BMP0_SCREEN + 39)
    lda current_page
    bne scroll_left6
        ldx #<(BMP1_SCREEN + 39) ; draw into BMP1 if current page 0
        ldy #>(BMP1_SCREEN + 39)
scroll_left6:
    stx rcolumn_dst2 + 1
    sty rcolumn_dst2 + 2


;    PRINT_TEXT scroll_left_t
;    PRINT_HEX16 draw_buffer
;    PRINT_HEX16 rcolumn_src2 + 1
;    PRINT_HEX16 rcolumn_dst2 + 1
;    lda #$0a
;    jsr CIOUT
;    lda #0
;    jsr CIOUT

    sei ; no interrupts without kernal ROM
    lda #KERNAL_OUT
    sta PORT_REG
    ldy #24
rcolumn_src2:
    lda $ffff
;    lda #$12 ; DEBUG
rcolumn_dst2:
    sta $ffff
    ADD_LITERAL16 rcolumn_src2 + 1, rcolumn_src2 + 1, 40
    ADD_LITERAL16 rcolumn_dst2 + 1, rcolumn_dst2 + 1, 40
    dey
    bpl rcolumn_src2
; switch in kernal ROM
        lda #KERNAL_IN
        sta PORT_REG
        cli ; enable interrupts
        jmp loop






scroll_color:
    ldx #217
    jsr left_COLOR

; draw new color column
; set destination
    ldx #<(COLOR_DST + 39)
    ldy #>(COLOR_DST + 39)
    stx rcolumn_dst3 + 1
    sty rcolumn_dst3 + 2
; set source
    ADD_LITERAL16 draw_buffer, scroll_buffer, 9000 ; scroll buffer + 9000 + column / 2
    lda scroll_counter
    lsr ; / 2
    clc
    adc draw_buffer
    sta rcolumn_src3 + 1
    lda #0
    adc draw_buffer + 1
    sta rcolumn_src3 + 2
; compute nibble to copy
    lda scroll_counter
    lsr ; even numbered column C = 0, odd numbered column C = 1
    lda #$ea ; default to NOP
    bcs rcolumn_odd
; odd numbered column copies bits 0:3 NOP
; even numbered column copies bits 4:7 ASL
        lda #$4a
rcolumn_odd:
        sta rcolumn_nibble_mod
        sta rcolumn_nibble_mod + 1
        sta rcolumn_nibble_mod + 2
        sta rcolumn_nibble_mod + 3

;    PRINT_TEXT scroll_left_t
;    PRINT_HEX16 draw_buffer
;    PRINT_HEX16 rcolumn_src3 + 1
;    PRINT_HEX16 rcolumn_dst3 + 1
;    lda #$0a
;    jsr CIOUT
;    lda #0
;    jsr CIOUT


    ldy #24
    sei ; no interrupts without kernal ROM
rcolumn_color_loop:
    ldx #KERNAL_OUT
    stx PORT_REG
rcolumn_src3:
    lda $ffff
;    lda #$00 ; DEBUG
rcolumn_nibble_mod: ; overwrite with nibble operation
    lsr
    lsr
    lsr
    lsr
; switch in kernal ROM
    ldx #KERNAL_IN
    stx PORT_REG
rcolumn_dst3:
    sta $ffff
    ADD_LITERAL16 rcolumn_src3 + 1, rcolumn_src3 + 1, 20
    ADD_LITERAL16 rcolumn_dst3 + 1, rcolumn_dst3 + 1, 40
    dey
    bpl rcolumn_color_loop
        cli ; enable interrupts
        rts




flip_page:
; wait for raster line >= 256
;    lda $d011
;    bpl flip_page

    lda #1
    eor current_page
    sta current_page
    cmp #0
    bne flip_page2 ; current_page == 1

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
    rts

ENABLE_SMOOTH := 1
raster_interrupt:
    dec raster_counter
    bne raster_interrupt2

; alternate between 3 & 2 raster interrupts
        lda raster_counter2
        eor #1
;        sta raster_counter2
; constant
;        lda #SCROLL_SPEED
        sta raster_counter

.ifdef ENABLE_SMOOTH
        lda $d016
        and #7
.else
        lda pixel_counter
.endif
        beq raster_interrupt3
            tax
            dex
            txa
.ifdef ENABLE_SMOOTH
            ora #D016_DEFAULT
            sta $d016
.else
            sta pixel_counter
.endif
            jmp raster_interrupt2

raster_interrupt3:
; need a page flip & a scroll operation
    lda do_scroll
    bne raster_interrupt2 ; not ready to page flip & scroll

        jsr flip_page

; don't step on current_page
;        lda #1
;        eor current_page
;        sta current_page

; reset the scroll position
.ifdef ENABLE_SMOOTH
        lda #(D016_DEFAULT + 7)
        sta $d016
.else
        lda #7
        sta pixel_counter
.endif

; DEBUG
;    lda debug_counter
;    beq raster_interrupt2
;        dec debug_counter
    
; cue the color RAM + scroll operation
        lda #(SCROLL_COLOR + SCROLL_BITMAP)
        sta do_scroll

raster_interrupt2:
    asl $d019 ; clear interupt
    jmp $ea31 ; default irq

io_state:
    jmp io_idle

io_idle:
    rts

io_start_read:
.ifdef ENABLE_DEBUG
    PRINT_TEXT reading_tile_t
    PRINT_HEX8 loading_tile
    PRINT_HEX16 load_buffer
    lda #$0a
    jsr CIOUT
    lda #$00
    jsr CIOUT
.endif

; set up the buffer destination
    COPY_REG16 tile_dst_mod + 1, load_buffer
    ADD_LITERAL16 tile_end, tile_dst_mod + 1, 9500 ; end of tile

; get track & sector for the tile
    ldx loading_tile
    lda tracks,x
    sta current_track
    lda sectors,x
    sta current_sector
; reset RLE state
    lda #0
    sta is_rle
    jmp start_read ; loader.s

io_finished_state:
    jmp io_idle


first_loaded:
; set up 2nd tile load
    SET_IO_STATE io_start_read
    SET_LITERAL16 load_buffer, TILE2
    SET_IO_FINISHED_STATE second_loaded
    inc loading_tile

; copy the tile to the bitmap
    SET_LITERAL16 copy_src + 1, TILE1
    SET_LITERAL16 copy_dst + 1, BMP1
; switch out kernal ROM
    sei ; no interrupts without kernal ROM
    lda #KERNAL_OUT
    sta PORT_REG
copy_src:
    lda $ffff
copy_dst:
    sta $ffff
    INC16 copy_src + 1
    INC16 copy_dst + 1
    BRANCH_GREATEREQUAL16 copy_src + 1, (TILE1 + 8000), copy_screen
        jmp copy_src



copy_screen:
; copy the screen memory
    COPY_REG16 copy_src1 + 1, copy_src + 1
    SET_LITERAL16 copy_dst1 + 1, BMP1_SCREEN
copy_src1:
    lda $ffff
copy_dst1:
    sta $ffff
    INC16 copy_src1 + 1
    INC16 copy_dst1 + 1
    BRANCH_GREATEREQUAL16 copy_src1 + 1, (TILE1 + 9000), copy_color
        jmp copy_src1



copy_color:
; DEBUG
;jmp copy_done
    COPY_REG16 copy_src2 + 1, copy_src1 + 1
    SET_LITERAL16 copy_dst2 + 1, COLOR_DST
copy_src2:
    lda $ffff ; get 2 nibbles
    tax ; save low nibble for later
    lsr ; shift right
    lsr
    lsr
    lsr
; switch in kernal ROM
    ldy #KERNAL_IN
    sty PORT_REG
    sec ; store high nibble 1st
copy_dst2:
    sta $ffff ; store a nibble
    bcc copy_color2 ; done storing color
        INC16 copy_dst2 + 1 ; next dest nibble
        txa ; recover 2 nibbles
        and #$f
        clc ; store low nibble 2nd
        jmp copy_dst2

copy_color2:
; switch out kernal ROM
    lda #KERNAL_OUT
    sta PORT_REG
    INC16 copy_dst2 + 1 ; next dest nibble
    INC16 copy_src2 + 1 ; next source byte
    BRANCH_GREATEREQUAL16 copy_src2 + 1, (TILE1 + 9500), copy_done
        jmp copy_src2

copy_done:
; switch in kernal ROM
    lda #KERNAL_IN
    sta PORT_REG
    cli ; enable interrupts
    
;    PRINT_TEXT copy_done_t

    rts



second_loaded:
;    PRINT_TEXT second_loaded_t
    inc tiles_loaded
    TOGGLE_LOAD_BUFFER
; enough room for another tile?
    lda tiles_loaded
    cmp #2
    bcs done_loading ; >= 2
; set up next tile load
resume_tile_loading:
; next tile number
        inc loading_tile
        lda loading_tile
        cmp #W_TILES
        bcc resume_tile_loading2 ; < W_TILES
            lda #0 ; rewind
            sta loading_tile
resume_tile_loading2:
        SET_IO_STATE io_start_read
        SET_IO_FINISHED_STATE second_loaded
        rts

done_loading:
    SET_IO_STATE io_idle
    rts



.include "common.s"
.include "loader.s"
.include "marineris_scroll.s"
.include "world2.s"


welcome:
    .byte "welcome to marineris"
    .byte $0a, $00    ; null terminator for the message
copy_done_t:
    .byte "copy done"
    .byte $0a, $00    ; null terminator for the message
reading_tile_t:
    .byte "reading tile "
    .byte $00
scrolling_t:
    .byte "scrolling ", $00
scroll_left_t:
    .byte "scroll left ", $00
second_loaded_t:
    .byte "second loaded", $0a, $00

