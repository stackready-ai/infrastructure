#!/bin/bash
set -euo pipefail

echo "======================================"
echo "Updating Helm Chart Dependencies"
echo "======================================"

# Check if we're in the right directory
if [ ! -f "Makefile" ]; then
    echo "Error: Must run from infrastructure root directory"
    exit 1
fi

# Update all dependencies
echo "Building all Helm dependencies..."
make deps-all

# Check if any changes were made
if git diff --quiet --exit-code; then
    echo "No dependency updates found"
    exit 0
fi

echo ""
echo "Dependency changes detected:"
git status --short

echo ""
echo "To commit these changes, run:"
echo "  git add -A"
echo "  git commit -m 'Update Helm chart dependencies'"
echo "  git push"