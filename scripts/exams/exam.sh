#!/bin/bash
# Generic shell script wrapper for Exam Generation
#
# This script provides a convenient command-line interface for generating
# and compiling exams from exercise databases using the xsim package.
#
# This is part of the meta-book project and can be used with any book
# repository that follows the meta-book structure.
#
# Usage:
#   ./exam.sh --help                    # Show help
#   ./exam.sh --list                    # List available exercises
#   ./exam.sh --sample-config          # Create sample config
#   ./exam.sh --problems id1,id2,id3    # Generate exam with specific problems
#   ./exam.sh --config config.yaml     # Generate exam from config file
#   ./exam.sh --quick id1,id2           # Generate and compile in one step (default)
#   ./exam.sh --no-quick config.yaml   # Generate without compiling
#
# Author: meta-book project
# Date: 2024

set -e  # Exit on any error

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration
PYTHON=${PYTHON:-python3}
EXAM_GENERATOR="generate_exam.py"
LATEX=${LATEX:-pdflatex}

# Default paths (can be overridden)
BASE_PATH=${BASE_PATH:-"../.."}
EXERCISE_PATTERN=${EXERCISE_PATTERN:-"ch*_exercises.tex"}
STYLES_PATH=${STYLES_PATH:-"common/styles-tex"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}Success: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}Warning: $1${NC}"
}

print_info() {
    echo -e "${BLUE}Info: $1${NC}"
}

# Check dependencies
check_dependencies() {
    if ! command -v $PYTHON &> /dev/null; then
        print_error "Python3 not found. Please install Python 3."
        exit 1
    fi
    
    if ! $PYTHON -c "import yaml" &> /dev/null; then
        print_warning "PyYAML not found. Installing..."
        $PYTHON -m pip install pyyaml
    fi
    
    if ! [ -f "$EXAM_GENERATOR" ]; then
        print_error "Exam generator script not found: $EXAM_GENERATOR"
        exit 1
    fi
}

# Show help
show_help() {
    cat << EOF
Generic Exam Generator (meta-book)
==================================

USAGE:
    $0 [COMMAND] [OPTIONS]

COMMANDS:
    --help, -h              Show this help message
    --list, -l              List all available exercises
    --sample-config, -s     Create sample configuration file
    --problems PROBLEMS     Generate and compile exam with comma-separated problem IDs/hashes
    --config FILE           Generate and compile exam from YAML configuration file
    --no-quick FILE         Generate exam without compiling (use with --config or --problems)
    --solutions PROBLEMS    Generate exam with solutions
    --validate              Validate exercise database
    --stats                 Show exercise database statistics

OPTIONS (for --problems and --quick):
    --title TITLE           Exam title (default: "Exam")
    --date DATE             Exam date (default: today)
    --instructor NAME       Instructor name (default: "Instructor")
    --course COURSE         Course name (default: "Course")
    --version VERSION       Exam version (default: "A")
    --instructions TEXT     Custom exam instructions
    --output FILE           Output filename (default: auto-generated)

ENVIRONMENT VARIABLES:
    BASE_PATH               Path to book directory (default: "../..")
    EXERCISE_PATTERN        Glob pattern for exercise files (default: "ch*_exercises.tex")
    STYLES_PATH             Path to book styles (default: "common/styles-tex")

EXAMPLES:
    # List available exercises
    $0 --list
    
    # Create sample configuration
    $0 --sample-config
    
    # Generate and compile exam with specific problems (default behavior)
    $0 --problems prob1,prob2,prob3 --title "Midterm Exam"
    
    # Generate and compile exam from config file (default behavior)
    $0 --config midterm.yaml
    
    # Generate exam without compiling
    $0 --no-quick --config midterm.yaml
    $0 --no-quick --problems prob1,prob2 --title "Quiz 1"
    
    # Generate exam with solutions
    $0 --solutions prob1,prob2,prob3

EOF
}

# List available exercises
list_exercises() {
    print_info "Available exercises:"
    $PYTHON "$EXAM_GENERATOR" --list --base-path "$BASE_PATH" --exercise-pattern "$EXERCISE_PATTERN"
}

# Create sample configuration
create_sample_config() {
    print_info "Creating sample configuration file..."
    $PYTHON "$EXAM_GENERATOR" --sample-config
    print_success "Sample configuration created: exam_config_sample.yaml"
}

# Generate exam from problems list
generate_exam_from_problems() {
    local problems="$1"
    local no_quick="$2"
    shift 2
    
    print_info "Generating exam with problems: $problems"
    
    # Build command with optional parameters
    local cmd=("$PYTHON" "$EXAM_GENERATOR" "--problems" "$problems" "--base-path" "$BASE_PATH" "--exercise-pattern" "$EXERCISE_PATTERN" "--styles-path" "$STYLES_PATH")
    
    if [[ "$no_quick" == "true" ]]; then
        cmd+=("--no-quick")
    fi
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --title)
                cmd+=("--title" "$2")
                shift 2
                ;;
            --date)
                cmd+=("--date" "$2")
                shift 2
                ;;
            --instructor)
                cmd+=("--instructor" "$2")
                shift 2
                ;;
            --course)
                cmd+=("--course" "$2")
                shift 2
                ;;
            --version)
                cmd+=("--version" "$2")
                shift 2
                ;;
            --output)
                cmd+=("--output" "$2")
                shift 2
                ;;
            --instructions)
                cmd+=("--instructions" "$2")
                shift 2
                ;;
            --solutions)
                cmd+=("--solutions")
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    "${cmd[@]}"
    print_success "Exam generated successfully"
}

