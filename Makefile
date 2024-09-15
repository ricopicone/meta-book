
.PHONY: full partial p split_partial split_full split partial_sewn sewn solutions sol assignment_solutions asol all website exams spellcheck section source solution find split/outlined split/sewn split/partial thumbnails split/thumbnails thumbnail_single

# Determine the name of the main tex file
edition = 0# default - pass edition="hp2" to make another edition, e.g. make edition="hp2" or make full edition="hp2"
path = $(shell pwd)
dir_name = $(notdir $(path))
tex_default_base = $(shell python3 -c "dir = '$(dir_name)'; print(dir[1:] if dir.startswith('_') else dir)")
tex_default = $(tex_default_base:=-$(edition))

# Tex file version number
build_version_file := version-of-build-$(edition).txt
build_version := $(shell cat ${build_version_file})

# Use the trash command if available, otherwise rm -f
trash = $(shell if command -v trash; then echo "trash "; else echo "rm -f "; fi)

# Options and code snippets used when running latexmk
# ifneq (,$(findstring B,$(MAKEFLAGS)))
max_repeat = '1' # default
latex_command = latexmk -g -lualatex -e '$$max_repeat=$(max_repeat)' # force rebuild with -g
# else
#   latex_command = latexmk -lualatex
# endif
options = -interaction=nonstopmode -halt-on-error -file-line-error -shell-escape -synctex=1

solution_text = \def\issolution{1}\def\nocropmarks{1}\def\nowrite{1} # always crop the solution and don't write to .json
build_section_text = \def\nowrite{1} # don't write to .json
partial_text = \def\ispartial{1}\def\nowrite{1}\def\nocropmarks{1}

ifdef crop
ifeq ($(crop),true)
	crop_text = \def\nocropmarks{1} # crop, i.e. don't print crop marks and give true page size (7x9)
else
	crop_text = # crop, i.e. don't print crop marks and give true page size (7x9) OR crop_text = \def\nocropmarks{1} # don't crop (solution still crops, see above)
endif
else
crop_text = \def\nocropmarks{1} # crop, i.e. don't print crop marks and give true page size (7x9)
endif

ifdef nowrite
ifeq ($(nowrite),true)
	nowrite_text = \def\nowrite{1} # don't write .tex output to .json file (default for solution, see above)
else
	nowrite_text = # do write .tex output to .json file
endif
endif

# ifdef slides
# ifeq ($(slides),true)
# 	slides_text = \def\slidesonly{1}\def\nowrite{1}
# else
# 	slides_text = # empty
# endif
# endif

