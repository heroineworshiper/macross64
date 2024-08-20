.include "cbm_kernal.inc"
.include "common.inc"

PLAYER_X := 182
PLAYER_Y := 87
;PLAYER_X := 22
;PLAYER_Y := 13


.segment "DATA"



temp1: .res 2
temp2: .res 2
start_tile: .res 1 ; starting table entry of the drawing routine
column_number: .res 1 ; starting column number in the source tile
column_offset: .res 2 ; starting row & column offset in the source tile
row_number: .res 1 ; row counter
row_offset: .res 2 ; current row column 0 offset in the source tile
current_track: .res 1
current_sector: .res 1

; current position in the world, in cells
player_x: .res 2 ; 0 - 65535 for X
player_y: .res 1 ; 0 - 255 for Y
; position relative to the current tile, in cells
player_tile_x: .res 1
player_tile_y: .res 1
; player's screen position in cells
SCREEN_X := TILE_W / 2
SCREEN_Y := TILE_H / 2

; tile loader iterates over these tables & loads tiles
; the loader has to prioritize loads based on player heading
; 9 sectors define the tile containing the player + 8 border tiles
; 0xff for tiles out of bounds
tile_numbers: .res 9
; buffer numbers of loaded tiles or 0xff if not loaded
tile_buffers: .res 9
; tile buffer usage
buffer_used: .res 9

; new tables based on current player position
; this is copied to tile_numbers & matching tile_buffers reused
tile_numbers2: .res 9
tile_buffers2: .res 9
buffer_used2: .res 9

; number of the tile being loaded or 0xff if nothing loaded
loading_tile: .res 1



.include "scrollvars.inc"
.include "loader.inc"


; secondary & logical addresses for the world drive
CONTROL = 15
WORLD_DRIVE = 8

; size of tile table
TABLE_SIZE := 9

.macro SET_IO_STATE func
    SET_LITERAL16 io_state + 1, func
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

    jsr init_graphics

; starting player coordinate in cells
    lda #<PLAYER_X
    sta player_x
    lda #>PLAYER_X
    sta player_x + 1
    lda #PLAYER_Y
    sta player_y

; initalize player tables
    ldx #8
clear_tables:
    lda #$ff
    sta tile_numbers,x
    sta tile_buffers,x
    lda #$00
    sta buffer_used,x
    dex
    bpl clear_tables

    lda #$ff
    sta loading_tile

    jsr compute_tables
    jsr dump_newtables
    lda #$0a
    jsr CIOUT

; DEBUG
;    jmp hang

; start the IO thread
    SET_IO_STATE io_start_read
; DEBUG
;    SET_IO_STATE io_idle

loop:
;    jsr scroll_left
;    jsr flip_page

;    jsr update_pattern
    jsr io_state
    jmp loop

hang:
    jmp hang

io_state:
    jmp io_idle


io_idle:

    jsr GETIN
    beq keyboard4 ; got $00
;        sta temp1
;        PRINT_HEX8 temp1
;        lda #$0a
;        jsr CIOUT

STEP := 5
        cmp #'w'
        bne keyboard1
            SUB_LITERAL player_y, player_y, STEP
            jmp keyboard_common

keyboard1:
        cmp #'s'
        bne keyboard2
            ADD_LITERAL player_y, player_y, STEP
            jmp keyboard_common

keyboard2:
        cmp #'a'
        bne keyboard3
            SUB_LITERAL16 player_x, player_x, STEP
            jmp keyboard_common

keyboard3:
        cmp #'d'
        bne keyboard4
            ADD_LITERAL16 player_x, player_x, STEP
            jmp keyboard_common

keyboard4:
    rts

keyboard_common:
    jsr compute_tables
;    PRINT_TEXT keyboard_done
;    jsr dump_newtables
;    lda #$0a
;    jsr CIOUT
    SET_IO_STATE io_start_read
    rts

io_start_read:
; search the table for the next tile to read
;    ldy #(TABLE_SIZE - 1)
    ldy #0
tile_search:
    lda tile_numbers,y
    cmp #$ff
    beq tile_search2 ; tile number == 0xff, no tile assigned
; has a tile number
        lda tile_buffers,y
        cmp #$ff
        bne tile_search2 ; buffer number != 0xff, tile was loaded
; but no buffer number
            lda tile_numbers,y
            sta loading_tile ; store the tile to load

; find an unused buffer
            ldx #8
search_buffers:
            lda buffer_used,x
            beq search_buffers2 ; buffer not used
                dex
                bne search_buffers ; next buffer if X > 0

