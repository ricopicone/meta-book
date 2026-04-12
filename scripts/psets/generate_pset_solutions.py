#!/usr/bin/env python3
"""
Generic Problem Set Solutions Generator for xsim-based Exercise Books
=====================================================================

This script generates LaTeX problem set solution files by selecting exercises
from chapter exercise files based on their IDs or hashes. Solutions are always
included.

This is a generic version designed to work with any book repository that uses
the xsim exercise package and follows the meta-book structure.

Usage:
    python generate_pset_solutions.py --config pset_config.yaml
    python generate_pset_solutions.py --problems cedar,beacon --title "PS 3 Solutions"
    python generate_pset_solutions.py --help

Author: meta-book project
Date: 2026
"""

import argparse
import re
import yaml
import os
import sys
import shutil
from pathlib import Path
from typing import List, Dict, Optional
from datetime import datetime

# Import shared classes from the exam system
_exams_dir = str(Path(__file__).resolve().parent.parent / "exams")
if _exams_dir not in sys.path:
    sys.path.insert(0, _exams_dir)
from generate_exam import ExerciseExtractor, compile_pdf, load_config, list_available_exercises


def parse_xsim_numbering(base_path: Path) -> Dict[str, str]:
    """Parse the .xsim file to build a mapping from exercise ID to its canonical number (e.g. '13.3').

    Searches for .xsim files in base_path and returns {exercise_id: number_string}.
    """
    id_map = {}    # exercise-N -> exercise_id
    counter_map = {}  # exercise-N -> "13.3"

    xsim_files = sorted(base_path.glob("*.xsim"))
    if not xsim_files:
        return {}

    for xsim_file in xsim_files:
        try:
            content = xsim_file.read_text(encoding='utf-8')
        except Exception:
            continue

        # Parse ID line: \XSIM{ID}{exercise-1=={madrid}||exercise-2=={playmate}||...}
        # The outer braces contain nested braces, so match to end of line
        id_line_match = re.search(r'[\\]XSIM\{ID\}\{(.+)\}$', content, re.MULTILINE)
        if id_line_match:
            for m in re.finditer(r'exercise-(\d+)==\{(\w[\w-]*)\}', id_line_match.group(1)):
                id_map[f"exercise-{m.group(1)}"] = m.group(2)

        # Parse counter line: \XSIM{counter}{exercise-1=={1.1}||...}
        counter_line_match = re.search(r'[\\]XSIM\{counter\}\{(.+)\}$', content, re.MULTILINE)
        if counter_line_match:
            for m in re.finditer(r'exercise-(\d+)==\{([\d.]+)\}', counter_line_match.group(1)):
                counter_map[f"exercise-{m.group(1)}"] = m.group(2)

    # Build final mapping: exercise_id -> number
    result = {}
    for key, ex_id in id_map.items():
        if key in counter_map:
            result[ex_id] = counter_map[key]
    return result


def clean_solution_markdown(text: str, ex_id: str = '') -> str:
    r"""Convert leftover escaped markdown headers in solution text to LaTeX,
    and ensure all \subsubsection* entries get PDF bookmarks.

    Handles patterns like:  \# Part b \{-\}  ->  \subsubsection*{Part b}
    Also handles variants with or without the {-} unnumbered marker.
    """
    # \# Title \{-\}  or  \# Title  (at end of line or before newline)
    def _replace_header(m):
        title = m.group(1).strip()
        return f"\\subsubsection*{{{title}}}"

    # Match: \# Some Title \{-\}
    text = re.sub(r'\\#\s+(.+?)\s*\\\{-\\\}', _replace_header, text)
    # Match: \# Some Title  (end of line, no {-})
    text = re.sub(r'\\#\s+(.+?)$', _replace_header, text, flags=re.MULTILINE)

    # Add bookmarks for all sectioning commands (\subsubsection*, \subparagraph*, etc.)
    _part_counter = [0]
    def _add_bookmark(m):
        cmd = m.group(1)  # e.g. "subsubsection" or "subparagraph"
        title = m.group(2)
        _part_counter[0] += 1
        dest = f"ex-{ex_id}-part-{_part_counter[0]}" if ex_id else f"part-{_part_counter[0]}"
        bookmark = f"\\bookmark[dest={dest},level=2]{{{title}}}"
        hypertarget = f"\\hypertarget{{{dest}}}{{}}"
        return f"{bookmark}\n{hypertarget}\n\\{cmd}*{{{title}}}"

    text = re.sub(r'\\(subsubsection|subparagraph|paragraph)\*\{([^}]+)\}', _add_bookmark, text)
    return text


