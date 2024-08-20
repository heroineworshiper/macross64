// convert a png image into a series of of multicolor bitmap tiles
// the background color is constant for all tiles so they can 
// scroll into each other



#include <errno.h>
#include <math.h>
#include <png.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>




#define TEXTLEN 1024
#define D64_SIZE 174848
#define SQR(x) ((x) * (x))

// total characters less code for RLE
#define MAX_CHARS 255
// code for RLE
#define RLE_CODE 255

// commodore palette
uint32_t palette[] = 
{
// from c64_16farben.png
    0x000000,
    0xFFFFFF, 
    0x924a40, 
    0x84c5cc, 
    0x583271,
    0x72b14b,
    0x483AAA,
    0xd5df7c,
    0x99692d,
    0x675200,
    0xc18178,
    0x606060,
    0x8a8a8a,
    0xb3ec91,
    0x867ade,
    0xb3b3b3
};

#define PALETTE_SIZE (sizeof(palette) / sizeof(uint32_t))

#define TILE_W 320
#define TILE_H 200

int image_size;
int image_offset;
uint8_t *image_data;
int bg_index;
int total_chars = 0;
int w, h;

void png_read_function(png_structp png_ptr,
               png_bytep data, 
			   png_size_t length)
{
	if(image_size - image_offset < length)
	{
		printf("png_read_function %d: overrun\n", __LINE__);
		length = image_size - image_offset;
	}

	memcpy(data, &image_data[image_offset], length);
	image_offset += length;
};

float color_distance(uint8_t *rgb, int color2)
{
    int palette_r1 = rgb[0];
    int palette_g1 = rgb[1];
    int palette_b1 = rgb[2];
    int palette_r2 = (palette[color2] >> 16) & 0xff;
    int palette_g2 = (palette[color2] >> 8) & 0xff;
    int palette_b2 = palette[color2] & 0xff;
    float distance = sqrt(SQR(palette_r1 - palette_r2) + 
        SQR(palette_g1 - palette_g2) +
        SQR(palette_b1 - palette_b2));
    return distance;
}

int rgb_to_palette(uint8_t *pixel)
{
    float min_distance = -1;
    int min_i = -1;
    int r = pixel[0];
    int g = pixel[1];
    int b = pixel[2];
    for(int i = 0; i < PALETTE_SIZE; i++)
    {
        int palette_r = (palette[i] >> 16) & 0xff;
        int palette_g = (palette[i] >> 8) & 0xff;
        int palette_b = palette[i] & 0xff;
        float distance = sqrt(SQR(palette_r - r) + 
            SQR(palette_g - g) +
            SQR(palette_b - b));
        if(distance < min_distance || i == 0)
        {
            min_distance = distance;
            min_i = i;
        }
    }
    
    return min_i;
}

void write_test_image(uint8_t *bitmap_data, int w, int h)
{
    const char *path = "test_image.png";
    printf("write_test_image %d: writing %s\n", __LINE__, path);
    uint8_t *rgb = malloc(w * 3 * h);
    uint8_t **rows = malloc(sizeof(uint8_t*) * h);
    for(int i = 0; i < h; i++)
    {
        uint8_t *out_row = rgb + i * w * 3;
        uint8_t *in_row = bitmap_data + i * w;
        rows[i] = out_row;
        for(int j = 0; j < w; j++)
        {
            int palette_r = (palette[*in_row] >> 16) & 0xff;
            int palette_g = (palette[*in_row] >> 8) & 0xff;
            int palette_b = palette[*in_row] & 0xff;
            *out_row++ = palette_r;
            *out_row++ = palette_g;
            *out_row++ = palette_b;
            in_row++;
        }
    }
	png_structp png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, 0, 0, 0);
	png_infop info_ptr = png_create_info_struct(png_ptr);
	FILE *out_fd = fopen(path, "w");
	if(!out_fd)
	{
		printf("write_test_image %d %s\n", __LINE__, strerror(errno));
		return;
	}

	int png_cmodel = PNG_COLOR_TYPE_RGB;
	png_init_io(png_ptr, out_fd);
	png_set_compression_level(png_ptr, 9);
	png_set_IHDR(png_ptr, 
		info_ptr, 
		w, 
		h,
    	8, 
		png_cmodel, 
		PNG_INTERLACE_NONE, 
		PNG_COMPRESSION_TYPE_DEFAULT, 
		PNG_FILTER_TYPE_DEFAULT);
	png_write_info(png_ptr, info_ptr);
	png_write_image(png_ptr, rows);
	png_write_end(png_ptr, info_ptr);
	png_destroy_write_struct(&png_ptr, &info_ptr);
	fclose(out_fd);
    free(rgb);
    free(rows);
}