; X should always point to a free buffer by this point
search_buffers2:
; set the buffer used flag
            lda #1 
            sta buffer_used,x
; set the buffer number of the tile
            txa
            sta tile_buffers,y
; store the pointer to the buffer
            asl ; multiply buffer number by 2
            tax
            lda tile_storage,x ; low byte of buffer
            sta tile_dst_mod + 1 ; self modifying code
;            sta print_tile_mod + 1 ; debugging
            sta tile_end
            lda tile_storage + 1,x ; high byte of buffer
            sta tile_dst_mod + 2
;            sta print_tile_mod + 2 ; debugging
            sta tile_end + 1
            ADD_LITERAL16 tile_end, tile_end, 2500 ; set the buffer end

; print the results
            SET_IO_STATE io_start_read2
            jsr print_tile_search
            rts

; next table entry
tile_search2:
;    dey
;    bpl tile_search ; y >= 0
    iny
    cpy #TABLE_SIZE
    bne tile_search ; y < TABLE_SIZE

; no more tiles to load
        PRINT_TEXT tiles_done
        jsr dump_oldtables
        lda #$0a
        jsr CIOUT

; print a tile
;        lda #<($523c + 1000)
;        sta print_tile_mod + 1
;        lda #>($523c + 1000)
;        sta print_tile_mod + 2
;        jsr print_tile
        
        SET_IO_STATE io_idle
        jmp draw_screen
        rts

print_tile_search:
    PRINT_TEXT reading_tile
    PRINT_HEX8 loading_tile
    PRINT_HEX16 tile_dst_mod + 1
    lda #$0a
    jsr CIOUT
    rts

io_start_read2:
; get track & sector for the tile
    ldx loading_tile
    lda tracks,x
; DEBUG track 1
;    lda #1
    sta current_track
    lda sectors,x
; DEBUG sector 1
;    lda #1
    sta current_sector
; must reset RLE state here so RLE can bridge 2 sectors
    lda #0
    sta is_rle
    jmp start_read ; loader.s


io_read_finished:

.ifdef DEBUG_SECTOR
    jmp print_sector
.else
;    jsr print_tile
    lda #$0a
    jsr CIOUT
    lda #$0a
    jsr CIOUT
    SET_IO_STATE io_idle
    rts

.endif






draw_screen:
; get the table entry containing the starting cell
    lda #4 ; table entry containing the player is constant
    sta start_tile

; compute offset of the player in the tile
    ldx player_tile_y ; compute the row offset
    stx row_number ; compute the row number in the source tile
    lda row_to_offset,x
    sta row_offset
    lda #0
    sta row_offset + 1
    asl row_offset ; * 2
    rol row_offset + 1
    asl row_offset ; * 4
    rol row_offset + 1

    lda player_tile_x ; add player X to start of the row
    sta column_number ; compute the column number in the source tile
    clc
    adc row_offset
    sta column_offset
    lda #0
    adc row_offset + 1
    sta column_offset + 1

; offset of the starting column    
    SUB_LITERAL16 column_offset, column_offset, SCREEN_X ; subtract column from tile offset
    SUB_LITERAL column_number, column_number, SCREEN_X

    BRANCH_GREATEREQUAL player_tile_x, SCREEN_X, got_starting_column ; starting column is in same cell
        dec start_tile ; starting column is 1 tile left
        ADD_LITERAL16 column_offset, column_offset, TILE_W ; tile offset is to the right of player
        ADD_LITERAL column_number, column_number, TILE_W
got_starting_column:

    SUB_LITERAL16 column_offset, column_offset, (SCREEN_Y * TILE_W) ; subtract row from tile offse
    SUB_LITERAL16 row_offset, row_offset, (SCREEN_Y * TILE_W)
    SUB_LITERAL row_number, row_number, SCREEN_Y
    BRANCH_GREATEREQUAL player_tile_y, SCREEN_Y, got_starting_row ; starting row is in same cell
        dec start_tile ; starting row is 1 tile up
        dec start_tile
        dec start_tile
        ADD_LITERAL16 column_offset, column_offset, (TILE_W * TILE_H) ; tile offset is below player
        ADD_LITERAL16 row_offset, row_offset, (TILE_W * TILE_H)
        ADD_LITERAL row_number, row_number, TILE_H
got_starting_row:


    PRINT_TEXT screen_start
    PRINT_HEX8 start_tile ; table entry of tile
    PRINT_HEX8 column_number
    PRINT_HEX8 row_number
    PRINT_HEX16 column_offset ; offset in tile of top left cell
    PRINT_HEX16 row_offset ; offset in tile of the row
    lda #$0a
    jsr CIOUT

