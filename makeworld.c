// convert a world image into a character set & tiles


#include <errno.h>
#include <png.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

#define TEXTLEN 1024
#define D64_SIZE 174848
// total characters less code for RLE
#define MAX_CHARS 255
// code for RLE
#define RLE_CODE 255
// all possible substitutions of the 4 color masks.  
#define SUBS (4 * 4 * 4)

// multiple tiles in each sector with a table of offsets
//#define PACK_TILES

// 1 row of tiles per track
//#define PAD_TRACKS

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

typedef struct 
{
    int id;
    int rate;
} rate_t;
static int compare(const void *ptr1, const void *ptr2)
{
	rate_t *item1 = (rate_t*)ptr1;
	rate_t *item2 = (rate_t*)ptr2;
	return item1->rate <= item2->rate;
}


// return palette index of the RGB value
int rgb_to_palette(uint8_t *pixel)
{
    int i;
    for(i = 0; i < PALETTE_SIZE; i++)
    {
        if(pixel[0] == (palette[i] >> 16) &&
            pixel[1] == ((palette[i] >> 8) & 0xff) &&
            pixel[2] == (palette[i] & 0xff))
            return i;
    }
    return -1;
}

// return entry in the palette assigned to the color mask
int8_t mask_to_palette(int8_t *palette_masks, int8_t mask)
{
    int i;
    int last_entry = 0;
    for(i = 0; i < PALETTE_SIZE; i++)
    {
        if(palette_masks[i] == mask) return i;
        if(palette_masks[i] >= 0) last_entry = i;
    }

// if it's not assigned, return the last palette entry which was assigned 
// or the BG
    return last_entry;
}

void print_char(uint8_t *ptr, int indent)
{
    int i, j;
    for(i = 0; i < 8; i++)
    {
        for(j = 0; j < indent; j++)
            printf(" ");
        printf("%1x%1x%1x%1x\n", 
            ptr[i * 4 + 0], 
            ptr[i * 4 + 1], 
            ptr[i * 4 + 2], 
            ptr[i * 4 + 3]);
    }
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


void flush_rle(uint8_t *buffer, 
    int last_start, 
    int i, 
    int *compressed_size, 
    uint8_t *tile_temp)
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
        buffer[(*compressed_size)++] = RLE_CODE;
        buffer[(*compressed_size)++] = length - 1;
    }
    else
    {
// too short to encode
// write all bytes except 1st
        for(j = 0; j < length; j++)
        {
            if(tile_temp[last_start] == 0xff)
            {
// escape 0xff into an RLE code followed by 0xff
                buffer[(*compressed_size)++] = 0xff;
                buffer[(*compressed_size)++] = 0xff;
            }
            else
                buffer[(*compressed_size)++] = tile_temp[last_start];
        }
    }
}

// compute the character & palette for the current cell
void compute_cell(uint8_t *new_char,
    int8_t *palette_masks, 
    int *total_masks, 
    uint8_t **rows,
    int cell_x,
    int cell_y)
{
    memset(palette_masks, -1, PALETTE_SIZE);
// mask 0 is the bg color. page 128
    palette_masks[bg_index] = 0;
    *total_masks = 1;
    for(int row = 0; row < 8; row++)
    {
        for(int col = 0; col < 4; col++)
        {
            uint8_t *pixel = rows[cell_y + row] + cell_x * 3 + col * 6;
            int palette_index = rgb_to_palette(pixel);
            if(palette_index < 0)
            {
                printf("compute_cell %d: color not found 0x%02x%02x%02x %d,%d\n",
                    __LINE__,
                    pixel[0], 
                    pixel[1], 
                    pixel[2],
                    cell_x + col * 2,
                    cell_y + row);
                exit(1);
            }

            if(palette_masks[palette_index] < 0)
            {
                if(*total_masks >= 4)
                {
                    printf("compute_cell %d: too many colors at %d,%d\n",
                        __LINE__,
                        cell_x + col * 2,
                        cell_y + row);
                    exit(1);
                }

                palette_masks[palette_index] = (*total_masks)++;
            }

            new_char[row * 4 + col] = palette_masks[palette_index];
        }
    }

    if(*total_masks > 3) printf("compute_cell %d used color nibble at %d %d\n",
        __LINE__,
        cell_x / 8,
        cell_y / 8);
}

