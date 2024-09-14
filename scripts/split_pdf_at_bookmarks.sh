#!/bin/bash

echo "Splitting pdf at bookmarks"

# check os for sed compatibility
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux
                alias SED=sed;;
    Darwin*)    machine=Mac
                alias SED=gsed;;
    CYGWIN*)    machine=Cygwin
                alias SED=sed;;
    MINGW*)     machine=MinGw
                alias SED=sed;;
    *)          machine="UNKNOWN:${unameOut}"
                alias SED=sed
esac

infile=$1 # input pdf
outputprefix=$2 # to be prepended
if [ "$#" -ne 2 ]
then
  splitdir=$3
else
  splitdir='split'
fi
inname=$(basename ${infile%.*}) # sans extension
wdir=$(dirname "${infile}")
mkdir -p "${wdir}/${splitdir}"
rm -r -f "${wdir}/${splitdir}/*"
mkdir -p "${wdir}/${splitdir}/full"
mkdir -p "${wdir}/${splitdir}/partial"

# [ -e "$infile" -a -n "$outputprefix" ] || echo "Something wrong with input. Exiting ..."; exit 1 # Invalid args

# get bookmark lecture numbers, lecture names, and page numbers from .toc file
chapsectable=$(SED '/subsection/d' "$inname".toc | \
  SED '/paragraph/d' | \
  SED 's/\\contentsline {part}{\\partnumberline {/part_/g' | \
  SED 's/\\contentsline {chapter}{Preface*/000/g' | \
  SED 's/\\contentsline {chapter}{\\nameref {sec:preface}.*/000/g' | \
  SED 's/\\contentsline {chapter}{\\chapternumberline {//g' | \
  SED 's/\\contentsline {section}{\\numberline {//g' | \
  SED 's/\\contentsline {section}{Resource {//g' | \
  SED 's/\\contentsline {appendix}{\\chapternumberline {//g' | \
  SED 's/{\\hphantom {\\hbox to\\@tempdima {\(.*\)\\hfil }\\leftprotrusion }//g' | \
  SED 's/}/~~/' | \
  SED 's/}{[^}{}]*//2g' | \
  SED 's/}{/~~/' | \
  SED 's/}%//' | \
  SED '/\./!d' | \
  SED 's/\\xcapitalisewords {\(.*\)}/\1/g' | \
  SED 's/\\texttt {//g' ) # parse .toc for most data

# echo "${chapsectable[*]}"

lecture_numbers_f=$(SED '/subsection/d' "$inname".toc | \
  SED '/section\./!d' | \
  SED 's/^.*\(section.*}\).*$/\1/' | \
  SED 's/section\.//' | \
  SED 's/}//' ) # parse .toc for section numbers (works for acronym sections!)

# lecture_numbers_f_clean=$(echo "${lecture_numbers_f}" | \
#     SED 's/\./_/g' )

# readarray -t lecture_numbers < "${lecture_numbers_f_clean}"
# mapfile -t lecture_numbers < <(lecture_numbers_f_clean)
# echo "${lecture_numbers_f[*]}"
# exit 0

# get the page number offset after front matter pages with roman numeral numbering
pdftk_data=$(pdftk "$infile" dump_data)
first_page=$(echo "$pdftk_data" | awk '/PageLabelNewIndex:/ {++count; if (count == 2) print $2}') # Extract the number after "PageLabelNewIndex:" and save it to a variable
first_page=$((first_page - 1)) # shift by one
echo "First numbered page: $first_page" # Now $first_page contains the extracted number

j=0 # lecture index counter
while IFS='~~' read -ra ADDR; do
  for i in "${!ADDR[@]}"; do
    # echo "--- $i"
    # echo "${ADDR[$i]}"
    # echo $(( $i % 5 ))
    if [[ $i == 0 ]]; then
        # echo "lec number"
        # lecture_acronyms["$j"]="${ADDR[$i]}"
        lecture_numbers["$j"]="${ADDR[$i]}"
    elif [[ $i == 2 ]]; then
        # echo "lec name"
        lecture_names["$j"]="${ADDR[$i]}"
    elif [[ $i == 4 ]]; then
        # echo "page num"
        lecture_page_numbers["$j"]="$((ADDR[$i] + first_page))"
        let "j++" # increment lecture index counter
    fi
    # echo $(( $i % 5 ))
    # if [[ $(( $i % 5 )) == 0 ]]; then
    #     echo "lec number"
    #     lecture_acronyms["$j"]="${ADDR[$i]}"
    # elif [[ $(( $i % 5 )) == 2 ]]; then
    #     echo "lec name"
    #     lecture_names["$j"]="${ADDR[$i]}"
    # elif [[ $(( $i % 5 )) == 4 ]]; then
    #     echo "page num"
    #     lecture_page_numbers["$j"]="${ADDR[$i]}"
    #     # echo "lecture_page_numbers["$j"]: ${lecture_page_numbers["$j"]}"
    #     let "j++" # increment lecture index counter
    # fi
  done