; set the number of rows to draw
    lda #TILE_H
    sta temp2
; set bitmap destination
    SET_LITERAL16 draw_cell_mod_bmp + 1, BMP1
; set screen memory destination
    SET_LITERAL16 draw_cell_screen_mod2 + 1, BMP1_SCREEN

; draw all the rows
draw_rows:
; address of current tile
    ldx start_tile
    lda tile_buffers,x ; buffer number of tile
    asl ; buffer number * 2
    tax
    clc
    lda tile_storage,x ; address of tile buffer
    adc column_offset ; add player offset in current tile
    sta draw_cell_char_mod + 1
    lda tile_storage + 1,x
    adc column_offset + 1
    sta draw_cell_char_mod + 2

; address of screen memory source
    ADD_LITERAL16 draw_cell_screen_mod + 1, draw_cell_char_mod + 1, (TILE_W * TILE_H)



; reset the column number
    lda column_number
    sta temp1


;    PRINT_HEX16 draw_cell_char_mod + 1 ; source character address
;    PRINT_HEX16 draw_cell_mod_bmp + 1 ; bitmap dst address
;    lda #$0a
;    jsr CIOUT


; draw a complete row
    ldy #TILE_W ; total columns
draw_row:
; switch out kernal ROM
    sei ; no interrupts without kernal ROM
    lda #KERNAL_OUT
    sta PORT_REG
draw_cell_char_mod:
; load character number from the tile
    lda tile_storage
    sta draw_cell_charset_mod + 1
; high byte of character number
    lda #0
    sta draw_cell_charset_mod + 2

; copy screen memory from the tile
draw_cell_screen_mod:
    lda tile_storage + (TILE_W * TILE_H)
;    lda #$30 ; DEBUG
draw_cell_screen_mod2:
    sta BMP1_SCREEN

; copy color value from the tile

; switch in kernal ROM
    lda #KERNAL_IN
    sta PORT_REG
    cli ; enable interrupts



;    PRINT_HEX16 draw_cell_char_mod + 1
;    PRINT_HEX8 draw_cell_charset_mod + 1
;    lda #$0a
;    jsr CIOUT

; convert character number to character address
    asl draw_cell_charset_mod + 1 ; * 2
    rol draw_cell_charset_mod + 2
    asl draw_cell_charset_mod + 1 ; * 4
    rol draw_cell_charset_mod + 2
    asl draw_cell_charset_mod + 1 ; * 8
    rol draw_cell_charset_mod + 2
    ADD_LITERAL16 draw_cell_charset_mod + 1, draw_cell_charset_mod + 1, char_set ; + char set
; copy the character
    ldx #7
draw_cell_charset_mod:
    lda char_set,x
draw_cell_mod_bmp:
    sta BMP1,x
    dex
    bpl draw_cell_charset_mod
        dey ; advance column
        bne draw_row_continue2
            jmp draw_row_done

draw_row_continue2: ; row not done
; always advance the bitmap destination
    ADD_LITERAL16 draw_cell_mod_bmp + 1, draw_cell_mod_bmp + 1, 8 
; advance the screen memory destination
    INC16 draw_cell_screen_mod2 + 1

; test for end of row in source tile
    inc temp1
    lda temp1
    cmp #TILE_W
    bne draw_row_continue
; column 0, 1 source tile right
        lda #0
        sta temp1
        ldx start_tile
        inx
        lda tile_buffers,x ; buffer number of tile
        asl ; buffer number * 2
        tax
        clc

        lda tile_storage,x ; address of tile buffer
        adc row_offset ; add offset of the row, column 0 in the tile buffer
        sta draw_cell_char_mod + 1

        lda tile_storage + 1, x
        adc row_offset + 1
        sta draw_cell_char_mod + 2

        ADD_LITERAL16 draw_cell_screen_mod + 1, draw_cell_char_mod + 1, (TILE_W * TILE_H)
        jmp draw_row

draw_row_continue:
; next character source
    INC16 draw_cell_char_mod + 1
; next screen memory source
    INC16 draw_cell_screen_mod + 1
    jmp draw_row

draw_row_done:
    dec temp2 ; advance rows drawn
    beq draw_screen_done

; advance bitmap destination to the next row
        ADD_LITERAL16 draw_cell_mod_bmp + 1, draw_cell_mod_bmp + 1, 8
