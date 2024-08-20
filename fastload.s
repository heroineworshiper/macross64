; drive resident program for reading sectors
; based on 
; https://github.com/mist64/fastboot1541/blob/master/start.s

; 1541 ROM:
; https://g3sl.github.io/c1541rom.html


.segment	"FCODE"

;ENABLE_DEBUG := 1

; from 1541 ROM
PB := $1800 ; Data port B - Serial data I/O
;Bits for PB
DAT_IN  := $01 ; inverse of line voltage
DAT_OUT := $02 ; inverse of line voltage
CLK_IN   := $04 ; inverse of line voltage
CLK_OUT  := $08 ; inverse of line voltage
ATN_IN   := $80 ; inverse of attention voltage

DSKCNT := $1c00
LED := $08 ; 1 for on

; the sector buffer
BUFFER := $0300
BUFFER_N := 0
BUFFER_ID := $f9

TEMP := $05

; the subroutines
READ_SECTOR := $d586
INIT_DRIVE := $D042
; arguments for the sector read
TRACK := $06
SECTOR := $07
CLKLOW := $e9ae

.macro SET_LITERAL16 address, value
    lda #<value
    sta address
    lda #>value
    sta address + 1
.endmacro


.macro PRINT_TEXT string
    SET_LITERAL16 printmod + 1, string ; self modifying code
    jsr print
.endmacro

; begin
    sei ; disable interrupts
    jsr led_off
	lda #0  ; clock high, data high
	sta PB

;    cli ; enable interrupts
;    jsr $F0DF ; read BAM
;    jsr INIT_DRIVE
;    sei
;    jsr led_off

; delay 100ms
;    ldy #100
;delay:
;    jsr delay1ms
;    dey
;    bne delay

loop:
; wait for ATN low
wait_atn1:
    lda PB
    and #ATN_IN
    beq wait_atn1 ; 0 if high

; wait for ATN high
wait_atn2:
    lda PB
    and #ATN_IN
    bne wait_atn2 ; 1 if low


; copy pin to the LED
;test_pin:
;    lda PB
;    and #DAT_IN
;    bne test_pin2
;        lda DSKCNT
;        and #($ff - LED) ; LED off
;        sta DSKCNT
;        jmp test_pin
;test_pin2:
;        lda DSKCNT
;        ora #LED ; LED on
;        sta DSKCNT
;        jmp test_pin




    ldx #16
read_bit:
; wait for CLK low
    lda PB
    and #CLK_IN
    beq read_bit ; CLK_IN=0 if high

read_bit2:
; wait for CLK high
    lda PB
    and #CLK_IN
    bne read_bit2 ; CLK_IN=1 if low


; read the bit
    clc ; set next bit to 0
    lda PB
    eor #DAT_IN ; invert DAT pin
    ror ; shift DAT into carry
; shift it in, least significant 1st, sector 1st
    ror TRACK
    ror SECTOR
    dex
    bne read_bit

    lda #BUFFER_N
    sta BUFFER_ID ; read into address BUFFER

	lda #CLK_OUT  ; clock low to indicate read started
	sta PB

; must 0 this address or READ_SECTOR head bumps
    lda #0
    sta TEMP

    jsr led_on
    cli ; enable interrupts

.ifdef ENABLE_DEBUG
    lda SECTOR
    jsr blink_debug
.endif


    jsr READ_SECTOR ; minimum time required for host to detect the read starting
    sei ; disable interrupts to send data

; DEBUG
;    lda #0
;    sta BUFFER+255

	lda #0  ; clock high to indicate read finished
	sta PB
;    jsr led_off



; use Y as the byte counter.  Only 255 bytes are usable because of a bug
;    ldy #1
    ldy #0
send_loop:
;	lda BUFFER-1,y ; read from sector
	lda BUFFER,y ; read from sector
    sta TEMP

    ldx #8
bit_loop:
; test for clock low
    lda PB
    and #CLK_IN
    beq bit_loop ; got 0/high

    lda #DAT_OUT ; preload data low, CLK high
    ror TEMP ; next bit into C
    bcc bit_loop1
        lda #0 ; preload data high, CLK high
bit_loop1:
    sta PB

; wait for clock high
bit_loop2:
    lda PB
    and #CLK_IN
    bne bit_loop2 ; 0 = high

; next bit
    dex
    bne bit_loop
; next byte
    	iny
    	bne send_loop


            lda #0
            sta PB ; clock high, data high
            jsr led_off
            jmp loop

; copy CLK to the LED
;test_clk:
;    lda PB
;    and #CLK_IN
;    bne test_clk2
;        lda DSKCNT
;        and #($ff - LED) ; LED off
;        sta DSKCNT
;        jmp test_clk
;test_clk2:
;        lda DSKCNT
;        ora #LED ; LED on
;        sta DSKCNT
;        jmp test_clk

; copy DAT to the LED
;test_dat:
;    lda PB
;    and #DAT_IN
;    bne test_dat2
;        lda DSKCNT
;        and #($ff - LED) ; LED off
;        sta DSKCNT
;        jmp test_dat
;test_dat2:
;        lda DSKCNT
;        ora #LED ; LED on
;        sta DSKCNT
;        jmp test_dat


.ifdef ENABLE_DEBUG
;delay 1ms using loop
delay1ms:
    pha
	txa             ;save X, A
	ldx #200-16     ;1000us-(1000/500*8=#40us holds)
delay1ms1:
	dex             ;5us loop
	bne delay1ms1
	tax             ;restore X, A
    pla
	rts

delay250ms:
    ldy #250
delay250ms2:
    jsr delay1ms
    dey
    bne delay250ms2
        rts
.endif ; ENABLE_DEBUG




led_off:
    pha
    lda DSKCNT
    and #($ff - LED) ; LED off
    sta DSKCNT
    pla
    rts

led_on:
    pha
    lda DSKCNT
    ora #LED ; LED on
    sta DSKCNT
    pla
    rts

hang:
    jmp hang


; blink A
.ifdef ENABLE_DEBUG
blink_debug:
    ldx #8
blink_debug3:
    jsr led_off
    jsr delay250ms
    jsr delay250ms
    jsr delay250ms
    jsr delay250ms
    jsr led_on
    asl
    bcs blink_debug1
        jsr delay250ms
        jmp blink_debug2
blink_debug1:
    jsr delay250ms
    jsr delay250ms
    jsr delay250ms
    jsr delay250ms
blink_debug2:
    dex
    bne blink_debug3
        jsr led_off
        rts
.endif ; ENABLE_DEBUG



;debpia:
;	lda PB       ;debounce the port
;	cmp PB
;	bne debpia
;	rts
