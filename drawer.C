// Draw constrained lines on top of an image

// This requires https://github.com/heroineworshiper/guicast
// to build.






#include "clip.h"
#include "cursors.h"
#include "guicast.h"
#include "keys.h"
#include <string.h>

#define UNDO_LEVELS 10
#define MIN_ERASE 8
#define MAX_ERASE 32

const char *fg_filename;
const char *bg_filename;
BC_Hash *defaults;
int window_w = 640;
int window_h = 480;
int window_x = 0;
int window_y = 0;
int erase_size = 8;

// tables from tables.c
// X, Y for pixels in the border of an 8x8 cell
typedef struct
{
    int x, y;
} point_t;
const point_t border_pixels[] = 
{
    { 0, 0 }, { 1, 0 }, { 2, 0 }, { 3, 0 }, { 4, 0 }, { 5, 0 }, { 6, 0 }, { 7, 0 }, 
    { 0, 7 }, { 1, 7 }, { 2, 7 }, { 3, 7 }, { 4, 7 }, { 5, 7 }, { 6, 7 }, { 7, 7 }, 
    { 0, 0 }, { 0, 1 }, { 0, 2 }, { 0, 3 }, { 0, 4 }, { 0, 5 }, { 0, 6 }, { 0, 7 }, 
    { 7, 0 }, { 7, 1 }, { 7, 2 }, { 7, 3 }, { 7, 4 }, { 7, 5 }, { 7, 6 }, { 7, 7 }, 
};

#define TOTAL_BORDER (sizeof(border_pixels) / sizeof(point_t))

// all supported line angles to quantize to
// angles are drawn in patterns.xcf.bz2
const int angles[] = 
{
    0, 7, 14, 26, 45, 63, 75, 90, 
    104, 116, 135, 153, 165, 172, 180,
    -172, -165, -153, -135, -116, -104, -90, 
    -75, -63, -45, -26, -14, -7
};

// integer slope of each angle
const point_t slopes[] = 
{
    { 8, 0 }, { 8, 1 }, { 4, 1 }, { 2, 1 }, { 1, 1 }, { 1, 2 }, { 1, 4 }, { 0, 8 }, 
    { -1, 4 }, { -1, 2 }, { -1, 1 }, { -2, 1 }, { -4, 1 }, { -8, 1 }, { -8, 0 }, 
    { -8, -1 }, { -4, -1 }, { -2, -1 }, { -1, -1 }, { -1, -2 }, { -1, -4 }, { 0, -8 }, 
    { 1, -4 }, { 1, -2 }, { 1, -1 }, { 2, -1 }, { 4, -1 }, { 8, -1 }, 
};
#define TOTAL_ANGLES (sizeof(angles) / sizeof(int))



// the supported angles for each border pixel in border_pixels
// least significant bit is 1st entry in angles[]
const uint32_t angle_starts[] = 
{
    0x0ff00003, 0x00700000, 0x00700000, 0x00780000, 0x00f00000, 0x00700000, 0x00700000, 0x007fe000, 
    0x080001ff, 0x000001c0, 0x000001c0, 0x000003c0, 0x000001e0, 0x000001c0, 0x000001c0, 0x0000ffc0, 
    0x0ff00003, 0x08000007, 0x0c000003, 0x0800000f, 0x0e000003, 0x08000007, 0x0c000003, 0x080001ff, 
    0x007fe000, 0x0000f000, 0x0001e000, 0x0000f800, 0x0003e000, 0x0000f000, 0x0001e000, 0x0000ffc0, 
};




class MainWindow : public BC_Window
{
public:
// the background image
    VFrame *bg;
// the user drawing
    VFrame *fg;
    int show_bg;
// top left of window in bg image
    int zoom_x;
    int zoom_y;
    int zoom_factor;
// start of drag
    int drag_x;
    int drag_y;
    int drag_zoom_x;
    int drag_zoom_y;
// accumulated drag motion
    int drag_accum_x;
    int drag_accum_y;
    int dragging;
// constrained cursor position in image
    int cursor_x;
    int cursor_y;
    int overlay_visible;
// drawing a line
    int drawing_line;
    int erasing;
#define LINES 0
#define ERASE 1
    int mode;
    int hide_bg;
// nearest border pixel of the last cursor motion
// or the start of the current line
    int border_pixel;
    int line_x1;
    int line_y1;
    int line_x2;
    int line_y2;
// array of points on the current line
    ArrayList<point_t> current_line;
    int multicolor;
    int current_undo;
    int total_undos;
    VFrame *undo_before[UNDO_LEVELS];
    VFrame *undo_after[UNDO_LEVELS];
    int changed;