; advance the screen memory destination to the next row
        INC16 draw_cell_screen_mod2 + 1
; advance the starting input row & column 1 row
        ADD_LITERAL16 column_offset, column_offset, TILE_W
; advance the starting input column 0
        ADD_LITERAL16 row_offset, row_offset, TILE_W
; test for end of rows in the source tile
        inc row_number
        lda row_number
        cmp #TILE_H
        bne draw_rows_continue

; advance the source tile 1 row down
            inc start_tile
            inc start_tile
            inc start_tile
; rewind the column offset to the 1st row
            SUB_LITERAL16 column_offset, column_offset, (TILE_W * TILE_H)
            SUB_LITERAL16 row_offset, row_offset, (TILE_W * TILE_H)

draw_rows_continue:
        jmp draw_rows

draw_screen_done:
    rts





.ifdef DEBUG_SECTOR
print_sector:
; reset counter
    lda #0
    sta sector_offset
    SET_IO_STATE print_loop
    rts

print_loop:
    ldx sector_offset
    lda SECTOR_DST,x
    tay
    jsr print_hex8
    lda #' '
    jsr CIOUT
    inc sector_offset
    bne print_loop2

        lda #$0a ; newline
        jsr CIOUT
        lda #$0a ; flush
        jsr CIOUT
        SET_IO_STATE io_idle
        rts ; donechak

print_loop2:
    rts
.else ; DEBUG_SECTOR

print_tile:
; just a single screen of data
    ADD_LITERAL16 tile_end, print_tile_mod + 1, 1000
    lda #40
    sta temp1
print_tile_mod:
    PRINT_HEX8 $ffff ; set during the start of the read
    INC16 print_tile_mod + 1
    dec temp1
    bne print_tile2
        lda #$0a
        jsr CIOUT
        lda #40
        sta temp1
print_tile2:
    lda print_tile_mod + 1
    cmp tile_end
    bne print_tile_mod
        lda print_tile_mod + 2
        cmp tile_end + 1
        bne print_tile_mod

            lda #$0a
            jsr CIOUT
            rts

.endif


; compute the tile tables
; Must call every time the player moves
compute_tables:
    ldx #8
; reset the new tables
clear_tables2:
    lda #$ff
    sta tile_numbers2,x
    sta tile_buffers2,x
    lda #$00
    sta buffer_used2,x
    dex
    bpl clear_tables2

; compute the tile row
        lda player_y ; player y into the counter
        sec
        ldy #0
compute_row:
    iny ; increase row number
    sbc #TILE_H ; subtract tile height from counter
    bcs compute_row ; repeat if counter >= 0
        dey ; rewind 1 row
        adc #TILE_H ; rewind 1 tile height
; store player Y relative to current tile
        sta player_tile_y
; compute the tile column
        lda player_x ; 16 bit player X into the counter
        sta temp1
        lda player_x + 1
        sta temp1 + 1

        ldx #0
compute_col:
        inx ; increase column number
        SUB_LITERAL16 temp1, temp1, TILE_W ; subtract tile width from counter
        bcs compute_col ; repeat if counter >= 0
            dex ; rewind 1 column
; store player X relative to current tile
            ADD_LITERAL player_tile_x, temp1, TILE_W ; rewind 1 tile width
; tile result = column
            txa
            clc
compute_tile2: ; add rows to tile result
            dey
            bmi compute_tile3
                adc #W_TILES ; add 1 row of tiles
                jmp compute_tile2
compute_tile3:
; store tile number in middle of table
    sta tile_numbers2 + 4
; set right column
    BRANCH_GREATEREQUAL16 player_x, (WORLD_W - TILE_W), compute_left_column
        lda tile_numbers2 + 4
        clc
        adc #1
        sta tile_numbers2 + 5
    BRANCH_GREATEREQUAL player_y, (WORLD_H - TILE_H), compute_right_column2
        lda tile_numbers2 + 5
        clc
        adc #W_TILES
        sta tile_numbers2 + 8
compute_right_column2:
    BRANCH_LESS player_y, TILE_H, compute_left_column
        lda tile_numbers2 + 5
        sec
        sbc #W_TILES
        sta tile_numbers2 + 2
compute_left_column:
; set left column
    BRANCH_LESS16 player_x, TILE_W, compute_bottom
        lda tile_numbers2 + 4
        sec
        sbc #1
        sta tile_numbers2 + 3
    BRANCH_GREATEREQUAL player_y, (WORLD_H - TILE_H), compute_left_column2
        lda tile_numbers2 + 3
        clc
        adc #W_TILES
        sta tile_numbers2 + 6