void replace_prev_char(int reuse_char, // the character to be replaced
    uint8_t *char_set,
    uint8_t *char_memory,
    uint16_t *color_memory,
    uint8_t **rows,
    uint8_t *mask_subs)
{
    int8_t palette_masks[PALETTE_SIZE];
    int total_masks;
    int sub;
    uint8_t palette_indexes[3] = { 0, 0, 0 };

// delete the old character from the character set
    for(int i = reuse_char; i < total_chars - 1; i++)
        memcpy(char_set + i * 4 * 8, char_set + (i + 1) * 4 * 8, 4 * 8);
    total_chars--;
    uint8_t *new_char =  char_set + (total_chars - 1) * 4 * 8;

    for(int prev_cell_y = 0; prev_cell_y < h; prev_cell_y += 8)
    {
        for(int prev_cell_x = 0; prev_cell_x < w; prev_cell_x += 8)
        {
            int prev_offset = (prev_cell_y / 8) * (w / 8) + 
                (prev_cell_x / 8);
// replace the old character in screen memory
            if(char_memory[prev_offset] > reuse_char)
                char_memory[prev_offset]--;
            else
            if(char_memory[prev_offset] == reuse_char)
            {
                char_memory[prev_offset] = total_chars - 1;
// recompute the previous color palette
                uint16_t *prev_color = color_memory + prev_offset;
                uint8_t prev_char[4 * 8];
                compute_cell(prev_char,
                    palette_masks, 
                    &total_masks, 
                    rows, 
                    prev_cell_x, 
                    prev_cell_y);

// search for a color substitution with the new character
                for(sub = 0; sub < SUBS; sub++)
                {
                    int  got_it = 1;
                    for(int i = 0; i < 4 * 8; i++)
                    {
                        if(mask_subs[sub * 4 + new_char[i]] != prev_char[i])
                            got_it =0 ;
                    }
                    if(got_it) break;
                }

                palette_indexes[1] = mask_to_palette(palette_masks, mask_subs[sub * 4 + 1]);
                palette_indexes[2] = mask_to_palette(palette_masks, mask_subs[sub * 4 + 2]);
                palette_indexes[3] = mask_to_palette(palette_masks, mask_subs[sub * 4 + 3]);
                *prev_color = 
                    (palette_indexes[1] << 12) |
                    (palette_indexes[2] << 8) |
                    (palette_indexes[3] << 4);
            }
        }
    }
}


void print_charset(uint8_t *ptr, int indent)
{
    for(int i = 0; i < 8; i++)
    {
        for(int j = 0; j < indent; j++) printf(" ");
        printf("%d%d%d%d\n", 
            ptr[i * 4 + 0],
            ptr[i * 4 + 1],
            ptr[i * 4 + 2],
            ptr[i * 4 + 3]);
    }
}


