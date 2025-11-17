# A script that takes a LaTeX file and adds a space between the middle braces of 
# the two commands \frac and \begin{tabular}.
# \frac{a}{b} -> \frac{a} {b}
# \begin{tabular}{c} -> \begin{tabular} {c}
# This is a preprocessor for the latex to markdown conversion.

import sys
import argparse
import re

def space_frac_and_tabular_braces(input_file, output_file):
    with open(input_file, 'r') as f:
        lines = f.readlines()
    with open(output_file, 'w') as f:
        for line in lines:
            # Add space between the middle braces of \frac{a}{b} -> \frac{a} {b}
            line = re.sub(r'\\frac\{([^}]+)\}\{([^}]+)\}', r'\\frac{\1} {\2}', line)
            # Add space between the middle braces of \dfrac{a}{b} -> \dfrac{a} {b}
            line = re.sub(r'\\dfrac\{([^}]+)\}\{([^}]+)\}', r'\\dfrac{\1} {\2}', line)
            # Add space between the middle braces of \begin{tabular}{} -> \begin{tabular} {}
            line = line.replace(r'\begin{tabular}{', r'\begin{tabular} {')
            f.write(line)

def main():
    parser = argparse.ArgumentParser(description='Add a space between the middle braces of \frac and \begin{tabular}')
    parser.add_argument('input_file', help='Input LaTeX file')
    parser.add_argument('output_file', help='Output LaTeX file')
    args = parser.parse_args()
    space_frac_and_tabular_braces(args.input_file, args.output_file)

if __name__ == '__main__':
    main()

# Usage: python space_frac_and_tabular_braces.py input.tex output.tex
# The script reads the input LaTeX file, adds a space between the middle braces of \frac and \begin{tabular},
# and writes the output LaTeX file.
