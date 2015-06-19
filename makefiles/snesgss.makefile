
# Disable Builtin rules
.SUFFIXES:
MAKEFLAGS += --no-builtin-rules

API_DIR := $(realpath $(dir $(lastword $(MAKEFILE_LIST)))/../)

COMBINE_GSM = $(API_DIR)/utils/combine-gsm.py
SNESGSS_BUILD_INCS = $(API_DIR)/utils/snesgss_build_incs.py

SFXES	 = $(wildcard sfx/*.gsm)
MUSICS	 = $(wildcard music/*.gsm)


.PHONY: all
all: export/ export/snesgss.inc export/snesgss.inc.h


export/snesgss.inc export/snesgss.inc.h: export/spc700.bin
	"$(SNESGSS_BUILD_INCS)" export

export/spc700.bin: export/combined.gsm
	snesgss-export export/combined.gsm export

export/combined.gsm: $(SFXES) $(MUSICS)
	$(RM) export/*.bin
	"$(COMBINE_GSM)" $(SFXES) $(MUSICS) >|  $@

export/:
	mkdir export

.PHONY: clean
clean::
	$(RM) export/combined.gsm export/*.bin export/*.h export/*.inc export/*.asm