	MainWindow() : BC_Window(fg_filename, 
	    window_x, // x
	    window_y, // y
        window_w, // w
        window_h, // h
	    10, // minw
	    10, // minh
	    1, // allow resize
	    0, // private color
	    1, // hide
	    WHITE)
    {
        show_bg = 1;
        bg = 0;
        zoom_factor = 1;
        zoom_x = 0;
        zoom_y = 0;
        dragging = 0;
        drawing_line = 0;
        erasing = 0;
        overlay_visible = 0;
        border_pixel = 0;
        multicolor = 1;
        hide_bg = 0;
        mode = LINES;
        changed = 0;
    }

    void create_objects()
    {
        lock_window("create_objects");
//        set_cursor(CROSS_CURSOR, 0, 0);
        set_cursor(TRANSPARENT_CURSOR, 0, 0);


        bg = load(bg_filename);
        if(!bg)
        {
            printf("MainWindow::create_objects %d: giving up & going to a movie\n",
                __LINE__);
            exit(0);
        }

        fg = load(fg_filename);
        if(!fg) 
        {
            fg = new VFrame(bg->get_w(), bg->get_h(), BC_A8);
            memset(fg->get_rows()[0], 0xff, bg->get_w() * bg->get_h());
        }

// PNG doesn't properly save BC_A8
// convert to 8 bit
        if(fg->get_color_model() == BC_RGB888)
        {
            VFrame *fg2 = new VFrame(fg->get_w(), fg->get_h(), BC_A8);
            for(int i = 0; i < fg->get_h(); i++)
            {
                uint8_t *dst_row = fg2->get_rows()[i];
                uint8_t *src_row = fg->get_rows()[i];
                for(int j = 0; j < fg->get_w(); j++)
                {
                    *dst_row = *src_row;
                    src_row++;
                    dst_row++;
                }
            }
            delete fg;
            fg = fg2;
        }

        for(int i = 0; i < UNDO_LEVELS; i++)
        {
            undo_before[i] = new VFrame(bg->get_w(), bg->get_h(), BC_A8);
            undo_after[i] = new VFrame(bg->get_w(), bg->get_h(), BC_A8);
        }

        draw();
        show_window(1);
        unlock_window();
    }

    int resize_event(int w, int h)
    {
        window_w = w;
        window_h = h;
        draw_fragment(0,
            0,
            w,
            h);
	    BC_WindowBase::resize_event(w, h);
        return 0;
    }
    
    int translation_event()
    {
        window_x = get_x();
        window_y = get_y();
        return 0;
    }
    
    void zoom(int in, int out)
    {
        if(in && zoom_factor < 32 ||
            out && zoom_factor > 1)
        {
// position of cursor in image
            int x1 = zoom_x + get_cursor_x() / zoom_factor;
            int y1 = zoom_y + get_cursor_y() / zoom_factor;
            if(in) zoom_factor *= 2;
            if(out) zoom_factor /= 2;
            zoom_x = x1 - get_cursor_x() / zoom_factor;
            zoom_y = y1 - get_cursor_y() / zoom_factor;
            CLAMP(zoom_x, 0, bg->get_w() - window_w / zoom_factor);
            CLAMP(zoom_y, 0, bg->get_h() - window_h / zoom_factor);
            draw();
        }
    }


    int button_press_event()
    {
        switch(get_buttonpress())
        {
            case WHEEL_UP:
                zoom(1, 0);
                return 1;
                break;
            case WHEEL_DOWN:
                zoom(0, 1);
                return 1;
                break;
            case LEFT_BUTTON:
                if(mode == LINES)
                {
                    if(!drawing_line)
                        start_line();
                    else
                        finish_line();
                }
                else
                {
                    start_erase();
                }
                return 1;
                break;
            case MIDDLE_BUTTON:
                dragging = 1;
                drag_x = get_cursor_x();
                drag_y = get_cursor_y();
                drag_zoom_x = zoom_x;
                drag_zoom_y = zoom_y;
                drag_accum_x = 0;
                drag_accum_y = 0;
                return 1;
                break;
            case RIGHT_BUTTON:
                if(drawing_line) abort_drawing();
                break;
        }
        return 0;
    }

    int button_release_event()
    {
        if(dragging)
        {
            dragging = 0;
            return 1;
        }
        if(erasing)
        {
            erasing = 0;
            push_undo_after();
            return 1;
        }
        return 0;
    }

