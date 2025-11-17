# meta-book

Generic material, utilities, and systems shared across multiple book projects.

## Overview

This repository contains generic formatting, structure, and utilities that are shared among several book projects. The key principle is that **nothing book-specific should be in this meta submodule** - only generic, reusable components.

## Contents

### LaTeX Templates and Style Files
- `0-*.tex` - Generic document structure files
- `latexmkrc*` - LaTeX compilation configurations

### Scripts and Utilities
- `scripts/` - Generic utilities for book production
	- `exams/` - **Exam generation system** (see below)
	- `artlog.py` - Art logging utilities
	- `build-alone.py` - Build individual sections
	- Various conversion and processing scripts

### Distribution System
- `link-there.py` - Distribute meta files to book repositories
- `link-here.py` - Update meta from book repositories
- `links.json` - Configuration for file distribution

## Exam Generation System

A complete, generic exam generation system for books using the xsim exercise package. Located in `scripts/exams/`.

### Features
- Automatically extracts exercises from chapter files
- Generates professional LaTeX exams with PDF compilation
- Flexible problem selection by ID or hash
- Configurable via YAML files or command line
- Support for solutions and multiple exam versions
- Book-agnostic design with configurable paths and patterns

### Quick Start

After linking to a book repository:

```bash
cd exams
./exam.sh --list                    # List available exercises
./exam.sh --sample-config          # Create sample configuration
./exam.sh --config midterm.yaml    # Generate exam from config
```

See `scripts/exams/README.md` for complete documentation.

### Integration

The exam system is designed to work with any book repository that:
1. Uses xsim package for exercises with `ID=` and `hash=` parameters
2. Has exercise files matching a pattern (default: `ch*_exercises.tex`)
3. Has book style files in a standard location (default: `common/styles-tex/`)

Configuration can be customized via environment variables or command-line arguments.

## Usage

### Distributing Meta Files to Book Repositories

1. Update `links.json` to specify which files should be distributed
2. From within the meta-book directory, run:
	 ```bash
	 python3 link-there.py
	 ```
	 This creates hard links from meta-book to the parent book directory

### Updating Meta Files from Book Repositories

If you've made changes in a book repository that should be pulled back:

```bash
python3 link-here.py
```

This reverses the link direction (useful for testing changes).

## File Structure

```
meta-book/
├── README.md                      # This file
├── links.json                     # File distribution configuration
├── link-there.py                  # Distribute to books
├── link-here.py                   # Update from books
├── 0-*.tex                        # LaTeX structure files
├── latexmkrc*                     # LaTeX build configs
├── requirements.txt               # Python dependencies
└── scripts/
		├── exams/                     # Exam generation system
		│   ├── README.md             # Exam system documentation
		│   ├── generate_exam.py      # Main exam generator
		│   ├── exam.sh               # Shell wrapper
		│   ├── Makefile              # Make targets
		│   ├── validate_exercises.py # Validation utility
		│   ├── show_stats.py         # Statistics utility
		│   └── exam_config_sample.yaml # Sample config
		└── ...                        # Other utility scripts
```

## Adding New Generic Systems

When adding new generic utilities or systems to meta-book:

1. **Keep it generic** - No book-specific content
2. **Make it configurable** - Use parameters/config files for book-specific values
3. **Document it** - Add clear documentation and examples
4. **Update links.json** - Add files that should be distributed
5. **Test in multiple books** - Ensure it works across different book projects

## Requirements

See `requirements.txt` for Python dependencies. Common requirements:
- Python 3.6+
- PyYAML (for exam system)
- LaTeX distribution with latexmk

## License

See individual book repositories for licensing information.