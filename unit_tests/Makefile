
ROM_NAME    = unit_tests
CONFIG      = LOROM_1MBit
API_DIR     = ..
SOURCE_DIR  = .
RESOURCES_DIR = ../resources

# All API Modules
API_MODULES  = $(patsubst $(API_DIR)/routines/%.s,%,$(wildcard $(API_DIR)/routines/*.s $(API_DIR)/routines/*/*/.s))

include ../Makefile.in

