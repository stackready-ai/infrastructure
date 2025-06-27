.PHONY: help test deploy-prereq deploy-dev deploy-staging deploy-prod argocd-password argocd-ui gitlab-ui influxdb-ui nifi-ui librechat-ui librechat-mongodb librechat-meilisearch kubeflow-dashboard kubeflow-pipelines clean validate-config setup-wizard check-cluster argocd-status status-dev status-staging status-prod sync-dev sync-staging sync-prod

# Default target
help:
	@echo "StackReady Deployment Makefile"
	@echo "============================="
	@echo ""
	@echo "Available targets:"
	@echo "  make test              - Validate configuration files"
	@echo "  make deploy-prereq     - Deploy ArgoCD prerequisites"
	@echo "  make deploy-dev        - Deploy development environment"
	@echo "  make deploy-staging    - Deploy staging environment"
	@echo "  make deploy-prod       - Deploy production environment"
	@echo "  make argocd-password   - Get ArgoCD admin password"
	@echo "  make clean             - Clean up ArgoCD deployment"
	@echo "  make validate-config   - Check required config values"
	@echo "  make setup-wizard      - Interactive setup wizard for all configurations"
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
	@echo "  make status-dev        - Check development environment status"
	@echo "  make status-staging    - Check staging environment status"
	@echo "  make status-prod       - Check production environment status"
	@echo "  make sync-dev          - Sync development applications"
	@echo "  make sync-staging      - Sync staging applications"
	@echo "  make sync-prod         - Sync production applications (requires confirmation)"
	@echo ""

# Configuration variables that need to be set
REQUIRED_CONFIGS := CLUSTER_NAME DOMAIN GITHUB_REPO GITHUB_TOKEN AWS_REGION

# Setup wizard
setup-wizard:
	@echo "🧙 Starting StackReady Setup Wizard..."
	@./scripts/setup-wizard.sh

# Test command to validate configurations
test: validate-config
	@echo "✅ All configuration checks passed!"

# Validate that required configuration values are set
validate-config:
	@echo "🔍 Checking required configuration values..."
	@missing_configs=""; \
	for config in $(REQUIRED_CONFIGS); do \
		if [ -z "$${!config}" ]; then \
			missing_configs="$$missing_configs $$config"; \
		fi; \
	done; \
	if [ -n "$$missing_configs" ]; then \
		echo "❌ Missing required configuration values:$$missing_configs"; \
		echo ""; \
		echo "Please set the following environment variables:"; \
		for config in $$missing_configs; do \
			echo "  export $$config=<value>"; \
		done; \
		echo ""; \
		echo "Or create a .env file with these values."; \
		exit 1; \
	fi
	@echo "✅ All required configurations are set"
	@echo ""
	@echo "Current configuration:"
	@echo "  CLUSTER_NAME: ${CLUSTER_NAME}"
	@echo "  DOMAIN: ${DOMAIN}"
	@echo "  GITHUB_REPO: ${GITHUB_REPO}"
	@echo "  AWS_REGION: ${AWS_REGION}"
	@echo "  GITHUB_TOKEN: [REDACTED]"

# Deploy ArgoCD prerequisites
deploy-prereq:
	@echo "🚀 Deploying ArgoCD prerequisites..."
	@./deploy/prereq.sh


# Deploy development environment
deploy-dev: deploy-prereq
	@echo "🚀 Deploying development environment..."
	@echo "📦 Installing dev applications using Helm..."
	@helm upgrade --install root-apps-dev ./root/dev -n argocd --create-namespace
	@echo "✅ Development environment deployed successfully"

# Deploy staging environment
deploy-staging: deploy-prereq
	@echo "🚀 Deploying staging environment..."
	@echo "📦 Installing staging applications using Helm..."
	@helm upgrade --install root-apps-staging ./root/staging -n argocd --create-namespace
	@echo "✅ Staging environment deployed successfully"

# Deploy production environment
deploy-prod: deploy-prereq
	@echo "🚀 Deploying production environment..."
	@echo "⚠️  WARNING: You are about to deploy to PRODUCTION. Are you sure? [y/N]"
	@read -r response; \
	if [ "$$response" = "y" ] || [ "$$response" = "Y" ]; then \
		echo "📦 Installing production applications using Helm..."; \
		helm upgrade --install root-apps-prod ./root/prod -n argocd --create-namespace; \
		echo "✅ Production environment deployed successfully"; \
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

# Additional helpful targets
check-cluster:
	@echo "📡 Checking cluster connectivity..."
	@kubectl cluster-info || (echo "❌ Cannot connect to cluster" && exit 1)
	@echo "✅ Cluster is accessible"

argocd-status:
	@echo "📊 ArgoCD deployment status:"
	@kubectl get deployments -n argocd 2>/dev/null || echo "❌ ArgoCD namespace not found"
	@echo ""
	@kubectl get pods -n argocd 2>/dev/null || echo "❌ No ArgoCD pods found"

# Environment-specific status commands
status-dev:
	@echo "📊 Development environment status:"
	@echo ""
	@echo "ArgoCD Applications:"
	@kubectl get applications -n argocd -l environment=dev 2>/dev/null || echo "❌ No dev applications found"
	@echo ""
	@echo "Namespaces:"
	@kubectl get namespaces | grep -E "(nifi|gitlab|kubeflow|influxdb|librechat)-dev" || echo "❌ No dev namespaces found"

status-staging:
	@echo "📊 Staging environment status:"
	@echo ""
	@echo "ArgoCD Applications:"
	@kubectl get applications -n argocd -l environment=staging 2>/dev/null || echo "❌ No staging applications found"
	@echo ""
	@echo "Namespaces:"
	@kubectl get namespaces | grep -E "(nifi|gitlab|kubeflow|influxdb|librechat)-staging" || echo "❌ No staging namespaces found"

status-prod:
	@echo "📊 Production environment status:"
	@echo ""
	@echo "ArgoCD Applications:"
	@kubectl get applications -n argocd -l environment=prod 2>/dev/null || echo "❌ No prod applications found"
	@echo ""
	@echo "Namespaces:"
	@kubectl get namespaces | grep -E "^(nifi|gitlab|kubeflow|influxdb|librechat)$$" || echo "❌ No prod namespaces found"

# Sync environment-specific applications
sync-dev:
	@echo "🔄 Syncing development applications..."
	@argocd app sync -l environment=dev --prune || echo "❌ Failed to sync dev apps. Is ArgoCD CLI configured?"

sync-staging:
	@echo "🔄 Syncing staging applications..."
	@argocd app sync -l environment=staging --prune || echo "❌ Failed to sync staging apps. Is ArgoCD CLI configured?"

sync-prod:
	@echo "🔄 Syncing production applications..."
	@echo "⚠️  WARNING: You are about to sync PRODUCTION applications. Are you sure? [y/N]"
	@read -r response; \
	if [ "$$response" = "y" ] || [ "$$response" = "Y" ]; then \
		argocd app sync -l environment=prod --prune || echo "❌ Failed to sync prod apps. Is ArgoCD CLI configured?"; \
	else \
		echo "❌ Production sync cancelled"; \
	fi
