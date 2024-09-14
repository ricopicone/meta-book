#!/bin/bash

# usage
if [ "$1" == "-h" ]; then
  echo "Usage: `basename $0` 'a_notebook.ipynb' \n Must install pandoc, minted, and pandoc-minted filter."
  exit 0
fi

# write template file if it doesn't exist
template_file="./kill_hidden.tpl"
if [ ! -f $template_file ]; then
/bin/cat <<EOM >$template_file
{%- extends 'markdown.tpl' -%}

{%- block any_cell -%}
{%- if 'jupyter:kill_cell' in cell.metadata.get("tags",[]) -%}
{%- else -%}
    {{ super() }}
{%- endif -%}
{%- endblock any_cell -%}

{%-block input_group scoped-%}
{%- if 'jupyter:kill_input' in cell.metadata.get("tags",[]) and cell.cell_type == 'code'-%}
{%- else -%}
    {{ super() }}
{%- endif -%}
{%-endblock input_group -%}


{%-block output_group scoped-%}
{%- if 'jupyter:kill_output' in cell.metadata.get("tags",[]) and cell.cell_type == 'code'-%}
{%- else -%}
    {{ super() }}
{%- endif -%}
{%-endblock output_group -%}
EOM
fi

filename_ext=$(basename "$1") # with extension
filename="${filename_ext%.*}" # without

# convert to tex (just for pdf figs)
# jupyter nbconvert --to latex --template=kill_hidden.tpl "$filename".ipynb

# convert to markdown (could go straight to tex but want minted)
jupyter nbconvert --to markdown --template=kill_hidden.tpl "$filename".ipynb

# # convert to tex with minted plugin
pandoc --filter pandoc-minted -f markdown -t latex "$filename".md -o "$filename".tex