# Exam System - Usage Instructions

## Architecture

The exam generation system has two parts:

1. **Generic System (in meta-book)**: `meta-book/scripts/exams/`
   - Core exam generation logic
   - Validation and statistics utilities
   - Documentation

2. **Book-Specific Files (in book's exams/)**: 
   - YAML configuration files for specific exams
   - Book-specific README (optional)
   - Generated exam PDFs and LaTeX files

## How to Use the Exam System

### From the Electronics Book

The exam utilities can be used directly from the meta-book scripts directory:

```bash
# Navigate to meta-book scripts
cd meta-book/scripts/exams

# Set the base path to the book root (../../.. from meta-book/scripts/exams)
export BASE_PATH=../../..

# List exercises
./exam.sh --list

# Generate an exam using a config from the book's exams directory
./exam.sh --config ../../../exams/me345-exam-1-2025F.yaml

# Or use Python directly
python3 generate_exam.py --config ../../../exams/me345-exam-1-2025F.yaml
```

### Creating Wrapper Scripts in exams/

For convenience, you can create wrapper scripts in the book's `exams/` directory:

**exams/exam-gen.sh:**
```bash
#!/bin/bash
# Wrapper for exam generation from meta-book
cd ../meta-book/scripts/exams
export BASE_PATH=../../..
./exam.sh "$@"
```

Then use:
```bash
cd exams
./exam-gen.sh --list
./exam-gen.sh --config me345-exam-1-2025F.yaml
```

### Alternative: Symbolic Links

You can also create symbolic links in `exams/` to the meta-book scripts:

```bash
cd exams
ln -s ../meta-book/scripts/exams/exam.sh exam.sh
ln -s ../meta-book/scripts/exams/generate_exam.py generate_exam.py
```

Then configure with a `.env` file or shell aliases:
```bash
# exams/.env
export BASE_PATH=..
export EXERCISE_PATTERN="ch*_exercises.tex"
export STYLES_PATH="common/styles-tex"
```

## File Organization

### What Lives Where

**meta-book/scripts/exams/** (version controlled in meta-book):
- `generate_exam.py` - Core generator
- `exam.sh` - Shell wrapper
- `Makefile` - Make targets
- `validate_exercises.py` - Validation
- `show_stats.py` - Statistics
- `README.md` - Generic documentation
- `exam_config_sample.yaml` - Sample config
- `requirements.txt` - Python dependencies

**book/exams/** (version controlled in book repo):
- `*.yaml` - Exam configurations (e.g., `midterm.yaml`, `final.yaml`)
- `*.tex` - Generated LaTeX files (can be gitignored)
- `*.pdf` - Generated PDFs (can be gitignored)
- `README.md` - Book-specific instructions (optional)
- `exam-gen.sh` - Convenience wrapper (optional)

### What to Version Control

In meta-book:
- ✅ All exam system scripts
- ✅ Generic documentation
- ✅ Sample configurations

In book repositories:
- ✅ Exam YAML configurations
- ✅ Book-specific README
- ❌ Generated .tex files (can be regenerated)
- ❌ Generated .pdf files (can be regenerated)
- ❌ Auxiliary LaTeX files (.aux, .log, etc.)

## Quick Start Examples

### Example 1: Simple Exam

```bash
cd meta-book/scripts/exams
export BASE_PATH=../../..

# Generate and compile
./exam.sh --problems crumble,mad,np \
    --title "Quiz 1" \
    --instructor "Dr. Smith" \
    --course "Electronics 101" \
    --output ../../../exams/quiz1
```

### Example 2: From Configuration

Create `exams/midterm.yaml`:
```yaml
title: 'Midterm Exam'
course: 'Electronics 101'
instructor: 'Dr. Smith'
date: 'March 15, 2024'
problems:
  - id: crumble
    points: 20
  - id: mad
    points: 25
  - np
```

Generate:
```bash
cd meta-book/scripts/exams
export BASE_PATH=../../..
./exam.sh --config ../../../exams/midterm.yaml
```

### Example 3: Using Make

```bash
cd meta-book/scripts/exams
export BASE_PATH=../../..

make list
make quick-exam CONFIG=../../../exams/midterm.yaml
```

## Path Configuration

The exam system needs to know where things are:

- **BASE_PATH**: Where to find exercise files (e.g., `ch01_exercises.tex`)
  - From `meta-book/scripts/exams`: use `../../..` 
  - From `exams/` with symlink: use `..`

- **EXERCISE_PATTERN**: Glob pattern for exercise files
  - Default: `ch*_exercises.tex`

- **STYLES_PATH**: Where to find book style files
  - Default: `common/styles-tex`

Set via environment variables or command-line arguments.

## Troubleshooting

### "No exercise files found"
- Check BASE_PATH is correct
- Verify exercise files exist and match EXERCISE_PATTERN
- Run with `--stats` to see what was found

### "Exercise not found"
- Run `--list` to see available exercises
- Check spelling of exercise ID
- Verify exercise has proper ID= parameter in source

### LaTeX compilation errors
- Verify STYLES_PATH points to correct location
- Check that all required style files exist
- Run with `--no-quick` to separate generation from compilation

## Advanced: Multi-Book Setup

If you have multiple books sharing the meta-book:

```
project/
├── meta-book/
│   └── scripts/exams/  (generic system)
├── book1/
│   ├── meta-book -> ../meta-book  (symlink)
│   └── exams/
│       └── *.yaml
├── book2/
│   ├── meta-book -> ../meta-book  (symlink)
│   └── exams/
│       └── *.yaml
```

Each book can use the same exam system with different configurations.

## Summary

✅ **Keep generic code in meta-book**  
✅ **Keep book-specific configs in book repos**  
✅ **Use wrappers or symlinks for convenience**  
✅ **Configure paths appropriately**  
✅ **Version control configs, not generated files**
