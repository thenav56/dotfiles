#!/bin/bash

find . -type d \
    -not -path './libs' \
    -not -path './libs/*' \
    -not -path '*/__pycache__' \
    -not -path './*/__pycache__/*' \
    -not -path './.ruff_cache/*' \
    -not -path './.ruff_cache' \
    -not -path './.git/*' \
    -not -path './.git' \
    -not -path './assets/*' \
    -not -path './assets' \
    -not -path './.github/*' \
    -not -path './.github' \
    -not -path './.venv/*' \
    -not -path './.venv' \
    -not -path './helm/*' \
    -not -path './helm' \
    ! -exec test -e '{}/__init__.py' \; -print