    int cursor_motion_event()
    {
        if(drawing_line)
        {
            update_line();
        }

        if(dragging)
        {
            int xdiff = get_cursor_x() - drag_x;
            int ydiff = get_cursor_y() - drag_y;
            
            int new_zoom_x = drag_zoom_x - xdiff / zoom_factor;
            int new_zoom_y = drag_zoom_y - ydiff / zoom_factor;
// clamp accumulators & window position
            if(new_zoom_x < 0)
            {
                new_zoom_x = 0;
            }
            if(new_zoom_y < 0)
            {
                new_zoom_y = 0;
            }
            if(new_zoom_x > bg->get_w() - window_w / zoom_factor)
            {
                new_zoom_x = bg->get_w() - window_w / zoom_factor;
            }
            if(new_zoom_y > bg->get_h() - window_h / zoom_factor)
            {
                new_zoom_y = bg->get_h() - window_h / zoom_factor;
            }
            
//printf("cursor_motion_event %d %d %d\n", __LINE__, new_zoom_x, new_zoom_y);
            if(new_zoom_x != zoom_x ||
                new_zoom_y != zoom_y)
            {
                zoom_x = new_zoom_x;
                zoom_y = new_zoom_y;
                draw();
            }

            return 1;
        }
        else
        if(mode == ERASE)
        {
            if(erasing) 
            {
                update_erase();
            }
            else
            {
// hide overlay
                if(overlay_visible) draw_overlay(0);
                cursor_x = zoom_x + get_cursor_x() / zoom_factor;
                cursor_y = zoom_y + get_cursor_y() / zoom_factor;
            
// show overlay
                draw_overlay(1);
            }
        }
        else
        if(!drawing_line)
        {
// hide overlay
            if(overlay_visible) draw_overlay(0);
// constrain cursor position to the border of an 8x8 cell
            cursor_x = zoom_x + get_cursor_x() / zoom_factor;
            cursor_y = zoom_y + get_cursor_y() / zoom_factor;

            int left = cursor_x - (cursor_x % 8);
            int top = cursor_y - (cursor_y % 8);

// constrain to double pixels by aligning the cursor on the horizontal borders
            if(multicolor)
            {
                if(cursor_x - left < 4 && (cursor_x % 2) == 1) cursor_x--;
                else
                if(cursor_x - left >= 4 && (cursor_x % 2) == 0) cursor_x++;
            }

            float min_distance = 65536;
            border_pixel = -1;
            for(int i = 0; i < TOTAL_BORDER; i++)
            {
                int border_x = left + border_pixels[i].x;
                int border_y = top + border_pixels[i].y;
                float new_distance = hypot(cursor_x - border_x, cursor_y - border_y);
                if(i == 0 || min_distance > new_distance)
                {
                    min_distance = new_distance;
                    border_pixel = i;
                }
            }
            cursor_x = left + border_pixels[border_pixel].x;
            cursor_y = top + border_pixels[border_pixel].y;

// show overlay
            draw_overlay(1);
        }
        return 0;
    }

    int keypress_event()
    {
        switch(get_keypress())
        {
            case RIGHT:
                zoom_x++;
                CLAMP(zoom_x, 0, bg->get_w() - window_w / zoom_factor);
                draw();
                break;
            case LEFT:
                zoom_x--;
                CLAMP(zoom_x, 0, bg->get_w() - window_w / zoom_factor);
                draw();
                break;
            case UP:
                zoom_y--;
                CLAMP(zoom_y, 0, bg->get_h() - window_h / zoom_factor);
                draw();
                break;
            case DOWN:
                zoom_y++;
                CLAMP(zoom_y, 0, bg->get_h() - window_h / zoom_factor);
                draw();
                break;
            case ESC:
                if(drawing_line) 
                {
                    abort_drawing();
                    break;
                }
            case 'q':
                if(changed)
                {
                    printf("Changes made.  Really quit (y/n)? \n");
                    char string[BCTEXTLEN];
                    char* _ = fgets(string, BCTEXTLEN, stdin);
                    while(string[strlen(string) - 1] == '\n') 
                        string[strlen(string) - 1] = 0;
//                    printf("%s\n", string);
                    if(strcmp(string, "y")) break;
                }
                set_done(0);
                break;

            case 'h':
                hide_bg = !hide_bg;
                draw();
                break;

            case 'e':
                if(overlay_visible) draw_overlay(0);
                if(mode == ERASE)
                {
                    mode = LINES;
                    draw_overlay(1);
                    printf("MainWindow::keypress_event %d LINE MODE\n", __LINE__);
                }
                else
                {
                    mode = ERASE;
                    draw_overlay(1);
                    printf("MainWindow::keypress_event %d ERASE MODE\n", __LINE__);
                }
                break;

            case '+':
                if(overlay_visible) draw_overlay(0);
                if(erase_size < MAX_ERASE) erase_size += 8;
                draw_overlay(1);
                printf("MainWindow::keypress_event %d: ERASE SIZE %d\n", __LINE__, erase_size);
                break;

            case '-':
                if(overlay_visible) draw_overlay(0);
                if(erase_size > MIN_ERASE) erase_size -= 8;
                draw_overlay(1);
                printf("MainWindow::keypress_event %d: ERASE SIZE %d\n", __LINE__, erase_size);
                break;

            case 's':
                save();
                break;
            
            case 'z':
                pop_undo();
                break;
            case 'Z':
                pop_redo();
                break;
        }
        return 0;
    }
    
