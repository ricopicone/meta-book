import os
import re
import argparse

# Parse command-line arguments

parser = argparse.ArgumentParser(description='Split a markdown file into sections and create a LaTeX file.')
parser.add_argument('input_file', help='The input markdown file to split.')
args = parser.parse_args()
input_file = args.input_file

# Function to split a markdown file into sections and create a LaTeX file

def split_markdown(input_file):
    # Read the input markdown file
    with open(input_file, 'r') as file:
        content = file.read()

    # Regular expression to match top-level sections (e.g., # Section Title)
    # Use the fact that the section titles all end with a closing brace } and the comments do not.
    section_pattern = re.compile(r'^(# )(.*\{.*\})', re.MULTILINE)  # This works
    
    # Find all top-level sections
    sections = section_pattern.findall(content)
    if not sections:
        print("No top-level sections found.")
        return

    # Split content by sections
    parts = section_pattern.split(content)

    # Initialize LaTeX document content
    # Get chapter short name from the title of the first section of the input file
    # Strip off the trailing braces {} and its contents
    chapter_title = re.sub(r'\{.*\}', '', parts[2]).strip()
    chapter_short_name = chapter_title.strip().replace(' ', '-').lower()
    chapterx_short_name = "chx-" + chapter_short_name
    latex_content = f"\\input{{{chapterx_short_name + '/' + chapterx_short_name + '-header'}}}\n\n"

    # Write the chapterx_short_name/chapter_short_name-header latex file
    os.makedirs(chapterx_short_name, exist_ok=True)
    with open(os.path.join(chapterx_short_name, f"{chapterx_short_name}-header.tex"), 'w') as f:
        f.write(f"% Chapter short name: {chapterx_short_name}\n")
        print(parts[2])
        h_match = re.search(r'\{.*h\s*=\s*(?:"([^"]*)"|(\S+))\}', parts[2]).group(1)
        f.write(f"% Chapter title: {chapter_title}\n\n")
        f.write(f"\chapter[{chapter_title}]{{{chapter_short_name}}}{{{h_match}}}{{{chapter_title}}}")

    # Process each section
    for i in range(1, len(parts), 3):
        header_level = parts[i].strip()  # This will be '# ' for top-level sections
        section_title = parts[i+1].strip()  # The title of the section
        section_content = parts[i+2].strip()  # The content of the section

        # Get the h attribute for the section.
        # The h attribute appears as h="value" or h=value in the braces after the section title.
        h_match = re.search(r'\{.*h\s*=\s*(?:"([^"]*)"|(\S+))\}', section_title)

        # Create a safe directory name from the section title
        directory_name = h_match.group(1) if h_match else section_title
        os.makedirs(directory_name, exist_ok=True)

        # Write the section content to a source.md file in the directory
        with open(os.path.join(directory_name, 'source.md'), 'w') as f:
            f.write(f"# {section_title}\n{section_content}")

        # Add the \includesection command to the LaTeX document
        section_title_stripped = re.sub(r'\{.*\}', '', section_title).strip()
        latex_content += f"\\includesection{{{directory_name}}} % {section_title_stripped}\n\n"

    # Write LaTeX file. Use the same name as the input file but with a .tex extension and a suffix _split
    latex_content += "%\\begin{exercises}{XX}\n%\t\\includesection{XX}\n%\\end{exercises}"
    with open(os.path.join(chapterx_short_name, f"{chapterx_short_name}.tex"), 'w') as f:
        f.write(f"% Chapter short name: {chapterx_short_name}\n")
        f.write(f"% Chapter title: {chapter_title}\n\n")
        f.write(latex_content)

    print("Markdown file split into sections and LaTeX file created successfully.")

# Use the function with an example input file
split_markdown(input_file)