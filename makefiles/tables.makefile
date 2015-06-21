
# Disable Builtin rules
.SUFFIXES:
.DELETE_ON_ERROR:
MAKEFLAGS += --no-builtin-rules

TABLES = $(patsubst %.py,%.inc, $(wildcard *.py))

.PHONY: all
all: $(TABLES)

%.inc: %.py
	python3 $< >| $@


.PHONY: clean
clean::
	$(RM) $(TABLES)