void to_tracksector(int *track, int *sector, int abs_sector)
{
    const int track_sector[] = 
    {
        1, 21,   // starting track, sectors per track
        18, 19,
        25, 18,
        31, 17,
        36, 0
    };
    
    int rows = sizeof(track_sector) / sizeof(int) / 2;
    int current_row = 0;
    int current_track = 1;
    int current_sector = 0;
    for(int i = 1; i <= abs_sector; i++)
    {
        current_sector++;
        int track_sectors = track_sector[current_row * 2 + 1];
        if(current_sector >= track_sectors)
        {
            current_track++;
            current_sector = 0;
            if(current_track >= track_sector[(current_row + 1) * 2])
            {
                current_row++;
                if(current_row >= rows - 1)
                {
                    printf("to_tracksector %d: disk full abs_sector=%d\n", 
                        __LINE__,
                        abs_sector);
                    exit(1);
                }
            }
        }
    }

    *track = current_track;
    *sector = current_sector;
}

void flush_rle(uint8_t *dst, 
    int last_start, 
    int i, 
    int *compressed_size, 
    uint8_t *src)
{
    int j;
// all bytes except 1st
    int length = i - last_start - 1;
// long enough to encode
    if(length > 2)
    {
// encode all bytes except 1st.
// Subtract 1 for the minimum length.  Loader adds it back.
// Can only subtract 1 because
// the loader uses an 8 bit type to count the length.
        dst[(*compressed_size)++] = RLE_CODE;
        dst[(*compressed_size)++] = length - 1;
    }
    else
    {
// too short to encode
// write all bytes except 1st
        for(j = 0; j < length; j++)
        {
            if(src[last_start] == 0xff)
            {
// escape 0xff into an RLE code followed by 0xff
                dst[(*compressed_size)++] = 0xff;
                dst[(*compressed_size)++] = 0xff;
            }
            else
                dst[(*compressed_size)++] = src[last_start];
        }
    }
}

int compress_rle(uint8_t *dst, uint8_t *src, int size)
{
    int compressed_size = 0;
    int last_start = 0;
    for(int i = 0; i < size; i++)
    {
// copy 1st byte
        if(i == last_start)
        {
            if(src[i] == 0xff)
            {
// escape 0xff into an RLE code followed by 0xff
                dst[compressed_size++] = 0xff;
                dst[compressed_size++] = 0xff;
// DEBUG
//              dst[compressed_size++] = 0xfe;
            }
            else
            {
// unique byte
                dst[compressed_size++] = src[i];
            }
        }
        else
// byte value changed, reached last byte, or length hit maximum
        if(src[i] != src[last_start] ||
            i - last_start >= 256)
        {
            flush_rle(dst, last_start, i, &compressed_size, src);

            last_start = i;
// copy new byte
            if(src[last_start] == 0xff)
            {
// escape 0xff into an RLE code followed by 0xff
                dst[compressed_size++] = 0xff;
                dst[compressed_size++] = 0xff;
            }
            else
                dst[compressed_size++] = src[last_start];
        }
    }
    flush_rle(dst, last_start, size, &compressed_size, src);
    return compressed_size;
}

void main(int argc, char *argv[])
{
	if(argc < 3)
	{
		printf("Usage: %s <output prefix> <world .png image>\n", argv[0]);
		printf("Example: %s world2 marineris1.png\n", argv[0]);
		exit(1);
	}

    printf("Welcome to world maker\n");
    const char *output = argv[1];
    const char *input = argv[2];
    
    FILE *in = fopen(input, "r");
    if(!in)
    {
        printf("Couldn't open %s\n", input);
        exit(1);
    }
    
    fseek(in, 0, SEEK_END);
    image_size = ftell(in);
    fseek(in, 0, SEEK_SET);
    image_offset = 0;
    image_data = malloc(image_size);
    int _ = fread(image_data, 1, image_size, in);
    fclose(in);
	png_structp png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, 0, 0, 0);
	png_infop info_ptr = png_create_info_struct(png_ptr);
	int color_model;
	png_set_read_fn(png_ptr, 0, png_read_function);
	png_read_info(png_ptr, info_ptr);
	w = png_get_image_width(png_ptr, info_ptr);
	h = png_get_image_height(png_ptr, info_ptr);
    color_model = png_get_color_type(png_ptr, info_ptr);
    int components = 3;
    if(color_model ==  PNG_COLOR_TYPE_RGB_ALPHA)
    {
        components = 4;
    }

    printf("main %d: components=%d w=%d h=%d\n", 
        __LINE__, 
        components, 
        w, 
        h);
    
    if((w % 320) || (h % 200))
    {
        printf("main %d: w & h are not multiples of 320 & 200\n", __LINE__);
        exit(1);
    }

    uint8_t *in_image = malloc(w * h * components);
    uint8_t **in_rows = malloc(sizeof(uint8_t*) * h);
    int i, j, k, l;
    for(i = 0; i < h; i++)
        in_rows[i] = in_image + w * components * i;
    png_read_image(png_ptr, in_rows);
    free(image_data);

