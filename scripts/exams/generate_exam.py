#!/usr/bin/env python3
"""
Generic Exam Generator for xsim-based Exercise Books
====================================================

This script generates LaTeX exam files by selecting exercises from chapter
exercise files based on their IDs or hashes. It uses the xsim package structure
already present in the exercise files and imports the book's style files.

This is a generic version designed to work with any book repository that uses
the xsim exercise package and follows the meta-book structure.

Usage:
    python generate_exam.py --config exam_config.yaml
    python generate_exam.py --problems crumble,mad,np --title "Midterm Exam"
    python generate_exam.py --help

Features:
    - Uses book's style files and xsim exercise environment
    - Generates PDF by default (use --no-quick to skip compilation)
    - YAML and TEX files have matching base names
    - Simple heading instead of full title page
    - Points display integrated with exercise environment
    - Configurable exercise file patterns and paths

Author: meta-book project
Date: 2024
"""

import argparse
import re
import yaml
import os
import sys
import subprocess
import shutil
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from datetime import datetime

class ExerciseExtractor:
    """Extract exercises from chapter exercise files."""

    def __init__(self, base_path: str = "..", exercise_pattern: str = "ch*_exercises.tex"):
        """
        Initialize the exercise extractor.
        
        Args:
            base_path: Base path to the book directory containing exercise files
            exercise_pattern: Glob pattern(s) for exercise files (default: "ch*_exercises.tex")
                             Multiple patterns can be separated by commas
        """
        self.base_path = Path(base_path)
        # Support multiple patterns separated by commas
        if ',' in exercise_pattern:
            self.exercise_patterns = [p.strip() for p in exercise_pattern.split(',')]
        else:
            self.exercise_patterns = [exercise_pattern]
        self.exercises_db = {}
        self._load_exercises()

    def _load_exercises(self):
        """Load all exercises from chapter files into memory."""
        # Find all exercise files matching the patterns
        exercise_files = []
        for pattern in self.exercise_patterns:
            matched_files = sorted(self.base_path.glob(pattern))
            exercise_files.extend(matched_files)
        
        # Remove duplicates while preserving order
        seen = set()
        unique_files = []
        for f in exercise_files:
            if f not in seen:
                seen.add(f)
                unique_files.append(f)
        exercise_files = unique_files
        
        if not exercise_files:
            print(f"Warning: No exercise files found matching patterns {self.exercise_patterns} in {self.base_path}")
            return
        
        for file_path in exercise_files:
            self._parse_exercise_file(file_path, file_path.name)

    def _parse_exercise_file(self, file_path: Path, file_name: str):
        """Parse a single exercise file and extract exercises."""
        if not file_path.exists():
            print(f"Warning: {file_name} not found at {file_path}")
            return
            
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Pattern to match exercise blocks
        exercise_pattern = r'\\begin\{exercise\}\[([^\]]+)\](.*?)\\end\{exercise\}'
        solution_pattern = r'\\begin\{solution\}(.*?)\\end\{solution\}'

        # Find all exercises
        exercise_matches = re.finditer(exercise_pattern, content, re.DOTALL)

        for match in exercise_matches:
            options = match.group(1)
            exercise_content = match.group(2).strip()

            # Extract ID and hash from options
            id_match = re.search(r'ID=([^,\]]+)', options)
            hash_match = re.search(r'hash=([^,\]]+)', options)

            if id_match:
                exercise_id = id_match.group(1)
                exercise_hash = hash_match.group(1) if hash_match else exercise_id

                # Find corresponding solution
                solution_content = ""
                # Look for solution immediately after the exercise
                remaining_content = content[match.end():]
                solution_match = re.match(r'\s*\\begin\{solution\}(.*?)\\end\{solution\}',
                                        remaining_content, re.DOTALL)
                if solution_match:
                    solution_content = solution_match.group(1).strip()

                self.exercises_db[exercise_id] = {
                    'id': exercise_id,
                    'hash': exercise_hash,
                    'file': file_name,
                    'options': options,
                    'content': exercise_content,
                    'solution': solution_content,
                    'full_exercise': match.group(0),
                    'full_solution': solution_match.group(0) if solution_match else ""
                }

    def get_exercise(self, identifier: str) -> Optional[Dict]:
        """Get exercise by ID or hash."""
        # First try by ID
        if identifier in self.exercises_db:
            return self.exercises_db[identifier]

        # Then try by hash
        for exercise in self.exercises_db.values():
            if exercise['hash'] == identifier:
                return exercise

        return None

    def list_exercises(self) -> Dict:
        """Return all available exercises."""
        return self.exercises_db

    def get_exercises_by_file(self, file_name: str) -> List[Dict]:
        """Get all exercises from a specific file."""
        return [ex for ex in self.exercises_db.values() if ex['file'] == file_name]