    VFrame* load(const char *path)
    {
        VFrame *dst = 0;
        FILE *fd = fopen(path, "r");
	    if(!fd)
	    {
		    printf("MainWindow::load %d: couldn't read %s\n", 
                __LINE__, path);
	    }
	    else
	    {
		    fseek(fd, 0, SEEK_END);
		    int size = ftell(fd);
		    fseek(fd, 0, SEEK_SET);

		    unsigned char *buffer = new unsigned char[size + 4];
		    int _ = fread(buffer + 4, size, 1, fd);
		    buffer[0] = size >> 24;
		    buffer[1] = (size >> 16) & 0xff;
		    buffer[2] = (size >> 8) & 0xff;
		    buffer[3] = size & 0xff;

//printf("MainWindow::load %d %s\n", __LINE__, path);
		    dst = new VFrame(buffer);
		    delete [] buffer;
	    }
        return dst;
    }
    
    void save()
    {
        int result = fg->write_png(fg_filename, 9);
        if(!result)
        {
            printf("MainWindow::save %d: saved %s\n", __LINE__, fg_filename);
            changed = 0;
        }
    }


    void draw()
    {
        draw_fragment(0,
            0,
            window_w,
            window_h);
        overlay_visible = 0;
    }

    void draw_fragment(int x1,
        int y1,
        int x2,
        int y2)
    {
        int bg_w = bg->get_w();
        int bg_h = bg->get_h();
        int src_x1 = zoom_x + x1 / zoom_factor;
        int src_x2 = zoom_x + x2 / zoom_factor;
        int src_y1 = zoom_y + y1 / zoom_factor;
        int src_y2 = zoom_y + y2 / zoom_factor;
        if(src_x2 > bg_w)
        {
            x2 -= (src_x2 - bg_w) * zoom_factor;
            src_x2 = bg_w;
        }
        if(src_y2 > bg_h)
        {
            y2 -= (src_y2 - bg_h) * zoom_factor;
            src_y2 = bg_h;
        }

        BC_Bitmap *bitmap = get_temp_bitmap(window_w,
            window_h,
            get_color_model());
        int bg_components = cmodel_components(bg->get_color_model());

// draw directly to BGR8888
        switch(get_color_model())
        {
            case BC_BGR8888:
                for(int i = 0; i < y2 - y1; i++)
                {
                    int src_y = src_y1 + i / zoom_factor;
                    if(src_y >= 0 && src_y < bg_h)
                    {
                        uint8_t *bg_row = bg->get_rows()[src_y] + src_x1 * bg_components;
                        uint8_t *fg_row = fg->get_rows()[src_y] + src_x1;
                        uint8_t *dst_row = bitmap->get_row_pointers()[y1 + i] + 
                            x1 * 4;
                        for(int j = 0; j < x2 - x1; j++)
                        {
                            int src_x = j / zoom_factor;
                            if(src_x >= 0 && src_x < bg_w)
                            {
                                uint8_t *bg_pixel = bg_row + j / zoom_factor * 4;
                                uint8_t *fg_pixel = fg_row + j / zoom_factor;
                                uint8_t r = *bg_pixel++;
                                uint8_t g = *bg_pixel++;
                                uint8_t b = *bg_pixel++;
                                uint8_t fg_value = *fg_pixel++;
                                if(hide_bg) r = g = b = 0xff;
                                if(!fg_value) r = g = b = 0;

                                *dst_row++ = b;
                                *dst_row++ = g;
                                *dst_row++ = r;
                                dst_row++;
                            }
                        }
                    }
                }
                break;
        }

        int x1_zoomed = (x1 - zoom_x) * zoom_factor;
        int y1_zoomed = (y1 - zoom_y) * zoom_factor;
        int w_zoomed = (x2 - x1) * zoom_factor;
        int h_zoomed = (y2 - y1) * zoom_factor;
        draw_bitmap(bitmap, 
            0,
            x1,
            y1,
            x2 - x1,
            y2 - y1,
            x1,
            y1,
            x2 - x1,
            y2 - y1,
            0);
        flash(x1, y1, x2 - x1, y2 - y1, 0);
        flush();
    }

// no XOR for text, so draw our own
    #define CHAR_W 8
    #define CHAR_H 16
    #define CHAR_ADVANCE 12
    void draw_digit(int x, int y, int n)
    {
// segments:
// 000
// 6 1
// 555
// 4 2
// 333
// segments in each digit
        const int used_segments[] = 
        {
            1, 1, 1, 1, 1, 0, 1, // 0
            0, 1, 1, 0, 0, 0, 0, // 1
            1, 1, 0, 1, 1, 1, 0, // 2
            1, 1, 1, 1, 0, 1, 0, // 3
            0, 1, 1, 0, 0, 1, 1, // 4
            1, 0, 1, 1, 0, 1, 1, // 5
            1, 0, 1, 1, 1, 1, 1, // 6
            1, 1, 1, 0, 0, 0, 0, // 7
            1, 1, 1, 1, 1, 1, 1, // 8
            1, 1, 1, 1, 0, 1, 1, // 9
        };

// coordinates of each segment
        const int lines[] = {
            0,      0,          CHAR_W, 0,
            CHAR_W, 0,          CHAR_W, CHAR_H / 2,
            CHAR_W, CHAR_H / 2, CHAR_W, CHAR_H,
            CHAR_W, CHAR_H,     0,      CHAR_H,
            0,      CHAR_H,     0,      CHAR_H / 2,
            0,      CHAR_H / 2, CHAR_W, CHAR_H / 2,
            0,      CHAR_H / 2, 0,      0
        };
        
        for(int i = 0; i < 7; i++)
        {
            if(used_segments[n * 7 + i])
            {
                draw_line(x + lines[i * 4 + 0],
                    y + lines[i * 4 + 1],
                    x + lines[i * 4 + 2],
                    y + lines[i * 4 + 3]);
            }
        }
    }
    
