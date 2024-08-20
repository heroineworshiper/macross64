; test sector read
;DEBUG_SECTOR = 1

; sector buffer for testing
SECTOR_DST = $c000

; variables
sector_offset := $ff ; offset when loading/printing sector
is_rle        := $fe ; got an RLE code.  Next byte is an RLE count
rle_count     := $fd
last_char     := $fc ; last character before RLE code
tile_end      := $fa ; 2 bytes. end of tile buffer being loaded



