#!/bin/bash
# Wrapper script for exam generation using the meta-book exam system
# This allows you to run exam commands from the exams/ directory
# while using the generic system from meta-book/scripts/exams/

# Resolve paths relative to this script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine exam system directory with fallbacks
# Priority:
#  1) EXAM_SYSTEM_DIR env var (if set and exists)
#  2) ../meta-book/scripts/exams relative to this script
#  3) ../scripts/exams relative to this script (when linked via link-there)
#  4) ../../meta-book/scripts/exams (if exams/ is nested differently)
#  5) ../../scripts/exams
if [ -n "${EXAM_SYSTEM_DIR}" ] && [ -d "${EXAM_SYSTEM_DIR}" ]; then
    : # use provided env var
else
    CANDIDATES=(
        "${SCRIPT_DIR}/../meta-book/scripts/exams"
        "${SCRIPT_DIR}/../scripts/exams"
        "${SCRIPT_DIR}/../../meta-book/scripts/exams"
        "${SCRIPT_DIR}/../../scripts/exams"
    )
    EXAM_SYSTEM_DIR=""
    for d in "${CANDIDATES[@]}"; do
        if [ -d "$d" ]; then
            EXAM_SYSTEM_DIR="$d"
            break
        fi
    done
fi

# Base path for exercise files (relative to where the exam system runs)
export BASE_PATH="../../.."

# Exercise pattern (default includes both chapter exercises and versioned exercises)
export EXERCISE_PATTERN="${EXERCISE_PATTERN:-*/exercises.tex,common/versioned/*/index.tex}"

# Styles path (default works for electronics book)
export STYLES_PATH="${STYLES_PATH:-common/styles-tex}"

# Check if exam system exists
if [ -z "$EXAM_SYSTEM_DIR" ] || [ ! -d "$EXAM_SYSTEM_DIR" ]; then
    echo "Error: Exam system not found."
    echo "Tried:"
    echo "  - \\"${SCRIPT_DIR}/../meta-book/scripts/exams\\""
    echo "  - \\"${SCRIPT_DIR}/../scripts/exams\\""
    echo "  - \\"${SCRIPT_DIR}/../../meta-book/scripts/exams\\""
    echo "  - \\"${SCRIPT_DIR}/../../scripts/exams\\""
    echo "Options to fix:"
    echo "  1) Initialize the meta-book submodule (recommended)"
    echo "  2) Link the exam system into scripts/exams via meta-book/link-there.py"
    echo "  3) Set EXAM_SYSTEM_DIR to point to scripts/exams"
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
