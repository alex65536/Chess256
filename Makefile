# This file is part of Chess 256.
# 
# Copyright © 2018 Alexander Kernozhitsky <sh200105@mail.ru>
# 
# Chess 256 is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Chess 256 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Chess 256.  If not, see <http://www.gnu.org/licenses/>.

.PHONY: build build-sf32 build-sf64 build-sf build-img build-all
.PHONY: clean clean-sf clean-img clean-all
.PHONY: help default install

default: help

PREFIX = /usr/local
INSTALL_PREFIX = $(DESTDIR)$(PREFIX)

# Determine OS
ifeq ($(OS), Windows_NT)
    BUILD_OS := Windows
else
    BUILD_OS := $(shell uname -s)
endif

#Determine CPU
ifeq ($(BUILD_OS), Windows)
	ifeq ($(PROCESSOR_ARCHITECTURE), x86)
		BUILD_CPU := i386
	else ifeq ($(PROCESSOR_ARCHITECTURE), AMD64)
		BUILD_CPU := x86_64
	else
		BUILD_CPU := unknown
	endif
else
	BUILD_CPU := $(shell uname -m)
endif

# Check if we can build for this CPU and OS
.PHONY: check
check:
ifneq ($(BUILD_CPU), $(filter $(BUILD_CPU), i386 x86_64))
	@echo "Fatal error: Unknown CPU: $(BUILD_CPU)"
	@echo "-------------------------------------------------------------------------------"
	@echo "This CPU is not supported now, but if you know how to port Chess 256 for this"
	@echo "CPU architecture, you can modify the program and contribute to its repository:"
	@echo "https://github.com/alex65536/Chess256"
	@false
endif
ifneq ($(BUILD_OS), $(filter $(BUILD_OS), Windows Linux))
	@echo "Fatal error: Unknown OS: $(BUILD_OS)"
	@echo "-------------------------------------------------------------------------------"
	@echo "This OS is not supported now, but if you know how to port Chess 256 for this"
	@echo "operating system, you can modify the program and contribute to its repository:"
	@echo "https://github.com/alex65536/Chess256"
	@false
endif

help: check
	@echo "Welcome to the Chess 256 build system!"
	@echo "Copyright (C) 2018 Alexander Kernozhitsky"
	@echo "This is free software; see the GNU General Public License version 3 or later "
	@echo "for copying conditions. There is NO warranty; not even for MERCHANTABILITY or "
	@echo "FITNESS FOR A PARTICULAR PURPOSE."
	@echo "-------------------------------------------------------------------------------"
	@echo "Available targets:"
	@echo "    build      Builds Chess 256."
	@echo "    build-sf32 Builds Stockfish (for i386 CPU architecture)."
	@echo "    build-sf64 Builds Stockfish (for x86_64 CPU architecture)."
	@echo "    build-sf   Builds Stockfish (automatically detecting CPU architecture)."
	@echo "    build-img  Builds images from their SVG sources into PNG."
	@echo "    build-all  Builds everything."
	@echo "    clean      Cleans Chess 256."
	@echo "    clean-sf   Cleans Stockfish."
	@echo "    clean-img  Cleans built images."
	@echo "    clean-all  Cleans everything."
	@echo "    help       Shows this help."
	@echo "    install    Installs Chess 256 to the system."

build: check
	cd Sources && lazbuild Chess256.lpi

STOCKFISH_SRC_EXE = "stockfish"
STOCKFISH_TARGET_EXE = "stockfish-$(DEFINED_CPU)"

ifeq ($(BUILD_OS), Windows)
	STOCKFISH_SRC_EXE = "$(STOCKFISH_SRC_EXE).exe"
	STOCKFISH_TARGET_EXE = "$(STOCKFISH_TARGET_EXE).exe"
endif

build-sf32: DEFINED_CPU := i386
build-sf32: DEFINED_SF_CPU := x86-32
build-sf64: DEFINED_CPU := x86_64
build-sf64: DEFINED_SF_CPU := x86-64-modern

build-sf32 build-sf64: check
	@# It seems that, without make clean, Stockfish building fails when invoked twice in a row.
	+cd Stockfish/src && make clean
	+cd Stockfish/src && make build ARCH=$(DEFINED_SF_CPU)
	cp Stockfish/src/$(STOCKFISH_SRC_EXE) Binary/$(STOCKFISH_TARGET_EXE)

.PHONY: build-sf-i386 build-sf-x86_64
build-sf-i386: build-sf32
build-sf-x86_64: build-sf64

build-sf: check build-sf-$(BUILD_CPU)

build-img: check
	+cd Images && make build

build-all: check build build-sf build-img

clean: check
	rm -rf Sources/backup
	rm -rf Sources/lib
	$(RM) Binary/Chess256

clean-sf: check
	+cd Stockfish/src && make clean
	$(RM) Binary/stockfish*

clean-img: check
	+cd Images && make clean

clean-all: check clean clean-sf clean-img

install:
	install -D -T Binary/Chess256 $(INSTALL_PREFIX)/bin/chess256
	+cd Images && make install PREFIX=$(INSTALL_PREFIX)
	install -D -T Other/Chess256.desktop $(INSTALL_PREFIX)/share/applications/chess256.desktop