class PsetSolutionsGenerator:
    """Generate problem set solution LaTeX files from selected exercises."""

    def __init__(self, extractor: ExerciseExtractor, styles_path: str = "common/styles-tex"):
        self.extractor = extractor
        self.styles_path = styles_path
        self.xsim_numbers = parse_xsim_numbering(extractor.base_path)
        self.template_header = self._get_template_header()
        self.template_footer = self._get_template_footer()

    def _find_book_aux(self, compile_root: Path) -> Optional[str]:
        """Locate a main book .aux file and return a path relative to the compile root."""
        candidates = ["systems-0.aux", "systems.aux", "main.aux"]
        search_dirs = [compile_root.resolve()] + list(compile_root.resolve().parents)
        for d in search_dirs:
            for name in candidates:
                for candidate in (d / name, d / "systems" / name):
                    if candidate.exists():
                        try:
                            return os.path.relpath(candidate.resolve(), compile_root.resolve())
                        except Exception:
                            return str(candidate)
        return None

    def _get_template_header(self) -> str:
        return r"""\documentclass[11pt,letterpaper]{article}

% Required packages
\usepackage[margin=1in]{geometry}
\usepackage{fancyhdr}
\usepackage{lastpage}
\usepackage{enumerate}
\usepackage{enumitem}
\usepackage{xparse}
\usepackage{standalone}
\usepackage{marginnote}
<<BIBLATEX_PACKAGE>>
\usepackage{xr}
\usepackage{hyperref}
\usepackage{bookmark}
<<XR_EXTERNAL>>
\usepackage[draft=false,newfloat]{minted}

% Tables
\usepackage{booktabs}
\usepackage{tabularx}

% Figures and subfigures
\usepackage{graphicx}
\graphicspath{{.},{./figures},{./source/figures},{./common},{./common/figures},{../common},{../common/figures}}
\usepackage[margin=.5ex]{subcaption}
\usepackage{float}
\usepackage[all]{hypcap}
\usepackage[noabbrev,capitalise,nameinlink]{cleveref}
  \crefname{figure}{figure}{figures}
  \crefname{table}{table}{tables}
  \crefname{problem}{problem}{problems}
  \Crefname{figure}{Figure}{Figures}
  \Crefname{table}{Table}{Tables}
  \Crefname{problem}{Problem}{Problems}

% Import book style files
\usepackage{<<STYLES_PATH>>/bookmathmacros}
\usepackage{<<STYLES_PATH>>/booktikz}

% Simplified mintedwrapper environment (from book's environments.sty)
\newboolean{insideformattedoutput}
\setboolean{insideformattedoutput}{false}
\NewDocumentEnvironment{mintedwrapper}{}{\begingroup}{\endgroup}

% pgf figure input (from book's environments.sty)
\newcommand{\inputpgf}[1]{%
\begin{tikzpicture}%
\node[inner sep=0pt] {\input{#1}};%
\end{tikzpicture}%
}%

% matplotlib pgf compatibility
\newcommand{\mathdefault}[1][]{#1}

% Minted configuration
\setminted{
  usepygments=true,
  linenos=false,
  breaklines=true,
  frame=none,
  framesep=1mm,
  fontsize=\small,
  bgcolor=white,
  parskip=0pt
}

% Compact spacing for minted
\BeforeBeginEnvironment{minted}{\vspace{-0.5em}}
\AfterEndEnvironment{minted}{\vspace{-0.5em}}

\setminted[text]{
  frame=leftline,
  rulecolor=gray,
  framerule=2pt,
  xleftmargin=10pt,
  parskip=0pt
}

% Simplified book macros
\makeatletter
\NewDocumentCommand{\figcaption}{o O{float} m m}{%
  \caption{#4}%
  \label{#3}%
}
\makeatother

\makeatletter
\NewDocumentCommand{\tabcaption}{O{#4} O{float} m m}{%
  \caption[#1]{#4}%
  \label{#3}%
}
\makeatother

\def\graphicslist{}

% Enumerate defaults
\setlist[enumerate,1]{label=\alph*.}
\setlist[enumerate,2]{label=\roman*.}

% Problem counter
\newcounter{problem}
\setcounter{problem}{0}

% Header and footer
\newcommand{\psettitle}{<<PSET_TITLE>>}
\newcommand{\psetdate}{<<PSET_DATE>>}
\newcommand{\coursename}{<<COURSE_NAME>>}
\newcommand{\instructorname}{<<INSTRUCTOR_NAME>>}

% First-page style: no header, just page number
\fancypagestyle{firstpage}{%
  \fancyhf{}%
  \renewcommand{\headrulewidth}{0pt}%
  \renewcommand{\footrulewidth}{0.4pt}%
  \cfoot{Page \thepage\ of \pageref{LastPage}}%
}

% Running style for subsequent pages
\pagestyle{fancy}
\fancyhf{}
\renewcommand{\headrulewidth}{0.4pt}
\renewcommand{\footrulewidth}{0.4pt}
\lhead{\coursename}
\chead{\psettitle}
\rhead{\psetdate}
\lfoot{\instructorname}
\cfoot{Page \thepage\ of \pageref{LastPage}}
\rfoot{}

% Import bookcolors at document begin
\AtBeginDocument{
  \input{<<STYLES_PATH>>/bookcolors.sty}
}

\begin{document}

\thispagestyle{firstpage}
\noindent{\large\textbf{\psettitle}} \hfill \coursename \hfill \psetdate \hfill \instructorname
\vspace{2pt}\hrule\vspace{0.4cm}

% Begin problems
"""

    def _get_template_footer(self) -> str:
        return r"""
\end{document}
"""

    def _find_bib_file(self, base_path: Path) -> Optional[str]:
        """Auto-detect the book's bibliography file."""
        # Check preamble files for \addbibresource
        for preamble in sorted(base_path.glob("0-*.tex")):
            try:
                text = preamble.read_text(encoding='utf-8')
                m = re.search(r'\\addbibresource\{([^}]+)\}', text)
                if m:
                    bib_path = base_path / m.group(1)
                    if bib_path.exists():
                        return m.group(1)
            except Exception:
                continue
        # Fallback: check common locations
        for candidate in ["common/book.bib", "book.bib", "references.bib"]:
            if (base_path / candidate).exists():
                return candidate
        return None

    def generate(self, config: Dict) -> str:
        """Generate a complete problem set solutions LaTeX file."""
        compile_root = Path(config.get('base_path_resolved', self.extractor.base_path)).resolve()
        aux_rel = self._find_book_aux(compile_root)
        if aux_rel and aux_rel.endswith('.aux'):
            aux_rel = aux_rel[:-4]
        xr_external = f"\\externaldocument{{{aux_rel}}}" if aux_rel else ''

        # Generate the problems section first so we can check for citations
        include_problems = config.get('include_problems', False)
        problems_section = self._generate_problems(config['problems'], include_problems)

        # Determine bibliography: explicit config, or auto-detect if content has citations
        bib_file = config.get('bibliography')
        has_citations = bool(re.search(
            r'\\(?:auto)?cite|\\textcite|\\parencite|\\footcite|\\fullcite', problems_section))
        if not bib_file and has_citations:
            bib_file = self._find_bib_file(compile_root)

        if bib_file:
            biblatex_package = f"\\usepackage[backend=biber,style=numeric,sorting=none,natbib=true]{{biblatex}}\n\\addbibresource{{{bib_file}}}"
        else:
            biblatex_package = ""

        replacements = {
            '<<PSET_TITLE>>': config.get('title', 'Problem Set Solutions'),
            '<<PSET_DATE>>': config.get('date', datetime.now().strftime('%B %d, %Y')),
            '<<COURSE_NAME>>': config.get('course', 'Course'),
            '<<INSTRUCTOR_NAME>>': config.get('instructor', 'Instructor'),
            '<<STYLES_PATH>>': self.styles_path,
            '<<BIBLATEX_PACKAGE>>': biblatex_package,
            '<<XR_EXTERNAL>>': xr_external,
        }

        header = self.template_header
        for placeholder, value in replacements.items():
            header = header.replace(placeholder, value)

        footer = self.template_footer
        if bib_file:
            footer = "\n\n\\printbibliography\n" + footer

        return header + problems_section + footer

    def _generate_problems(self, problem_specs: List, include_problems: bool = False) -> str:
        """Generate the problems section with solutions."""
        problems_latex = ""

        for i, problem_spec in enumerate(problem_specs, 1):
            if isinstance(problem_spec, str):
                identifier = problem_spec
                points = None
                page_break_after = False
            elif isinstance(problem_spec, dict):
                identifier = problem_spec['id']
                points = problem_spec.get('points')
                page_break_after = problem_spec.get('page_break', False)
            else:
                print(f"Warning: Invalid problem specification: {problem_spec}")
                continue

            exercise = self.extractor.get_exercise(identifier)
            if not exercise:
                print(f"Warning: Exercise '{identifier}' not found")
                continue

            ex_id = exercise['id']
            # Look up original textbook number from xsim data
            book_number = self.xsim_numbers.get(ex_id, '')

            # Build heading
            ex_id_upper = ex_id.upper()
            heading_parts = "Problem"
            if book_number:
                heading_parts += f"~{book_number}"
            heading_parts += f" (\\texttt{{{ex_id_upper}}})"
            if not include_problems:
                heading_parts += " Solution"
            if points:
                heading_parts += f"~({points} points)"
            heading_parts += "."

            # PDF bookmark for navigation
            bookmark_label = "Solution" if not include_problems else ""
            bookmark_title = f"Problem {book_number} ({ex_id_upper}){' ' + bookmark_label if bookmark_label else ''}" if book_number else f"Problem ({ex_id_upper}){' ' + bookmark_label if bookmark_label else ''}"
            problems_latex += f"\n\\bookmark[dest=ex-{ex_id},level=1]{{{bookmark_title}}}\n"
            problems_latex += f"\\hypertarget{{ex-{ex_id}}}{{}}\n"

            problems_latex += f"\\noindent\\textbf{{{heading_parts}}}"
            if exercise.get('hash'):
                problems_latex += f"\\label{{{exercise['hash']}}}"
            problems_latex += "\n"

            # Problem statement (only if requested)
            if include_problems:
                content = exercise['content']
                content = re.sub(r'\\begin\{exercise\}.*?\n', '', content)
                content = re.sub(r'\\end\{exercise\}', '', content)
                content = re.sub(r'^\\def\\labelenum.*\n', '', content, flags=re.MULTILINE)
                problems_latex += content
                problems_latex += "\n\n\\noindent\\textbf{Solution:}\\par\n"

            # Solution (always included)
            if exercise['solution']:
                solution = exercise['solution']
                solution = re.sub(r'\\begin\{solution\}.*?\n', '', solution)
                solution = re.sub(r'\\end\{solution\}', '', solution)
                solution = clean_solution_markdown(solution, ex_id)
                problems_latex += solution
            else:
                problems_latex += "\\textit{No solution available.}\\par\n"

            if page_break_after:
                problems_latex += "\n\\clearpage\n"
            else:
                problems_latex += "\n\\vspace{1.5cm}\n"

        return problems_latex


