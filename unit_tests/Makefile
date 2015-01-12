
API_DIR = ..
API_MODULES = $(wildcard $(API_DIR)/obj/*.o)

CONFIG = $(API_DIR)/config/LOROM_1MBit.cfg

BIN = bin/unit_tests.sfc
OBJECTS = bin/unit_tests.o
INCLUDES = $(wildcard *.inc tests/*.asm)
RESOURCES = $(API_DIR)/resources/font8x8-bold-transparent.2bpp $(API_DIR)/resources/font8x16-bold-transparent.2bpp


.PHONY: all

all: $(BIN)

$(BIN): $(API_MODULES) $(OBJECTS)
	ld65 -vm -m $(@:.sfc=.memlog) -C $(CONFIG) -o $@ $^

$(OBJECTS) : $(INCLUDES) $(CONFIG) $(API_MODULES) $(RESOURCES) Makefile

bin/%.o: %.s
	ca65 -I $(API_DIR) -o $@ $<



.PHONY: clean
clean:
	$(RM) $(BIN) $(OBJECTS)