compute_left_column2:
    BRANCH_LESS player_y, TILE_H, compute_bottom
        lda tile_numbers2 + 3
        sec
        sbc #W_TILES
        sta tile_numbers2
compute_bottom:
    BRANCH_GREATEREQUAL player_y, (WORLD_H - TILE_H), compute_top
        lda tile_numbers2 + 4
        clc
        adc #W_TILES
        sta tile_numbers2 + 7
compute_top:
    BRANCH_LESS player_y, TILE_H, compute_tables_done
        lda tile_numbers2 + 4
        sec
        sbc #W_TILES
        sta tile_numbers2 + 1
compute_tables_done:

; copy previous tile instances to the new table
    ldy #8
search_new:
    lda tile_numbers2,y ; get tile number in new sector
    cmp #$ff
    beq search_new2 ; no tile assigned

; search old table for tile
        sta temp1
        ldx #8
search_old:
        lda tile_numbers,x
        cmp temp1
        bne search_old2 ; doesn't match old sector
; got a previous instance of the tile
; copy old buffer number to new sector
            lda tile_buffers,x
            sta tile_buffers2,y
; copy the buffer usage for the old buffer
            tax
            lda #1
            sta buffer_used2,x
            jmp search_new2

; next sector in old table
search_old2:
        dex
        bpl search_old

; next sector in new table
search_new2:
    dey
    bpl search_new

; copy new tables to old tables
        ldx #8
copy_tables:
        lda tile_numbers2,x
        sta tile_numbers,x
        lda tile_buffers2,x
        sta tile_buffers,x
        lda buffer_used2,x
        sta buffer_used,x
        dex
        bpl copy_tables ; x >= 0
            rts

dump_oldtables:
    SET_LITERAL16 dump_tables_mod1 + 1, tile_numbers
    SET_LITERAL16 dump_tables_mod2 + 1, tile_buffers
    jmp dump_tables

dump_newtables:
    SET_LITERAL16 dump_tables_mod1 + 1, tile_numbers2
    SET_LITERAL16 dump_tables_mod2 + 1, tile_buffers2


dump_tables:
; some debugging
;    PRINT_HEX8 player_tile_x
;    PRINT_HEX8 player_tile_y
    lda #$0a
    jsr CIOUT

    ldx #0
dump_tables3:
    jsr dump_tables2
    inx
    jsr dump_tables2
    inx
    jsr dump_tables2
    inx
    lda #$0a
    jsr CIOUT
    cpx #9
    bne dump_tables3
        rts

dump_tables2:
dump_tables_mod1:
    ldy $ffff,x
    txa
    pha
    jsr print_hex8
    pla
    tax
    lda #'-'
    jsr CIOUT
dump_tables_mod2:
    ldy $ffff,x
    txa
    pha
    jsr print_hex8
    pla
    tax
    lda #' '
    jsr CIOUT
    rts

.include "common.s"
.include "loader.s"
.include "scroll.inc"
.include "world.s"

; tile addresses
tile_storage:
    .word $f63c
    .word $ec78
    .word $e2b4
    .word $d8f0
    .word $cf2c
    .word $c5f8
; COLOR_SRC $c000-$c400
; BMP1 $a000-$c000 gap from $c400 - $c5f8
    .word $963c
    .word $8c78
; BMP1_SCREEN $8000-$8400 gap from $8400 - $8c78 
; BMP0 $6000-$8000
; BMP0_SCREEN $5c00
    .word $523c

; row to offset / 4
row_to_offset:
    .byte 10 * 0, 10 * 1, 10 * 2, 10 * 3, 10 * 4, 10 * 5
    .byte 10 * 6, 10 * 7, 10 * 8, 10 * 9, 10 * 10, 10 * 11
    .byte 10 * 12, 10 * 13, 10 * 14, 10 * 15, 10 * 16, 10 * 17
    .byte 10 * 18, 10 * 19, 10 * 20, 10 * 21, 10 * 22, 10 * 23
    .byte 10 * 24

welcome:
    .byte "welcome to macross64"
    .byte $0a, $00    ; null terminator for the message

reading_tile:
    .byte "reading tile "
    .byte $00    ; null terminator for the message
sector_done:
    .byte "sector done"
    .byte $0a, $00    ; null terminator for the message
tiles_done:
    .byte "tiles done"
    .byte $0a, $00
screen_start:
    .byte "screen start "
    .byte 0
keyboard_done:
    .byte "keyboard done"
    .byte $0a, $00


