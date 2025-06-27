#!/bin/bash
set -euo pipefail

# StackReady Setup Wizard
# This script guides users through setting up all necessary configurations and secrets

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration file
CONFIG_FILE=".stackready.env"
SECRETS_DIR="secrets"

# Function to print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Function to print header
print_header() {
    echo
    print_color "$BLUE" "=================================================="
    print_color "$BLUE" "$1"
    print_color "$BLUE" "=================================================="
    echo
}

# Function to read password with confirmation
read_password() {
    local prompt="$1"
    local var_name="$2"
    local password=""
    local password_confirm=""
    
    while true; do
        read -s -p "$prompt: " password
        echo
        read -s -p "Confirm $prompt: " password_confirm
        echo
        
        if [ "$password" = "$password_confirm" ]; then
            eval "$var_name='$password'"
            break
        else
            print_color "$RED" "Passwords do not match. Please try again."
        fi
    done
}

# Function to generate random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local missing_tools=()
    
    # Check required tools
    for tool in kubectl helm openssl; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        else
            print_color "$GREEN" "✅ $tool is installed"
        fi
    done
    
    # Check cluster connectivity
    if kubectl cluster-info &> /dev/null; then
        print_color "$GREEN" "✅ Connected to Kubernetes cluster"
    else
        print_color "$RED" "❌ Cannot connect to Kubernetes cluster"
        missing_tools+=("kubernetes-connection")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_color "$RED" "\nMissing prerequisites: ${missing_tools[*]}"
        print_color "$YELLOW" "Please install missing tools and ensure kubectl is configured."
        exit 1
    fi
    
    echo
}

# Function to setup global configuration
setup_global_config() {
    print_header "Global Configuration"
    
    # Check if config file exists
    if [ -f "$CONFIG_FILE" ]; then
        print_color "$YELLOW" "Configuration file $CONFIG_FILE already exists."
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_color "$BLUE" "Loading existing configuration..."
            source "$CONFIG_FILE"
            return
        fi
    fi
    
    # Cluster name
    read -p "Enter cluster name (default: stackready): " CLUSTER_NAME
    CLUSTER_NAME=${CLUSTER_NAME:-stackready}
    
    # Domain
    read -p "Enter base domain (e.g., example.com): " DOMAIN
    while [ -z "$DOMAIN" ]; do
        print_color "$RED" "Domain is required."
        read -p "Enter base domain: " DOMAIN
    done
    
    # GitHub configuration
    read -p "Enter GitHub repository URL (default: https://github.com/stackready-ai/infrastructure): " GITHUB_REPO
    GITHUB_REPO=${GITHUB_REPO:-https://github.com/stackready-ai/infrastructure}
    
    read -p "Enter GitHub token (for private repos, leave empty for public): " -s GITHUB_TOKEN
    echo
    
    # AWS Region (optional)
    read -p "Enter AWS region (leave empty if not using AWS): " AWS_REGION
    
    # Save configuration
    cat > "$CONFIG_FILE" << EOF
# StackReady Configuration
export CLUSTER_NAME="$CLUSTER_NAME"
export DOMAIN="$DOMAIN"
export GITHUB_REPO="$GITHUB_REPO"
export GITHUB_TOKEN="$GITHUB_TOKEN"
export AWS_REGION="$AWS_REGION"
EOF
    
    print_color "$GREEN" "✅ Configuration saved to $CONFIG_FILE"
    echo
}

# Function to setup application secrets
setup_app_secrets() {
    local app_name="$1"
    local namespace="$2"
    shift 2
    
    print_header "Setting up $app_name secrets"
    
    # Create namespace if it doesn't exist
    kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -
    
    # Process each secret
    while [ $# -gt 0 ]; do
        local secret_type="$1"
        shift
        
        case "$secret_type" in
            "gitlab")
                setup_gitlab_secrets "$namespace"
                ;;
            "influxdb")
                setup_influxdb_secrets "$namespace"
                ;;
            "nifi")
                setup_nifi_secrets "$namespace"
                ;;
            "librechat")
                setup_librechat_secrets "$namespace"
                ;;
            "kubeflow")
                setup_kubeflow_secrets "$namespace"
                ;;
            *)
                print_color "$YELLOW" "Unknown secret type: $secret_type"
                ;;
        esac
    done
}

