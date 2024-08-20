.include        "cbm_kernal.inc"

; secondary & logical addresses for the world drive
CONTROL = 15
WORLD_DRIVE = 8
; sector buffer for testing
SECTOR_DST = $c000
; start of loader in drive memory
LOADER_START = $0400
; bytes per m-w command.  Maximum is 42-6 but the manual says 34
LOADER_FRAGMENT = 34

.segment "DATA"
temp1: .res 2
temp2: .res 2
temp3: .res 2
current_track: .res 1
current_sector: .res 2
sector_offset: .res 1
pointer: .res 2
counter: .res 1
; times
profile1: .res 2
profile2: .res 2
profile3: .res 2
profile4: .res 2
; debug buffer
debug_buf: .res 32

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



; printer device number
PRINTER = 4

; macros
.macro SET_LITERAL8 address, value
    lda #value
    sta address
.endmacro

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

; branch if address content >= literal
.macro BRANCH_GREATEREQUAL16 address, literal, where
    sec
    lda address
    sbc #<literal ; low
    lda address + 1
    sbc #>literal ; high
    bcs where
.endmacro

; branch if address content < literal
.macro BRANCH_LESS16 address, literal, where
    sec
    lda address
    sbc #<literal ; low
    lda address + 1
    sbc #>literal ; high
    bcc where
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
.endmacro

.macro PRINT_HEX8 address
    ldy address
    jsr print_hex8
    lda #' '
    jsr CIOUT
.endmacro

.macro INIT_DEBUG
; open the printer page 338
    lda #7 ; logical number
    ldx #PRINTER ; device number
    ldy #7 ; secondary address
    jsr SETLFS

    jsr OPEN
.endmacro

.macro SELECT_PRINTER
; direct CIOUT to the printer
    lda #PRINTER
    jsr LISTEN
.endmacro

; setup timer for profiling
.macro INIT_PROFILER
    lda #$ff   ; reset CIA 2 timer A
    sta d2t1h
    sta d2t2l  ; reset CIA 2 timer B
    lda #$11
    sta d2cra  ; start timer A
    lda #$51
    sta d2crb  ; run timer B off of timer A
.endmacro

.macro GET_TIME dst
    lda #$ff
    sbc d2t1h ; get CIA 2 timer A
    sta dst
    lda #$ff
    sbc d2t2l ; get CIA 2 timer B
    sta dst + 1
    lda #$ff ; reset the clock
    sta d2t1h
    sta d2t2l
    lda #$11
    sta d2cra
    lda #$51
    sta d2crb
.endmacro


.macro SELECT_CONTROL
    lda #WORLD_DRIVE ; write to the command channel
    jsr LISTEN
    lda #(CONTROL | $60) ; secondary address needs to be ored with 0x60
    jsr SECOND
.endmacro


;set clock & data line high (inverted)
.macro CLKDATHI
	lda d2pra
	and #($ff - CLK_OUT - DAT_OUT)
	sta d2pra
.endmacro

;set clock line high (inverted)
.macro CLKHI
	lda d2pra
	and #($ff-CLK_OUT)
	sta d2pra
.endmacro

;set clock line low  (inverted)
.macro CLKLO
	lda d2pra
	ora #CLK_OUT
	sta d2pra
.endmacro

;set data line high (inverted)
.macro DATHI
	lda d2pra
	and #($ff-DAT_OUT)
	sta d2pra
.endmacro

;set data line low (inverted)
.macro DATLO
	lda d2pra
	ora #DAT_OUT
	sta d2pra
.endmacro

;set ATN line high (inverted)
.macro ATNHI
	lda d2pra
	and #($ff-ATN_OUT)
	sta d2pra
.endmacro

;set ATN line low (inverted)
.macro ATNLO
	lda d2pra
	ora #ATN_OUT
	sta d2pra
.endmacro


.segment	"START"

    .byte $01, $08, $0b, $08, $13, $02, $9e, $32, $30, $36, $31, $00, $00, $00

.segment	"CODE"
mane:
    INIT_DEBUG

; print something
    SELECT_PRINTER
    PRINT_TEXT welcome

FASTLOAD_SIZE := (fastload_end - fastload_start)

    ldy #>FASTLOAD_SIZE
    jsr print_hex8
    ldy #<FASTLOAD_SIZE
    jsr print_hex8
    lda #$0a
    jsr CIOUT

    ldy #>fastload_end
    jsr print_hex8
    ldy #<fastload_end
    jsr print_hex8
    lda #$0a
    jsr CIOUT
    ldy #>temp1
    jsr print_hex8
    ldy #<temp1
    jsr print_hex8
    lda #$0a
    jsr CIOUT

    PRINT_TEXT loading
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


    