# Generate exam from config file
generate_exam_from_config() {
    local config_file="$1"
    local no_quick="$2"
    local solutions="$3"
    
    if [[ ! -f "$config_file" ]]; then
        print_error "Configuration file not found: $config_file"
        exit 1
    fi
    
    print_info "Generating exam from configuration: $config_file"
    
    local cmd=("$PYTHON" "$EXAM_GENERATOR" "--config" "$config_file" "--base-path" "$BASE_PATH" "--exercise-pattern" "$EXERCISE_PATTERN" "--styles-path" "$STYLES_PATH")
    if [[ "$no_quick" == "true" ]]; then
        cmd+=("--no-quick")
    fi
    if [[ "$solutions" == "true" ]]; then
        cmd+=("--solutions")
    fi
    
    "${cmd[@]}"
    print_success "Exam generated successfully"
}

# Validate exercise database
validate_database() {
    print_info "Validating exercise database..."
    
    $PYTHON -c "
import sys
sys.path.append('.')
try:
    from generate_exam import ExerciseExtractor
    extractor = ExerciseExtractor('$BASE_PATH', '$EXERCISE_PATTERN')
    exercises = extractor.list_exercises()
    print(f'✓ Successfully loaded {len(exercises)} exercises')
    
    warnings = 0
    for ex_id, ex in exercises.items():
        if not ex['content'].strip():
            print(f'⚠ Warning: Exercise {ex_id} has empty content')
            warnings += 1
        if ex['solution'] and not ex['solution'].strip():
            print(f'⚠ Warning: Exercise {ex_id} has empty solution')
            warnings += 1
    
    if warnings == 0:
        print('✓ No issues found')
    else:
        print(f'⚠ Found {warnings} warnings')
        
    print('Validation complete')
except Exception as e:
    print(f'✗ Validation failed: {e}')
    sys.exit(1)
"
    print_success "Database validation completed"
}

# Show statistics
show_stats() {
    print_info "Exercise Database Statistics:"
    
    $PYTHON -c "
import sys
from pathlib import Path
import re

def count_exercises_in_file(file_path):
    if not file_path.exists():
        return 0
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        return len(re.findall(r'\\\\begin\{exercise\}', content))
    except Exception:
        return 0

base_path = Path('$BASE_PATH')
exercise_files = sorted(base_path.glob('$EXERCISE_PATTERN'))

total_exercises = 0
files_found = 0

for file_path in exercise_files:
    count = count_exercises_in_file(file_path)
    total_exercises += count
    files_found += 1
    status = '✓' if file_path.exists() else '✗'
    print(f'{file_path.name}: {count} exercises {status}')

print(f'Total exercises: {total_exercises}')
print(f'Files found: {files_found}')

# Try to load with the extractor for comparison
try:
    from generate_exam import ExerciseExtractor
    extractor = ExerciseExtractor('$BASE_PATH', '$EXERCISE_PATTERN')
    exercises = extractor.list_exercises()
    print(f'Exercises loaded by extractor: {len(exercises)}')
    
    if len(exercises) != total_exercises:
        print(f'⚠ Warning: Mismatch between file count ({total_exercises}) and extractor count ({len(exercises)})')
except ImportError:
    print('Note: Could not import exercise extractor for verification')
except Exception as e:
    print(f'Note: Error loading exercise extractor: {e}')
"
}

# Main script logic
main() {
    # Check dependencies
    check_dependencies
    
    # Parse command line arguments
    case "${1:-}" in
        --help|-h|help)
            show_help
            ;;
        --list|-l|list)
            list_exercises
            ;;
        --sample-config|-s|sample-config)
            create_sample_config
            ;;
        --problems|problems)
            if [[ -z "$2" ]]; then
                print_error "Problems list required"
                echo "Usage: $0 --problems id1,id2,id3 [OPTIONS]"
                exit 1
            fi
            problems_list="$2"
            shift 2
            generate_exam_from_problems "$problems_list" "false" "$@"
            ;;
        --config|config)
            if [[ -z "$2" ]]; then
                print_error "Configuration file required"
                echo "Usage: $0 --config config.yaml"
                exit 1
            fi
            generate_exam_from_config "$2" "false"
            ;;
        --no-quick)
            if [[ -z "$2" ]]; then
                print_error "Command required after --no-quick"
                echo "Usage: $0 --no-quick --config config.yaml"
                echo "Usage: $0 --no-quick --problems id1,id2,id3"
                exit 1
            fi
            case "$2" in
                --config)
                    if [[ -z "$3" ]]; then
                        print_error "Configuration file required"
                        exit 1
                    fi
                    generate_exam_from_config "$3" "true"
                    ;;
                --problems)
                    if [[ -z "$3" ]]; then
                        print_error "Problems list required"
                        exit 1
                    fi
                    problems_list="$3"
                    shift 3
                    generate_exam_from_problems "$problems_list" "true" "$@"
                    ;;
                *)
                    print_error "Invalid option after --no-quick: $2"
                    echo "Use --config or --problems after --no-quick"
                    exit 1
                    ;;
            esac
            ;;
        --solutions|solutions)
            if [[ -z "$2" ]]; then
                print_error "Problems list required"
                echo "Usage: $0 --solutions id1,id2,id3"
                exit 1
            fi
            problems_list="$2"
            shift 2
            generate_exam_from_problems "$problems_list" "false" --solutions "$@"
            ;;
        --validate|validate)
            validate_database
            ;;
        --stats|stats)
            show_stats
            ;;
        "")
            print_error "No command specified"
            echo "Use '$0 --help' for usage information"
            exit 1
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Use '$0 --help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
