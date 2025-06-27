# Makefile for Stackready Infrastructure

.PHONY: help deps deps-nifi deps-gitlab deps-influxdb deps-librechat deps-kubeflow deps-loadbalancer deps-all deploy-dev deploy-staging deploy-prod argocd-password argocd-ui gitlab-ui influxdb-ui nifi-ui librechat-ui librechat-mongodb librechat-meilisearch kubeflow-dashboard kubeflow-pipelines clean validate-config setup-wizard check-cluster argocd-status status-dev status-staging status-prod sync-dev sync-staging sync-prod

# Default target
help:
	@echo "StackReady Infrastructure Makefile"
	@echo "=================================="
	@echo ""
	@echo "Dependency Management:"
	@echo "  make deps-all       - Build all Helm chart dependencies"
	@echo "  make deps-nifi      - Build NiFi Helm dependencies"
	@echo "  make deps-gitlab    - Build GitLab Helm dependencies"
	@echo "  make deps-influxdb  - Build InfluxDB Helm dependencies"
	@echo "  make deps-librechat - Build LibreChat Helm dependencies"
	@echo "  make clean-deps     - Clean up downloaded dependencies"
	@echo ""
	@echo "Deployment targets:"
	@echo "  make deploy-dev     - Deploy to development environment"
	@echo "  make deploy-staging - Deploy to staging environment"
	@echo "  make deploy-prod    - Deploy to production environment"
	@echo "  make argocd-password - Get ArgoCD admin password"
	@echo ""
	@echo "Port-forwarding targets:"
	@echo "  make argocd-ui         - Port-forward ArgoCD UI (localhost:8080)"
	@echo "  make gitlab-ui         - Port-forward GitLab UI (localhost:8081)"
	@echo "  make influxdb-ui       - Port-forward InfluxDB UI (localhost:8086)"
	@echo "  make nifi-ui           - Port-forward NiFi UI (localhost:8082)"
	@echo "  make librechat-ui      - Port-forward LibreChat UI (localhost:8083)"
	@echo "  make librechat-mongodb - Port-forward LibreChat MongoDB (localhost:27017)"
	@echo "  make librechat-meilisearch - Port-forward LibreChat MeiliSearch (localhost:7700)"
	@echo "  make kubeflow-dashboard - Port-forward Kubeflow Dashboard (localhost:8084)"
	@echo "  make kubeflow-pipelines - Port-forward Kubeflow Pipelines UI (localhost:8085)"
	@echo ""
	@echo "Environment management:"
	@echo "  make verify-dev     - Check development applications status"
	@echo "  make verify-staging - Check staging applications status"
	@echo "  make verify-prod    - Check production applications status"
	@echo "  make sync-dev       - Sync development applications"
	@echo "  make sync-staging   - Sync staging applications"
	@echo "  make sync-prod      - Sync production applications"

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
	@echo "🚀 Deploying to development environment..."
	@cd root && helm upgrade --install root-apps-dev . -n argocd -f dev/values.yaml
	@echo "✅ Development deployment complete!"

deploy-staging: deps-all
	@echo "🚀 Deploying to staging environment..."
	@cd root && helm upgrade --install root-apps-staging . -n argocd -f staging/values.yaml
	@echo "✅ Staging deployment complete!"

deploy-prod: deps-all
	@echo "🚀 Deploying to production environment..."
	@echo "⚠️  WARNING: You are about to deploy to PRODUCTION. Are you sure? [y/N]"
	@read -r response; \
	if [ "$$response" = "y" ] || [ "$$response" = "Y" ]; then \
		cd root && helm upgrade --install root-apps-prod . -n argocd -f prod/values.yaml; \
		echo "✅ Production deployment complete!"; \
	else \
		echo "❌ Production deployment cancelled"; \
	fi

# Get ArgoCD admin password
argocd-password:
	@echo "🔑 Getting ArgoCD admin password..."
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || echo "❌ ArgoCD not deployed or secret not found"
	@echo ""

# Port-forward ArgoCD UI
argocd-ui:
	@echo "🌐 Port-forwarding ArgoCD UI to http://localhost:8080"
	@echo "Press Ctrl+C to stop..."
	@kubectl port-forward svc/argocd-server -n argocd 8080:443

# Port-forward GitLab UI
gitlab-ui:
	@echo "🌐 Port-forwarding GitLab UI to http://localhost:8081"
	@echo "Press Ctrl+C to stop..."
	@kubectl port-forward svc/gitlab-webservice-default -n gitlab 8081:8181

# Port-forward InfluxDB UI
influxdb-ui:
	@echo "🌐 Port-forwarding InfluxDB UI to http://localhost:8086"
	@echo "Press Ctrl+C to stop..."
	@kubectl port-forward svc/influxdb -n influxdb 8086:8086

