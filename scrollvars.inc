
temp16:       .res    2       ; 2 bytes
bmp_dst:      .res    2       ; the current bitmap
bmp_src:      .res    2       ; the oppposite bitmap for scroll copy
color_ptr:    .res    2       ; the current color map
color_ptr2:   .res    2       ; the oppposite color map for scroll copy
step:         .res    1       ; count the number of loops
current_page: .res    1
