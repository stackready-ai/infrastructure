#!/bin/bash
set -euo pipefail

# ArgoCD Prerequisites Deployment Script
# This script deploys the initial ArgoCD setup to a Kubernetes cluster

ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
ARGOCD_VERSION="${ARGOCD_VERSION:-v2.11.3}"

echo "🚀 Deploying ArgoCD Prerequisites"
echo "================================"
echo "ArgoCD Version: ${ARGOCD_VERSION}"
echo "Namespace: ${ARGOCD_NAMESPACE}"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl command not found. Please install kubectl first."
    exit 1
fi

# Check cluster connectivity
echo "📡 Checking cluster connectivity..."
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi
echo "✅ Connected to cluster"

# Create ArgoCD namespace
echo "📦 Creating ArgoCD namespace..."
kubectl create namespace ${ARGOCD_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
echo "🔧 Installing ArgoCD ${ARGOCD_VERSION}..."
kubectl apply -n ${ARGOCD_NAMESPACE} -f https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "⏳ Waiting for ArgoCD components to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n ${ARGOCD_NAMESPACE}
kubectl wait --for=condition=available --timeout=300s deployment/argocd-repo-server -n ${ARGOCD_NAMESPACE}
kubectl wait --for=condition=available --timeout=300s deployment/argocd-applicationset-controller -n ${ARGOCD_NAMESPACE}
kubectl wait --for=condition=available --timeout=300s deployment/argocd-notifications-controller -n ${ARGOCD_NAMESPACE}
kubectl wait --for=condition=available --timeout=300s deployment/argocd-redis -n ${ARGOCD_NAMESPACE}
kubectl wait --for=condition=available --timeout=300s deployment/argocd-dex-server -n ${ARGOCD_NAMESPACE}

echo ""
echo "✅ ArgoCD deployed successfully!"
echo ""
echo "📌 Next steps:"
echo "1. Get the initial admin password:"
echo "   kubectl -n ${ARGOCD_NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "2. Port-forward to access ArgoCD UI:"
echo "   kubectl port-forward svc/argocd-server -n ${ARGOCD_NAMESPACE} 8080:443"
echo ""
echo "3. Login using:"
echo "   Username: admin"
echo "   Password: (from step 1)"
echo ""