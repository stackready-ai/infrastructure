.PHONY: help test deploy-prereq deploy-root argocd-password argocd-ui clean validate-config

# Default target
help:
	@echo "StackReady Deployment Makefile"
	@echo "============================="
	@echo ""
	@echo "Available targets:"
	@echo "  make test           - Validate configuration files"
	@echo "  make deploy-prereq  - Deploy ArgoCD prerequisites"
	@echo "  make deploy-root    - Deploy root applications to ArgoCD"
	@echo "  make argocd-password - Get ArgoCD admin password"
	@echo "  make argocd-ui      - Port-forward ArgoCD UI"
	@echo "  make clean          - Clean up ArgoCD deployment"
	@echo "  make validate-config - Check required config values"
	@echo ""

# Configuration variables that need to be set
REQUIRED_CONFIGS := CLUSTER_NAME DOMAIN GITHUB_REPO GITHUB_TOKEN AWS_REGION

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

# Deploy root applications
deploy-root:
	@echo "🚀 Deploying root applications..."
	@echo "📦 Installing root applications using Helm..."
	@helm upgrade --install root-apps ./root -n argocd --create-namespace
	@echo "✅ Root applications deployed successfully"

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