# GitLab secrets setup
setup_gitlab_secrets() {
    local namespace="$1"
    
    print_color "$BLUE" "Setting up GitLab secrets..."
    
    # Check if secrets already exist
    if kubectl get secret gitlab-initial-root-password -n "$namespace" &> /dev/null; then
        print_color "$YELLOW" "GitLab secrets already exist."
        read -p "Do you want to recreate them? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    # Read or generate passwords
    print_color "$BLUE" "Enter passwords for GitLab (leave empty to auto-generate):"
    
    read -s -p "GitLab root password: " GITLAB_ROOT_PASS
    echo
    GITLAB_ROOT_PASS=${GITLAB_ROOT_PASS:-$(generate_password)}
    
    read -s -p "PostgreSQL password: " POSTGRES_PASS
    echo
    POSTGRES_PASS=${POSTGRES_PASS:-$(generate_password)}
    
    read -s -p "Redis password: " REDIS_PASS
    echo
    REDIS_PASS=${REDIS_PASS:-$(generate_password)}
    
    # MinIO credentials
    MINIO_ACCESS_KEY="gitlab-minio"
    MINIO_SECRET_KEY=$(generate_password)
    
    # Create secrets
    kubectl create secret generic gitlab-initial-root-password \
        -n "$namespace" \
        --from-literal=password="$GITLAB_ROOT_PASS" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl create secret generic gitlab-postgresql-password \
        -n "$namespace" \
        --from-literal=postgresql-password="$POSTGRES_PASS" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl create secret generic gitlab-redis-password \
        -n "$namespace" \
        --from-literal=password="$REDIS_PASS" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl create secret generic gitlab-minio-secret \
        -n "$namespace" \
        --from-literal=accesskey="$MINIO_ACCESS_KEY" \
        --from-literal=secretkey="$MINIO_SECRET_KEY" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Save credentials to file
    mkdir -p "$SECRETS_DIR"
    cat > "$SECRETS_DIR/gitlab-credentials.txt" << EOF
GitLab Credentials
==================
Root Username: root
Root Password: $GITLAB_ROOT_PASS
PostgreSQL Password: $POSTGRES_PASS
Redis Password: $REDIS_PASS
MinIO Access Key: $MINIO_ACCESS_KEY
MinIO Secret Key: $MINIO_SECRET_KEY
EOF
    chmod 600 "$SECRETS_DIR/gitlab-credentials.txt"
    
    print_color "$GREEN" "✅ GitLab secrets created successfully"
    print_color "$YELLOW" "Credentials saved to: $SECRETS_DIR/gitlab-credentials.txt"
}

# InfluxDB secrets setup
setup_influxdb_secrets() {
    local namespace="$1"
    
    print_color "$BLUE" "Setting up InfluxDB secrets..."
    
    read -p "InfluxDB admin username (default: admin): " INFLUX_USER
    INFLUX_USER=${INFLUX_USER:-admin}
    
    read -s -p "InfluxDB admin password (leave empty to auto-generate): " INFLUX_PASS
    echo
    INFLUX_PASS=${INFLUX_PASS:-$(generate_password)}
    
    read -p "InfluxDB organization (default: stackready): " INFLUX_ORG
    INFLUX_ORG=${INFLUX_ORG:-stackready}
    
    read -p "InfluxDB bucket (default: default): " INFLUX_BUCKET
    INFLUX_BUCKET=${INFLUX_BUCKET:-default}
    
    # Create secret
    kubectl create secret generic influxdb-auth \
        -n "$namespace" \
        --from-literal=admin-user="$INFLUX_USER" \
        --from-literal=admin-password="$INFLUX_PASS" \
        --from-literal=admin-token="$(generate_password)" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Save credentials
    cat > "$SECRETS_DIR/influxdb-credentials.txt" << EOF
InfluxDB Credentials
====================
Admin Username: $INFLUX_USER
Admin Password: $INFLUX_PASS
Organization: $INFLUX_ORG
Bucket: $INFLUX_BUCKET
EOF
    chmod 600 "$SECRETS_DIR/influxdb-credentials.txt"
    
    print_color "$GREEN" "✅ InfluxDB secrets created successfully"
}

# NiFi secrets setup
setup_nifi_secrets() {
    local namespace="$1"
    
    print_color "$BLUE" "Setting up NiFi secrets..."
    
    read -p "NiFi admin username (default: admin): " NIFI_USER
    NIFI_USER=${NIFI_USER:-admin}
    
    read -s -p "NiFi admin password (leave empty to auto-generate): " NIFI_PASS
    echo
    NIFI_PASS=${NIFI_PASS:-$(generate_password)}
    
    # Create secret
    kubectl create secret generic nifi-admin \
        -n "$namespace" \
        --from-literal=username="$NIFI_USER" \
        --from-literal=password="$NIFI_PASS" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Save credentials
    cat > "$SECRETS_DIR/nifi-credentials.txt" << EOF
NiFi Credentials
================
Admin Username: $NIFI_USER
Admin Password: $NIFI_PASS
EOF
    chmod 600 "$SECRETS_DIR/nifi-credentials.txt"
    
    print_color "$GREEN" "✅ NiFi secrets created successfully"
}

