#!/bin/bash

filename="$1" # pdf file to sew
outname="$2" # sewn pdf output file

# paper dimensions ... not in pdftk dum_data
# ASSUME: 8.5 x 11 in paper size.
width_in=17 # page width in inches
height_page_in=7 # page height in inches minus 1in+1in trim (warning: can't use floating point without bc calculator)

max_height=222

# get number of pages in pdf
n_pages=$(pdftk "$filename" dump_data | grep NumberOfPages  | cut -f2 -d' ')

# compute height after sewing vertically
# height_sewn=$(($n_pages * $height_page_in))
height_sewn=$(echo $n_pages*$height_page_in | bc)

if (( $(echo "$height_sewn > $max_height" |bc -l) )); then
	width_in=$(echo $max_height*$width_in/$height_sewn | bc);
	height_sewn=$max_height;
fi;

echo "height to sew: ${height_sewn}"
echo "resulting width: ${width_in}"
# sew using pdfjam/pdfnup (available in TeXLive)
pdfjam \
	--nup 1x"$(($n_pages + 1))" \
	--suffix '_' \
	--frame false \
	--trim '0cm .45in 0cm .45in' \
	--clip true \
	--no-landscape \
	--papersize "{${width_in}in,${height_sewn}in}" \
	--openright true \
	--outfile "$2" \
	"$1"
