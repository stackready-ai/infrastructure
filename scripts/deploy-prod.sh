#!/bin/bash
set -euo pipefail

echo "======================================"
echo "Deploying to PRODUCTION environment"
echo "======================================"

# Check if we're in the right directory
if [ ! -f "Makefile" ]; then
    echo "Error: Must run from infrastructure root directory"
    exit 1
fi

# Confirm production deployment
echo "WARNING: You are about to deploy to PRODUCTION!"
read -p "Are you sure you want to deploy to PRODUCTION? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled"
    exit 0
fi

# Double confirmation for production
read -p "Type 'PRODUCTION' to confirm: " confirm_prod
if [ "$confirm_prod" != "PRODUCTION" ]; then
    echo "Deployment cancelled"
    exit 0
fi

# Build dependencies and deploy
echo "Building Helm dependencies..."
make deps-all

echo ""
echo "Deploying applications to production..."
make deploy-prod

echo ""
echo "Waiting for applications to sync..."
sleep 10

echo ""
echo "Verifying deployment status..."
make verify-prod

echo ""
echo "Production deployment complete!"
echo "Run 'make verify-prod' to check application status"