; load the fastloader
    SET_LITERAL16 pointer, LOADER_START
loader_loop:
;    SELECT_PRINTER
;    PRINT_HEX16 loader_mod1 + 1
;    lda #$0a
;    jsr CIOUT

    SELECT_CONTROL
    lda #'m'
    jsr CIOUT
    lda #'-'
    jsr CIOUT
    lda #'w'
    jsr CIOUT
    lda pointer ; send dst address
    jsr CIOUT
    lda pointer + 1
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
        ADD_LITERAL16 pointer, pointer, LOADER_FRAGMENT
        BRANCH_GREATEREQUAL16 loader_mod1 + 1, fastload_end, loader_done
            jmp loader_loop

loader_done:
;    jsr verify
    SELECT_PRINTER
    PRINT_TEXT running


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

; last LISTEN call
    SELECT_PRINTER

    CLKDATHI


    sei ; disable interrupts


;    ldx #24
;delay2:
; delay 100ms
    ldy #100
delay:
    jsr delay1ms
    dey
    bne delay
;        dex
;        bne delay2
;    jsr read_debug
    PRINT_TEXT loader_started
    lda #4
    sta current_track
    lda #0
    sta current_sector

loop:


    ATNLO
    nop
    nop
    nop
    nop
    ATNHI



; send the sector & track number
    lda current_track
    sta temp1 ; track
    lda current_sector
    sta temp2 ; sector
    PRINT_TEXT reading_track_sector
    PRINT_HEX8 current_track
    PRINT_HEX8 current_sector
    lda #$0a
    jsr CIOUT

    ldx #16
start_read:
    CLKLO
    ror temp1
    ror temp2
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
    bne start_read


    DATHI





; wait for clock low to indicate read started
wait_loader3:
    lda d2pra
    and #CLK_IN
    bne wait_loader3
; wait for clock high to indicate read complete
wait_loader4:
    lda d2pra
    and #CLK_IN
    beq wait_loader4



; read out 255 bytes
;    ldy #1
    ldy#0
byte_loop:
    ldx #8

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

        lda temp1
;        sta SECTOR_DST - 1, y
        sta SECTOR_DST, y
        iny
        bne byte_loop


    PRINT_TEXT sector_done
    jsr print_sector

    inc current_sector
    ldx current_track
    lda current_sector
    cmp sectors_per_track,x
    bne loop2
        lda #0
        sta current_sector
        inc current_track
        lda current_track
        cmp #36
        beq donechak

loop2:
    jmp loop

; really done
donechak:
    ldx #3
    jsr CHKOUT
    rts


read_debug:
    ldy #0 ; buffer pointer
read_debug_byte:
    ldx #8
read_debug1: ; wait for CLK low
    jsr debpia
    bmi read_debug1 ; N = 1

read_debug2: ; wait for CLK high
    jsr debpia
    bpl read_debug2 ; N = 0

    ror temp1 ; shift carry into output
    dex
    bne read_debug1
; byte complete
        lda temp1
        jsr CHROUT
        sta debug_buf,y
        beq debug_done ; done if 0
            iny
; next byte
            jmp read_debug_byte
; print the buffer
debug_done:
    SELECT_PRINTER


    ldy 0
debug_done2:
    lda debug_buf,y
    beq debug_done3
        jsr CIOUT
        iny
        jmp debug_done2
debug_done3:
    rts

;loop:
;    ldy #$ff
;loop2:
;    jsr delay1ms ; delay
;    dey
;    bne loop2

;    lda d2pra
;    and #$c0 ; show data & clock in
;    tay
;    jsr print_hex8
;    lda #$0a
;    jsr CIOUT
;    jmp loop



verify:
; read back the fastloader
    SET_LITERAL16 pointer, LOADER_START
    SELECT_PRINTER
    PRINT_TEXT verifying_text

verify_loop:
    SELECT_CONTROL
    lda #'m'
    jsr CIOUT
    lda #'-'
    jsr CIOUT
    lda #'r'
    jsr CIOUT
    lda pointer
    jsr CIOUT
    lda pointer + 1
    jsr CIOUT
    lda #8 ; number of bytes
    jsr CIOUT
    jsr UNLSN ; execute the command

    lda #8
    sta temp2
verify_loop2:
    lda #WORLD_DRIVE ; read from the control channel
    jsr TALK
    lda #(CONTROL | $60) ; secondary address needs to be ored with 0x60
    jsr TKSA
    
    jsr ACPTR
    sta temp1
    SELECT_PRINTER
    PRINT_HEX8 temp1
verify_mod:
    lda fastload_start ; load from src address
    cmp temp1 ; compare with readback
    bne verify_fail

