.PHONY: build clean

DIRS := Design Glyphs Icons
DIRS_BUILD := $(DIRS:%=%-build)
DIRS_CLEAN := $(DIRS:%=%-clean)

build: $(DIRS_BUILD)
clean: $(DIRS_CLEAN)

.PHONY: $(DIRS_BUILD) $(DIRS_CLEAN)

$(DIRS_BUILD):
	+cd $(@:%-build=%) && make build

$(DIRS_CLEAN):
	+cd $(@:%-clean=%) && make clean