class ExamGenerator:
    """Generate exam LaTeX files from selected exercises."""

    def __init__(self, extractor: ExerciseExtractor, styles_path: str = "common/styles-tex"):
        """
        Initialize the exam generator.
        
        Args:
            extractor: ExerciseExtractor instance
            styles_path: Path to book style files (relative to book root)
        """
        self.extractor = extractor
        self.styles_path = styles_path
        self.template_header = self._get_template_header()
        self.template_footer = self._get_template_footer()

    def _get_template_header(self) -> str:
        """Get the LaTeX header template."""
        return r"""\documentclass[11pt,letterpaper]{article}

% Required packages
\usepackage[margin=1in]{geometry}
\usepackage{fancyhdr}
\usepackage{lastpage}
\usepackage{enumerate}
\usepackage{enumitem}
\usepackage{xparse}  % For NewDocumentCommand used in simplified macros

% Essential packages for figures and subfigures
\usepackage{graphicx}
\graphicspath{{.},{./figures},{./common},{./common/figures},{../common},{../common/figures}}
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

% Import book style files directly
\usepackage{<<STYLES_PATH>>/bookmathmacros}
\usepackage{<<STYLES_PATH>>/booktikz}

% Simplified version of book macros for exams
% These override complex book macros that have dependencies we don't need in exams

% Simplified figcaption that just calls standard caption
% Arguments: [optional key/value][optional float/nofloat]{id}{caption}
\makeatletter
\NewDocumentCommand{\figcaption}{o O{float} m m}{%
  \caption{#4}%
  \label{#3}%
}
\makeatother

% Simplified tabcaption that just calls standard caption
% Arguments: [short caption][float/nofloat]{id}{caption}
\makeatletter
\NewDocumentCommand{\tabcaption}{O{#4} O{float} m m}{%
  \caption[#1]{#4}%
  \label{#3}%
}
\makeatother

% Define graphicslist as empty (used by book's figcaption)
\def\graphicslist{}

% Simple counter for problems
\newcounter{problem}
\setcounter{problem}{0}

% Exam header and footer setup
\pagestyle{fancy}
\fancyhf{}
\renewcommand{\headrulewidth}{0.4pt}
\renewcommand{\footrulewidth}{0.4pt}

% Exam-specific information
\newcommand{\examtitle}{<<EXAM_TITLE>>}
\newcommand{\examdate}{<<EXAM_DATE>>}
\newcommand{\examtime}{<<EXAM_TIME>>}
\newcommand{\coursename}{<<COURSE_NAME>>}
\newcommand{\instructorname}{<<INSTRUCTOR_NAME>>}
\newcommand{\examversion}{<<EXAM_VERSION>>}

% Header and footer content
\lhead{\coursename}
\chead{\examtitle}
\rhead{Version \examversion}
\lfoot{\instructorname}
\cfoot{Page \thepage\ of \pageref{LastPage}}
\rfoot{\examdate}

% Simple exam header command (no title page)
\newcommand{\makeexamheader}{%
  \begin{center}
    {\Large \textbf{\examtitle}} \\[0.3cm]
    {\large \coursename\ --- Version \examversion} \\[0.2cm]
    {\normalsize \examdate\ --- \examtime} \\[0.2cm]
    {\normalsize \instructorname}
  \end{center}
  \vspace{0.3cm}

  \noindent\textbf{Name:} \rule{3in}{0.5pt}
  \vspace{0.5cm}

  \noindent\textbf{Instructions:} <<EXAM_INSTRUCTIONS>>
  \vspace{0.5cm}
}

% Command for problem spacing
\newcommand{\problemspace}[1][1.5cm]{
  \vspace{#1}
}

% Command for answer boxes
\newcommand{\answerbox}[2][4cm]{
  \par\vspace{0.5cm}
  \noindent\textbf{Answer:}
  \framebox[#1][l]{\rule{0pt}{#2}}
  \par\vspace{0.5cm}
}

% Command for solution space
\newcommand{\solutionspace}[1][5cm]{
  \par\vspace{0.2cm}
  \noindent\textbf{Solution:}
  \par\vspace{#1}
}

% Import bookcolors at document begin to avoid spurious output in preamble
\AtBeginDocument{
  \input{<<STYLES_PATH>>/bookcolors.sty}
}

\begin{document}

% Create simple header
\makeexamheader

% Begin problems
"""

    def _get_template_footer(self) -> str:
        """Get the LaTeX footer template."""
        return r"""
\end{document}
"""

    def generate_exam(self, config: Dict) -> str:
        """Generate a complete exam LaTeX file."""
        # Replace template variables
        header = self.template_header
        replacements = {
            '<<EXAM_TITLE>>': config.get('title', 'Exam'),
            '<<EXAM_DATE>>': config.get('date', datetime.now().strftime('%B %d, %Y')),
            '<<EXAM_TIME>>': config.get('time_limit', 'Time Limit: 2 hours'),
            '<<COURSE_NAME>>': config.get('course', 'Course'),
            '<<INSTRUCTOR_NAME>>': config.get('instructor', 'Instructor'),
            '<<EXAM_VERSION>>': config.get('version', 'A'),
            '<<EXAM_INSTRUCTIONS>>': config.get('instructions', 'Show all work for full credit. Clearly indicate your final answers. Use appropriate units in your calculations.'),
            '<<STYLES_PATH>>': self.styles_path
        }

        for placeholder, value in replacements.items():
            header = header.replace(placeholder, value)

        # Generate problems section
        problems_section = self._generate_problems(config['problems'],
                                                 config.get('include_solutions', False))

        return header + problems_section + self.template_footer

    def _generate_problems(self, problem_specs: List, include_solutions: bool = False) -> str:
        """Generate the problems section of the exam."""
        problems_latex = ""

        for i, problem_spec in enumerate(problem_specs, 1):
            if isinstance(problem_spec, str):
                # Simple string identifier
                identifier = problem_spec
                points = None
                custom_instructions = None
            elif isinstance(problem_spec, dict):
                # Dictionary with additional options
                identifier = problem_spec['id']
                points = problem_spec.get('points')
                custom_instructions = problem_spec.get('instructions')
            else:
                print(f"Warning: Invalid problem specification: {problem_spec}")
                continue

            exercise = self.extractor.get_exercise(identifier)
            if not exercise:
                print(f"Warning: Exercise '{identifier}' not found")
                continue

            # Start the problem with inline formatting
            problems_latex += f"\n\\stepcounter{{problem}}\n"
            problems_latex += f"\\noindent\\textbf{{Problem \\theproblem"
            if points:
                problems_latex += f"~({points} points)"
            problems_latex += ".} "

            # Add custom instructions if provided
            if custom_instructions:
                problems_latex += f"\\textit{{{custom_instructions}}} "

            # Add exercise content (clean it from xsim markup)
            content = exercise['content']
            # Remove any \begin{exercise} and \end{exercise} from the content
            content = re.sub(r'\\begin\{exercise\}.*?\n', '', content)
            content = re.sub(r'\\end\{exercise\}', '', content)
            problems_latex += content

            # Add solution if requested
            if include_solutions and exercise['solution']:
                problems_latex += f"\n\n\\noindent\\textbf{{Solution:}}\\par\n"
                solution = exercise['solution']
                # Remove any \begin{solution} and \end{solution} from the content
                solution = re.sub(r'\\begin\{solution\}.*?\n', '', solution)
                solution = re.sub(r'\\end\{solution\}', '', solution)
                problems_latex += solution

            # Add spacing between problems
            problems_latex += "\n\\problemspace\n"

        return problems_latex

