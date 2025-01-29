#!/bin/bash
# .devcontainer/post-create.sh

# Exit on any error
set -e

echo "🚀 Initializing development environment..."

# Verify installations
echo "📦 Verifying tool installations..."
terraform version
kubectl version --client
gcloud version
python --version

# Initialize Terraform
echo "🔧 Initializing Terraform..."
cd "$PROJECT_ROOT"
terraform init


# Create directories for build artifacts
echo "📁 Creating build directories..."
mkdir -p "$PROJECT_ROOT/build"
mkdir -p "$PROJECT_ROOT/function-source"

echo "✅ Development environment setup complete!"

# Print help information
cat << EOF
==============================================
🎉 Development Environment Ready!

Available Commands:
------------------
▪️ terraform-init   : Initialize Terraform for a new project
▪️ terraform-plan   : Preview infrastructure changes
▪️ terraform-apply  : Apply infrastructure changes
▪️ build-function  : Build Cloud Function source
▪️ build-container : Build Cloud Run container
▪️ deploy-k8s     : Deploy Kubernetes resources

For more information, check the README.md
==============================================
EOF