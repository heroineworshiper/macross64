; from kernal source
cia1	=$dc00                  ;device1 6526 (page1 irq)
d1pra	=cia1+0
colm	=d1pra                  ;keyboard matrix
d1prb	=cia1+1
rows	=d1prb                  ;keyboard matrix
d1ddra	=cia1+2
d1ddrb	=cia1+3
d1t1l	=cia1+4
d1t1h	=cia1+5
d1t2l	=cia1+6
d1t2h	=cia1+7
d1tod1	=cia1+8
d1tods	=cia1+9
d1todm	=cia1+10
d1todh	=cia1+11
d1sdr	=cia1+12
d1icr	=cia1+13
d1cra	=cia1+14
d1crb	=cia1+15

cia2	=$dd00                  ;device2 6526 (page2 nmi)
d2pra	=cia2+0 ; the data port
CLK_OUT := $10 ; inverse of line voltage
DAT_OUT := $20 ; inverse of line voltage
CLK_IN  := $40 ; direct line voltage
DAT_IN  := $80 ; direct line voltage
VIC_OUT := $03 ; bits need to be on to keep VIC happy
ATN_OUT := $08 ; inverse of ATN

d2prb	=cia2+1
d2ddra	=cia2+2
d2ddrb	=cia2+3
d2t1l	=cia2+4
d2t1h	=cia2+5
d2t2l	=cia2+6
d2t2h	=cia2+7
d2tod1	=cia2+8
d2tods	=cia2+9
d2todm	=cia2+10
d2todh	=cia2+11
d2sdr	=cia2+12
d2icr	=cia2+13
d2cra	=cia2+14
d2crb	=cia2+15

; start of loader in drive memory
LOADER_START = $0400
; bytes per m-w command.  Maximum is 42-6 but the manual says 34
LOADER_FRAGMENT = 34




init_loader:
    ; load the fastloader
    SET_LITERAL16 temp1, LOADER_START

loader_loop:
    SELECT_CONTROL
    lda #'m'
    jsr CIOUT
    lda #'-'
    jsr CIOUT
    lda #'w'
    jsr CIOUT
    lda temp1 ; send dst address
    jsr CIOUT
    lda temp2
    jsr CIOUT
    lda #LOADER_FRAGMENT ; send number of bytes
    jsr CIOUT

; send 34 bytes
    ldx #0
loader_mod1:
    lda fastload_start,x ; load form src address
    jsr CIOUT
    inx
    cpx #LOADER_FRAGMENT
    bne loader_mod1
        jsr UNLSN ; execute the command
; next 34 bytes
        ADD_LITERAL16 loader_mod1 + 1, loader_mod1 + 1, LOADER_FRAGMENT
        ADD_LITERAL16 temp1, temp1, LOADER_FRAGMENT
        BRANCH_GREATEREQUAL16 loader_mod1 + 1, fastload_end, loader_done
            jmp loader_loop

loader_done:

    SELECT_CONTROL
    lda #'m'
    jsr CIOUT
    lda #'-'
    jsr CIOUT
    lda #'e'
    jsr CIOUT
    lda #<LOADER_START
    jsr CIOUT
    lda #>LOADER_START
    jsr CIOUT
    jsr UNLSN ; execute the command


; must disable interrupts since VIC bank sets the same register as the GPIOs
    sei
    CLKDATHI
    cli
; wait for fastloader
    ldy #100
delay:
    jsr delay1ms
    dey
    bne delay

; last LISTEN call
        SELECT_PRINTER

        PRINT_TEXT loader_started
        rts


;delay 1ms using loop
delay1ms:
	txa             ;save .x
	ldx #200-16     ;1000us-(1000/500*8=#40us holds)
delay1ms1:	dex             ;5us loop
	bne delay1ms1
	tax             ;restore .x
	rts


start_read:
.ifdef ENABLE_DEBUG
;    PRINT_TEXT reading_track_sector
;    PRINT_HEX8 current_track
;    PRINT_HEX8 current_sector
;    lda #$0a
;    jsr CIOUT
;    lda #$00
;    jsr CIOUT
.endif

; pulse ATN to synchronize drive
    sei
    ATNLO
; do some initialization stuff to delay
    lda current_track
    sta temp1
    lda current_sector
    sta temp2
    ATNHI
    cli


    ldx #16
    sei
start_read1:
    CLKLO
    ror temp1 ; track
    ror temp2 ; sector
    bcs start_read2 ; least significant bit is 1
        DATLO ; least significant bit is 0
        jmp start_read3