def load_config(config_file: str) -> Dict:
    """Load exam configuration from YAML file."""
    with open(config_file, 'r') as f:
        return yaml.safe_load(f)

def create_sample_config():
    """Create a sample configuration file."""
    sample_config = {
        'title': 'Midterm Exam',
        'date': 'March 15, 2024',
        'time_limit': 'Time Limit: 2 hours',
        'course': 'Course Name',
        'instructor': 'Dr. Smith',
        'version': 'A',
        'include_solutions': False,
        'instructions': 'Show all work for full credit. Clearly indicate your final answers. Use appropriate units in your calculations. Partial credit will be given for correct methodology.',
        'problems': [
            {'id': 'exercise1', 'points': 20, 'instructions': 'Show all work clearly.'},
            {'id': 'exercise2', 'points': 25},
            'exercise3',  # Simple identifier
            {'id': 'exercise4', 'points': 30, 'instructions': 'Use appropriate methods.'}
        ]
    }

    with open('exam_config_sample.yaml', 'w') as f:
        yaml.dump(sample_config, f, default_flow_style=False, indent=2)

    print("Sample configuration created: exam_config_sample.yaml")

def list_available_exercises(extractor: ExerciseExtractor):
    """List all available exercises."""
    exercises = extractor.list_exercises()

    print("Available Exercises:")
    print("=" * 50)

    by_file = {}
    for ex in exercises.values():
        if ex['file'] not in by_file:
            by_file[ex['file']] = []
        by_file[ex['file']].append(ex)

    for file_name, file_exercises in sorted(by_file.items()):
        print(f"\n{file_name}:")
        for ex in file_exercises:
            print(f"  ID: {ex['id']:<15} Hash: {ex['hash']:<15}")

