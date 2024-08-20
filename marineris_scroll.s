; we only go 1 way in this game

;GRANULARITY = 7

left_BMP0_to_BMP1_256:
.ifdef GRANULARITY
    txa
    and #GRANULARITY
    bne left_BMP0_to_BMP1_256_continue
        txa
        pha
        jsr io_state
        pla
        tax
.endif
left_BMP0_to_BMP1_256_continue:
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
.ifdef GRANULARITY
    txa
    and #GRANULARITY
    bne left_BMP0_to_BMP1_64_continue
        txa
        pha
        jsr io_state
        pla
        tax
.endif
left_BMP0_to_BMP1_64_continue:
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
.ifdef GRANULARITY
    txa
    and #GRANULARITY
    bne left_BMP1_to_BMP0_256_continue
        txa
        pha
        jsr io_state
        pla
        tax
.endif
left_BMP1_to_BMP0_256_continue:
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
.ifdef GRANULARITY
    txa
    and #GRANULARITY
    bne left_BMP1_to_BMP0_64_continue
        txa
        pha
        jsr io_state
        pla
        tax
.endif
left_BMP1_to_BMP0_64_continue:
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




left_BMP1SCREEN_to_BMP0SCREEN:
    lda BMP1_SCREEN - 216 + 40 * 0,x
    sta BMP0_SCREEN - 217 + 40 * 0,x
    lda BMP1_SCREEN - 216 + 40 * 1,x
    sta BMP0_SCREEN - 217 + 40 * 1,x
    lda BMP1_SCREEN - 216 + 40 * 2,x
    sta BMP0_SCREEN - 217 + 40 * 2,x
    lda BMP1_SCREEN - 216 + 40 * 3,x
    sta BMP0_SCREEN - 217 + 40 * 3,x
    lda BMP1_SCREEN - 216 + 40 * 4,x
    sta BMP0_SCREEN - 217 + 40 * 4,x
    lda BMP1_SCREEN - 216 + 40 * 5,x
    sta BMP0_SCREEN - 217 + 40 * 5,x
    lda BMP1_SCREEN - 216 + 40 * 6,x
    sta BMP0_SCREEN - 217 + 40 * 6,x
    lda BMP1_SCREEN - 216 + 40 * 7,x
    sta BMP0_SCREEN - 217 + 40 * 7,x
    lda BMP1_SCREEN - 216 + 40 * 8,x
    sta BMP0_SCREEN - 217 + 40 * 8,x
    lda BMP1_SCREEN - 216 + 40 * 9,x
    sta BMP0_SCREEN - 217 + 40 * 9,x
    lda BMP1_SCREEN - 216 + 40 * 10,x
    sta BMP0_SCREEN - 217 + 40 * 10,x
    lda BMP1_SCREEN - 216 + 40 * 11,x
    sta BMP0_SCREEN - 217 + 40 * 11,x
    lda BMP1_SCREEN - 216 + 40 * 12,x
    sta BMP0_SCREEN - 217 + 40 * 12,x
    lda BMP1_SCREEN - 216 + 40 * 13,x
    sta BMP0_SCREEN - 217 + 40 * 13,x
    lda BMP1_SCREEN - 216 + 40 * 14,x
    sta BMP0_SCREEN - 217 + 40 * 14,x
    lda BMP1_SCREEN - 216 + 40 * 15,x
    sta BMP0_SCREEN - 217 + 40 * 15,x
    lda BMP1_SCREEN - 216 + 40 * 16,x
    sta BMP0_SCREEN - 217 + 40 * 16,x
    lda BMP1_SCREEN - 216 + 40 * 17,x
    sta BMP0_SCREEN - 217 + 40 * 17,x
    lda BMP1_SCREEN - 216 + 40 * 18,x
    sta BMP0_SCREEN - 217 + 40 * 18,x
    lda BMP1_SCREEN - 216 + 40 * 19,x
    sta BMP0_SCREEN - 217 + 40 * 19,x
    lda BMP1_SCREEN - 216 + 40 * 20,x
    sta BMP0_SCREEN - 217 + 40 * 20,x
    lda BMP1_SCREEN - 216 + 40 * 21,x
    sta BMP0_SCREEN - 217 + 40 * 21,x
    lda BMP1_SCREEN - 216 + 40 * 22,x
    sta BMP0_SCREEN - 217 + 40 * 22,x
    lda BMP1_SCREEN - 216 + 40 * 23,x
    sta BMP0_SCREEN - 217 + 40 * 23,x
    lda BMP1_SCREEN - 216 + 40 * 24,x
    sta BMP0_SCREEN - 217 + 40 * 24,x
    inx
    bne left_BMP1SCREEN_to_BMP0SCREENb
    rts