    int draw_number(int x, int y, int n)
    {
        int x1 = x;
        if(n >= 1000)
        {
            draw_digit(x1, y, n / 1000);
            x1 += CHAR_ADVANCE;
        }
        if(n >= 100)
        {
            draw_digit(x1, y, (n % 1000) / 100);
            x1 += CHAR_ADVANCE;
        }
        if(n >= 10)
        {
            draw_digit(x1, y, (n % 100) / 10);
            x1 += CHAR_ADVANCE;
        }
        draw_digit(x1, y, (n % 10));
        x1 += CHAR_ADVANCE;
        return x1;
    }

    void draw_overlay(int flash_it)
    {
        int margin = BC_Resources::theme->widget_border;
        set_color(WHITE);
        set_inverse();

// draw coordinates.  Text can't do inverse.
        static int x_buffer;
        static int y_buffer;
        static int cursor_x_buffer;
        static int cursor_y_buffer;
        if(!overlay_visible)
        {
            x_buffer = cursor_x;
            x_buffer -= x_buffer % 2;
            y_buffer = cursor_y;
            cursor_x_buffer = get_cursor_x();
            cursor_y_buffer = get_cursor_y();
        }

        if(cursor_x_buffer > get_w() / 2 || cursor_y_buffer > get_h() / 2)
        {
            int x = draw_number(margin, margin, x_buffer);
            x += CHAR_ADVANCE;
            draw_number(x, margin, y_buffer);
        }
        else
        {
            int x = draw_number(get_w() - CHAR_ADVANCE * 9 - margin, 
                get_h() - CHAR_H - margin, 
                x_buffer);
            x += CHAR_ADVANCE;
            draw_number(x, get_h() - CHAR_H - margin, y_buffer);
        }

// guides
        if(mode != ERASE)
        {
            draw_line(0, (cursor_y - zoom_y) * zoom_factor,
                get_w(), (cursor_y - zoom_y) * zoom_factor);
            draw_line((cursor_x - zoom_x) * zoom_factor, 0,
                (cursor_x - zoom_x) * zoom_factor, get_h());
        }

        if(mode == ERASE)
        {
            int x1;
            int y1;
            int x2;
            int y2;
            get_erase_coords(&x1, &y1, &x2, &y2);
            draw_rectangle((x1 - zoom_x) * zoom_factor, 
                (y1 - zoom_y) * zoom_factor, 
                (x2 - x1) * zoom_factor, 
                (y2 - y1) * zoom_factor);
        }
        else
        if(zoom_factor == 1)
        {

            if(drawing_line)
            {
// the starting position
//                draw_pixel(line_x1 - zoom_x, line_y1 - zoom_y);
// the line
                for(int i = 0; i < current_line.size(); i++)
                {
                    point_t *point = current_line.get_pointer(i);
                    draw_pixel(point->x - zoom_x, point->y - zoom_y);
                }
            }
            else
            {
                int x = cursor_x - zoom_x;
                int y = cursor_y - zoom_y;
    // the current position
                draw_pixel(x, y);
                if(multicolor)
                {
                    if((cursor_x % 2) == 1) 
                        draw_pixel(x - 1, y);
                    else
                        draw_pixel(x + 1, y);
                }
            }
        }
        else
        {

            if(drawing_line)
            {
// the starting position
//                 draw_rectangle((line_x1 - zoom_x) * zoom_factor, 
//                     (line_y1 - zoom_y) * zoom_factor, 
//                     zoom_factor, 
//                     zoom_factor);
// the line
                for(int i = 0; i < current_line.size(); i++)
                {
                    point_t *point = current_line.get_pointer(i);
                    draw_box((point->x - zoom_x) * zoom_factor, 
                        (point->y - zoom_y) * zoom_factor, 
                        zoom_factor, 
                        zoom_factor);
                }
            }
            else
            {
                int x = (cursor_x - zoom_x) * zoom_factor;
                int y = (cursor_y - zoom_y) * zoom_factor;
// the current position
                draw_box(x, y, zoom_factor, zoom_factor);
                if(multicolor)
                {
                    if((cursor_x % 2) == 1) 
                        draw_box(x - zoom_factor, y, zoom_factor, zoom_factor);
                    else
                        draw_box(x + zoom_factor, y, zoom_factor, zoom_factor);
                }
            }
        }
        set_opaque();
        if(flash_it) flash(1);
        overlay_visible = !overlay_visible;
    }
    
