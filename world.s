; dimensions in cells
WORLD_W := 320
WORLD_H := 200
TILE_W := 40
TILE_H := 25
W_TILES := 8
H_TILES := 8
RLE_CODE := $ff

tracks:
    .byte 1, 1, 1, 1, 1, 1, 1, 1
    .byte 1, 1, 1, 1, 1, 1, 2, 2
    .byte 2, 2, 2, 2, 2, 2, 3, 3
    .byte 3, 3, 3, 3, 3, 3, 4, 4
    .byte 4, 4, 4, 4, 4, 5, 5, 5
    .byte 5, 5, 5, 5, 5, 6, 6, 6
    .byte 6, 6, 6, 6, 6, 6, 6, 6
    .byte 6, 6, 6, 7, 7, 7, 7, 7
sectors:
    .byte 0, 1, 3, 4, 5, 7, 9, 11
    .byte 12, 14, 15, 18, 19, 20, 0, 1
    .byte 4, 6, 8, 12, 16, 20, 2, 3
    .byte 5, 7, 9, 12, 17, 20, 2, 4
    .byte 5, 7, 9, 13, 18, 1, 5, 7
    .byte 9, 11, 12, 16, 19, 0, 2, 3
    .byte 4, 6, 7, 10, 11, 12, 14, 15
    .byte 16, 18, 19, 0, 1, 2, 4, 5

