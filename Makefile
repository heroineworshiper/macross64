OBJDIR := $(shell uname --machine)
CC65_DIR := /root/cc65-master/bin/
AS := $(CC65_DIR)ca65
CC := $(CC65_DIR)cc65
LD := $(CC65_DIR)ld65
CC := g++
CXXFLAGS := -O3 -I/amazon/root/guicast
LFLAGS := ../hvirtual/guicast/$(OBJDIR)/libguicast.a \
	../hvirtual/guicast/$(OBJDIR)/libcmodel.a \
	-lX11 \
	-lXext \
	-lXv \
	-lpthread \
	-lm \
	-lpng \
        -lGL \
        -lXft

MACROSS_DEPS := \
	world.s \
	fastload.inc \
	loader.s \
	macross.cfg \
	macross.s \
	common.inc \
	common.s \
	scroll.inc \
	bitmapunroll.s

MARINERIS_DEPS := \
        marineris.s \
        marineris.cfg \
        world2.s \
        fastload.inc \
	loader.s \
	common.inc \
	common.s \
	marineris_scroll.s

makeworld: makeworld.c
	gcc -O2 -o makeworld makeworld.c -lpng
makeworld2: makeworld2.c
	gcc -g -O2 -o makeworld2 makeworld2.c -lpng -lm

fastload.inc: fastload.s
	rm -f test_read.d64
	$(AS) fastload.s
	$(LD) -C fastload.cfg fastload.o -o fastload.prg
	./bintoasm.py fastload.prg > fastload.inc

marineris.d64: $(MARINERIS_DEPS)
	rm -f marineris.d64
	$(AS) -t c64 marineris.s
	$(LD) -C marineris.cfg -m marineris.map marineris.o -o marineris c64.lib
	c1541 -format "marineris,00" d64 marineris.d64
	c1541 -attach marineris.d64 -write marineris marineris,p
	dd if=world2.d64 of=marineris.d64 conv=notrunc bs=256

macross.d64: $(MACROSS_DEPS)
	rm -f macross.d64
	$(AS) -t c64 macross.s
	$(LD) -C macross.cfg -m macross.map macross.o -o macross c64.lib
	c1541 -format "macross,00" d64 macross.d64
	c1541 -attach macross.d64 -write macross macross,p
	dd if=world.d64 of=macross.d64 conv=notrunc bs=256


bitmapscroll.d64: bitmapscroll.s
	$(AS) -t c64 bitmapscroll.s
	$(LD) -m bitmapscroll.map -t c64 bitmapscroll.o -o bitmapscroll c64.lib
	c1541 -format "bitmapscroll,00" d64 bitmapscroll.d64
	c1541 -attach bitmapscroll.d64 -write bitmapscroll bitmapscroll,p

bitmapscroll_slow.d64: bitmapscroll_slow.s
	$(AS) -t c64 bitmapscroll_slow.s
	$(LD) -m bitmapscroll_slow.map -t c64 bitmapscroll_slow.o -o bitmapscroll_slow c64.lib
	c1541 -format "disk,00" d64 bitmapscroll_slow.d64
	c1541 -attach bitmapscroll_slow.d64 -write bitmapscroll_slow bitmapscroll_slow,p

test_read.d64: test_read.s fastload.inc test_read.cfg world.d64
	rm -f test_read.d64
	$(AS) -t c64 test_read.s
	$(LD) -C test_read.cfg -m test_read.map test_read.o -o test_read c64.lib
	c1541 -format "disk,00" d64 test_read.d64
	c1541 -attach test_read.d64 -write test_read test_read,p
	dd if=world.d64 of=test_read.d64 conv=notrunc

test.d64: test.s common.inc common.s
	rm -f test.d64
	$(AS) -t c64 test.s
	$(LD) -C macross.cfg -m test.map test.o -o test c64.lib
	c1541 -format "disk,00" d64 test.d64
	c1541 -attach test.d64 -write test test,p

tables: tables.c
	gcc -o tables tables.c

drawer: drawer.C
	$(CC) -o drawer drawer.C $(CXXFLAGS) $(LFLAGS)

run: disk.d64
	x64 -VICIIdsize -ntsc -autostart disk.d64  


clean:
	rm -f disk.d64 drawer