// RGBA to RGB
    if(color_model ==  PNG_COLOR_TYPE_RGB_ALPHA)
    {
        for(i = 0; i < w * h; i++)
        {
            in_image[i * 3] = in_image[i * components];
            in_image[i * 3 + 1] = in_image[i * components + 1];
            in_image[i * 3 + 2] = in_image[i * components + 2];
        }
    }

// recompute the rows
    for(i = 0; i < h; i++)
        in_rows[i] = in_image + w * 3 * i;

// Downsample to 160x200 per tile
    for(i = 0; i < h; i++)
    {
        uint8_t *row = in_rows[i];
        for(j = 0; j < w; j += 2)
        {
            uint8_t *rgb1 = row + j * 3;
            uint8_t *rgb2 = rgb1 + 3;
            int r = (rgb1[0] + rgb2[0]) / 2;
            int g = (rgb1[1] + rgb2[1]) / 2;
            int b = (rgb1[2] + rgb2[2]) / 2;
            rgb1[0] = rgb2[0] = r;
            rgb1[1] = rgb2[1] = g;
            rgb1[2] = rgb2[2] = b;
        }
    }

    int total_tiles = (w / TILE_W) * (h / TILE_H);
// 1 byte per pixel with the palette entry
    uint8_t *bitmap_data = calloc(sizeof(uint16_t), w * h);
// 1 byte per pixel with the bit mask
    uint8_t *bitmask_data = calloc(sizeof(uint16_t), w * h);

// assign nearest color to all pixels
    int totals[PALETTE_SIZE] = { 0 };
    for(i = 0; i < h; i++)
    {
        uint8_t *in_row = in_rows[i];
        for(j = 0; j < w; j++)
        {
            int color = rgb_to_palette(in_row + j * 3);
            bitmap_data[i * w + j] = color;
            totals[color]++;
        }
    }

// write test image
//    write_test_image(bitmap_data, w, h);

// most frequently used color is the background
    int bg_color = -1;
    int bg_count = -1;
    printf("main %d: totals=", __LINE__);
    for(i = 0; i < PALETTE_SIZE; i++)
    {
        printf("%d ", totals[i]);
        if(totals[i] > bg_count || i == 0)
        {
            bg_color = i;
            bg_count = totals[i];
        }
    }
    printf("\n");