def compile_pdf(tex_file: str, base_path: str = "..") -> bool:
    """Compile the LaTeX file to PDF.

    Strategy:
      1) Prefer latexmk if available (env LATEXMK or PATH)
      2) Fall back to pdflatex (env PDFLATEX or PATH), run twice
      3) If no toolchain is available, fail gracefully with guidance
    """
    original_dir = os.getcwd()
    try:
        # Normalize paths
        tex_path = Path(tex_file)

        # Change to the book directory for compilation
        book_dir = Path(base_path).resolve()
        os.chdir(book_dir)

        # Determine exam file location (absolute vs relative)
        exam_file = tex_path if tex_path.is_absolute() else Path(original_dir) / tex_path
        target_file = book_dir / tex_path.name

        if exam_file.exists():
            shutil.copy2(exam_file, target_file)

        # Resolve toolchain; also check common macOS TeX bin if PATH lacks it
        latexmk_cmd = (
            os.environ.get('LATEXMK')
            or shutil.which('latexmk')
            or (str(Path('/Library/TeX/texbin/latexmk')) if Path('/Library/TeX/texbin/latexmk').exists() else None)
        )
        pdflatex_cmd = (
            os.environ.get('PDFLATEX')
            or shutil.which('pdflatex')
            or (str(Path('/Library/TeX/texbin/pdflatex')) if Path('/Library/TeX/texbin/pdflatex').exists() else None)
        )

        # Prefer latexmk
        if latexmk_cmd:
            cmd = [latexmk_cmd, '-pdf', '-f', '-interaction=batchmode', tex_path.name]
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=book_dir)
        elif pdflatex_cmd:
            # Fallback to pdflatex (run twice for refs)
            cmd1 = [pdflatex_cmd, '-interaction=batchmode', tex_path.name]
            r1 = subprocess.run(cmd1, capture_output=True, text=True, cwd=book_dir)
            r2 = subprocess.run(cmd1, capture_output=True, text=True, cwd=book_dir)
            # Combine outputs for diagnostics
            result = r2
        else:
            print("No LaTeX toolchain found (latexmk or pdflatex). Skipping PDF compilation.")
            print("To enable PDF compilation on macOS:")
            print("  - Install MacTeX (recommended): brew install --cask mactex-no-gui")
            print("  - Or ensure /Library/TeX/texbin is on your PATH if already installed")
            print("  - Alternatively run with --no-quick to skip compilation")
            return False

        # Check if PDF was created
        pdf_file = book_dir / tex_path.with_suffix('.pdf').name
        if pdf_file.exists():
            # Copy PDF back next to the .tex file
            dest_pdf = (
                tex_path.with_suffix('.pdf')
                if tex_path.is_absolute()
                else Path(original_dir) / tex_path.with_suffix('.pdf').name
            )
            try:
                if pdf_file.resolve() != dest_pdf.resolve():
                    shutil.copy2(pdf_file, dest_pdf)
            except FileNotFoundError:
                # If resolve fails for dest (doesn't exist yet), just copy
                shutil.copy2(pdf_file, dest_pdf)
            print(f"PDF compiled successfully: {dest_pdf}")
            return True
        else:
            print("PDF compilation did not produce an output file.")
            if result and getattr(result, 'stderr', None):
                print("LaTeX errors:", result.stderr[-500:])
            return False

    except Exception as e:
        print(f"Error during PDF compilation: {e}")
        return False
    finally:
        os.chdir(original_dir)