# LibreChat secrets setup
setup_librechat_secrets() {
    local namespace="$1"
    
    print_color "$BLUE" "Setting up LibreChat secrets..."
    
    # JWT Secret
    JWT_SECRET=$(generate_password)
    
    # Encryption key
    CREDS_KEY=$(generate_password)
    
    # MongoDB password
    read -s -p "MongoDB password (leave empty to auto-generate): " MONGO_PASS
    echo
    MONGO_PASS=${MONGO_PASS:-$(generate_password)}
    
    # OpenAI API Key (optional)
    read -s -p "OpenAI API Key (optional, press Enter to skip): " OPENAI_KEY
    echo
    
    # Create secrets
    kubectl create secret generic librechat-config \
        -n "$namespace" \
        --from-literal=JWT_SECRET="$JWT_SECRET" \
        --from-literal=CREDS_KEY="$CREDS_KEY" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl create secret generic librechat-mongodb \
        -n "$namespace" \
        --from-literal=mongodb-passwords="$MONGO_PASS" \
        --from-literal=mongodb-root-password="$MONGO_PASS" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    if [ -n "$OPENAI_KEY" ]; then
        kubectl create secret generic librechat-openai \
            -n "$namespace" \
            --from-literal=api-key="$OPENAI_KEY" \
            --dry-run=client -o yaml | kubectl apply -f -
    fi
    
    # Save credentials
    cat > "$SECRETS_DIR/librechat-credentials.txt" << EOF
LibreChat Credentials
=====================
MongoDB Password: $MONGO_PASS
JWT Secret: $JWT_SECRET
Encryption Key: $CREDS_KEY
EOF
    
    if [ -n "$OPENAI_KEY" ]; then
        echo "OpenAI API Key: [STORED IN SECRET]" >> "$SECRETS_DIR/librechat-credentials.txt"
    fi
    
    chmod 600 "$SECRETS_DIR/librechat-credentials.txt"
    
    print_color "$GREEN" "✅ LibreChat secrets created successfully"
}

# Kubeflow secrets setup
setup_kubeflow_secrets() {
    local namespace="$1"
    
    print_color "$BLUE" "Setting up Kubeflow secrets..."
    
    # For now, Kubeflow uses default credentials
    # Add custom setup here if needed
    
    print_color "$GREEN" "✅ Kubeflow will use default authentication"
}

# Function to update application configurations
update_app_configs() {
    print_header "Updating Application Configurations"
    
    # Update GitLab values
    if [ -f "applications/gitlab/values.yaml" ]; then
        print_color "$BLUE" "Updating GitLab configuration..."
        # Update domain in GitLab values
        sed -i "s/domain: example.com/domain: $DOMAIN/g" applications/gitlab/values.yaml
        sed -i "s/gitlab.example.com/gitlab.$DOMAIN/g" applications/gitlab/values.yaml
        sed -i "s/registry.example.com/registry.$DOMAIN/g" applications/gitlab/values.yaml
        sed -i "s/minio.example.com/minio-gitlab.$DOMAIN/g" applications/gitlab/values.yaml
        print_color "$GREEN" "✅ GitLab configuration updated"
    fi
    
    # Add updates for other applications as needed
}

# Main setup flow
main() {
    print_color "$BLUE" "╔════════════════════════════════════════════╗"
    print_color "$BLUE" "║        StackReady Setup Wizard            ║"
    print_color "$BLUE" "╚════════════════════════════════════════════╝"
    echo
    
    # Check prerequisites
    check_prerequisites
    
    # Setup global configuration
    setup_global_config
    
    # Source the configuration
    source "$CONFIG_FILE"
    
    # Ask which applications to setup
    print_header "Application Setup"
    print_color "$BLUE" "Which applications would you like to configure?"
    echo
    
    declare -A apps=(
        ["gitlab"]="GitLab - Source code management"
        ["influxdb"]="InfluxDB - Time series database"
        ["nifi"]="Apache NiFi - Data flow automation"
        ["librechat"]="LibreChat - AI chat interface"
        ["kubeflow"]="Kubeflow - ML workflows"
    )
    
    selected_apps=()
    
    for app in gitlab influxdb nifi librechat kubeflow; do
        read -p "Setup ${apps[$app]}? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            selected_apps+=($app)
        fi
    done
    
    # Setup secrets for selected applications
    for app in "${selected_apps[@]}"; do
        case $app in
            gitlab)
                setup_app_secrets "GitLab" "gitlab" "gitlab"
                ;;
            influxdb)
                setup_app_secrets "InfluxDB" "influxdb" "influxdb"
                ;;
            nifi)
                setup_app_secrets "NiFi" "nifi" "nifi"
                ;;
            librechat)
                setup_app_secrets "LibreChat" "librechat" "librechat"
                ;;
            kubeflow)
                setup_app_secrets "Kubeflow" "kubeflow" "kubeflow"
                ;;
        esac
    done
    
    # Update configurations with domain and other settings
    update_app_configs
    
    # Summary
    print_header "Setup Complete!"
    
    print_color "$GREEN" "✅ Configuration saved to: $CONFIG_FILE"
    print_color "$GREEN" "✅ Credentials saved to: $SECRETS_DIR/"
    echo
    print_color "$YELLOW" "Next steps:"
    print_color "$BLUE" "1. Deploy ArgoCD prerequisites:"
    echo "   make deploy-prereq"
    echo
    print_color "$BLUE" "2. Deploy root applications:"
    echo "   make deploy-ENV as aproproiate"
    echo
    print_color "$BLUE" "3. Access ArgoCD UI:"
    echo "   make argocd-ui"
    echo "   make argocd-password"
    echo
    print_color "$BLUE" "4. Monitor application deployment in ArgoCD"
    echo
    print_color "$YELLOW" "⚠️  Keep the $SECRETS_DIR directory secure!"
    echo
}

# Run main function
main "$@"