# Source files
commondir = ./common
chapters = $(shell find . -type f -name 'ch*.tex')
exercises = $(wildcard ch*_exercises.tex)
appendices = $(wildcard ap*.tex)
figures = $(wildcard figures/*.pdf)
common_tex = $(wildcard common/*.tex)
common_figures = $(wildcard common/figures/*.jpg) $(wildcard common/figures/*.png) $(wildcard common/figures/*.pdf)
versionless_sources = $(shell find versionless -type f -name '*source.md')
versionless_targets_tex = $(versionless_sources:source.md=index.tex)
versioned_sources = $(shell find common/versioned -type f -name '*source.md')
versioned_targets_tex = $(versioned_sources:source.md=index.tex)
book_json_sources = $(shell find $(commondir)/book-json -type f -name '*raw.json')
book_json_targets = $(book_json_sources:raw.json=cleaned.json)
lua_filters = $(shell find ./common/lua-filters -type f -name '*Makefile') # this is to exclude it in the line below, right? We don't want to make these.
engcom_makes = $(shell find ./source/engcom -type f -name '*Makefile')
source_makes = $(shell find ./source -type f -name '*Makefile')
statemint_makes = $(shell find ./source/StateMint -type f -name '*Makefile')
meta_book_makes = $(shell find ./meta-book -type f -name '*Makefile')
meta_common_makes = $(shell find ./common/meta-common -type f -name '*Makefile')
nosubmakes = $(lua_filters) $(engcom_makes) $(statemint_makes) $(source_makes) $(meta_book_makes) $(meta_common_makes)
submakefiles = $(filter-out $(nosubmakes), $(shell find . -mindepth 2 -type f -not -path './common/source/matlab/matlab2tikz/*' -not -path './common/lua-filters'  -not -path './exams' -name '*Makefile'))
$(info $$submakefiles is [${submakefiles}])
index_see_entries = ./scripts/index-see-entries.tex
ifdef h
section_source = $(shell find ./versionless ./common/versioned -type f -path "*/$(h)/source.md")
ifeq ($(section_source),)
	section_source = $(shell find ./ch* -type f -path "*/$(h).tex") # see if file match is found in chXX dirs
	section_source_tex = $(section_source)
else
	section_source_tex = $(section_source:source.md=index.tex)
endif
endif

source_files = $(book_json_targets) $(chapters) $(exercises) $(appendices) $(figures) $(common_tex) $(common_figures) $(versionless_targets_tex) $(versioned_targets_tex) $(index_see_entries) source

# Generates the latexmk command
# Takes one optional argument: LaTeX code snippets
define tex_cmd
	$(latex_command) $(options) -jobname=$(basename $(notdir $@)) --output-directory=$(dir $@) -lualatex="lualatex %O '$(1)$(crop_text)$(nowrite_text)\PassOptionsToPackage{outputdir=$(dir $@)}{minted}\input{$(basename $<)}'" $(basename $<)
endef

# Default target, build the full document
full: $(tex_default).pdf

define show_matlab
	@if [ -s matlab_run.sh ]; then \
		echo "MATLAB is not installed in the docker container. Due to out of date files, the following MATLAB commands should be run. This can also be done by running the generated matlab_run.sh script."; \
		cat matlab_run.sh; \
	fi
endef

$(tex_default).pdf: $(tex_default).tex $(source_files)
	$(eval options+= -norc -r latexmkrc_main)
	-$(call tex_cmd) # leading dash tells make to continue even if error
	cp $(tex_default).pdf ./build-versions/$(tex_default)-v$(build_version).pdf
	$(call show_matlab)

# Build the slides
slides: $(tex_default).tex $(source_files)
	$(latex_command) $(options) -jobname=slides-$(basename $(notdir $@)) --output-directory=$(dir $@)/slides -lualatex="lualatex %O '$(1)\def\slidesonly{1}\def\nowrite{1}\PassOptionsToPackage{outputdir=$(dir $@)/slides}{minted}\input{$(basename $<)}'" $(basename $<)

# Build the partial document
partial: $(tex_default)_partial.pdf

p: partial

$(tex_default)_partial.pdf: $(tex_default).tex $(source_files)
	$(call tex_cmd,$(partial_text))

# SPLIT =============

# Split partial document
split_partial: split/partial

# Split full document
partial_full: split/full

# Splits the partial document (requires .toc file)
split/partial: $(tex_default)_partial.pdf
	./scripts/split_pdf_at_bookmarks.sh $< partial/$(tex_default)_partial split

# Splits the full document (requires .toc file)
split/full: $(tex_default).pdf
	./scripts/split_pdf_at_bookmarks.sh $< full/$(tex_default) split

split: split_partial split_full

# OUTLINE ===========

outlined: split/outlined

# Determine the files which need to be outlined
split/outlined: split/partial
	$(MAKE) $(patsubst $</%.pdf, $@/%.pdf, $(wildcard $</*.pdf))

# Outline split partial pages with ghostscript
split/outlined/$(tex_default)_%.pdf: split/partial/$(tex_default)_%.pdf
	mkdir -p $(dir $@)
	gs -o $@ -dNoOutputFonts -dColorConversionStrategy=/LeaveColorUnchanged -dEncodeColorImages=false -dEncodeGrayImages=false -dEncodeMonoImages=false -sDEVICE=pdfwrite $<

# SEW ================

# Sew the outlined split partial document pages

sewn: split/sewn

# Determine the files which need to be sewn
split/sewn: split/outlined
	$(MAKE) $(patsubst $</%.pdf, $@/%.pdf, $(wildcard $</*.pdf))

# Sew split outlined partial pages
split/sewn/$(tex_default)_%.pdf: split/outlined/$(tex_default)_%.pdf
	mkdir -p $(dir $@)
	./scripts/pdfjam_sew.sh $< $@

# GENERATE THUMBNAILS =======

# Determine the files which need to be thumnails
thumbnails: split/thumbnails thumbnail_single

split/thumbnails: split/partial
	mkdir -p $@
	-$(trash) $@/*
	$(MAKE) $(patsubst $</%.pdf, $@/%.jpg, $(wildcard $</*.pdf))

split/thumbnails/$(tex_default)_%.jpg: split/partial/$(tex_default)_%.pdf
	gs -dNOPAUSE -dBATCH -sDEVICE=jpeg -r300 -sOutputFile="$@" -dLastPage=1 "$<"

# Make single (whole) document thumbnail
thumbnail_single: $(tex_default)_partial.pdf
	gs -dNOPAUSE -dBATCH -sDEVICE=jpeg -r300 -sOutputFile="split/thumbnails/$(tex_default)_partial.jpg" -dLastPage=1 "$(tex_default)_partial.pdf"

# COPY FILES TO WEBSITE =======
website: $(tex_default)_partial.pdf split/partial thumbnails
# 	$(MAKE) $(<:pdf=jpg) $(patsubst %.pdf, %.jpg, $(wildcard $(word 2, $^)*.pdf))
	-$(trash) $(commondir)/split/partial/*.pdf
	-$(trash) $(commondir)/split/partial/*.jpg
	cp $(tex_default)_partial.pdf $(commondir)/split/partial
	cp split/partial/*.pdf $(commondir)/split/partial
	cp split/thumbnails/*.jpg $(commondir)/split/partial

# OTHER ===============

$(commondir)/source_dependencies.mk: $(commondir)/source-dependencies.json
	python $(commondir)/scripts/source_dependencies_rule_writer.py $(commondir)/source-dependencies.json $(commondir)/source_dependencies.mk

$(commondir)/source-dependencies.json:

include $(commondir)/common.mk
include $(commondir)/source_dependencies.mk

versionless-tex: $(versionless_targets_tex)

# Make sub-makefiles like for matlab source code
source:
	echo -n > matlab_run.sh
	for makefile in $(submakefiles); do \
		$(MAKE) -C $$(dirname $$makefile); \
	done

spellcheck:
	for f in versionless/*/source.md common/versioned/*/source.md; do \
		aspell check -M -p ./dictionary $$f; \
	done
	for f in ch*/*.tex ch*/**/*.tex *.tex; do \
		aspell check -t -p ./dictionary $$f; \
	done

find:
	@if [ -z "$(pattern)" ]; then \
		echo "Pattern not specified."; \
	else \
		# echo '$(pattern)'; \
		# find . -type f -name "test.md" -exec grep -lP '$(pattern)' {} \; ; \
		find ./versionless/ ./common/versioned/ -type f -name "*.md" -exec grep -lP '$(pattern)' {} \; ; \
		find ./ch*/ -type f -name "*.tex" -exec grep -lP '$(pattern)' {} \; ; \
		find ./ -maxdepth 1 -type f -name "*.tex" -exec grep -lP '$(pattern)' {} \; ; \
	fi

# build a section alone
trashaux = "false" # default don't trash aux files
section: $(versionless_targets_tex) $(versioned_targets_tex)
	test -n "$(h)" || (echo "Pass hash as, for instance: make section h=qv" ; exit 1)
	@echo "Searching for h=$(h) ..."
ifeq ($(section_source_tex),)
	$(error no versioned or versionless source found for h=$(h))
else
	@echo "\t... source for h=$(h) found."
	@echo "Building $(h) ..."
	$(MAKE) $(section_source_tex) # pandoc
	python "scripts/build-alone.py" $(h) --trashaux $(trashaux) # create build-sections tex file
	$(MAKE) "build-sections/$(h)/$(h).pdf"
endif

build-sections/%.pdf: build-sections/%.tex
	$(call tex_cmd,$(build_section_text))

# build a solutions manual
trashaux = "false" # default don't trash aux files
solution: $(shell find common -name *.md) $(shell find common/versionless -name *.md) $(shell find source -name *.md)
	make "solutions-manuals/math-solutions-manual-0/math-solutions-manual-0.pdf" # default

solutions-manuals/%.pdf: solutions-manuals/%.tex $(versionless_targets_tex) $(versioned_targets_tex)
	$(eval options+= -norc -r latexmkrc_solutions)
	-$(call tex_cmd,$(solution_text))
	cp $@ ./solutions-manuals/solutions-manuals-repo/

./scripts/index-see-entries.tex: ./scripts/generate-see-index-entries.py # this also contains the dict with the entries
	cd "./scripts"; python "./generate-see-index-entries.py"

# The all target builds everything
all: full partial split_partial partial_sewn solutions assignment_solutions exams versioned-tex

# Convert an old LaTeX chapter file to a new pandoc markdown file using the scripts/latex-to-md-filter.lua script
# Usage: make convert_chapter ch=chXX.tex
convert_chapter:
	@echo "Converting $(ch) to markdown..."
	@python scripts/space_frac_and_tabular_braces.py $(ch) $(ch)
	@pandoc -s --from=latex+raw_tex -t markdown -o $(ch:tex=md) $(ch) --lua-filter=scripts/latex-to-md-filter.lua

# Split a converted old LaTeX chapter from its new markdown form using scripts/converted_markdown_split.py script
# We could do the conversion and splitting in one step, but this allows for the editing of the markdown file before splitting, which is a little more convenient
# Usage: make split_converted_chapter ch=chXX.md
split_converted_chapter:
	@echo "Splitting $(ch)..."
	@python scripts/converted_markdown_split.py $(ch)