    void get_erase_coords(int *x1, int *y1, int *x2, int *y2)
    {
        *x1 = cursor_x - (cursor_x % 8);
        *y1 = cursor_y - (cursor_y % 8);
        *x2 = *x1 + 8;
        *y2 = *y1 + 8;
        switch(erase_size)
        {
            case 16:
                *x2 += 8;
                *y2 += 8;
                break;
            case 24:
                *x1 -= 8;
                *y1 -= 8;
                *x2 += 8;
                *y2 += 8;
                break;
            case 32:
                *x1 -= 16;
                *y1 -= 16;
                *x2 += 8;
                *y2 += 8;
                break;
        }
    }
    
    void start_erase()
    {
        push_undo_before();
        erasing = 1;
        update_erase();
    }
    
    void update_erase()
    {
        int x1, y1, x2, y2;
        cursor_x = zoom_x + get_cursor_x() / zoom_factor;
        cursor_y = zoom_y + get_cursor_y() / zoom_factor;
        get_erase_coords(&x1, &y1, &x2, &y2);
        for(int i = y1; i < y2; i++)
        {
            uint8_t *row = fg->get_rows()[i];
            for(int j = x1; j < x2; j++)
            {
                row[j] = 0xff;
            }
        }
        draw();
        draw_overlay(1);
        changed = 1;
    }

    void start_line()
    {
        push_undo_before();
        if(overlay_visible) draw_overlay(0);
        drawing_line = 1;
        line_x1 = cursor_x;
        line_y1 = cursor_y;
        current_line.remove_all();
        draw_overlay(1);
    }
    
    int get_sign(int x)
    {
        if(x < 0) return -1;
        return 1;
    }

// add a point with checking for dupes
    void append_point(point_t *point)
    {
        int got_it = 0;
        for(int i = 0; i < current_line.size(); i++)
        {
            point_t *point2 = current_line.get_pointer(i);
            if(!memcmp(point2, point, sizeof(point_t)))
            {
                got_it = 1;
                break;
            }
        }
        if(!got_it)
        {
            current_line.append(*point);
        }
    }

// double the width for multicolor
    void double_point(point_t *point)
    {
        point_t need;
        need.y = point->y;
        if(point->x % 2)
            need.x = point->x - 1;
        else
            need.x = point->x + 1;
        append_point(&need);
    }

