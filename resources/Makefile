
IMAGES = font8x8-bold.2bpp font8x8-bold-transparent.2bpp font8x16-bold-transparent.2bpp
PALETTES =  $(patsubst %.2bpp,%.clr,$(patsubst %.4bpp,%.clr,$(SOURCES)))

.PHONY: ALL

ALL: $(IMAGES) $(PALETTES)

%.2bpp %.clr: %.pcx
	pcx2snes -n -s8 -c4 $*
	mv $*.pic $*.2bpp

%.4bpp %.clr: %.pcx
	pcx2snes -n -s8 -c16 $*
	mv $*.pic $*.4bpp

.PHONY: clean
clean:
	$(RM) $(IMAGES) $(PALETTES)

.PRECIOUS: $(PALETTES)

