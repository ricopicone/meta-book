#!/bin/bash
# Wrapper script for problem set solutions generation using the meta-book pset system
# This allows you to run pset commands from the psets/ directory
# while using the generic system from meta-book/scripts/psets/

# Resolve paths relative to this script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine pset system directory with fallbacks
if [ -n "${PSET_SYSTEM_DIR}" ] && [ -d "${PSET_SYSTEM_DIR}" ]; then
    :
else
    CANDIDATES=(
        "${SCRIPT_DIR}/../meta-book/scripts/psets"
        "${SCRIPT_DIR}/../scripts/psets"
        "${SCRIPT_DIR}/../../meta-book/scripts/psets"
        "${SCRIPT_DIR}/../../scripts/psets"
    )
    PSET_SYSTEM_DIR=""
    for d in "${CANDIDATES[@]}"; do
        if [ -d "$d" ]; then
            PSET_SYSTEM_DIR="$d"
            break
        fi
    done
fi

# Base path for exercise files (relative to where the pset system runs)
export BASE_PATH="../../.."

# Exercise pattern
export EXERCISE_PATTERN="${EXERCISE_PATTERN:-ch*_exercises.tex,common/versioned/*/index.tex}"

# Styles path
export STYLES_PATH="${STYLES_PATH:-common/styles-tex}"

# Check if pset system exists
if [ -z "$PSET_SYSTEM_DIR" ] || [ ! -d "$PSET_SYSTEM_DIR" ]; then
    echo "Error: Problem set system not found."
    echo "Tried:"
    echo "  - \"${SCRIPT_DIR}/../meta-book/scripts/psets\""
    echo "  - \"${SCRIPT_DIR}/../scripts/psets\""
    echo "  - \"${SCRIPT_DIR}/../../meta-book/scripts/psets\""
    echo "  - \"${SCRIPT_DIR}/../../scripts/psets\""
    echo "Options to fix:"
    echo "  1) Initialize the meta-book submodule (recommended)"
    echo "  2) Link the pset system into scripts/psets via meta-book/link-there.py"
    echo "  3) Set PSET_SYSTEM_DIR to point to scripts/psets"
    exit 1
fi

# Ensure latexmk is available in PATH
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

# Run the pset system with processed arguments
cd "$PSET_SYSTEM_DIR"
./pset.sh "${ARGS[@]}"