left_BMP1SCREEN_to_BMP0SCREENb:
    jmp left_BMP1SCREEN_to_BMP0SCREEN

left_BMP0SCREEN_to_BMP1SCREEN:
    lda BMP0_SCREEN - 216 + 40 * 0,x
    sta BMP1_SCREEN - 217 + 40 * 0,x
    lda BMP0_SCREEN - 216 + 40 * 1,x
    sta BMP1_SCREEN - 217 + 40 * 1,x
    lda BMP0_SCREEN - 216 + 40 * 2,x
    sta BMP1_SCREEN - 217 + 40 * 2,x
    lda BMP0_SCREEN - 216 + 40 * 3,x
    sta BMP1_SCREEN - 217 + 40 * 3,x
    lda BMP0_SCREEN - 216 + 40 * 4,x
    sta BMP1_SCREEN - 217 + 40 * 4,x
    lda BMP0_SCREEN - 216 + 40 * 5,x
    sta BMP1_SCREEN - 217 + 40 * 5,x
    lda BMP0_SCREEN - 216 + 40 * 6,x
    sta BMP1_SCREEN - 217 + 40 * 6,x
    lda BMP0_SCREEN - 216 + 40 * 7,x
    sta BMP1_SCREEN - 217 + 40 * 7,x
    lda BMP0_SCREEN - 216 + 40 * 8,x
    sta BMP1_SCREEN - 217 + 40 * 8,x
    lda BMP0_SCREEN - 216 + 40 * 9,x
    sta BMP1_SCREEN - 217 + 40 * 9,x
    lda BMP0_SCREEN - 216 + 40 * 10,x
    sta BMP1_SCREEN - 217 + 40 * 10,x
    lda BMP0_SCREEN - 216 + 40 * 11,x
    sta BMP1_SCREEN - 217 + 40 * 11,x
    lda BMP0_SCREEN - 216 + 40 * 12,x
    sta BMP1_SCREEN - 217 + 40 * 12,x
    lda BMP0_SCREEN - 216 + 40 * 13,x
    sta BMP1_SCREEN - 217 + 40 * 13,x
    lda BMP0_SCREEN - 216 + 40 * 14,x
    sta BMP1_SCREEN - 217 + 40 * 14,x
    lda BMP0_SCREEN - 216 + 40 * 15,x
    sta BMP1_SCREEN - 217 + 40 * 15,x
    lda BMP0_SCREEN - 216 + 40 * 16,x
    sta BMP1_SCREEN - 217 + 40 * 16,x
    lda BMP0_SCREEN - 216 + 40 * 17,x
    sta BMP1_SCREEN - 217 + 40 * 17,x
    lda BMP0_SCREEN - 216 + 40 * 18,x
    sta BMP1_SCREEN - 217 + 40 * 18,x
    lda BMP0_SCREEN - 216 + 40 * 19,x
    sta BMP1_SCREEN - 217 + 40 * 19,x
    lda BMP0_SCREEN - 216 + 40 * 20,x
    sta BMP1_SCREEN - 217 + 40 * 20,x
    lda BMP0_SCREEN - 216 + 40 * 21,x
    sta BMP1_SCREEN - 217 + 40 * 21,x
    lda BMP0_SCREEN - 216 + 40 * 22,x
    sta BMP1_SCREEN - 217 + 40 * 22,x
    lda BMP0_SCREEN - 216 + 40 * 23,x
    sta BMP1_SCREEN - 217 + 40 * 23,x
    lda BMP0_SCREEN - 216 + 40 * 24,x
    sta BMP1_SCREEN - 217 + 40 * 24,x
    inx
    bne left_BMP0SCREEN_to_BMP1SCREENb
    rts
