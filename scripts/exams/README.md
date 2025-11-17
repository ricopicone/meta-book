# Generic Exam Generation System (meta-book)

This directory contains a complete, generic exam generation system designed to work with any book repository that uses the xsim package for exercises and follows the meta-book structure.

## Overview

The exam generation system automatically extracts exercises from chapter exercise files and generates professional LaTeX exams with PDF compilation. It's designed to be book-agnostic and easily configurable for different book projects.

## Features

- **Exercise Database Integration**: Automatically extracts exercises from chapter files matching a configurable pattern
- **Flexible Problem Selection**: Select problems by ID or hash
- **Customizable Exam Parameters**: Set title, date, instructor, course, version, etc.
- **Multiple Generation Methods**: Command line, configuration files, or shell scripts
- **Automatic PDF Compilation**: Generate and compile to PDF in one step (default behavior)
- **Book Style Integration**: Professional appearance using the book's visual elements
- **Solution Generation**: Optional inclusion of solutions with automatic compilation
- **Consistent File Naming**: YAML config and generated files share the same base name

## Quick Start

### 1. Setup in Your Book Repository

The exam system files should be linked from the meta-book submodule to an `exams` directory in your book repository using the `link-there.py` script. See the main meta-book documentation for details.

### 2. List Available Exercises

```bash
cd exams
./exam.sh --list
```

### 3. Generate and Compile Exam (Default Behavior)

```bash
# From YAML config (recommended)
./exam.sh --config midterm.yaml

# From command line
./exam.sh --problems id1,id2,id3 --title "Quiz 1" --instructor "Dr. Smith"

# Using Python script directly
python3 generate_exam.py --config midterm.yaml
```

### 4. Generate Without Compilation

```bash
# Skip PDF compilation
./exam.sh --no-quick --config midterm.yaml
python3 generate_exam.py --config midterm.yaml --no-quick
```

## File Structure

```
meta-book/scripts/exams/
├── README.md                 # This file
├── generate_exam.py         # Main Python exam generator script  
├── exam.sh                  # Shell script wrapper (recommended interface)
├── Makefile                 # Make targets for exam generation
├── exam_config_sample.yaml  # Sample configuration file
├── validate_exercises.py    # Exercise database validation utility
└── show_stats.py            # Statistics reporting utility
```

## Configuration

The exam system can be configured through:

1. **Environment variables** (for paths):
   - `BASE_PATH`: Path to book directory (default: `../..` from exams directory)
   - `EXERCISE_PATTERN`: Glob pattern for exercise files (default: `ch*_exercises.tex`)
   - `STYLES_PATH`: Path to book style files (default: `common/styles-tex`)

2. **YAML configuration files** (for exam content):
   - See `exam_config_sample.yaml` for a complete example

3. **Command-line arguments**:
   - All parameters can be overridden via command line

## Usage Methods

### Method 1: Shell Script (Recommended)

The `exam.sh` script provides the most user-friendly interface:

```bash
# Show help
./exam.sh --help

# List all available exercises
./exam.sh --list

# Generate and compile exam (default behavior)
./exam.sh --problems id1,id2,id3 \
    --title "Midterm Exam" \
    --instructor "Dr. Johnson" \
    --course "Course 101" \
    --date "March 15, 2024"

# Generate from config file (recommended)
./exam.sh --config midterm.yaml

# Generate without compilation
./exam.sh --no-quick --config midterm.yaml

# Generate with solutions
./exam.sh --solutions id1,id2,id3
```

### Method 2: Python Script

Direct use of the Python generator:

```bash
# Generate and compile (default)
python3 generate_exam.py --problems id1,id2,id3 --title "My Exam"

# From configuration file (recommended)
python3 generate_exam.py --config my_exam_config.yaml

# Skip PDF compilation
python3 generate_exam.py --config my_exam_config.yaml --no-quick

# Generate with solutions
python3 generate_exam.py --config my_exam_config.yaml --solutions

# List exercises
python3 generate_exam.py --list

# Create sample config
python3 generate_exam.py --sample-config
```

### Method 3: Makefile

Use make targets for common tasks:

```bash
# List exercises
make list

# Create sample config
make sample-config

# Generate exam (TEX only)
make exam CONFIG=midterm.yaml

# Generate and compile (TEX + PDF)
make quick-exam CONFIG=midterm.yaml

# Generate with solutions
make solutions CONFIG=midterm.yaml

# Validate exercise database
make validate

# Show statistics
make stats
```

