#!/bin/bash
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

# Usage: InstallIcon.sh <dest dir>
#
# To install the icons into the system, <dest dir> must be like this:
# /usr/share

set -e

. IconSizes.sh

DEST_DIR="$1/icons/hicolor"

for SIZE in "${SIZES[@]}"; do
	CUR_ICON="Icon${SIZE}.png"
	CUR_DIR="${DEST_DIR}/${SIZE}x${SIZE}/apps"
	mkdir -p "${CUR_DIR}"
	install -T "${CUR_ICON}" "${CUR_DIR}/chess256.png"
done
