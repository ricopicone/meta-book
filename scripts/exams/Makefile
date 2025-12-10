# Makefile for Generic Exam Generation and Compilation
# 
# This Makefile provides convenient targets for generating and compiling exams
# from exercise databases using the xsim package.
#
# This is part of the meta-book project and can be used with any book
# repository that follows the meta-book structure.
#
# Usage:
#   make list                    # List all available exercises
#   make sample-config          # Create sample configuration file
#   make exam PROBLEMS=id1,id2,id3  # Generate exam with specific problems
#   make exam CONFIG=config.yaml # Generate exam from config file
#   make compile EXAM=exam.tex   # Compile exam to PDF
#   make clean                   # Clean temporary files
#
# Author: meta-book project
# Date: 2024

# Default settings
PYTHON = python3
EXAM_GENERATOR = ../meta-book/scripts/exams/generate_exam.py
LATEX = pdflatex
BIBTEX = bibtex
MAKEINDEX = makeindex

# Default paths (can be overridden)
BASE_PATH ?= ../..
EXERCISE_PATTERN ?= ch*_exercises.tex
STYLES_PATH ?= common/styles-tex

# Default exam parameters
DEFAULT_TITLE = "Exam"
DEFAULT_INSTRUCTOR = "Instructor"
DEFAULT_COURSE = "Course"
DEFAULT_VERSION = "A"

# Directories
BUILD_DIR = build
TEMP_DIR = temp

# Default target
.PHONY: help
help:
	@echo "Generic Exam Generator (meta-book)"
	@echo "=================================="
	@echo ""
	@echo "Available targets:"
	@echo "  help           - Show this help message"
	@echo "  list           - List all available exercises"
	@echo "  sample-config  - Create sample configuration file"
	@echo "  exam           - Generate exam TEX file only (use CONFIG= or PROBLEMS=)"
	@echo "  compile        - Compile existing TEX file to PDF (use EXAM=)"
	@echo "  quick-exam     - Generate and compile exam to PDF (default behavior)"
	@echo "  solutions      - Generate exam with solutions and compile to PDF"
	@echo "  clean          - Clean temporary files"
	@echo "  clean-all      - Clean all generated files"
	@echo ""
	@echo "Variables:"
	@echo "  BASE_PATH      - Path to book directory (default: ../..)"
	@echo "  EXERCISE_PATTERN - Glob pattern for exercises (default: ch*_exercises.tex)"
	@echo "  STYLES_PATH    - Path to book styles (default: common/styles-tex)"
	@echo ""
	@echo "Examples:"
	@echo "  make exam PROBLEMS=prob1,prob2,prob3              # TEX only"
	@echo "  make exam CONFIG=midterm_config.yaml              # TEX only"  
	@echo "  make quick-exam CONFIG=midterm_config.yaml        # TEX + PDF"
	@echo "  make quick-exam PROBLEMS=prob1,prob2 TITLE='Quiz 1'"
	@echo "  make solutions CONFIG=midterm_config.yaml         # With solutions"

# List available exercises
.PHONY: list
list:
	@$(PYTHON) $(EXAM_GENERATOR) --list --base-path $(BASE_PATH) --exercise-pattern "$(EXERCISE_PATTERN)"

# Create sample configuration file
.PHONY: sample-config
sample-config:
	@$(PYTHON) $(EXAM_GENERATOR) --sample-config
	@echo "Sample configuration created: exam_config_sample.yaml"

# Generate exam from configuration file (TEX only, no PDF)
.PHONY: exam
exam:
ifdef CONFIG
	@echo "Generating exam from configuration: $(CONFIG)"
	@$(PYTHON) $(EXAM_GENERATOR) --config $(CONFIG) --no-quick \
		--base-path $(BASE_PATH) \
		--exercise-pattern "$(EXERCISE_PATTERN)" \
		--styles-path $(STYLES_PATH) \
		$(if $(OUTPUT),--output $(OUTPUT),)
else ifdef PROBLEMS
	@echo "Generating exam with problems: $(PROBLEMS)"
	@$(PYTHON) $(EXAM_GENERATOR) \
		--problems $(PROBLEMS) \
		--no-quick \
		--base-path $(BASE_PATH) \
		--exercise-pattern "$(EXERCISE_PATTERN)" \
		--styles-path $(STYLES_PATH) \
		$(if $(TITLE),--title "$(TITLE)",--title $(DEFAULT_TITLE)) \
		$(if $(INSTRUCTOR),--instructor "$(INSTRUCTOR)",--instructor $(DEFAULT_INSTRUCTOR)) \
		$(if $(COURSE),--course "$(COURSE)",--course $(DEFAULT_COURSE)) \
		$(if $(VERSION),--version $(VERSION),--version $(DEFAULT_VERSION)) \
		$(if $(DATE),--date "$(DATE)",) \
		$(if $(OUTPUT),--output $(OUTPUT),)
else
	@echo "Error: Either CONFIG or PROBLEMS must be specified"
	@echo "Usage: make exam CONFIG=config.yaml"
	@echo "   or: make exam PROBLEMS=id1,id2,id3"
	@exit 1
