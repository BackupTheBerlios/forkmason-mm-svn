CC=gcc
CFLAGS=-g -Wall -fPIC

COMPILE = $(CC) $(CFLAGS)
LINK = $(CC) $(CFLAGS)

INSTALL = /usr/bin/install -c
INSTALL_DATA = $(INSTALL) -m 644
INSTALL_PROGRAM = $(INSTALL) -m 755

CONVERT=convert

MAP8=$(CONVERT) -map colormap_256.png -depth 8 -dither
MAP4=$(CONVERT) -map colormap_16.png -depth 4 -dither
EXTRACT=$(CONVERT) -extract
RESIZE=$(CONVERT) -resize
SCALE=$(CONVERT) -scale
COMPOSITE=composite

PRIMARY=src/usplash_primary.png

top: tmp colormaps usplash-theme-gnewsense.so

tmp:
	mkdir tmp

usplash256.png: $(PRIMARY)
	$(CONVERT) -depth 8 -colors 253 -dither $(PRIMARY) usplash256.png

usplash16.png: $(PRIMARY)
	$(CONVERT) -depth 4 -colors 13 -dither $(PRIMARY) usplash16.png

colormaps: usplash256.png usplash16.png
	$(CONVERT) -unique-colors -depth 8 -colors 253 -dither usplash256.png tmp/colormap_256.png
	$(CONVERT) -unique-colors -depth 4 -colors 13 -dither usplash16.png tmp/colormap_16.png
	$(CONVERT) -size 256x1 xc:white -fill red -draw "point 255,0" red256.png 
	$(CONVERT) -size 255x1 xc:white -fill green -draw "point 254,0" green256.png 
	$(COMPOSITE) -compose atop -geometry +0+0 green256.png red256.png greenred256.png
	$(COMPOSITE) -compose atop -geometry +0+0 tmp/colormap_256.png greenred256.png tmp/green_red_colormap_256.png
	$(CONVERT) -depth 8 -colors 256 tmp/green_red_colormap_256.png colormap_256.png
	$(CONVERT) -size 16x1 xc:white -fill red -draw "point 15,0" red16.png 
	$(CONVERT) -size 15x1 xc:white -fill green -draw "point 14,0" green16.png 
	$(COMPOSITE) -compose atop -geometry +0+0 green16.png red16.png greenred16.png
	$(COMPOSITE) -compose atop -geometry +0+0 tmp/colormap_16.png greenred16.png tmp/green_red_colormap_16.png
	$(CONVERT) -depth 4 -colors 16 tmp/green_red_colormap_16.png colormap_16.png

throbber_back.png: usplash256.png
	$(EXTRACT) 320x18+1280+1182 $< tmp/$@
	$(MAP8) tmp/$@ $@

throbber_fore.png: usplash256.png
	$(EXTRACT) 320x18+0+1182 $< tmp/$@
	$(MAP8) tmp/$@ $@

throbber_back_16.png: usplash16.png
	$(EXTRACT) 216x8+1384+1160 $< tmp/$@
	$(MAP4) tmp/$@ $@

throbber_fore_16.png: usplash16.png
	$(EXTRACT) 216x8+0+1160 $< tmp/$@
	$(MAP4) tmp/$@ $@

usplash256_base.png: usplash256.png
	$(EXTRACT) 1301x976+150+0 $< tmp/$@
	$(MAP8) tmp/$@ $@

usplash_1600_938_base.png: usplash256.png
	$(EXTRACT) 1600x938+0+0 $< tmp/$@
	$(MAP8) tmp/$@ $@

usplash16_base.png: usplash16.png
	$(EXTRACT) 1561x976+20+0 $< tmp/$@
	$(MAP4) tmp/$@ $@

usplash_1024_768.png: usplash256_base.png
	$(RESIZE) 1024  $(8BITS) $< tmp/$@
	$(MAP8) tmp/$@ $@

usplash_1024_600.png:  usplash_1600_938_base.png
	$(RESIZE) 1024 $< tmp/$@
	$(MAP8) tmp/$@ $@

usplash_1365_768.png: usplash256.png
	$(EXTRACT) 1365x768+118+0 $< tmp/$@
	$(MAP8) tmp/$@ $@

usplash_1365_768_scaled.png: usplash_1365_768.png
	$(SCALE) 1024x768! $(8BITS) $< tmp/$@
	$(MAP8) tmp/$@ $@

usplash_640_400.png:  usplash16_base.png
	$(RESIZE) 640 $< tmp/$@
	$(MAP4) tmp/$@ $@

usplash_640_480.png:  usplash256_base.png
	$(RESIZE) 640 $< tmp/$@
	$(MAP8) tmp/$@ $@

usplash_800_600.png:  usplash256_base.png
	$(RESIZE) 800 $< tmp/$@
	$(MAP8) tmp/$@ $@

usplash-theme-gnewsense.o:
	$(COMPILE) -o usplash-theme-gnewsense.o -c src/usplash-theme-gnewsense.c

usplash-theme-gnewsense.so: \
	throbber_back.png.c.o \
	throbber_back_16.png.c.o \
	throbber_fore.png.c.o \
	throbber_fore_16.png.c.o \
	usplash_1024_600.png.c.o \
	usplash_1024_768.png.c.o \
	usplash_1365_768_scaled.png.c.o \
	usplash_800_600.png.c.o \
	usplash_640_400.png.c.o \
	usplash_640_480.png.c.o \
	usplash-theme-gnewsense.o
	$(COMPILE) -shared -o $@ $^

%.png.c: %.png
	pngtousplash $< > $@

%.bdf.c: %.bdf
	bdftousplash $< > $@

%.c.o: %.c
	$(COMPILE) -o $@ -c $<

install:
	$(INSTALL) -d $(DESTDIR)/usr/lib/usplash
	$(INSTALL_PROGRAM) usplash-theme-gnewsense.so $(DESTDIR)/usr/lib/usplash/usplash-theme-gnewsense.so
clean:
	rm -f *.png.c *.bdf.c *.c.o *.so *.png *.o tmp/*
	rmdir tmp
	find ./ -name *.svn -exec rm -rv {} +