// screen memory & color nibble for each cell
    uint16_t *color_data = calloc(sizeof(uint16_t), (w / 8) * (h / 8));
    for(i = 0; i < h; i += 8)
    {
        for(j = 0; j < w; j += 8)
        {
// get total of each color in the cell except the bg color
            bzero(totals, PALETTE_SIZE * sizeof(int));
            for(k = 0; k < 8; k++)
            {
                for(l = 0; l < 8; l++)
                {
                    int color = bitmap_data[(i + k) * w + j + l];
                    if(color != bg_color) totals[color]++;
                }
            }

// get top 3 totals.  2 extra to handle sorting
            int top3[5] = { -1, -1, -1, -1, -1 };
//printf("main %d %d %d %d %d %d\n", __LINE__, top3[0], top3[1], top3[2], top3[3], top3[4]);
            for(k = 0; k < PALETTE_SIZE; k++)
            {
                for(l = 0; l < 3; l++)
                {
                    if(totals[k] > 0 &&
                        (top3[l] == -1 ||
                        totals[k] > totals[top3[l]]))
                    {
// shift lower colors down & insert higher color
                        top3[l + 2] = top3[l + 1];
                        top3[l + 1] = top3[l];
// store the palette entry of the higher color
                        top3[l] = k;
                        break;
                    }
                }
            }


// Copy previous colors if all current ones are present in the previous cell
            if(i > 0 || (j % TILE_W) > 0)
            {
// recover the previous cell in the current tile
                int prev_j = j;
                int prev_i = i;
                if((j % TILE_W) > 0)
                {
                    prev_j -= 8;
                }
                else
                {
                    prev_i -= 8;
                    prev_j += TILE_W - 8;
                }
                uint16_t *prev_colors = color_data + 
                    (prev_i / 8) * (w / 8) + 
                    (prev_j / 8);
                int prev_top3[3];
                prev_top3[0] = *prev_colors >> 12;
                prev_top3[1] = (*prev_colors >> 8) & 0xf;
                prev_top3[2] = (*prev_colors >> 4) & 0xf;
                
                
                for(k = 0; k < 3; k++)
                {
                    for(l = 0; l < 3; l++)
                    {
                        if(top3[k] == -1 ||
                            top3[k] == prev_top3[l]) break;
                    }
                    if(l == 3) break;
                }

                if(k == 3)
                {
// if we get here, all the current colors are in the previous cell or not used
// so copy the order to improve compression
                    top3[0] = prev_top3[0];
                    top3[1] = prev_top3[1];
                    top3[2] = prev_top3[2];
                }
            }

// fill in unused colors
// TODO: previous cell should copy future colors into its unused slots
            if(top3[0] == -1)
                top3[0] = top3[1] = top3[2] = bg_color;
            else
            if(top3[1] == -1)
                top3[1] = top3[2] = top3[0];
            else
            if(top3[2] == -1)
                top3[2] = top3[1];


// replace lower colors with the top 3 in the cell
            for(k = 0; k < 8; k++)
            {
                for(l = 0; l < 8; l++)
                {
                    uint8_t *src = bitmap_data + (i + k) * w + j + l;
                    uint8_t *dst = bitmask_data + (i + k) * w + j + l;
                    int color = *src;
                    if(color != bg_color &&
                        color != top3[0] &&
                        color != top3[1] &&
                        color != top3[2])
                    {
// get original RGB triplet
                        uint8_t *rgb = in_rows[i + k] + (j + l) * 3;
                        int min_distance = -1;
// get nearest of 4 palette colors
                        min_distance = color_distance(rgb, bg_color);
                        color = bg_color;

                        int new_distance = color_distance(rgb, top3[0]);
                        if(min_distance > new_distance)
                        {
                            min_distance = new_distance;
                            color = top3[0];
                        }

                        new_distance = color_distance(rgb, top3[1]);
                        if(min_distance > new_distance)
                        {
                            min_distance = new_distance;
                            color = top3[1];
                        }

                        new_distance = color_distance(rgb, top3[2]);
                        if(min_distance > new_distance)
                        {
                            min_distance = new_distance;
                            color = top3[2];
                        }

//                         printf("main %d: replaced color %d with %d at x=%d y=%d\n",
//                             __LINE__,
//                             *data,
//                             color,
//                             j + l,
//                             i + k);
//                             
// store the new color for testing
                        *src = color;
                    }



// convert the palette value to a bit mask
                    if(color == bg_color) *dst = 0; // background color
                    else
                    if(color == top3[0])  *dst = 1; // upper 4 bits of screen memory
                    else
                    if(color == top3[1])  *dst = 2; // lower 4 bits of screen memory
                    else
                    if(color == top3[2])  *dst = 3; // color nibble
                }
            }

// store the color memory
            uint16_t *color_dst = color_data + (i / 8) * (w / 8) + (j / 8);
            *color_dst = (top3[0] << 12) | // screen memory 4:7
                (top3[1] << 8) | // screen memory 0:3
                top3[2] << 4;  // color nibble

// debug
//             if(i == 0 && j == 120)
//             {
//                 printf("main %d %d %d %d\n",
//                     __LINE__,
//                     top3[0],
//                     top3[1],
//                     top3[2]);
//             }
        }
    }

    write_test_image(bitmap_data, w, h);

// Create tile data
#define TILE_SIZE ((TILE_W / 8) * TILE_H + (TILE_W / 8) * (TILE_H / 8) * 3 / 2)
    uint8_t tile_data[TILE_SIZE];

// starting sector of each tile
    int sectors[total_tiles];
// generate tile disk
    char map_output[TEXTLEN];
    sprintf(map_output, "%s.d64", output);
    printf("main %d: writing %s\n", __LINE__, map_output);
    FILE *out = fopen(map_output, "w");
    int tile_number = 0;

    int tile_x;
