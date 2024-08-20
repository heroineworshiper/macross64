; dimensions in cells
WORLD_W := 280
WORLD_H := 25
TILE_W := 40
TILE_H := 25
W_TILES := 7
H_TILES := 1
RLE_CODE := $ff
BG_COLOR := $c

tracks:
    .byte 1, 1, 3, 4, 5, 7, 8
sectors:
    .byte 0, 19, 4, 11, 19, 5, 12

