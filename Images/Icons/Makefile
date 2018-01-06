.PHONY: build clean
.PRECIOUS: Icon.ico

Icon.ico: Icon.svg
	./BuildIcon.sh

build: Icon.ico

clean:
	rm -f *.png *.ico