### Method 4: Configuration Files (Recommended for Repeatable Exams)

Create a YAML configuration file for consistent, repeatable exams. The generated files will have the same base name as your config file.

**Example: `midterm_2024.yaml`**
```yaml
title: 'Midterm Exam'
course: 'Course 101 - Introduction' 
date: 'March 15, 2024'
time_limit: 'Time Limit: 2 hours'
instructor: 'Dr. Smith'
version: 'A'
include_solutions: false
instructions: 'Show all work for full credit. Use engineering notation for numerical answers. Clearly label elements and variables. Partial credit given for correct methodology.'
problems:
  - id: prob1
    points: 20
    instructions: Show all work clearly.
  - id: prob2
    points: 25
  - prob3  # Simple reference without points/instructions
  - id: prob4
    points: 30
    instructions: Use appropriate analysis methods.
```

**Generate files:** `midterm_2024.tex` + `midterm_2024.pdf`
```bash
./exam.sh --config midterm_2024.yaml
# or
python3 generate_exam.py --config midterm_2024.yaml
```

## Adapting to Your Book Repository

To use this exam system in a new book repository:

1. **Ensure your exercise files use the xsim package** with this structure:
   ```latex
   \begin{exercise}[ID=uniqueid,hash=shortha5h]
   Exercise content here...
   \end{exercise}
   
   \begin{solution}
   Solution content here...
   \end{solution}
   ```

2. **Configure the exercise file pattern**:
   - Default pattern is `ch*_exercises.tex` (matches `ch01_exercises.tex`, `ch02_exercises.tex`, etc.)
   - Override with `--exercise-pattern` argument or `EXERCISE_PATTERN` environment variable
   - Examples: `chapter*_exercises.tex`, `*_problems.tex`, `exercises/*.tex`

3. **Set up your book styles**:
   - Default expects styles in `common/styles-tex/` with files:
     - `bookmathmacros.sty` - Math macros and operators
     - `booktikz.sty` - TikZ and circuit diagram setup
     - `bookcolors.sty` - Color definitions
   - Override with `--styles-path` argument or `STYLES_PATH` environment variable

4. **Link the exam system files** to your book's exams directory using `link-there.py`

## Requirements

- Python 3.6+
- PyYAML (`pip install pyyaml`)
- LaTeX distribution with:
  - `latexmk`
  - `pdflatex`
  - Required packages: `fancyhdr`, `lastpage`, `graphicx`, `subcaption`, `cleveref`, etc.
  - Book-specific packages as defined in your style files

## Troubleshooting

### No exercises found
- Check that `BASE_PATH` points to the correct directory
- Verify `EXERCISE_PATTERN` matches your exercise file names
- Run `./exam.sh --stats` to see what files were detected

### LaTeX compilation errors
- Ensure `STYLES_PATH` points to the correct location
- Verify all required style files exist
- Check that figures/graphics paths are correct
- Run with `--no-quick` to debug LaTeX errors separately

### Missing exercises
- Run `./exam.sh --validate` to check the exercise database
- Verify exercises have proper `ID=` and `hash=` parameters
- Check for syntax errors in exercise files

## Advanced Usage

### Custom Exercise Patterns

```bash
# For exercise files named chapter01_problems.tex, chapter02_problems.tex, etc.
export EXERCISE_PATTERN="chapter*_problems.tex"
./exam.sh --list

# Or use command-line argument
python3 generate_exam.py --list --exercise-pattern "chapter*_problems.tex"
```

### Different Book Structure

```bash
# If exercises are in a subdirectory
export BASE_PATH="../.."
export EXERCISE_PATTERN="exercises/*.tex"
./exam.sh --list
```

### Custom Style Paths

```bash
# If styles are in a different location
export STYLES_PATH="styles/tex"
./exam.sh --config midterm.yaml
```

## Integration with meta-book

This exam system is designed to be part of the meta-book project. To integrate it:

1. **Add to `links.json`** in the meta-book repository
2. **Run `link-there.py`** to distribute to book repositories
3. **Create book-specific exam configs** in each book's exams directory
4. **Keep the generic system in meta-book** for easy updates across all books

## License

Part of the meta-book project. See main repository for license information.
