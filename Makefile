# Makefile for Stackready Infrastructure

.PHONY: help deps deps-nifi deps-gitlab deps-influxdb deps-librechat deps-kubeflow deps-loadbalancer deps-all deploy-dev deploy-staging deploy-prod

# Default target
help:
	@echo "Available targets:"
	@echo "  make deps-all       - Build all Helm chart dependencies"
	@echo "  make deps-nifi      - Build NiFi Helm dependencies"
	@echo "  make deps-gitlab    - Build GitLab Helm dependencies"
	@echo "  make deps-influxdb  - Build InfluxDB Helm dependencies"
	@echo "  make deps-librechat - Build LibreChat Helm dependencies"
	@echo "  make deps-kubeflow  - Build Kubeflow Helm dependencies (local chart)"
	@echo "  make deps-loadbalancer - Build LoadBalancer Helm dependencies (local chart)"
	@echo "  make deploy-dev     - Deploy to development environment"
	@echo "  make deploy-staging - Deploy to staging environment"
	@echo "  make deploy-prod    - Deploy to production environment"

# Individual dependency targets
deps-nifi:
	@echo "Building NiFi Helm dependencies..."
	@cd applications/base/nifi && helm dependency build

deps-gitlab:
	@echo "Building GitLab Helm dependencies..."
	@cd applications/base/gitlab && helm dependency build

deps-influxdb:
	@echo "Building InfluxDB Helm dependencies..."
	@cd applications/base/influxdb && helm dependency build

deps-librechat:
	@echo "Building LibreChat Helm dependencies..."
	@cd applications/base/librechat && helm dependency build

deps-kubeflow:
	@echo "Kubeflow is a local chart, no external dependencies to build"

deps-loadbalancer:
	@echo "LoadBalancer is a local chart, no external dependencies to build"

# Build all dependencies
deps-all: deps-nifi deps-gitlab deps-influxdb deps-librechat deps-kubeflow deps-loadbalancer
	@echo "All Helm dependencies built successfully!"

# Shorthand for deps-all
deps: deps-all

# Deployment targets
deploy-dev: deps-all
	@echo "Deploying to development environment..."
	@cd root && helm upgrade --install root-apps-dev . -n argocd -f dev/values.yaml
	@echo "Development deployment complete!"

deploy-staging: deps-all
	@echo "Deploying to staging environment..."
	@cd root && helm upgrade --install root-apps-staging . -n argocd -f staging/values.yaml
	@echo "Staging deployment complete!"

deploy-prod: deps-all
	@echo "Deploying to production environment..."
	@cd root && helm upgrade --install root-apps-prod . -n argocd -f prod/values.yaml
	@echo "Production deployment complete!"

# Clean up downloaded dependencies
clean-deps:
	@echo "Cleaning up Helm dependencies..."
	@rm -rf applications/base/nifi/charts applications/base/nifi/Chart.lock
	@rm -rf applications/base/gitlab/charts applications/base/gitlab/Chart.lock
	@rm -rf applications/base/influxdb/charts applications/base/influxdb/Chart.lock
	@rm -rf applications/base/librechat/charts applications/base/librechat/Chart.lock
	@echo "Dependencies cleaned!"

# Verify all applications are healthy
verify-dev:
	@echo "Checking development applications status..."
	@kubectl get applications -n argocd | grep -E "(NAME|dev)"

verify-staging:
	@echo "Checking staging applications status..."
	@kubectl get applications -n argocd | grep -E "(NAME|staging)"

verify-prod:
	@echo "Checking production applications status..."
	@kubectl get applications -n argocd | grep -E "(NAME|prod)"