.include        "cbm_kernal.inc"


.segment "DATA"

temp1: .res 2
temp2: .res 2
temp3: .res 2

.include        "common.inc"



.segment	"START"

    .byte $01, $08, $0b, $08, $13, $02, $9e, $32, $30, $36, $31, $00, $00, $00

.segment	"CODE"
mane:
    INIT_DEBUG
    SELECT_PRINTER
    PRINT_TEXT welcome


    lda #<160
    sta temp1
    lda #>160
    sta temp1 + 1

    ldx #0
compute_col:
    inx
    SUB_LITERAL16 temp1, temp1, 40
    bcs compute_col
        dex
        stx temp2
        PRINT_TEXT result
        PRINT_HEX8 temp2

; restore output
    ldx #3
    jsr CHKOUT
    rts

welcome:
    .byte "welcome to macross64"
    .byte $0a, $00    ; null terminator for the message

result:
    .byte "result "
    .byte $00    ; null terminator for the message

.include "common.s"
