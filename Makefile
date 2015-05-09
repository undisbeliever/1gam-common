
SOURCES  = $(wildcard routines/*.s) $(wildcard routines/*/*.s)
OBJECTS  = $(patsubst routines/%.s,obj/%.o,$(SOURCES))

EXAMPLES = $(wildcard examples/*.s)
EXAMPLE_OBJECTS = $(patsubst examples/%.s,examples/obj/%.o,$(EXAMPLES))

BINARIES = $(patsubst examples/%.s,examples/bin/%.sfc,$(EXAMPLES))

HEADERS = $(wildcard */*.inc */*.h)
CONFIG = config/LOROM_1MBit.cfg

.PHONY: all
all: dirs resources $(OBJECTS) $(BINARIES)

# Dependancy modules for each binary.
# $^ will include all of them in linker
examples/bin/flashing_colors.sfc: obj/reset-snes.o
examples/bin/game_of_life.sfc: obj/reset-snes.o obj/cpu-usage.o obj/block.o
examples/bin/print_test.sfc: obj/reset-snes.o obj/math.o obj/block.o obj/text.o obj/text8x8.o 
examples/bin/timer.sfc: obj/reset-snes.o obj/math.o obj/text.o obj/block.o obj/text8x8.o obj/text8x16.o 

# Resources used in .o files
examples/obj/print_test.o: resources/font8x8-bold.2bpp
examples/obj/timer.o: resources/font8x8-bold-transparent.2bpp resources/font8x16-bold-transparent.2bpp

# Maths is split up
obj/math.o: $(wildcard routines/math/*.asm) 

examples/bin/%.sfc: examples/obj/%.o
	ld65 -vm -m $(@:.sfc=.memlog) -C $(CONFIG) -o $@ $^
	cd examples/bin/ && ucon64 --snes --nhd --chk $(notdir $@)


examples/obj/%.o: examples/%.s
	ca65 -I . -o $@ $<

obj/%.o: routines/%.s
	ca65 -I . -o $@ $<

$(OBJECTS) : $(HEADERS) $(CONFIG)
$(EXAMPLE_OBJECTS) : $(HEADERS) $(CONFIG)


.PHONY: dirs
dirs: obj/ examples/obj/ examples/bin/

obj/:
	mkdir $(sort $(dir $(OBJECTS)))

examples/obj/:
	mkdir $(sort $(dir $(EXAMPLE_OBJECTS)))

examples/bin/:
	mkdir $(sort $(dir $(BINARIES)))


.PHONY: resources
resources:
	cd resources/ && $(MAKE)

.PHONY: clean
clean:
	$(RM) $(OBJECTS) $(EXAMPLE_OBJECTS)
	cd resources/ && $(MAKE) clean
	$(MAKE) -C resources clean

.PRECIOUS: $(EXAMPLE_OBJECTS)

