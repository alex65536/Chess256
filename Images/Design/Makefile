.PHONY: build clean

SVGS := $(wildcard *.svg)
PNGS := $(SVGS:%.svg=%.png)

build: $(PNGS)

clean:
	rm -rf *.png

%.png : %.svg
	inkscape $^ -e $@
