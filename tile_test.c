// test tile decoding

// gcc -o tile_test tile_test.c



#include <stdint.h>
#include <stdio.h>


void main()
{
    uint8_t compressed[] = 
    {
	0x36, 0xff, 0x03, 0x2a, 0x2a, 0x36, 0x00, 0xff, 0x02, 0x36, 0xff, 0x08, 0x00, 0xff, 0x07, 0x36, 
	0xff, 0x05, 0x2a, 0x2a, 0x36, 0xff, 0x03, 0x2a, 0x2a, 0x36, 0x00, 0xff, 0x02, 0x36, 0xff, 0x08, 
	0x00, 0xff, 0x07, 0x36, 0xff, 0x05, 0x2a, 0x2a, 0x36, 0xff, 0x03, 0x2a, 0x2a, 0x36, 0x00, 0xff, 
	0x02, 0x36, 0xff, 0x08, 0x00, 0xff, 0x07, 0x36, 0xff, 0x05, 0x2a, 0x2a, 0x36, 0xff, 0x03, 0x2a, 
	0x2a, 0x36, 0x00, 0xff, 0x02, 0x36, 0xff, 0x08, 0x00, 0xff, 0x07, 0x36, 0xff, 0x05, 0x2a, 0x2a, 
	0x36, 0xff, 0x03, 0x2a, 0x30, 0x36, 0x00, 0xff, 0x02, 0x36, 0xff, 0x08, 0x00, 0xff, 0x07, 0x36, 
	0xff, 0x05, 0x2a, 0x30, 0x36, 0xff, 0x03, 0x30, 0x00, 0xff, 0x04, 0x36, 0xff, 0x06, 0x00, 0xff, 
	0x09, 0x36, 0xff, 0x05, 0x30, 0x00, 0x36, 0xff, 0x03, 0x00, 0xff, 0x05, 0x36, 0xff, 0x05, 0x00, 
	0xff, 0x0a, 0x36, 0xff, 0x05, 0x00, 0xff, 0x04, 0x36, 0x00, 0xff, 0x05, 0x36, 0x00, 0xff, 0x03, 
	0x36, 0x00, 0xff, 0x0a, 0x36, 0x00, 0xff, 0x03, 0x36, 0x00, 0xff, 0xfe, 0x00, 0xff, 0xfe, 0x00, 
	0xff, 0xa8, 0x60, 0xff, 0x05, 0xd0, 0xff, 0x1f, 0x60, 0xff, 0x05, 0xd6, 0xd0, 0xff, 0x1e, 0x60, 
	0xff, 0x06, 0xd6, 0xd0, 0xff, 0x1d, 0x60, 0xff, 0x07, 0xd6, 0xd0, 0xff, 0x1c, 0x60, 0xff, 0x08, 
	0xd6, 0xd0, 0xff, 0x1b, 0x60, 0xff, 0x09, 0xd6, 0xd6, 0xd0, 0xff, 0x19, 0x60, 0xff, 0x0b, 0xd6, 
	0xd6, 0xd0, 0xff, 0x17, 0x60, 0xff, 0x0d, 0xd6, 0xd6, 0xd6, 0xd0, 0xff, 0x14, 0x60, 0xff, 0x10, 
	0xd6, 0xd6, 0xd0, 0xff, 0x12, 0x60, 0xff, 0x12, 0xd6, 0xd6, 0xd0, 0xff, 0x10, 0x60, 0xff, 0x14, 
	0xd6, 0xd0, 0xff, 0x0f, 0x60, 0xff, 0x14, 0x6d, 0xd0, 0xff, 0x0f, 0x60, 0xff, 0x14, 0x6d, 0xd0, 

	0xff, 0x0f, 0x60, 0xff, 0x13, 0x6d, 0xd0, 0xff, 0x10, 0x60, 0xff, 0x12, 0x6d, 0xd0, 0xff, 0x11, 
	0x60, 0xff, 0x11, 0x6d, 0xd0, 0xff, 0x12, 0x60, 0xff, 0x10, 0x6d, 0xd0, 0xff, 0x13, 0x60, 0xff, 
	0x0f, 0x6d, 0xd0, 0xff, 0x14, 0x60, 0xff, 0x0e, 0x6d, 0xd0, 0xff, 0x15, 0x60, 0xff, 0x0e, 0xd0, 
	0xff, 0x16, 0x60, 0xff, 0x0d, 0x6d, 0xd0, 0xff, 0x16, 0x60, 0xff, 0x0d, 0x6d, 0xd0, 0xff, 0x16, 
	0x60, 0xff, 0x0d, 0xd0, 0xff, 0x17, 0x60, 0xff, 0x0d, 0x6d, 0xd0, 0xff, 0x16, 0x60, 0xff, 0x0d, 
	0x6d, 0xd0, 0xff, 0x16, 0x00, 0xff, 0xfe, 0x00, 0xff, 0xf2, 
    };
    
    uint8_t output[2500];
    int output_size = 0;
    int i, j;
    int is_rle = 0;
    int rle_count = 0;
    uint8_t last_char;
    for(i = 0; i < sizeof(compressed); i++)
    {
        if(is_rle)
        {
            is_rle = 0;
            if(compressed[i] == 0xff)
            {
                last_char = 0xff;
                rle_count = 1;
            }
            else
            {
                rle_count = compressed[i] + 1;
            }
        }
        else
        if(compressed[i] == 0xff)
        {
            is_rle = 1;
        }
        else
        {
            last_char = compressed[i];
            rle_count = 1;
        }
        
        if(!is_rle)
        {
            for(j = 0; j < rle_count; j++)
            {
                output[output_size++] = last_char;
                printf("%02x ", last_char);
            }
        }
    }
    
    printf("\n");
    printf("output_size=%d\n", output_size);
}






