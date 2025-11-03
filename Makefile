.PHONY: help setup validate test build clean

help:
	@echo "Health Data Aggregator - Development Commands"
	@echo ""
	@echo "Available commands:"
	@echo "  make setup       - Run setup script"
	@echo "  make validate    - Validate code structure"
	@echo "  make test        - Run tests"
	@echo "  make build       - Build the app"
	@echo "  make clean       - Clean build artifacts"
	@echo "  make codegen     - Generate code with build_runner"
	@echo "  make analyze     - Run Flutter analyzer"

setup:
	@./setup.sh

validate:
	@./scripts/validate.sh

test:
	@flutter test

build: codegen
	@flutter build web --release

clean:
	@flutter clean
	@rm -rf build/

codegen:
	@flutter pub run build_runner build --delete-conflicting-outputs

analyze:
	@flutter analyze

pub-get:
	@flutter pub get

all: pub-get codegen validate analyze test
	@echo "✓ All checks passed!"

