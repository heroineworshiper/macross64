#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>



// angle corresponding to each 8x8 cell in line_start.ppm
const int angles[] = 
{
    0, 7, 14, 26, 45, 63, 75, 90, 
    104, 116, 135, 153, 165, 172, 180,
    -172, -165, -153, -135, -116, -104, -90, 
    -75, -63, -45, -26, -14, -7
};

// line_start.ppm dimensions
#define W 224
#define H 8
#define TOTAL_ANGLES (sizeof(angles) / sizeof(int))
#define TOTAL_BORDER (8 * 4)

// X, Y for pixels in the border of an 8x8 cell
typedef struct
{
    int x, y;
} point_t;
point_t border_pixels[TOTAL_BORDER];
// supported angles for each border pixel.  1 bit per angle
uint32_t angle_starts[TOTAL_BORDER];

// integer slopes for the 1st 8 angles
const point_t slopes[] =
{
    { 8, 0 }, { 8, 1 }, { 4, 1 }, { 2, 1 }, { 1, 1 }, { 1, 2 }, { 1, 4 }, { 0, 8 }, 
};

void main()
{
// compute the border pixels
    for(int i = 0; i < 8; i++)
    {
// top row
        border_pixels[i].x = i;
        border_pixels[i].y = 0;
// bottom row
        border_pixels[i + 8].x = i;
        border_pixels[i + 8].y = 7;
// left column
        border_pixels[i + 16].x = 0;
        border_pixels[i + 16].y = i;
// right column
        border_pixels[i + 24].x = 7;
        border_pixels[i + 24].y = i;
    }

    printf(
        "typedef struct\n"
        "{\n"
        "    int x, y;\n"
        "} point_t;\n\n"
        "const point_t border_pixels[] = \n{\n    "
    );
    for(int i = 0; i < TOTAL_BORDER; i++)
    {
        printf("{ %d, %d }, ", border_pixels[i].x, border_pixels[i].y);
        if(i == 7 || i == 15 || i == 23) printf("\n    ");
    }
    printf("\n};\n");


// compute the supported angles for each border pixel
// by loading an image marking the border pixels for each angle
// the black pixels are the valid starting points of each angle
    FILE *fd = fopen("line_start.pnm", "r");
    uint8_t *image = malloc(W * H * 3);
    int linefeeds = 0;
    while(!feof(fd) && linefeeds < 4)
    {
        int c = fgetc(fd);
        if(c == 0x0a) linefeeds++;
    }
    fread(image, W * H * 3, 1, fd);
    fclose(fd);


    int i;
    int j;
    bzero(angle_starts, sizeof(angle_starts));
    for(i = 0; i < TOTAL_BORDER; i++)
    {
        for(j = 0; j < TOTAL_ANGLES; j++)
        {
            int x = j * 8 + border_pixels[i].x;
            int y = border_pixels[i].y;
            if(image[y * W * 3 + x * 3] == 0) angle_starts[i] |= (1 << j);
        }
    }

    printf(
        "\nconst uint32_t angle_starts[] = \n{\n    "
    );
    for(i = 0; i < TOTAL_BORDER; i++)
    {
        printf("0x%08x, ", angle_starts[i]);
        if(i > 0 && i < TOTAL_BORDER - 1 && ((i + 1) % 8) == 0) printf("\n    ");
    }
    printf("\n};\n");



    point_t slopes2[TOTAL_ANGLES];
    memcpy(slopes2, slopes, sizeof(point_t) * 8);
// finish the slopes table
    for(i = 0; i < 7; i++)
    {
        slopes2[i + 8].x = -slopes[6 - i].x;
        slopes2[i + 8].y = slopes[6 - i].y;
    }
    for(i = 0; i < 7; i++)
    {
        slopes2[i + 15].x = -slopes[i + 1].x;
        slopes2[i + 15].y = -slopes[i + 1].y;
    }
    for(i = 0; i < 7; i++)
    {
        slopes2[i + 22].x = slopes[6 - i].x;
        slopes2[i + 22].y = -slopes[6 - i].y;
    }

    printf(
        "const point_t slopes[] = \n{\n    "
    );
    for(int i = 0; i < TOTAL_ANGLES; i++)
    {
        printf("{ %d, %d }, ", slopes2[i].x, slopes2[i].y);
        if(i == 7 || i == 14 || i == 21) printf("\n    ");
    }
    printf("\n};\n");

}