left_BMP0SCREEN_to_BMP1SCREENb:
    jmp left_BMP0SCREEN_to_BMP1SCREEN

left_COLOR:
    lda COLOR_DST - 216 + 40 * 0,x
    sta COLOR_DST - 217 + 40 * 0,x
    lda COLOR_DST - 216 + 40 * 1,x
    sta COLOR_DST - 217 + 40 * 1,x
    lda COLOR_DST - 216 + 40 * 2,x
    sta COLOR_DST - 217 + 40 * 2,x
    lda COLOR_DST - 216 + 40 * 3,x
    sta COLOR_DST - 217 + 40 * 3,x
    lda COLOR_DST - 216 + 40 * 4,x
    sta COLOR_DST - 217 + 40 * 4,x
    lda COLOR_DST - 216 + 40 * 5,x
    sta COLOR_DST - 217 + 40 * 5,x
    lda COLOR_DST - 216 + 40 * 6,x
    sta COLOR_DST - 217 + 40 * 6,x
    lda COLOR_DST - 216 + 40 * 7,x
    sta COLOR_DST - 217 + 40 * 7,x
    lda COLOR_DST - 216 + 40 * 8,x
    sta COLOR_DST - 217 + 40 * 8,x
    lda COLOR_DST - 216 + 40 * 9,x
    sta COLOR_DST - 217 + 40 * 9,x
    lda COLOR_DST - 216 + 40 * 10,x
    sta COLOR_DST - 217 + 40 * 10,x
    lda COLOR_DST - 216 + 40 * 11,x
    sta COLOR_DST - 217 + 40 * 11,x
    lda COLOR_DST - 216 + 40 * 12,x
    sta COLOR_DST - 217 + 40 * 12,x
    lda COLOR_DST - 216 + 40 * 13,x
    sta COLOR_DST - 217 + 40 * 13,x
    lda COLOR_DST - 216 + 40 * 14,x
    sta COLOR_DST - 217 + 40 * 14,x
    lda COLOR_DST - 216 + 40 * 15,x
    sta COLOR_DST - 217 + 40 * 15,x
    lda COLOR_DST - 216 + 40 * 16,x
    sta COLOR_DST - 217 + 40 * 16,x
    lda COLOR_DST - 216 + 40 * 17,x
    sta COLOR_DST - 217 + 40 * 17,x
    lda COLOR_DST - 216 + 40 * 18,x
    sta COLOR_DST - 217 + 40 * 18,x
    lda COLOR_DST - 216 + 40 * 19,x
    sta COLOR_DST - 217 + 40 * 19,x
    lda COLOR_DST - 216 + 40 * 20,x
    sta COLOR_DST - 217 + 40 * 20,x
    lda COLOR_DST - 216 + 40 * 21,x
    sta COLOR_DST - 217 + 40 * 21,x
    lda COLOR_DST - 216 + 40 * 22,x
    sta COLOR_DST - 217 + 40 * 22,x
    lda COLOR_DST - 216 + 40 * 23,x
    sta COLOR_DST - 217 + 40 * 23,x
    lda COLOR_DST - 216 + 40 * 24,x
    sta COLOR_DST - 217 + 40 * 24,x
    inx
    bne left_COLORb
    rts
left_COLORb:
    jmp left_COLOR