start_read2:
    DATHI ; least significant bit is a 1
start_read3:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    CLKHI
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dex
    bne start_read1
    cli
; wait for clock low to indicate read started
wait_loader3:
    lda d2pra
    and #CLK_IN
    bne wait_loader3
        sei
        DATHI
        cli
        SET_IO_STATE wait_sector
        rts

; wait for clock high to indicate read finished
wait_sector:
    lda d2pra
    and #CLK_IN
    beq wait_sector2
;        PRINT_TEXT read_finished


; reset the sector reader.
        lda #0
        sta sector_offset
        SET_IO_STATE read_sector
wait_sector2:
    rts


read_sector:
    ldx #8
    sei
bit_loop:
    CLKLO
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    CLKHI

    lda d2pra
    rol ; shift DAT into C
    ror temp1 ; shift C into result

    dex
    bne bit_loop
    cli

; print the incoming byte
;        PRINT_HEX8 temp1

        lda is_rle
        beq read_sector_next_byte ; not waiting for an RLE count
; reset the RLE flag
            lda #0
            sta is_rle
; load the RLE count & write decompressed data
            lda temp1
            cmp #$ff
            bne read_sector_rle ; rle_count != 0xff
; store an escaped 0xff
                jmp read_sector_single
                

read_sector_rle:
            sta rle_count
            inc rle_count ; add back part of the minimum length
            jmp read_sector_store_chars

read_sector_next_byte:
        lda temp1
        cmp #RLE_CODE
        beq read_sector_is_rle ; got RLE code. next char is the count


; got a standalone char
read_sector_single:
    sta last_char
    lda #1
    sta rle_count

read_sector_store_chars:
; switch out kernal ROM
    sei ; no interrupts without kernal ROM
    lda #KERNAL_OUT
    sta PORT_REG

read_sector_store_chars2:
    lda last_char
tile_dst_mod:
    sta $ffff ; self modifying dst
    ADD_LITERAL16 tile_dst_mod + 1, tile_dst_mod + 1, 1 ; next dst byte
; next character in RLE counter
    dec rle_count
    bne read_sector_store_chars2

; switch in kernal ROM
        lda #KERNAL_IN
        sta PORT_REG
        cli ; enable interrupts

; test for end of tile
        lda tile_dst_mod + 1 
        cmp tile_end
        bne read_sector_continue
            lda tile_dst_mod + 2
            cmp tile_end + 1
            bne read_sector_continue
; tile finished
.ifdef ENABLE_DEBUG
                PRINT_TEXT tile_done
                lda #$00
                jsr CIOUT
.endif

                inc sector_offset
                beq read_sector_flushed ; tile ended on the end of a sector

; more data in the sector
                SET_IO_STATE read_sector_flush
                rts




read_sector_is_rle:
    lda #1
    sta is_rle

read_sector_continue:
        inc sector_offset
        bne read_sector2

; end of sector. 
; get next sector until tile is finished.
    ldx current_track
    inc current_sector
    lda current_sector
    cmp sectors_per_track,x
    bne read_sector3
        inc current_track
        lda #0
        sta current_sector
read_sector3:
    SET_IO_STATE start_read
    
            

read_sector2:
    rts




; flush rest of sector to get fastloader back into idle
read_sector_flush:
    ldx #8
    sei
read_sector_flush3:
    CLKLO
    nop
    nop
    nop
    nop
    CLKHI
    nop
    nop
    nop
    nop
    dex
    bne read_sector_flush3
        cli
        inc sector_offset
        beq read_sector_flushed
            rts

read_sector_flushed:
    SET_IO_STATE io_finished_state
    rts

; last sector + 1 in each track
sectors_per_track:
; track 0
    .byte 0
; track 1 - 17
    .byte 21, 21, 21, 21, 21, 21, 21, 21
    .byte 21, 21, 21, 21, 21, 21, 21, 21
    .byte 21
; track 18 - 24
    .byte 19, 19, 19, 19, 19, 19, 19
; track 25-30
    .byte 18, 18, 18, 18, 18, 18
; track 31-35
    .byte 17, 17, 17, 17, 17


loading_loader:
    .byte "loading loader"
    .byte $0a, $00    ; null terminator for the message
loader_started:
    .byte "loader started"
    .byte $0a, $00    ; null terminator for the message
read_finished:
    .byte "read finished"
    .byte $0a, $00
tile_done:
    .byte "tile done"
    .byte $0a, $00
reading_track_sector:
    .byte "reading track/sector "
    .byte $00    ; null terminator for the message

.include "fastload.inc"
