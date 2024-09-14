#!/bin/bash

ftex="$1"
fmd="${ftex%.*}.md"

pandoc -f latex+raw_tex -t markdown+raw_tex --lua-filter latex-to-md-filter.lua -o "$fmd" "$1"