def create_sample_config():
    """Create a sample configuration file."""
    sample_config = {
        'title': 'Problem Set 1 Solutions',
        'date': 'March 15, 2026',
        'course': 'Course Name',
        'instructor': 'Dr. Smith',
        'bibliography': None,
        'problems': [
            {'id': 'exercise1', 'points': 20},
            {'id': 'exercise2', 'points': 25, 'page_break': True},
            'exercise3',
            {'id': 'exercise4', 'points': 30},
        ]
    }

    with open('pset_config_sample.yaml', 'w') as f:
        yaml.dump(sample_config, f, default_flow_style=False, indent=2)

    print("Sample configuration created: pset_config_sample.yaml")


def main():
    parser = argparse.ArgumentParser(description='Generate problem set solutions from exercise database')
    parser.add_argument('--config', help='YAML configuration file')
    parser.add_argument('--problems', help='Comma-separated list of problem IDs/hashes')
    parser.add_argument('--title', default='Problem Set Solutions', help='Document title')
    parser.add_argument('--date', help='Date (default: today)')
    parser.add_argument('--instructor', default='Instructor', help='Instructor name')
    parser.add_argument('--course', default='Course', help='Course name')
    parser.add_argument('--output', '-o', help='Output file base name (default: auto-generated)')
    parser.add_argument('--list', action='store_true', help='List available exercises')
    parser.add_argument('--sample-config', action='store_true', help='Create sample config file')
    parser.add_argument('--base-path', default=os.environ.get('BASE_PATH', '../..'),
                        help='Base path to exercise files')
    parser.add_argument('--exercise-pattern', default=os.environ.get('EXERCISE_PATTERN', 'ch*_exercises.tex'),
                        help='Glob pattern(s) for exercise files (comma-separated)')
    parser.add_argument('--styles-path', default='common/styles-tex',
                        help='Path to book style files (relative to book root)')
    parser.add_argument('--include-problems', action='store_true',
                        help='Include problem statements before solutions (default: solutions only)')
    parser.add_argument('--no-quick', action='store_true', help='Skip PDF compilation')

    args = parser.parse_args()

    if args.sample_config:
        create_sample_config()
        return

    extractor = ExerciseExtractor(Path(args.base_path).resolve(), args.exercise_pattern)

    if args.list:
        list_available_exercises(extractor)
        return

    generator = PsetSolutionsGenerator(extractor, args.styles_path)

    if args.config:
        config = load_config(args.config)
        config_path = Path(args.config).resolve()
        base_name = config_path.stem
        config['config_path'] = str(config_path)
        config['base_path_resolved'] = str(extractor.base_path)
        if args.include_problems:
            config['include_problems'] = True
    elif args.problems:
        problem_list = [p.strip() for p in args.problems.split(',')]
        config = {
            'title': args.title,
            'date': args.date or datetime.now().strftime('%B %d, %Y'),
            'instructor': args.instructor,
            'course': args.course,
            'problems': problem_list,
            'include_problems': args.include_problems,
        }
        safe_title = re.sub(r'[^\w\s-]', '', config['title']).strip()
        base_name = re.sub(r'[-\s]+', '_', safe_title).lower()
    else:
        parser.error('Either --config or --problems must be specified')

    latex_content = generator.generate(config)

    if args.output:
        base_name = args.output

    if args.config:
        output_dir = Path(config['config_path']).parent
        if config.get('output_dir'):
            output_dir = Path(config['output_dir']).resolve()
        output_file = str((output_dir / f"{base_name}.tex").resolve())
    else:
        if config.get('output_dir'):
            output_dir = Path(config['output_dir']).resolve()
            output_file = str(output_dir / f"{base_name}.tex")
        else:
            output_dir = Path('.').resolve()
            output_file = str(output_dir / f"{base_name}.tex")

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(latex_content)

    print(f"Problem set solutions generated: {output_file}")

    if not args.no_quick:
        print("Compiling PDF...")
        compile_pdf(output_file, args.base_path)


if __name__ == '__main__':
    main()