// 1 row of tiles
    int tile_y = 0;
    for(tile_x = 0; tile_x < w; tile_x += TILE_W)
    {
// process each cell
        for(i = 0; i < TILE_H; i += 8)
        {
            for(j = 0; j < TILE_W; j += 8)
            {
                uint8_t *bitmap_dst = tile_data + 
                    (i / 8) * 320 + 
                    (i % 8) + 
                    (j / 8) * 8;
// 8 pixels bitmap data
                for(k = 0; k < 8; k++)
                {
                    uint8_t *bitmap_src = bitmask_data + 
                        (tile_y + i + k) * w + 
                        tile_x + j;
                    *bitmap_dst++ = (bitmap_src[0] << 6) |
                        (bitmap_src[2] << 4) |
                        (bitmap_src[4] << 2) |
                        (bitmap_src[6]);
                }
// 1 cell of screen data
                uint8_t *screen_dst = tile_data + 8000 + (i / 8) * 40 + j / 8;
                uint16_t *color_src = color_data + 
                    (tile_y + i) / 8 * (w / 8) +
                    (tile_x + j) / 8;
                *screen_dst = *color_src >> 8;

// 1 cell of color data
                if((j % 16) == 0)
                {
                    uint8_t *color_dst = tile_data + 9000 + (i / 8) * 20 + j / 16;
                    *color_dst = (color_src[0] & 0xf0) |
                        ((color_src[1] & 0xf0) >> 4);
                }
            }
        }

// debug
//         if(tile_x == 0)
//         {
//             printf("main %d %02x %02x %02x %02x\n",
//                 __LINE__,
//                 tile_data[9006],
//                 tile_data[9007],
//                 tile_data[9008],
//                 tile_data[9009]);
//         }

// compress the tile
        uint8_t buffer[TILE_SIZE];
        int compressed_size = 0;
        compressed_size = compress_rle(buffer, tile_data, TILE_SIZE);
        if(compressed_size > TILE_SIZE)
            printf("FIXME: compressed size overran buffer\n");
        printf("main %d: x=%d y=%d compressed=%d\n", __LINE__, tile_x, tile_y, compressed_size);

// pad to a multiple of the sector size to aid seeking
        while((compressed_size % 256) > 0)
        {
            buffer[compressed_size++] = 0;
        }
        sectors[tile_number] = ftell(out) / 256;
// write complete tile
        fwrite(buffer, 1, compressed_size, out);

        tile_number++;
    }

    int offset = ftell(out);
    printf("main %d: total %d tiles %d bytes %d%% ~%d tiles left\n", 
        __LINE__, 
        total_tiles, 
        offset,
        offset * 100 / D64_SIZE,
        total_tiles * D64_SIZE / offset - total_tiles);
    fclose(out);

    char asm_output[TEXTLEN];
    sprintf(asm_output, "%s.s", output);
    printf("main %d writing %s\n", __LINE__, asm_output);
    out = fopen(asm_output, "w");
    fprintf(out, "; dimensions in cells\n");
    fprintf(out, "WORLD_W := %d\nWORLD_H := %d\n", w / 8, h / 8);
    fprintf(out, "TILE_W := %d\nTILE_H := %d\n",
        TILE_W / 8,
        TILE_H / 8);
    fprintf(out, "W_TILES := %d\nH_TILES := %d\n", w / TILE_W, h / TILE_H);
    fprintf(out, "RLE_CODE := $%x\n", RLE_CODE);
    fprintf(out, "BG_COLOR := $%x\n\n", bg_color);
    
// write TOC
// 1 row per row of tiles
    int pass;
    int passes = 2;
    for(pass = 0; pass < passes; pass++)
    {
        switch(pass)
        {
        case 0:
            fprintf(out, "tracks:\n");
            break;
        case 1:
            fprintf(out, "sectors:\n");
            break;
        }
            
        fprintf(out, "    .byte ");
        for(i = 0; i < total_tiles; i++)
        {
            int abs_sector = sectors[i];
            int track;
            int sector;
            to_tracksector(&track, &sector, abs_sector);

//                 printf("main %d: tile 0x%02x track %d sector %d %d\n",
//                     __LINE__,
//                     i + j,
//                     track,
//                     sector,
//                     abs_sector);

            switch(pass)
            {
            case 0:
                fprintf(out, "%d", track);
                break;
            case 1:
                fprintf(out, "%d", sector);
                break;
            }

            if(i < total_tiles - 1)
                fprintf(out, ", ");
        }
        fprintf(out, "\n");
    }
    fprintf(out, "\n");
    fclose(out);
}