char_set:
    .byte $54, $54, $52, $52, $4a, $4a, $2a, $2a ; char 0x00
    .byte $15, $15, $85, $85, $a1, $a1, $a8, $a8 ; char 0x01
    .byte $55, $55, $55, $55, $54, $52, $4a, $2a ; char 0x02
    .byte $54, $52, $4a, $2a, $aa, $aa, $aa, $aa ; char 0x03
    .byte $55, $55, $55, $55, $55, $55, $50, $0a ; char 0x04
    .byte $55, $55, $55, $55, $55, $00, $aa, $aa ; char 0x05
    .byte $55, $55, $55, $55, $55, $55, $00, $aa ; char 0x06
    .byte $15, $85, $a1, $a8, $aa, $aa, $aa, $aa ; char 0x07
    .byte $55, $55, $55, $55, $05, $a0, $aa, $aa ; char 0x08
    .byte $55, $55, $55, $55, $55, $55, $05, $a0 ; char 0x09
    .byte $55, $55, $55, $55, $15, $85, $a1, $a8 ; char 0x0a
    .byte $05, $a0, $aa, $aa, $aa, $aa, $aa, $aa ; char 0x0b
    .byte $55, $55, $05, $a0, $aa, $aa, $aa, $aa ; char 0x0c
    .byte $55, $55, $55, $00, $aa, $aa, $aa, $aa ; char 0x0d
    .byte $00, $55, $55, $55, $55, $55, $55, $55 ; char 0x0e
    .byte $55, $55, $55, $55, $00, $aa, $aa, $aa ; char 0x0f
    .byte $54, $54, $54, $54, $52, $52, $52, $52 ; char 0x10
    .byte $4a, $4a, $4a, $4a, $2a, $2a, $2a, $2a ; char 0x11
    .byte $55, $55, $00, $aa, $aa, $aa, $aa, $aa ; char 0x12
    .byte $55, $00, $aa, $aa, $aa, $aa, $aa, $aa ; char 0x13
    .byte $54, $54, $54, $54, $54, $54, $54, $54 ; char 0x14
    .byte $52, $52, $52, $52, $52, $52, $52, $52 ; char 0x15
    .byte $55, $55, $55, $55, $50, $0a, $aa, $aa ; char 0x16
    .byte $55, $55, $50, $0a, $aa, $aa, $aa, $aa ; char 0x17
    .byte $50, $0a, $aa, $aa, $aa, $aa, $aa, $aa ; char 0x18
    .byte $4a, $4a, $4a, $4a, $4a, $4a, $4a, $4a ; char 0x19
    .byte $15, $15, $15, $15, $85, $85, $85, $85 ; char 0x1a
    .byte $52, $52, $52, $52, $54, $54, $54, $54 ; char 0x1b
    .byte $14, $14, $84, $84, $a0, $a0, $a8, $a8 ; char 0x1c
    .byte $15, $15, $85, $85, $a1, $a1, $a8, $00 ; char 0x1d
    .byte $00, $54, $50, $50, $44, $44, $14, $14 ; char 0x1e
    .byte $54, $54, $54, $54, $54, $54, $44, $44 ; char 0x1f
    .byte $54, $54, $52, $52, $4a, $4a, $2a, $00 ; char 0x20
    .byte $55, $55, $54, $54, $50, $50, $41, $41 ; char 0x21
    .byte $04, $04, $14, $14, $54, $54, $44, $44 ; char 0x22
    .byte $54, $44, $44, $04, $04, $04, $04, $04 ; char 0x23
    .byte $15, $15, $14, $14, $10, $10, $11, $11 ; char 0x24
    .byte $05, $05, $14, $14, $50, $50, $41, $41 ; char 0x25
    .byte $55, $45, $45, $05, $05, $05, $05, $05 ; char 0x26
    .byte $04, $04, $04, $04, $04, $04, $04, $04 ; char 0x27
    .byte $04, $04, $14, $14, $54, $54, $54, $54 ; char 0x28
    .byte $05, $05, $15, $15, $55, $55, $55, $55 ; char 0x29
    .byte $55, $55, $56, $56, $5a, $5a, $6a, $6a ; char 0x2a
    .byte $15, $15, $16, $16, $1a, $1a, $2a, $2a ; char 0x2b
    .byte $54, $54, $52, $52, $4a, $4a, $00, $00 ; char 0x2c
    .byte $56, $56, $59, $59, $65, $65, $95, $95 ; char 0x2d
    .byte $00, $54, $52, $52, $4a, $4a, $00, $2a ; char 0x2e
    .byte $00, $54, $52, $52, $4a, $4a, $2a, $2a ; char 0x2f
    .byte $00, $14, $14, $14, $14, $14, $14, $14 ; char 0x30
    .byte $00, $55, $55, $55, $54, $54, $51, $51 ; char 0x31
    .byte $00, $45, $15, $15, $55, $55, $55, $55 ; char 0x32
    .byte $14, $14, $14, $14, $14, $14, $14, $00 ; char 0x33
    .byte $55, $55, $55, $55, $54, $54, $51, $51 ; char 0x34
    .byte $45, $45, $15, $15, $55, $55, $55, $55 ; char 0x35
    .byte $15, $15, $15, $15, $15, $15, $15, $00 ; char 0x36
    .byte $00, $00, $00, $01, $01, $05, $05, $15 ; char 0x37
    .byte $15, $55, $55, $55, $55, $55, $55, $55 ; char 0x38
    .byte $00, $15, $85, $85, $a1, $a1, $a8, $a8 ; char 0x39
    .byte $00, $15, $15, $15, $15, $15, $15, $15 ; char 0x3a
    .byte $00, $54, $54, $54, $54, $54, $54, $54 ; char 0x3b
    .byte $14, $14, $12, $12, $0a, $0a, $2a, $2a ; char 0x3c
    .byte $54, $54, $54, $54, $54, $54, $54, $51 ; char 0x3d
    .byte $51, $51, $51, $51, $51, $51, $51, $45 ; char 0x3e
    .byte $45, $45, $45, $45, $45, $45, $45, $00 ; char 0x3f
    .byte $55, $55, $55, $55, $55, $55, $55, $aa ; char 0x40
    .byte $56, $56, $59, $59, $65, $65, $95, $aa ; char 0x41
    .byte $55, $55, $55, $55, $55, $55, $54, $54 ; char 0x42
    .byte $50, $52, $4a, $4a, $2a, $2a, $aa, $aa ; char 0x43
    .byte $00, $55, $55, $55, $55, $55, $54, $54 ; char 0x44
    .byte $01, $a1, $81, $81, $21, $21, $a1, $a1 ; char 0x45
    .byte $52, $52, $4a, $4a, $2a, $2a, $aa, $aa ; char 0x46
    .byte $52, $52, $52, $52, $52, $52, $12, $12 ; char 0x47
    .byte $52, $52, $4a, $4a, $2a, $2a, $aa, $00 ; char 0x48
    .byte $55, $55, $55, $55, $55, $55, $54, $00 ; char 0x49
    .byte $54, $54, $50, $50, $41, $41, $05, $05 ; char 0x4a
    .byte $12, $12, $52, $52, $52, $52, $12, $12 ; char 0x4b
    .byte $55, $55, $55, $54, $54, $54, $54, $54 ; char 0x4c
    .byte $51, $11, $11, $11, $11, $11, $11, $11 ; char 0x4d
    .byte $54, $54, $50, $50, $41, $41, $45, $45 ; char 0x4e
    .byte $14, $14, $50, $50, $41, $41, $05, $05 ; char 0x4f
    .byte $54, $14, $14, $14, $14, $14, $14, $14 ; char 0x50
    .byte $11, $11, $11, $11, $11, $11, $11, $11 ; char 0x51
    .byte $54, $54, $54, $54, $55, $55, $55, $55 ; char 0x52
    .byte $01, $01, $01, $01, $55, $55, $55, $55 ; char 0x53
    .byte $14, $14, $14, $14, $14, $14, $14, $14 ; char 0x54
    .byte $12, $12, $52, $52, $52, $52, $52, $52 ; char 0x55
    .byte $15, $15, $55, $55, $55, $55, $55, $55 ; char 0x56
    .byte $56, $56, $5a, $5a, $6a, $6a, $aa, $aa ; char 0x57
    .byte $14, $14, $14, $14, $15, $15, $15, $15 ; char 0x58
    .byte $54, $54, $50, $50, $48, $48, $28, $28 ; char 0x59
    .byte $15, $85, $a1, $a8, $0a, $50, $55, $55 ; char 0x5a
    .byte $55, $55, $55, $55, $15, $85, $01, $50 ; char 0x5b
    .byte $55, $55, $55, $55, $40, $4a, $2a, $2a ; char 0x5c
    .byte $55, $55, $55, $55, $05, $85, $05, $05 ; char 0x5d
    .byte $55, $55, $55, $55, $15, $55, $55, $55 ; char 0x5e
    .byte $55, $55, $55, $55, $55, $54, $54, $50 ; char 0x5f
    .byte $54, $54, $51, $01, $51, $51, $51, $51 ; char 0x60
    .byte $54, $54, $52, $50, $52, $52, $52, $52 ; char 0x61
    .byte $55, $55, $55, $55, $50, $50, $50, $50 ; char 0x62
    .byte $50, $50, $50, $50, $50, $50, $51, $51 ; char 0x63
    .byte $4a, $4a, $4a, $4a, $5a, $5a, $6a, $6a ; char 0x64
    .byte $52, $52, $52, $52, $55, $55, $55, $55 ; char 0x65
    .byte $55, $55, $55, $55, $aa, $aa, $aa, $aa ; char 0x66
    .byte $51, $51, $52, $52, $aa, $aa, $aa, $aa ; char 0x67
    .byte $05, $a0, $aa, $aa, $2a, $ca, $f2, $fc ; char 0x68