endif

# Generate exam with solutions (includes PDF compilation)
.PHONY: solutions
solutions:
ifdef CONFIG
	@echo "Generating exam with solutions from configuration: $(CONFIG)"
	@$(PYTHON) $(EXAM_GENERATOR) --config $(CONFIG) --solutions \
		--base-path $(BASE_PATH) \
		--exercise-pattern "$(EXERCISE_PATTERN)" \
		--styles-path $(STYLES_PATH) \
		$(if $(OUTPUT),--output $(OUTPUT),)
else ifdef PROBLEMS
	@echo "Generating exam with solutions for problems: $(PROBLEMS)"
	@$(PYTHON) $(EXAM_GENERATOR) \
		--problems $(PROBLEMS) \
		--solutions \
		--base-path $(BASE_PATH) \
		--exercise-pattern "$(EXERCISE_PATTERN)" \
		--styles-path $(STYLES_PATH) \
		$(if $(TITLE),--title "$(TITLE)",--title $(DEFAULT_TITLE)) \
		$(if $(INSTRUCTOR),--instructor "$(INSTRUCTOR)",--instructor $(DEFAULT_INSTRUCTOR)) \
		$(if $(COURSE),--course "$(COURSE)",--course $(DEFAULT_COURSE)) \
		$(if $(VERSION),--version $(VERSION),--version $(DEFAULT_VERSION)) \
		$(if $(DATE),--date "$(DATE)",) \
		$(if $(OUTPUT),--output $(OUTPUT),)
else
	@echo "Error: Either CONFIG or PROBLEMS must be specified"
	@echo "Usage: make solutions CONFIG=config.yaml"
	@echo "   or: make solutions PROBLEMS=id1,id2,id3"
	@exit 1
endif

# Generate and compile exam (default behavior - includes PDF compilation)
.PHONY: quick-exam
quick-exam:
ifdef CONFIG
	@echo "Generating and compiling exam from configuration: $(CONFIG)"
	@$(PYTHON) $(EXAM_GENERATOR) --config $(CONFIG) \
		--base-path $(BASE_PATH) \
		--exercise-pattern "$(EXERCISE_PATTERN)" \
		--styles-path $(STYLES_PATH) \
		$(if $(OUTPUT),--output $(OUTPUT),)
else ifdef PROBLEMS
	@echo "Generating and compiling exam with problems: $(PROBLEMS)"
	@$(PYTHON) $(EXAM_GENERATOR) \
		--problems $(PROBLEMS) \
		--base-path $(BASE_PATH) \
		--exercise-pattern "$(EXERCISE_PATTERN)" \
		--styles-path $(STYLES_PATH) \
		$(if $(TITLE),--title "$(TITLE)",--title $(DEFAULT_TITLE)) \
		$(if $(INSTRUCTOR),--instructor "$(INSTRUCTOR)",--instructor $(DEFAULT_INSTRUCTOR)) \
		$(if $(COURSE),--course "$(COURSE)",--course $(DEFAULT_COURSE)) \
		$(if $(VERSION),--version $(VERSION),--version $(DEFAULT_VERSION)) \
		$(if $(DATE),--date "$(DATE)",) \
		$(if $(OUTPUT),--output $(OUTPUT),)
else
	@echo "Error: Either CONFIG or PROBLEMS must be specified"
	@echo "Usage: make quick-exam CONFIG=config.yaml"
	@echo "   or: make quick-exam PROBLEMS=id1,id2,id3"
	@exit 1
endif

# Validate exercise database
.PHONY: validate
validate:
	@echo "Validating exercise database..."
	@$(PYTHON) -c "from generate_exam import ExerciseExtractor; \
		extractor = ExerciseExtractor('$(BASE_PATH)', '$(EXERCISE_PATTERN)'); \
		exercises = extractor.list_exercises(); \
		print(f'✓ Successfully loaded {len(exercises)} exercises')"

# Show statistics
.PHONY: stats
stats:
	@echo "Exercise Database Statistics:"
	@$(PYTHON) -c "import sys; from pathlib import Path; import re; \
		base_path = Path('$(BASE_PATH)'); \
		exercise_files = sorted(base_path.glob('$(EXERCISE_PATTERN)')); \
		total = sum(len(re.findall(r'\\\\begin\{exercise\}', f.read_text())) for f in exercise_files if f.exists()); \
		print(f'Total exercises: {total}'); \
		print(f'Files found: {len(exercise_files)}')"

# Clean temporary files
.PHONY: clean
clean:
	@echo "Cleaning temporary files..."
	@rm -f *.aux *.log *.out *.toc *.fdb_latexmk *.fls *.synctex.gz
	@rm -rf $(BUILD_DIR) $(TEMP_DIR)
	@echo "Clean complete"

# Clean all generated files
.PHONY: clean-all
clean-all: clean
	@echo "Cleaning all generated files..."
	@rm -f *.pdf *.tex
	@echo "Clean complete"

.PHONY: all
all: help
