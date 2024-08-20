GRANULARITY = 7

left_BMP0_to_BMP1_256:
    txa
    and #GRANULARITY
    bne left_BMP0_to_BMP1_256_continue
        txa
        pha
        jsr io_state
        pla
        tax
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
    txa
    and #GRANULARITY
    bne left_BMP0_to_BMP1_64_continue
        txa
        pha
        jsr io_state
        pla
        tax
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
    txa
    and #GRANULARITY
    bne left_BMP1_to_BMP0_256_continue
        txa
        pha
        jsr io_state
        pla
        tax
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
    txa
    and #GRANULARITY
    bne left_BMP1_to_BMP0_64_continue
        txa
        pha
        jsr io_state
        pla
        tax
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


