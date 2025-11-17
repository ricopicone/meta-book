#!/usr/bin/env python3
"""
Exercise Database Statistics Script
==================================

Shows statistics about the exercise database.
Part of the meta-book exam generation system.

Usage:
    python3 show_stats.py [--base-path PATH] [--exercise-pattern PATTERN]

Author: meta-book project
Date: 2024
"""

import sys
import re
import argparse
from pathlib import Path

def count_exercises_in_file(file_path):
    """Count exercises in a single file."""
    if not file_path.exists():
        return 0
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        return len(re.findall(r'\\begin\{exercise\}', content))
    except Exception:
        return 0

def main():
    """Show exercise database statistics."""
    parser = argparse.ArgumentParser(description='Show exercise database statistics')
    parser.add_argument('--base-path', default='../..', help='Base path to exercise files')
    parser.add_argument('--exercise-pattern', default='ch*_exercises.tex', help='Glob pattern for exercise files')
    
    args = parser.parse_args()
    
    print("Exercise Database Statistics:")
    print("=============================")
    
    # Check each file matching pattern
    base_path = Path(args.base_path)
    exercise_files = sorted(base_path.glob(args.exercise_pattern))
    
    total_exercises = 0
    files_found = 0
    
    for file_path in exercise_files:
        count = count_exercises_in_file(file_path)
        total_exercises += count
        
        if file_path.exists():
            files_found += 1
            status = "✓"
        else:
            status = "✗"
        
        print(f"{file_path.name}: {count} exercises {status}")
    
    print(f"Total exercises: {total_exercises}")
    print(f"Files found: {files_found}")
    
    # Try to load with the extractor for comparison
    try:
        from generate_exam import ExerciseExtractor
        extractor = ExerciseExtractor(args.base_path, args.exercise_pattern)
        exercises = extractor.list_exercises()
        
        print(f"Exercises loaded by extractor: {len(exercises)}")
        
        if len(exercises) != total_exercises:
            print(f"⚠ Warning: Mismatch between file count ({total_exercises}) and extractor count ({len(exercises)})")
    
    except ImportError:
        print("Note: Could not import exercise extractor for verification")
    except Exception as e:
        print(f"Note: Error loading exercise extractor: {e}")

if __name__ == '__main__':
    main()