done <<< "$chapsectable"

# printf '%s\n' "${lecture_names[@]}"
# echo "Lecture numbers: ${lecture_numbers[@]}"

# j=0 # lecture index counter
# while IFS='~~' read -ra ADDR; do
#   for i in "${!ADDR[@]}"; do
#     echo "$j"
#     echo "${ADDR[$i]}"
#     lecture_numbers["$j"]="${ADDR[$i]}" # don't know why I have to mix i and j
#     let "j++" # increment lecture index counter
#   done
# done <<< "$lecture_numbers_f"

# echo "Lecture numbers: ${lecture_numbers[@]}"

j=0 # lecture index counter
for i in "${!lecture_names[@]}"; do
  lecture_names_clean[$i]=$(echo "${lecture_names[$i]}" | \
    SED 's/ /_/g' | \
    SED "s/'/_/g" | \
    SED "s/,/_/g" | \
    SED "s/:/_/g" | \
    SED "s/?//g" )
  # lecture_acronyms_clean[$i]=$(echo "${lecture_numbers[$i]}" | \
  #   SED 's/\./-/g' | \
  #   SED 's/[[:space:]]*$//' )
  # echo "Lecture number: ${lecture_numbers[$j]}"
  lecture_numbers_clean[$j]=$(echo "${lecture_numbers[$j]}" | \
    SED 's/\./-/g' )
  let "j++" # increment lecture index counter
done

for i in "${!lecture_numbers_clean[@]}"; do
  cha=$(echo ${lecture_numbers[$i]} | cut -f1 -d.)
  sec=$(echo ${lecture_numbers[$i]} | cut -f2 -d.)
  # echo "Chapter: $cha"
  # echo "Section: $sec"
  if [[ $cha == [A-Z] ]] ; then
    lecture_numbers_clean[$i]=$(printf "%s-%02d" ${cha} ${sec})
  else
    lecture_numbers_clean[$i]=$(printf "%02d-%02d" ${cha} ${sec})
  fi
done

# echo "Lecture numbers clean: ${lecture_numbers_clean[*]}"
# exit 0

# actually extract each lecture file
# rm "$PWD/${splitdir}/${outputprefix}*" # clear directory ... no idea why this throws an error
n_lectures="$(expr ${#lecture_page_numbers[@]} - 1)"
for i in ${!lecture_page_numbers[@]}; do
  a=${lecture_page_numbers[$i]} # start page number
  if [[ "$i" = "$n_lectures" ]]; then
    b="end"
  else
    b="$((${lecture_page_numbers[$i+1]}))" # end page number
  fi
  # echo "n_lectures: $n_lectures"
  # echo "lecture_page_numbers: ${lecture_page_numbers[i]}"
  # echo "a = $a"
  # echo "cat $a-$b"
  # echo "${wdir}/${splitdir}/${outputprefix}"_"${lecture_numbers_clean[$i]}"_"${lecture_acronyms_clean[$i]}"_"${lecture_names_clean[$i]}".pdf
  # pdftk "$infile" cat $a-$b output "${wdir}/${splitdir}/${outputprefix}"_"${lecture_numbers_clean[$i]}"_"${lecture_acronyms_clean[$i]}"_"${lecture_names_clean[$i]}".pdf
  echo "${wdir}/${splitdir}/${outputprefix}"_"${lecture_numbers_clean[$i]}"_"${lecture_names_clean[$i]}".pdf
  pdftk "$infile" cat $a-$b output "${wdir}/${splitdir}/${outputprefix}"_"${lecture_numbers_clean[$i]}"_"${lecture_names_clean[$i]}".pdf
done
