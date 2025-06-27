#!/bin/bash
set -euo pipefail

echo "======================================"
echo "Deploying to DEVELOPMENT environment"
echo "======================================"

# Check if we're in the right directory
if [ ! -f "Makefile" ]; then
    echo "Error: Must run from infrastructure root directory"
    exit 1
fi

# Build dependencies and deploy
echo "Building Helm dependencies..."
make deps-all

echo ""
echo "Deploying applications to development..."
make deploy-dev

echo ""
echo "Waiting for applications to sync..."
sleep 10

echo ""
echo "Verifying deployment status..."
make verify-dev

echo ""
echo "Development deployment complete!"
echo "Run 'make verify-dev' to check application status"