void main(int argc, char *argv[])
{
	if(argc < 4)
	{
		printf("Usage: %s <output prefix> <world .png image> <bg color index>\n", argv[0]);
		printf("Example: %s world map1.png 0\n", argv[0]);
		exit(1);
	}

    printf("Welcome to world maker\n");
    const char *output = argv[1];
    const char *input = argv[2];
    bg_index = atoi(argv[3]);
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

    printf("main %d: components=%d w=%d h=%d bg_index=%d\n", 
        __LINE__, 
        components, 
        w, 
        h, 
        bg_index);

    if((w % 8) || (h % 8))
    {
        printf("main %d: w & h are not multiples of 8\n", __LINE__);
        exit(1);
    }

    if((w % TILE_W) || (h % TILE_H))
    {
        printf("main %d: w & h are not multiples of tile size\n", __LINE__);
        exit(1);
    }

    uint8_t *image = malloc(w * h * components);
    uint8_t **rows = malloc(sizeof(uint8_t*) * h);
    int i, j;
    for(i = 0; i < h; i++)
        rows[i] = image + w * components * i;
    png_read_image(png_ptr, rows);
    free(image_data);

// RGBA to RGB
    if(color_model ==  PNG_COLOR_TYPE_RGB_ALPHA)
    {
        for(i = 0; i < w * h; i++)
        {
            image[i * 3] = image[i * components];
            image[i * 3 + 1] = image[i * components + 1];
            image[i * 3 + 2] = image[i * components + 2];
        }
    }

    for(i = 0; i < h; i++)
        rows[i] = image + w * 3 * i;

// allocate char memory & color memory
    int total_tiles = (w / TILE_W) * (h / TILE_H);
    uint16_t *color_memory = calloc(sizeof(uint16_t), (w / 8) * (h / 8));
    uint8_t *char_memory = calloc(1, (w / 8) * (h / 8));
// character set defined by color bitmask.  1 byte per pixel
    uint8_t *char_set = calloc(1, 256 * 4 * 8);

// new char using palette indexes.  1 byte per pixel
    uint8_t new_char[4 * 8];
// bitmask assignment for each color.  Up to 4 colors can be assigned a bitmask.
// -1 for not assigned.
// Mask 0 is always the bg. page 128
    int8_t palette_masks[PALETTE_SIZE];
// total color masks used in the current cell
    int total_masks;

// all possible substitutions of the 4 color masks.  
// 1 byte per color.  4 bytes per substitution
// Mask 0 must always be the background color.  The other 3 masks can be any of the
// 4 colors.
#define SUBS (4 * 4 * 4)
    uint8_t mask_subs[SUBS * 4];

// create mask substitution table
// It's basically all the numbers from 0-64
    for(i = 0; i < SUBS; i++)
    {
        uint8_t mask = i;
// mask 0 must be the background color
        mask_subs[i * 4 + 0] = 0;
// the 4 colors can go in any of the foreground masks
        mask_subs[i * 4 + 1] = (mask >> 4) & 0x3;
        mask_subs[i * 4 + 2] = (mask >> 2) & 0x3;
        mask_subs[i * 4 + 3] = mask & 0x3;
    }

// scan a cell at a time
    int cell_x, cell_y, row, col;
    for(cell_y = 0; cell_y < h; cell_y += 8)
    {
        for(cell_x = 0; cell_x < w; cell_x += 8)
        {
            int screen_offset = (cell_y / 8) * (w / 8) + (cell_x / 8);
            compute_cell(new_char,
                palette_masks, 
                &total_masks, 
                rows, 
                cell_x, 
                cell_y);
// if(screen_offset < 2) printf("main %d: %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n",
// __LINE__,
// palette_masks[0],
// palette_masks[1],
// palette_masks[2],
// palette_masks[3],
// palette_masks[4],
// palette_masks[5],
// palette_masks[6],
// palette_masks[7],
// palette_masks[8],
// palette_masks[9],
// palette_masks[10],
// palette_masks[11],
// palette_masks[12],
// palette_masks[13],
// palette_masks[14],
// palette_masks[15]);

// find a matching character by testing all possible substitutions
// of the color masks in all existing characters
            int got_it = 0;
            int reuse_char = 0;
            int sub = 0;
            for(reuse_char = 0; reuse_char < total_chars; reuse_char++)
            {
                uint8_t *test_char = char_set + reuse_char * 4 * 8;
                for(sub = 0; sub < SUBS; sub++)
                {
// test char using substituted palette indexes
                    got_it = 1;
                    for(i = 0; i < 4 * 8; i++)
                    {
                        if(mask_subs[sub * 4 + test_char[i]] != new_char[i])
                        {
                            got_it = 0;
                        }
                    }
                    if(got_it) break;
                }
                if(got_it) break;
            }

            uint16_t *color_dst = color_memory + screen_offset;
            uint8_t palette_indexes[3] = { 0, 0, 0 };

// DEBUG
//             if(cell_y == 75 * 8 + 0 * 8 && cell_x == 160 * 8 + 15 * 8)
//             {
//                 printf("main %d: got_it=%d reuse_char=%d\n", __LINE__, got_it, reuse_char);
//                 printf("new_char=\n");
//                 print_charset(new_char, 4);
//                 printf("reuse_char=\n");
//                 print_charset(char_set + reuse_char * 4 * 8, 4);
//             }

// create a new character
            if(!got_it)
            {
                reuse_char = -1;
                if(total_chars >= MAX_CHARS)
                {
                    printf("main %d: out of characters at %d,%d\n", 
                        __LINE__,
                        cell_x, 
                        cell_y);
                    exit(1);
                }

                uint8_t *dst = char_set + total_chars * 4 * 8;
                memcpy(dst, new_char, 4 * 8);
// set palette indexes from color masks
                palette_indexes[1] = mask_to_palette(palette_masks, 1);
                palette_indexes[2] = mask_to_palette(palette_masks, 2);
                palette_indexes[3] = mask_to_palette(palette_masks, 3);

// if(screen_offset < 2) printf("main %d: palette indexes=%d %d %d\n",
// __LINE__,
// palette_indexes[1],
// palette_indexes[2],
// palette_indexes[3]);
// set the char memory to the new character
                char_memory[screen_offset] = total_chars;
                total_chars++;
            }
            else
            {
// set palette indexes from substituted color masks.
                palette_indexes[1] = mask_to_palette(palette_masks, mask_subs[sub * 4 + 1]);
                palette_indexes[2] = mask_to_palette(palette_masks, mask_subs[sub * 4 + 2]);
                palette_indexes[3] = mask_to_palette(palette_masks, mask_subs[sub * 4 + 3]);
// set the char memory to the reused character
                char_memory[screen_offset] = reuse_char;
            }


// Set the color memory to the palette indexes.
            *color_dst = 
                (palette_indexes[1] << 12) |
                (palette_indexes[2] << 8) |
                (palette_indexes[3] << 4);

// if(screen_offset == (400 / 8) * (w / 8) + 118)
// {
// printf("main %d reuse_char=%d\n", __LINE__, reuse_char);
// *color_dst = 0;
// }

// if a new character is added, compare all past characters to the new character 
// with color substitutions
            if(reuse_char < 0)
            {
                for(reuse_char = 0; reuse_char < total_chars - 1; reuse_char++)
                {
                    uint8_t *test_char = char_set + reuse_char * 4 * 8;

//printf("main %d: test_char=\n", __LINE__);
//print_char(test_char, 4);

                    for(sub = 0; sub < SUBS; sub++)
                    {
// test char using substituted palette indexes
                        got_it = 1;

// printf("main %d: sub=%d\n", __LINE__, sub);
// for(i = 0; i < 8; i++)
// {
//     printf("        %1x%1x%1x%1x\n", 
//         mask_subs[sub * 4 + new_char[i * 4 + 0]], 
//         mask_subs[sub * 4 + new_char[i * 4 + 1]], 
//         mask_subs[sub * 4 + new_char[i * 4 + 2]], 
//         mask_subs[sub * 4 + new_char[i * 4 + 3]]);
// }

                        for(i = 0; i < 4 * 8; i++)
                        {
                            if(test_char[i] != mask_subs[sub * 4 + new_char[i]])
                            {
                                got_it = 0;
                            }
                        }
                        if(got_it) break;
                    }
                    if(got_it) break;
                }

                if(got_it)
                {
                    printf("main %d: got previous char=%d new char=%d substitution=%d\n",
                        __LINE__,
                        reuse_char,
                        total_chars - 1,
                        sub);
//                     printf("new_char=\n");
//                     print_charset(new_char, 4);
//                     printf("previous char=\n");
//                     print_charset(char_set + reuse_char * 4 * 8, 4);

                    replace_prev_char(reuse_char,
                        char_set,
                        char_memory,
                        color_memory,
                        rows,
                        mask_subs);
                }
            }

// if(cell_x == 3192 && cell_y == 0)
// {
// printf("main %d: %d,%d total_chars=%d total_masks=%d colors=%d,%d,%d,%d\n", 
// __LINE__, 
// cell_x, 
// cell_y, 
// total_chars,
// total_masks,
// bg_index,
// (*color_dst >> 12),
// ((*color_dst >> 8) & 0xf),
// ((*color_dst >> 4) & 0xf));
// print_char(new_char, 4);
// exit(0);
// }
        }
    }

    printf("main %d total_chars=%d\n", __LINE__, total_chars);

// test occurance of each character
//     rate_t char_rate[total_chars];
//     bzero(char_rate, total_chars * sizeof(rate_t));
//     for(j = 0; j < (w / 8) * (h / 8); j++)
//     {
//         char_rate[char_memory[j]].rate++;
//     }
// 
//     for(i = 0; i < total_chars; i++)
//         char_rate[i].id = i;
//     qsort(char_rate, total_chars, sizeof(rate_t), compare);
//
//     for(i = 0; i < total_chars; i++)
//     {
//         printf("    %d = %d\n", char_rate[i].id, char_rate[i].rate);
//     }


// generate tile disk
    char map_output[TEXTLEN];
#define TILE_SIZE (TILE_W * TILE_H * 5 / 2)
    uint8_t tile_temp[TILE_SIZE];
    int tile_offset = 0;
    sprintf(map_output, "%s.d64", output);
    printf("main %d writing %s\n", __LINE__, map_output);

// starting sector of each tile
    int sectors[total_tiles];
// offset in the sector of each tile
    int sector_offsets[total_tiles];

    FILE *out = fopen(map_output, "w");

// start at a track other than 1
    int abs_sector = 0;
    int prev_track = 1;
//     while(1)
//     {
//         int track;
//         int sector;
//         to_tracksector(&track, &sector, abs_sector);
//         printf("main %d: %d %d\n", __LINE__, track, sector);
//         if(track >= prev_track)
//         {
//             break;
//         }
//         uint8_t buffer[256];
//         memset(buffer, 0, sizeof(buffer));
//         fwrite(buffer, 1, sizeof(buffer), out);
//         abs_sector++;
//     }

    int tile_x, tile_y;
    int tile_number = 0;
    int sector_offset = 0;
    for(tile_y = 0; tile_y < h; tile_y += TILE_H)
    {
        for(tile_x = 0; tile_x < w; tile_x += TILE_W)
        {
            tile_number = (tile_y / TILE_H) * (w / TILE_W) + tile_x / TILE_W;
            tile_offset = 0;
// character memory
            for(row = 0; row < TILE_H; row += 8)
            {
                memcpy(tile_temp + tile_offset, 
                    char_memory + ((tile_y + row) / 8) * (w / 8) + tile_x / 8,
                    TILE_W / 8);
                tile_offset += TILE_W / 8;
            }
// screen memory/colors
            for(row = 0; row < TILE_H; row += 8)
            {
                uint8_t buffer[TILE_W / 8];
                uint16_t *color_src = color_memory + 
                    ((tile_y + row) / 8) * (w / 8)  +
                    tile_x / 8;
                for(col = 0; col < TILE_W; col += 8)
                {
//if(tile_x == 640 && tile_y == 400 && col == 38 && row == 10)
                    buffer[col / 8] = color_src[col / 8] >> 8;
                }
                memcpy(tile_temp + tile_offset, buffer, TILE_W / 8);
                tile_offset += TILE_W / 8;
            }
// color memory nybbles
// 2 characters packed per byte
            for(row = 0; row < TILE_H; row += 8)
            {
                uint8_t buffer[TILE_W / 8 / 2];
                uint16_t *color_src = color_memory + 
                    ((tile_y + row) / 8) * (w / 8) +
                    tile_x / 8;
                for(col = 0; col < TILE_W; col += 16)
                {
                    buffer[col / 16] = (color_src[col / 8] & 0xf0) |
                        ((color_src[(col + 8) / 8] & 0xf0) >> 4);
                }
                memcpy(tile_temp + tile_offset, buffer, TILE_W / 8 / 2);
                tile_offset += TILE_W / 8 / 2;
            }

// RLE compress
            int last_start = 0;
            uint8_t buffer[256 * 10];
            int compressed_size = 0;
            for(i = 0; i < tile_offset; i++)
            {
// copy 1st byte
                if(i == last_start)
                {
                    if(tile_temp[i] == 0xff)
                    {
// escape 0xff into an RLE code followed by 0xff
                        buffer[compressed_size++] = 0xff;
                        buffer[compressed_size++] = 0xff;
// DEBUG
//                        buffer[compressed_size++] = 0xfe;
                    }
                    else
                    {
// unique byte
                        buffer[compressed_size++] = tile_temp[i];
                    }
                }
                else
// byte value changed, reached last byte, or length hit maximum
                if(tile_temp[i] != tile_temp[last_start] ||
                    i - last_start >= 256)
                {
                    flush_rle(buffer, last_start, i, &compressed_size, tile_temp);

                    last_start = i;
// copy new byte
                    if(tile_temp[last_start] == 0xff)
                    {
// escape 0xff into an RLE code followed by 0xff
                        buffer[compressed_size++] = 0xff;
                        buffer[compressed_size++] = 0xff;
                    }
                    else
                        buffer[compressed_size++] = tile_temp[last_start];
                }
            }

// last code
            flush_rle(buffer, last_start, i, &compressed_size, tile_temp);


            printf("main %d: tile=0x%02x tile_x=%d\ttile_y=%d\tcompressed_size=%d\n", 
                __LINE__, 
                tile_number, 
                tile_x / 8, 
                tile_y / 8, 
                compressed_size);
// print the tile data
//            if(tile_number == 0x2c)
            {
// print source tile
//                for(i = 0; i < tile_offset; i++)
//                {
//                    printf("%02x ", tile_temp[i]);
//                }
//                printf("\n");

// print compressed data
//                 for(i = 0; i < compressed_size; i += 16)
//                 {
//                     printf("\t");
//                     for(j = 0; j < 16 && i + j < compressed_size; j++)
//                         printf("0x%02x, ", buffer[i + j]);
//                     printf("\n");
//                 }
            }
            if(compressed_size > sizeof(buffer))
                printf("FIXME: compressed size overran buffer\n");

// starting sector number
            sectors[tile_number] = ftell(out) / 256;
            sector_offsets[tile_number] = sector_offset;

// pad to a multiple of the sector size
#ifndef PACK_TILES
            while((compressed_size % 256) > 0)
            {
                buffer[compressed_size++] = 0;
            }
            
#endif

// write complete tile
            fwrite(buffer, 1, compressed_size, out);
        }

        uint8_t buffer[256];
        memset(buffer, 0, sizeof(buffer));
#ifdef PACK_TILES
// pad the last sector of the row
        if(sector_offset != 0)
        {
            int fragment = 256 - sector_offset;
            if(fragment < 256)
            {
                fwrite(buffer, 1, fragment, out);
            }
            sector_offset = 0;
        }
#endif


#ifdef PAD_TRACKS

// last sector of the row
        int abs_sector = ftell(out) / 256 - 1;
// test the last track & sector of the track
        int track;
        int sector;
        to_tracksector(&track, &sector, abs_sector);
//        printf("main %d: track=%d ftell=%x\n", __LINE__, track, (int)ftell(out));


        if(track != prev_track)
        {
 
            printf("main %d: row %d spanned 2 tracks\n", __LINE__, tile_y / TILE_H);
        }
        else
        {
// starting sector of next row
            abs_sector = ftell(out) / 256;
            to_tracksector(&track, &sector, abs_sector);
            while(track == prev_track)
            {
// pad until next track
                fwrite(buffer, 1, sizeof(buffer), out);
                abs_sector++;
                to_tracksector(&track, &sector, abs_sector);
            }
        }
//        printf("main %d: track=%d ftell=%x\n", __LINE__, track, (int)ftell(out));
        prev_track = track;
#endif
    }

// pad disk image
    int offset = ftell(out);
    printf("main %d: total used=%d tiles %d bytes %d%% ~%d tiles left\n", 
        __LINE__, 
        total_tiles, 
        offset,
        offset * 100 / D64_SIZE,
        total_tiles * D64_SIZE / offset - total_tiles);
    if(offset > D64_SIZE)
    {
        printf("main %d: no space left on disk\n", __LINE__);
    }
    else
    {
//        int remane = D64_SIZE - offset;
//        uint8_t buffer[remane];
//        bzero(buffer, remane);
//        fwrite(buffer, 1, remane, out);
    }

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
    fprintf(out, "RLE_CODE := $%x\n\n",
        RLE_CODE);



// write TOC
// 1 row per row of tiles
    int pass;
    int passes = 2;
#ifdef PACK_TILES
    passes = 3;
#endif
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
        case 2:
            fprintf(out, "offsets:\n");
            break;
        }
            
        prev_track = 1;
        for(i = 0; i < total_tiles; i += w / TILE_W)
        {
            fprintf(out, "    .byte ");
            for(j = 0; j < w / TILE_W; j++)
            {
                int abs_sector = sectors[i + j];
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
                case 2:
                    fprintf(out, "%d", sector_offsets[i + j]);
                    break;
                }

                if(j < w / TILE_W - 1)
                    fprintf(out, ", ");
                else
                    fprintf(out, "\n");
            }
        }
    }
    fprintf(out, "\n");

// generate character set from data table
    fprintf(out, "char_set:\n");
    for(i = 0; i < total_chars; i++)
    {
        fprintf(out, "    .byte ");
        for(j = 0; j < 8; j++)
        {
            uint8_t value = 
                (char_set[i * 4 * 8 + j * 4 + 0] << 6) |
                (char_set[i * 4 * 8 + j * 4 + 1] << 4) |
                (char_set[i * 4 * 8 + j * 4 + 2] << 2) |
                (char_set[i * 4 * 8 + j * 4 + 3]);
            fprintf(out, "$%02x", value);
            if(j < 7) 
                fprintf(out, ", ");
        }
        fprintf(out, " ; char 0x%02x\n", i);
    }
    fclose(out);

  
}