    void update_line()
    {
        if(overlay_visible) draw_overlay(0);

// unconstrained cursor position
        cursor_x = zoom_x + get_cursor_x() / zoom_factor;
        cursor_y = zoom_y + get_cursor_y() / zoom_factor;

// single pixel
        if(cursor_x == line_x1 && cursor_y == line_y1)
        {
            current_line.remove_all();
            draw_overlay(1);
            return;
        }

// determine possible angles from the starting point
        int best_angle;
        int best_i;
        int want_angle;
        int diff;
        int got_it = 0;
        want_angle = (int)(360 * atan2f(line_y1 - cursor_y, cursor_x - line_x1) / 2 / M_PI);

// test 2nd pixel if multicolor
        int border_pixel2 = border_pixel;
        if(multicolor)
        {
            int x1 = border_pixels[border_pixel].x;
            int x2;
            if((x1 % 2) > 0)
                x2 = border_pixels[border_pixel].x - 1;
            else
                x2 = border_pixels[border_pixel].x + 1;
//printf("update_line %d want_angle=%d x1=%d x2=%d\n", 
//__LINE__, (int)want_angle, border_pixels[border_pixel].x, x2);
            int y2 = border_pixels[border_pixel].y;
            for(int i = 0; i < TOTAL_BORDER; i++)
            {
                if(border_pixels[i].x == x2 &&
                    border_pixels[i].y == y2)
                {
                    border_pixel2 = i;
                    break;
                }
            }
        }

        for(int j = 0; j < TOTAL_ANGLES; j++)
        {
            if((angle_starts[border_pixel] & (1 << j)) ||
                (angle_starts[border_pixel2] & (1 << j)))
            {
                int test_angle = angles[j];
                if(!got_it || abs(test_angle - want_angle) < diff)
                {
                    got_it = 1;
                    diff = abs(test_angle - want_angle);
                    best_angle = test_angle;
                    best_i = j;
                }
            }
        }

// printf("update_line %d got_it=%d border_pixel=%d want_angle=%d best_angle=%d best_i=%d\n", 
// __LINE__, got_it, border_pixel, want_angle, best_angle, best_i);


// extend the line to the shortest distance from the current position
        current_line.remove_all();
        if(got_it)
        {
// start of the current cell
            point_t start_point;
            point_t current_point;
            current_point.x = line_x1;
            current_point.y = line_y1;
            point_t slope = slopes[best_i];
            int x_scale = 1;
            if(multicolor && abs(slope.x) == 1)
            {
                slope.y *= 2;
                x_scale = 2;
            }
            int y_count = slope.y;
            int x_count = slope.x;
// start of the last cell in the array
            int cell_start = 0;
// distance of the line from the cursor at cell_start
            float min_distance = -1;
//printf("update_line %d want_angle=%d best_angle=%d slope=%d,%d\n", 
//__LINE__, want_angle, best_angle, slope.x, slope.y);

            while(1)
            {
                start_point = current_point;
                if(abs(slope.x) > abs(slope.y))
                {
                    while(abs(current_point.x - start_point.x) < 8)
                    {
                        append_point(&current_point);
// double the width for multicolor
                        if(multicolor) double_point(&current_point);
                        current_point.x += get_sign(x_count) * x_scale;
                        x_count -= get_sign(x_count);
                        if(x_count == 0 && y_count != 0) 
                        {
                            current_point.y -= get_sign(y_count);
                            y_count -= get_sign(y_count);
                        }
                        if(x_count == 0 && y_count == 0)
                        {
                            x_count = slope.x;
                            y_count = slope.y;
                        }
                    }

                }
                else
                {
                    while(abs(current_point.y - start_point.y) < 8)
                    {
                        append_point(&current_point);
// double the width for multicolor
                        if(multicolor) double_point(&current_point);
                        current_point.y -= get_sign(y_count);
                        y_count -= get_sign(y_count);
                        if(y_count == 0 && x_count != 0) 
                        {
                            current_point.x += get_sign(x_count) * x_scale;
                            x_count -= get_sign(x_count);
                        }
                        if(x_count == 0 && y_count == 0)
                        {
                            x_count = slope.x;
                            y_count = slope.y;
                        }
                    }
                }
                
                float current_distance = hypot(current_point.x - cursor_x,
                    current_point.y - cursor_y);
// printf("update_line %d current_distance=%f min_distance=%f %d %d\n", 
// __LINE__, current_distance, min_distance, 
// current_line.size(), cell_start);
// if it went past the cursor, truncate it & quit
                if(min_distance >= 0 && current_distance > min_distance) 
                {
                    while(current_line.size() > cell_start)
                        current_line.remove();
                    break;
                }
                cell_start = current_line.size();
                min_distance = current_distance;
            }
        }
        draw_overlay(1);
    }