; next verify address
        ADD_LITERAL16 verify_mod + 1, verify_mod + 1, 1
        dec temp2
        bne verify_loop2
            lda #$0a ; line feed
            jsr CIOUT

                ADD_LITERAL16 pointer, pointer, 8
                BRANCH_GREATEREQUAL16 verify_mod + 1, fastload_end, verify_success
                    jmp verify_loop
verify_fail:
; mismatch after end of loader
    BRANCH_GREATEREQUAL16 verify_mod + 1, fastload_end, verify_success
; really failed
        SELECT_PRINTER
        PRINT_TEXT verify_fail_text
        lda #$0a
        jsr CIOUT
        lda #$0a
        jsr CIOUT
        jmp donechak

verify_success:
    SELECT_PRINTER
    lda #$0a
    jsr CIOUT
    rts


print:
    ldx #$00          ; initialize X register for indexing
printmod:
    lda $ffff,x       ; load the character from the message
    beq print2        ; if character is zero, we are done
        jsr CIOUT     ; call CIOUT routine to send the character to the serial port
        inx           ; increment X register
        jmp printmod  ; repeat the loop
print2:
    rts

; print the value of Y.  Overwrites A, X
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
    jsr CIOUT
    tya
    and #$0f
    tax
    lda hex_table,x
    jsr CIOUT
    rts




welcome:
    .byte "welcome to macross64"
    .byte $0a, $00    ; null terminator for the message

loading:
    .byte "loading loader"
    .byte $0a, $00    ; null terminator for the message
sector_done:
    .byte "sector done"
    .byte $0a, $00    ; null terminator for the message
running:
    .byte "running loader"
    .byte $0a, $00    ; null terminator for the message
loader_started:
    .byte "loader started"
    .byte $0a, $00    ; null terminator for the message

reading_track_sector:
    .byte $0a
    .byte "reading track/sector "
    .byte $00    ; null terminator for the message

time1:
    .byte "time1: "
    .byte $00    ; null terminator for the message
time2:
    .byte "time2: "
    .byte $00    ; null terminator for the message
time3:
    .byte "time3: "
    .byte $00    ; null terminator for the message
done:
    .byte "done"
    .byte $0a, $0a, $00    ; null terminator for the message
testing_printer:
    .byte "testing printer"
    .byte $0a, $0a, $00    ; null terminator for the message
nodev_text:
    .byte "nodev"
    .byte $0a, $00    ; null terminator for the message
verify_fail_text:
    .byte "verify failed"
    .byte $0a, $00
verifying_text:
    .byte "verifying"
    .byte $0a, $00

clkhi:
	lda d2pra
	and #($ff-CLK_OUT)
	sta d2pra
    rts

;set clock line low  (inverted)
clklo:
	lda d2pra
	ora #CLK_OUT
	sta d2pra
    rts

;set data line high (inverted)
dathi:
	lda d2pra
	and #($ff-DAT_OUT)
	sta d2pra
    rts

;set data line low (inverted)
datlo:
	lda d2pra
	ora #DAT_OUT
	sta d2pra
    rts


debpia:
	lda d2pra       ;debounce the port
	cmp d2pra
	bne debpia
	asl a           ;shift the data bit into the carry...
	rts             ;...and the clock into neg flag

;delay 1ms using loop
delay1ms:
	txa             ;save .x
	ldx #200-16     ;1000us-(1000/500*8=#40us holds)
delay1ms1:	dex             ;5us loop
	bne delay1ms1
	tax             ;restore .x
	rts

;read_sector:
;; reset counter
;    lda #0
;    sta sector_offset
;    SELECT_DATA
;read_loop:
;; read a character
;    jsr ACPTR ; read a character from the drive
;    ldx sector_offset
;    sta SECTOR_DST,x
;    inc sector_offset
;    bne read_loop
;    rts

print_sector:
; reset counter
;    lda #1
    lda #0
    sta sector_offset

print_loop:
    ldx sector_offset
;    lda SECTOR_DST - 1,x
    lda SECTOR_DST,x
    tay
    jsr print_hex8
    lda #' '
    jsr CIOUT
    inc sector_offset
    bne print_loop

        lda #$0a ; newline
        jsr CIOUT
        lda #$0a ; newline
        jsr CIOUT

; print profiling data
;        PRINT_TEXT time1
;        PRINT_HEX16 profile1
;        lda #' '
;        jsr CIOUT
;        PRINT_HEX16 profile2
;        lda #' '
;        jsr CIOUT
;        PRINT_HEX16 profile3
;        lda #$0a
;        jsr CIOUT
;        lda #$0a
;        jsr CIOUT
;        lda #$0a
;        jsr CIOUT
;        lda #$0a
;        jsr CIOUT


        rts ; donechak

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

fastload_start:
.include "fastload.inc"
fastload_end:



