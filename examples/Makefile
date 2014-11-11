
SOURCES  = $(wildcard *.s)
OBJECTS  = $(patsubst %.s,obj/%.o,$(SOURCES))
BINARIES = $(patsubst %.s,bin/%.sfc,$(SOURCES))

DEPENDS = $(wildcard ../includes/*.inc ../routines/*.s ../routines/*/*.s ../routines/*.h ../routines/*/*.h)
CONFIG = ../config/LOROM_1MBit.cfg

.PHONY: all
all: bin $(BINARIES)

$(BINARIES): $(CONFIG)

bin/%.sfc: obj/%.o
	ld65 -vm -m $(@:.sfc=.memlog) -C $(CONFIG) -o $@ $<

obj/%.o: %.s $(DEPENDS)
	ca65 -I .. -o $@ $<

.PHONY: clean
clean:
	$(RM) $(OBJECTS)

.PRECIOUS: $(OBJECTS)

