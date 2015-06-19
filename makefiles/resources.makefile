
# Disable Builtin rules
.SUFFIXES:
MAKEFLAGS += --no-builtin-rules

API_DIR  := $(realpath $(dir $(lastword $(MAKEFILE_LIST)))/../)

MAPS      = $(patsubst %.pcx,%.map, $(wildcard images8bpp/*.pcx))
MAPS     += $(patsubst %.pcx,%.map, $(wildcard images4bpp/*.pcx))
MAPS     += $(patsubst %.pcx,%.mp7, $(wildcard mode7/*.pcx))
TILES     = $(patsubst %.pcx,%.8bpp,$(wildcard images8bpp/*.pcx))
TILES    += $(patsubst %.pcx,%.4bpp,$(wildcard images4bpp/*.pcx))
TILES    += $(patsubst %.pcx,%.8bpp,$(wildcard tiles8bpp/*.pcx))
TILES    += $(patsubst %.pcx,%.4bpp,$(wildcard tiles4bpp/*.pcx))
TILES    += $(patsubst %.pcx,%.2bpp,$(wildcard tiles2bpp/*.pcx))
TILES    += $(patsubst %.pcx,%.pc7, $(wildcard mode7/*.pcx))
PALETTES  = $(patsubst %.4bpp,%.clr,$(patsubst %.2bpp,%.clr, $(patsubst %.pc7,%.clr,$(TILES))))

.PHONY: all
all: snesgss entities $(MAPS) $(TILES) $(PALETTES)

tiles2bpp/%.2bpp tiles2bpp/%.clr: tiles2bpp/%.pcx
	pcx2snes -n -s8 -c4 -o4 $(basename $<)
	mv $(basename $<).pic $(basename $<).2bpp

tiles4bpp/%.4bpp tiles4bpp/%.clr: tiles4bpp/%.pcx
	pcx2snes -n -s8 -c16 -o16 $(basename $<)
	mv $(basename $<).pic $(basename $<).4bpp

images4bpp/%.map images4bpp/%.4bpp images4bpp/%.clr: images4bpp/%.pcx
	pcx2snes -r -s8 -c16 -screen $(basename $<)
	mv $(basename $<).pic $(basename $<).4bpp

mode7/%.mp7 mode7/%.pc7 mode7/%.clr: mode7/%.pcx
	pcx2snes -screen7 $(basename $<)


.PHONY: snesgss
snesgss:
ifneq (,$(wildcard snesgss/))
  ifneq (,$(wildcard snesgss/Makefile))
	$(MAKE) -C snesgss
  else
	$(MAKE) -C snesgss -f "$(realpath $(API_DIR)/makefiles/snesgss.makefile)"
  endif
endif

.PHONY: entities
entities:
ifneq (,$(wildcard entities/Makefile))
	$(MAKE) -C entities
endif

.PHONY: clean
clean::
	$(RM) $(MAPS) $(TILES) $(PALETTES)
ifneq (,$(wildcard snesgss/))
  ifneq (,$(wildcard snesgss/Makefile))
	$(MAKE) -C snesgss clean
  else
	$(MAKE) -C snesgss -f "$(realpath $(API_DIR)/makefiles/snesgss.makefile)" clean
  endif
endif
ifneq (,$(wildcard entities/Makefile))
	$(MAKE) -C entities clean
endif


