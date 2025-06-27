#!/bin/bash
set -euo pipefail

echo "======================================"
echo "Deploying to STAGING environment"
echo "======================================"

# Check if we're in the right directory
if [ ! -f "Makefile" ]; then
    echo "Error: Must run from infrastructure root directory"
    exit 1
fi

# Confirm staging deployment
read -p "Are you sure you want to deploy to STAGING? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled"
    exit 0
fi

# Build dependencies and deploy
echo "Building Helm dependencies..."
make deps-all

echo ""
echo "Deploying applications to staging..."
make deploy-staging

echo ""
echo "Waiting for applications to sync..."
sleep 10

echo ""
echo "Verifying deployment status..."
make verify-staging

echo ""
echo "Staging deployment complete!"
echo "Run 'make verify-staging' to check application status"