    void finish_line()
    {
        if(overlay_visible) draw_overlay(0);

        int w = bg->get_w();
        int h = bg->get_h();
        uint8_t **rows = fg->get_rows();
        for(int i = 0; i < current_line.size(); i++)
        {
            point_t *point = current_line.get_pointer(i);
            if(point->x >= 0 && point->x < w &&
                point->y >= 0 && point->y < h)
            {
                rows[point->y][point->x] = 0x00;
            }
        }

        drawing_line = 0;
        push_undo_after();
        draw();
        draw_overlay(1);
        changed = 1;
    }

    void abort_drawing()
    {    
// abort line & update overlay
        if(overlay_visible) draw_overlay(0);
        drawing_line = 0;
        draw_overlay(1);
    }


    void push_undo_before()
    {
// free up a level
        if(current_undo >= UNDO_LEVELS)
        {
            VFrame *temp_before = undo_before[0];
            VFrame *temp_after = undo_after[0];
            for(int i = 0; i < UNDO_LEVELS - 1; i++)
            {
                undo_before[i] = undo_before[i + 1];
                undo_after[i] = undo_after[i + 1];
            }
            undo_before[UNDO_LEVELS - 1] = temp_before;
            undo_after[UNDO_LEVELS - 1] = temp_after;
            current_undo--;
            total_undos--;
        }

// put in current level & truncate redos
        undo_before[current_undo]->copy_from(fg);
    }

    void push_undo_after()
    {
        undo_after[current_undo]->copy_from(fg);

        current_undo++;
        total_undos = current_undo;
    }

    void pop_undo()
    {
    //printf("pop_undo %d %d %d\n", __LINE__, current_undo, total_undos);
        if(current_undo > 0)
        {
            current_undo--;
            fg->copy_from(undo_before[current_undo]);
            draw();
        }
    }

    void pop_redo()
    {
    //printf("pop_redo %d %d %d\n", __LINE__, current_undo, total_undos);
        if(current_undo < total_undos)
        {
            fg->copy_from(undo_after[current_undo]);
            current_undo++;
            draw();
        }
    }

};

void load_defaults()
{
    if(!defaults) defaults = new BC_Hash("~/.drawerrc");

	defaults->load();

    window_x = defaults->get("X", window_x);
    window_y = defaults->get("Y", window_y);
    window_w = defaults->get("W", window_w);
    window_h = defaults->get("H", window_h);
    erase_size = defaults->get("ERASE_SIZE", erase_size);
    erase_size -= (erase_size % 8);
    CLAMP(erase_size, 8, 32);
}

void save_defaults()
{
    defaults->update("X", window_x);
    defaults->update("Y", window_y);
    defaults->update("W", window_w);
    defaults->update("H", window_h);
    defaults->update("ERASE_SIZE", erase_size);
    defaults->save();
}


int main(int argc, char *argv[])
{
	if(argc < 3)
	{
		printf("Usage %s <output filename> <background .png image>\n", argv[0]);
		printf("Example: drawer fg.png bg.png\n");
		exit(1);
	}

    printf("Welcome to constrained line drawer\n");
    printf("ESC/q - quit\n");
    printf("s     - save foreground\n");
    printf("h     - hide background\n");
    printf("e     - toggle erase/line mode\n");
    printf("+/-   - change erase size\n");
    printf("z     - undo\n");
    printf("Z     - redo\n");
    printf("wheel - zoom\n");
    printf("left button    - start/stop line/erase\n");
    printf("middle button  - move around\n");
    printf("right button   - cancel line\n");

    fg_filename = argv[1];
    bg_filename = argv[2];

    load_defaults();



	MainWindow *mwindow = new MainWindow;
	mwindow->create_objects();
	mwindow->run_window();
    mwindow->save_defaults(defaults);
    save_defaults();
}

