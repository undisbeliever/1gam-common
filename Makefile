
SOURCES  = $(wildcard routines/*.s)
OBJECTS  = $(patsubst routines/%.s,obj/%.o,$(SOURCES))

EXAMPLES = $(wildcard examples/*.s)
EXAMPLE_OBJECTS = $(patsubst examples/%.s,examples/obj/%.o,$(EXAMPLES))

BINARIES = $(patsubst examples/%.s,examples/bin/%.sfc,$(EXAMPLES))

HEADERS = $(wildcard */*.inc */*.h)
CONFIG = config/LOROM_1MBit.cfg

.PHONY: all
all: resources $(BINARIES)

$(BINARIES): $(CONFIG) $(OBJECTS)

examples/bin/%.sfc: examples/obj/%.o $(OBJECTS)
	ld65 -vm -m $(@:.sfc=.memlog) -C $(CONFIG) -o $@ $< $(OBJECTS)

examples/obj/%.o: examples/%.s
	ca65 -I . -o $@ $<

obj/%.o: routines/%.s
	ca65 -I . -o $@ $<

$(OBJECTS) : $(HEADERS)
$(EXAMPLE_OBJECTS) : $(HEADERS)

.PHONY: resources
resources:
	cd resources/ && $(MAKE)

.PHONY: clean
clean:
	$(RM) $(OBJECTS) $(EXAMPLE_OBJECTS)
	cd resources/ && $(MAKE) clean
	$(MAKE) -C resources clean

.PRECIOUS: $(EXAMPLE_OBJECTS)