def main():
    parser = argparse.ArgumentParser(description='Generate exams from exercise database')
    parser.add_argument('--config', help='YAML configuration file')
    parser.add_argument('--problems', help='Comma-separated list of problem IDs/hashes')
    parser.add_argument('--title', default='Exam', help='Exam title')
    parser.add_argument('--date', help='Exam date (default: today)')
    parser.add_argument('--instructor', default='Instructor', help='Instructor name')
    parser.add_argument('--course', default='Course', help='Course name')
    parser.add_argument('--version', default='A', help='Exam version')
    parser.add_argument('--instructions', help='Custom exam instructions')
    parser.add_argument('--output', '-o', help='Output file base name (default: auto-generated)')
    parser.add_argument('--solutions', action='store_true', help='Include solutions')
    parser.add_argument('--list', action='store_true', help='List available exercises')
    parser.add_argument('--sample-config', action='store_true', help='Create sample config file')
    parser.add_argument('--base-path', default='..', help='Base path to exercise files')
    parser.add_argument('--exercise-pattern', default='ch*_exercises.tex', 
                       help='Glob pattern(s) for exercise files (comma-separated for multiple patterns)')
    parser.add_argument('--styles-path', default='common/styles-tex', help='Path to book style files (relative to book root)')
    parser.add_argument('--no-quick', action='store_true', help='Skip PDF compilation (default: compile PDF)')

    args = parser.parse_args()

    # Handle special commands
    if args.sample_config:
        create_sample_config()
        return

    # Initialize extractor
    extractor = ExerciseExtractor(args.base_path, args.exercise_pattern)

    if args.list:
        list_available_exercises(extractor)
        return

    # Generate exam
    generator = ExamGenerator(extractor, args.styles_path)

    if args.config:
        # Load from config file
        config = load_config(args.config)
        # Determine base name from config file
        config_path = Path(args.config)
        base_name = config_path.stem
    elif args.problems:
        # Create config from command line arguments
        problem_list = [p.strip() for p in args.problems.split(',')]
        config = {
            'title': args.title,
            'date': args.date or datetime.now().strftime('%B %d, %Y'),
            'instructor': args.instructor,
            'course': args.course,
            'version': args.version,
            'include_solutions': args.solutions,
            'problems': problem_list
        }
        if args.instructions:
            config['instructions'] = args.instructions
        # Generate base name from title
        safe_title = re.sub(r'[^\w\s-]', '', config['title']).strip()
        base_name = re.sub(r'[-\s]+', '_', safe_title).lower()
    else:
        parser.error('Either --config or --problems must be specified')

    # Generate the exam
    exam_latex = generator.generate_exam(config)

    # Determine output filename and directory
    if args.output:
        base_name = args.output

    # If a config file was provided and no explicit directory was given,
    # write outputs next to the config file for convenience
    if args.config:
        output_dir = Path(args.config).parent
        output_file = str(output_dir / f"{base_name}.tex")
    else:
        output_file = f"{base_name}.tex"

    # Write the exam file
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(exam_latex)

    print(f"Exam generated: {output_file}")

    # Optionally generate solutions file
    if args.solutions:
        config['include_solutions'] = True
        solutions_latex = generator.generate_exam(config)
        if args.config:
            solutions_file = str(output_dir / f"{base_name}_solutions.tex")
        else:
            solutions_file = f"{base_name}_solutions.tex"
        with open(solutions_file, 'w', encoding='utf-8') as f:
            f.write(solutions_latex)
        print(f"Solutions generated: {solutions_file}")

    # Compile PDF by default unless --no-quick is specified
    if not args.no_quick:
        print("Compiling PDF...")
        compile_success = compile_pdf(output_file, args.base_path)

        if args.solutions and compile_success:
            print("Compiling solutions PDF...")
            compile_pdf(solutions_file, args.base_path)

if __name__ == '__main__':
    main()
