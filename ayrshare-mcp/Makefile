.PHONY: help install test test-tools test-resources test-prompts test-client test-integration test-unit test-verbose test-coverage clean

help:
	@echo "Ayrshare MCP Server - Test Commands"
	@echo ""
	@echo "Setup:"
	@echo "  make install          Install dependencies including dev/test packages"
	@echo ""
	@echo "Testing:"
	@echo "  make test             Run all tests"
	@echo "  make test-tools       Run tool tests only"
	@echo "  make test-resources   Run resource tests only"
	@echo "  make test-prompts     Run prompt tests only"
	@echo "  make test-client      Run client tests only"
	@echo "  make test-integration Run integration tests only"
	@echo "  make test-unit        Run unit tests only"
	@echo "  make test-verbose     Run tests with verbose output"
	@echo "  make test-coverage    Run tests with coverage report"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean            Remove test artifacts and cache files"
	@echo ""

install:
	pip install -e ".[dev]"

test:
	pytest

test-tools:
	pytest tests/test_tools.py -v

test-resources:
	pytest tests/test_resources.py -v

test-prompts:
	pytest tests/test_prompts.py -v

test-client:
	pytest tests/test_client.py -v

test-integration:
	pytest tests/test_integration.py -v

test-unit:
	pytest -m unit -v

test-verbose:
	pytest -vs

test-coverage:
	pytest --cov=src --cov-report=html --cov-report=term
	@echo ""
	@echo "Coverage report generated in htmlcov/index.html"

clean:
	rm -rf .pytest_cache
	rm -rf htmlcov
	rm -rf .coverage
	rm -rf __pycache__
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	@echo "Cleaned test artifacts and cache files"
