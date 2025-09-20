# Makefile for oven-mlir package build and distribution
#
# Common tasks:
#   make build       - Build wheel package
#   make clean       - Clean build artifacts
#   make test        - Run tests
#   make check       - Check package configuration
#   make upload-test - Upload to Test PyPI
#   make upload      - Upload to PyPI

.PHONY: help build clean test check upload-test upload install install-dev format lint

# Default Python executable
PYTHON ?= python
PIP ?= pip

# Project directories
PROJECT_ROOT := $(shell pwd)
DIST_DIR := $(PROJECT_ROOT)/dist
BUILD_DIR := $(PROJECT_ROOT)/build

help: ## Show this help message
	@echo "oven-mlir Package Build System"
	@echo "=============================="
	@echo
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

clean: ## Clean build artifacts and cache files
	@echo "🧹 Cleaning build artifacts..."
	rm -rf $(DIST_DIR) $(BUILD_DIR)
	rm -rf *.egg-info/
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "✅ Cleanup completed"

install-deps: ## Install build dependencies
	@echo "📦 Installing build dependencies..."
	$(PIP) install -U pip setuptools wheel
	$(PIP) install build twine

install: ## Install package in development mode
	@echo "📦 Installing oven-mlir in development mode..."
	$(PIP) install -e .

install-dev: ## Install package with development dependencies
	@echo "📦 Installing oven-mlir with development dependencies..."
	$(PIP) install -e .[dev,test,docs]

install-all: ## Install package with all optional dependencies
	@echo "📦 Installing oven-mlir with all dependencies..."
	$(PIP) install -e .[python-compilation,dev,test,docs,build]

build: clean install-deps ## Build wheel and source distribution
	@echo "🏗️  Building oven-mlir package..."
	$(PYTHON) -m build
	@echo "✅ Build completed"
	@echo "📁 Built files:"
	@ls -lah $(DIST_DIR)/

build-wheel: clean install-deps ## Build wheel only
	@echo "🏗️  Building oven-mlir wheel..."
	$(PYTHON) -m build --wheel
	@echo "✅ Wheel build completed"

build-source: clean install-deps ## Build source distribution only
	@echo "🏗️  Building oven-mlir source distribution..."
	$(PYTHON) -m build --sdist
	@echo "✅ Source build completed"

check: ## Check package configuration and metadata
	@echo "🔍 Checking package configuration..."
	$(PYTHON) scripts/check_package.py

validate: build ## Validate built packages
	@echo "✅ Validating packages..."
	$(PYTHON) -m twine check $(DIST_DIR)/*

test: ## Run tests
	@echo "🧪 Running tests..."
	@if [ -d "tests" ]; then \
		$(PYTHON) -m pytest tests/ -v; \
	else \
		echo "⚠️  No tests directory found"; \
	fi

test-import: build ## Test package import after build
	@echo "🧪 Testing package import..."
	@cd $(DIST_DIR) && $(PYTHON) -c "import sys; sys.path.insert(0, '.'); import oven_mlir; print('✅ Import test passed')"

lint: ## Run code linting
	@echo "🔍 Running linters..."
	$(PYTHON) -m flake8 oven_mlir/ --max-line-length=88 --extend-ignore=E203,W503
	@echo "✅ Linting completed"

format: ## Format code with black and isort
	@echo "🎨 Formatting code..."
	$(PYTHON) -m black oven_mlir/
	$(PYTHON) -m isort oven_mlir/
	@echo "✅ Code formatting completed"

format-check: ## Check code formatting
	@echo "🎨 Checking code formatting..."
	$(PYTHON) -m black --check oven_mlir/
	$(PYTHON) -m isort --check-only oven_mlir/

type-check: ## Run type checking with mypy
	@echo "🔍 Running type checks..."
	$(PYTHON) -m mypy oven_mlir/ --ignore-missing-imports

upload-test: validate ## Upload to Test PyPI
	@echo "🚀 Uploading to Test PyPI..."
	$(PYTHON) -m twine upload --repository testpypi $(DIST_DIR)/*
	@echo "✅ Upload to Test PyPI completed"
	@echo "📦 Install with: pip install -i https://test.pypi.org/simple/ oven-mlir"

upload: validate ## Upload to PyPI (production)
	@echo "⚠️  You are about to upload to PRODUCTION PyPI!"
	@echo "This action cannot be undone."
	@read -p "Are you sure? (type 'yes' to confirm): " confirm && [ "$$confirm" = "yes" ]
	@echo "🚀 Uploading to PyPI..."
	$(PYTHON) -m twine upload $(DIST_DIR)/*
	@echo "✅ Upload to PyPI completed"
	@echo "📦 Package available at: https://pypi.org/project/oven-mlir/"

release: clean format lint test build validate upload ## Complete release workflow

dev-setup: install-dev ## Set up development environment
	@echo "🛠️  Setting up development environment..."
	pre-commit install 2>/dev/null || echo "⚠️  pre-commit not available"
	@echo "✅ Development environment ready"

# Development shortcuts
quick: build-wheel ## Quick build for development

all: clean format lint test build validate ## Run all checks and build

# Docker targets (optional)
docker-build: ## Build Docker image for building wheels
	@echo "🐳 Building Docker image..."
	docker build -t oven-mlir-builder .

docker-wheel: ## Build wheel in Docker container
	@echo "🐳 Building wheel in Docker..."
	docker run --rm -v $(PROJECT_ROOT):/workspace oven-mlir-builder make build

# Info targets
info: ## Show project information
	@echo "Project Information"
	@echo "=================="
	@echo "Name: oven-mlir"
	@echo "Description: Python-to-PTX GPU Kernel Compiler"
	@echo "Version: $(shell $(PYTHON) -c 'import oven_mlir; print(oven_mlir.__version__)' 2>/dev/null || echo 'unknown')"
	@echo "Python: $(shell $(PYTHON) --version)"
	@echo "Location: $(PROJECT_ROOT)"

deps: ## Show dependency tree
	@echo "📋 Dependency tree:"
	$(PIP) list --format=tree 2>/dev/null || $(PIP) list

# Aliases
b: build
c: clean
t: test
u: upload-test