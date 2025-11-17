#!/bin/bash
# Wrapper script for exam generation using the meta-book exam system
# This allows you to run exam commands from a book's exams/ directory
# while using the generic system from meta-book/scripts/exams/.
#
# Usage (from a book repo):
#   ./exam-gen.sh --list
#   ./exam-gen.sh --config midterm.yaml
#   ./exam-gen.sh --no-quick --config midterm.yaml
#
# Note: This file is intended to be linked into each book's exams/ via meta-book/links.json
# using link-there.py. It assumes the meta-book folder is at ../meta-book relative to exams/.

# Path to the meta-book exam system (relative to exams/ directory)
# Prefer the canonical meta-book path; alternatively, if scripts/exams exists in the repo
# (via link-there), you can change this to "../scripts/exams".
EXAM_SYSTEM_DIR="../meta-book/scripts/exams"

# Base path for exercise files (relative to where the exam system runs)
export BASE_PATH="../../.."

# Exercise pattern (default works for many books)
export EXERCISE_PATTERN="${EXERCISE_PATTERN:-ch*_exercises.tex}"

# Styles path (default works for books that put styles in common/styles-tex)
export STYLES_PATH="${STYLES_PATH:-common/styles-tex}"

# Check if exam system exists
if [ ! -d "$EXAM_SYSTEM_DIR" ]; then
    echo "Error: Exam system not found at $EXAM_SYSTEM_DIR"
    echo "Make sure the meta-book submodule is initialized."
    exit 1
fi

# Ensure latexmk is available in PATH for agent terminals (common macOS install path)
if ! command -v latexmk >/dev/null 2>&1; then
    if [ -x "/Library/TeX/texbin/latexmk" ]; then
        export PATH="/Library/TeX/texbin:$PATH"
        export LATEXMK="/Library/TeX/texbin/latexmk"
    fi
fi

# Build absolute path for --config argument if provided as a relative path
ORIG_DIR=$(pwd)
ARGS=()
expect_config_path=0
for arg in "$@"; do
    if [ $expect_config_path -eq 1 ]; then
        # Convert to absolute path if not already absolute
        if [[ "$arg" = /* ]]; then
            ARGS+=("$arg")
        else
            ARGS+=("$ORIG_DIR/$arg")
        fi
        expect_config_path=0
    else
        if [ "$arg" = "--config" ]; then
            ARGS+=("$arg")
            expect_config_path=1
        else
            ARGS+=("$arg")
        fi
    fi
done

# Run the exam system with processed arguments
cd "$EXAM_SYSTEM_DIR"
./exam.sh "${ARGS[@]}"
