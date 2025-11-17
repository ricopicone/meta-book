#!/usr/bin/env python3
"""
Exercise Database Validation Script
==================================

Validates the exercise database for completeness and consistency.
Part of the meta-book exam generation system.

Usage:
    python3 validate_exercises.py [--base-path PATH] [--exercise-pattern PATTERN]

Author: meta-book project
Date: 2024
"""

import sys
import argparse
from pathlib import Path

def main():
    """Validate the exercise database."""
    parser = argparse.ArgumentParser(description='Validate exercise database')
    parser.add_argument('--base-path', default='../..', help='Base path to exercise files')
    parser.add_argument('--exercise-pattern', default='ch*_exercises.tex', help='Glob pattern for exercise files')
    
    args = parser.parse_args()
    
    try:
        from generate_exam import ExerciseExtractor
        
        print("Validating exercise database...")
        extractor = ExerciseExtractor(args.base_path, args.exercise_pattern)
        exercises = extractor.list_exercises()
        
        print(f'✓ Successfully loaded {len(exercises)} exercises')
        
        warnings = 0
        errors = 0
        
        # Check each exercise
        for ex_id, ex in exercises.items():
            # Check for empty content
            if not ex['content'].strip():
                print(f'⚠ Warning: Exercise {ex_id} has empty content')
                warnings += 1
            
            # Check for empty solutions that should have content
            if ex['solution'] and not ex['solution'].strip():
                print(f'⚠ Warning: Exercise {ex_id} has empty solution')
                warnings += 1
            
            # Check for duplicate IDs (should not happen with dict structure, but check anyway)
            id_count = sum(1 for other_ex in exercises.values() if other_ex['id'] == ex['id'])
            if id_count > 1:
                print(f'✗ Error: Duplicate exercise ID: {ex_id}')
                errors += 1
            
            # Check that ID and hash are valid
            if not ex['id'] or not ex['hash']:
                print(f'✗ Error: Exercise {ex_id} has missing ID or hash')
                errors += 1
        
        # Check file coverage
        base_path = Path(args.base_path)
        exercise_files = sorted(base_path.glob(args.exercise_pattern))
        files_with_exercises = set(ex['file'] for ex in exercises.values())
        
        for expected_file in exercise_files:
            if expected_file.name not in files_with_exercises:
                print(f'⚠ Warning: No exercises found in {expected_file.name}')
                warnings += 1
        
        # Summary
        print()
        print("Validation Summary:")
        print(f"  Total exercises: {len(exercises)}")
        print(f"  Files processed: {len(files_with_exercises)}")
        print(f"  Warnings: {warnings}")
        print(f"  Errors: {errors}")
        
        if errors == 0 and warnings == 0:
            print("✓ All validation checks passed!")
            return 0
        elif errors == 0:
            print("✓ Validation completed with warnings only")
            return 0
        else:
            print("✗ Validation failed with errors")
            return 1
            
    except ImportError:
        print("✗ Error: Cannot import generate_exam module")
        return 1
    except Exception as e:
        print(f"✗ Validation failed with exception: {e}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())
