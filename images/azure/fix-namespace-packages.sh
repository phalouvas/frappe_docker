#!/bin/bash
#
# fix-namespace-packages.sh
#
# Fixes namespace package conflicts where a meta-package overwrites
# the __init__.py of a core package during pip install.
#
# Background:
#   The agent-framework meta-package ships an empty agent_framework/__init__.py,
#   while agent-framework-core ships the real ~250-line __init__.py with all
#   exports. When pip installs agent-framework AFTER agent-framework-core,
#   the empty __init__.py overwrites the real one, causing:
#     ImportError: cannot import name 'Agent' from 'agent_framework'
#
# This script force-reinstalls agent-framework-core LAST and verifies
# that the resulting __init__.py is non-empty and importable.
#
# Usage:
#   Must be run from the bench directory (/home/frappe/frappe-bench)
#   with the virtual environment active.
#
# Fail the build on any error
set -euo pipefail

BENCH_DIR="${BENCH_DIR:-/home/frappe/frappe-bench}"
VENV_PYTHON="${BENCH_DIR}/env/bin/python"
VENV_PIP="${BENCH_DIR}/env/bin/pip"

echo "=========================================="
echo "  Fixing namespace package conflicts..."
echo "=========================================="

# Step 1: Force-reinstall agent-framework-core last (with --no-deps to
#         avoid re-resolving the entire dependency tree)
echo "  → Force-reinstalling agent-framework-core..."
"${VENV_PIP}" install --force-reinstall --no-deps "agent-framework-core>=1.2.0"
echo "  ✓ agent-framework-core reinstalled successfully"

# Step 2: Verify agent_framework/__init__.py is non-empty
echo "  → Verifying agent_framework/__init__.py is non-empty..."
INIT_FILE=$("${VENV_PYTHON}" -c "
import agent_framework
import os
print(os.path.join(os.path.dirname(agent_framework.__file__), '__init__.py'))
")
if [ ! -s "${INIT_FILE}" ]; then
    echo "  ✗ ERROR: agent_framework/__init__.py is empty or missing!"
    echo "    Path: ${INIT_FILE}"
    ls -la "$(dirname "${INIT_FILE}")"
    exit 1
fi
INIT_SIZE=$(wc -c < "${INIT_FILE}")
echo "  ✓ agent_framework/__init__.py is ${INIT_SIZE} bytes (non-empty)"

# Step 3: Verify the actual import works
echo "  → Verifying 'from agent_framework import Agent' works..."
"${VENV_PYTHON}" -c "
from agent_framework import Agent
print(f'  ✓ Import OK: Agent = {Agent}')
"
echo ""
echo "=========================================="
echo "  Namespace package fix complete!"
echo "=========================================="
