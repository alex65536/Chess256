#!/bin/bash

. IconSizes.sh

ICON_FILES=()

for SIZE in "${SIZES[@]}"; do
	CUR_ICON="Icon${SIZE}.png"
	ICON_FILES+=("${CUR_ICON}")
	inkscape Icon.svg -e "${CUR_ICON}" -w "${SIZE}" -h "${SIZE}"
done

convert "${ICON_FILES[@]}" Icon.ico