# Port-forward NiFi UI
nifi-ui:
	@echo "🌐 Port-forwarding NiFi UI to http://localhost:8082"
	@echo "Press Ctrl+C to stop..."
	@kubectl port-forward svc/nifi -n nifi 8082:8080

# Port-forward LibreChat UI
librechat-ui:
	@echo "🌐 Port-forwarding LibreChat UI to http://localhost:8083"
	@echo "Press Ctrl+C to stop..."
	@kubectl port-forward svc/librechat -n librechat 8083:80

# Port-forward LibreChat MongoDB
librechat-mongodb:
	@echo "🌐 Port-forwarding LibreChat MongoDB to localhost:27017"
	@echo "Press Ctrl+C to stop..."
	@kubectl port-forward svc/librechat-mongodb -n librechat 27017:27017

# Port-forward LibreChat MeiliSearch
librechat-meilisearch:
	@echo "🌐 Port-forwarding LibreChat MeiliSearch to http://localhost:7700"
	@echo "Press Ctrl+C to stop..."
	@kubectl port-forward svc/librechat-meilisearch -n librechat 7700:7700

# Port-forward Kubeflow Dashboard
kubeflow-dashboard:
	@echo "🌐 Port-forwarding Kubeflow Dashboard to http://localhost:8084"
	@echo "Press Ctrl+C to stop..."
	@kubectl port-forward svc/centraldashboard -n kubeflow 8084:80

# Port-forward Kubeflow Pipelines
kubeflow-pipelines:
	@echo "🌐 Port-forwarding Kubeflow Pipelines UI to http://localhost:8085"
	@echo "Press Ctrl+C to stop..."
	@kubectl port-forward svc/ml-pipeline-ui -n kubeflow 8085:80

# Clean up downloaded dependencies
clean-deps:
	@echo "🧹 Cleaning up Helm dependencies..."
	@rm -rf applications/base/nifi/charts applications/base/nifi/Chart.lock
	@rm -rf applications/base/gitlab/charts applications/base/gitlab/Chart.lock
	@rm -rf applications/base/influxdb/charts applications/base/influxdb/Chart.lock
	@rm -rf applications/base/librechat/charts applications/base/librechat/Chart.lock
	@echo "✅ Dependencies cleaned!"

# Clean up ArgoCD deployment
clean:
	@echo "🧹 Cleaning up ArgoCD deployment..."
	@echo "⚠️  This will delete ArgoCD and all its resources. Are you sure? [y/N]"
	@read -r response; \
	if [ "$$response" = "y" ] || [ "$$response" = "Y" ]; then \
		kubectl delete namespace argocd --ignore-not-found=true; \
		echo "✅ ArgoCD namespace deleted"; \
	else \
		echo "❌ Cleanup cancelled"; \
	fi

# Check cluster connectivity
check-cluster:
	@echo "📡 Checking cluster connectivity..."
	@kubectl cluster-info || (echo "❌ Cannot connect to cluster" && exit 1)
	@echo "✅ Cluster is accessible"

# ArgoCD status
argocd-status:
	@echo "📊 ArgoCD deployment status:"
	@kubectl get deployments -n argocd 2>/dev/null || echo "❌ ArgoCD namespace not found"
	@echo ""
	@kubectl get pods -n argocd 2>/dev/null || echo "❌ No ArgoCD pods found"

# Verify all applications are healthy
verify-dev:
	@echo "📊 Checking development applications status..."
	@kubectl get applications -n argocd | grep -E "(NAME|dev)"

verify-staging:
	@echo "📊 Checking staging applications status..."
	@kubectl get applications -n argocd | grep -E "(NAME|staging)"

verify-prod:
	@echo "📊 Checking production applications status..."
	@kubectl get applications -n argocd | grep -E "(NAME|prod)"

# Sync applications
sync-dev:
	@echo "🔄 Syncing development applications..."
	@for app in $$(kubectl get applications -n argocd -o name | grep dev); do \
		echo "Syncing $$app..."; \
		kubectl patch $$app -n argocd --type merge -p '{"operation":{"sync":{"revision":"HEAD"}}}'; \
	done

sync-staging:
	@echo "🔄 Syncing staging applications..."
	@for app in $$(kubectl get applications -n argocd -o name | grep staging); do \
		echo "Syncing $$app..."; \
		kubectl patch $$app -n argocd --type merge -p '{"operation":{"sync":{"revision":"HEAD"}}}'; \
	done

sync-prod:
	@echo "🔄 Syncing production applications..."
	@echo "⚠️  WARNING: You are about to sync PRODUCTION applications. Are you sure? [y/N]"
	@read -r response; \
	if [ "$$response" = "y" ] || [ "$$response" = "Y" ]; then \
		for app in $$(kubectl get applications -n argocd -o name | grep prod); do \
			echo "Syncing $$app..."; \
			kubectl patch $$app -n argocd --type merge -p '{"operation":{"sync":{"revision":"HEAD"}}}'; \
		done; \
	else \
		echo "❌ Sync cancelled"; \
	fi