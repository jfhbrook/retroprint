set dotenv-load := true

# By default, run checks and tests, then format and lint
default:
  if [ ! -d venv ]; then just install; fi
  @just format
  @just check
  @just test
  @just lint

#
# Installing, updating and upgrading dependencies
#

_venv:
  if [ ! -d .venv ]; then uv venv; fi

_clean-venv:
  rm -rf .venv

# Install all dependencies
install:
  @just _venv
  uv sync --dev

# Update all dependencies
update:
  @just install

# Update all dependencies and rebuild the environment
upgrade:
  if [ -d venv ]; then just update && just check && just _upgrade; else just update; fi

_upgrade:
  @just _clean-venv
  @just _venv
  @just install

# Generate locked requirements files based on dependencies in pyproject.toml
compile:
  uv pip compile -o requirements.txt pyproject.toml
  cp requirements.txt requirements_dev.txt
  python3 -c 'import toml; print("\n".join(toml.load(open("pyproject.toml"))["dependency-groups"]["dev"]))' >> requirements_dev.txt

_clean-compile:
  rm -f requirements.txt
  rm -f requirements_dev.txt

#
# Development tooling - linting, formatting, etc
#

# Format with black and isort
format:
  uv run black './retroprint' ./tests
  uv run isort --settings-file . './retroprint' ./tests

# Lint with flake8
lint:
  uv run flake8 './retroprint' ./tests
  uv run validate-pyproject ./pyproject.toml

# Check type annotations with pyright
check:
  uv run npx pyright@latest

# Run tests with pytest
test:
  uv run pytest ./tests
  @just _clean-test

_clean-test:
  rm -f pytest_runner-*.egg
  rm -rf tests/__pycache__

#
# Shell and console
#

shell:
  uv run bash

console:
  uv run jupyter lab

#
# Documentation
#

# Live generate docs and host on a development webserver
docs:
  uv run mkdocs serve

# Build the documentation
build-docs:
  uv run mkdocs build

#
# Package publishing
#

# Build the package
build:
  uv build

_clean-build:
  rm -rf dist

# Tag the release in git
tag:
  uv run git tag -a "$(python3 -c 'import toml; print(toml.load(open("pyproject.toml", "r"))["project"]["version"])')" -m "Release $(python3 -c 'import toml; print(toml.load(open("pyproject.toml", "r"))["project"]["version"])')"

publish: build
  uv publish

# Clean up loose files
clean: _clean-venv _clean-compile _clean-test
  rm -rf retroprint.egg-info
  rm -f retroprint/*.pyc
  rm -rf retroprint/__pycache__
