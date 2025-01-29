# Makefile
.PHONY: init plan apply destroy build-function build-container deploy-k8s clean

# Variables
PROJECT_ID := $(shell gcloud config get-value project)
REGION := europe-west1
FUNCTION_NAME := metadata-processor
CONTAINER_NAME := image-processor

init:
	@echo "🚀 Initializing Terraform..."
	terraform init

plan:
	@echo "📋 Planning Terraform changes..."
	terraform plan -var="project_id=$(PROJECT_ID)" -var="region=$(REGION)"

apply:
	@echo "🔨 Applying Terraform changes..."
	terraform apply -var="project_id=$(PROJECT_ID)" -var="region=$(REGION)" -auto-approve

destroy:
	@echo "🗑️ Destroying infrastructure..."
	terraform destroy -var="project_id=$(PROJECT_ID)" -var="region=$(REGION)" -auto-approve

build-function:
	@echo "📦 Building Cloud Function..."
	cd function-source && \
	zip -r ../build/function-source.zip . && \
	echo "Function source built at build/function-source.zip"

build-container:
	@echo "🐳 Building Cloud Run container..."
	docker build -t gcr.io/$(PROJECT_ID)/$(CONTAINER_NAME):latest ./container
	docker push gcr.io/$(PROJECT_ID)/$(CONTAINER_NAME):latest

deploy-k8s:
	@echo "☸️ Deploying Kubernetes resources..."
	kubectl apply -f k8s/

clean:
	@echo "🧹 Cleaning build artifacts..."
	rm -rf build/*
	docker system prune -f

verify:
	@echo "🔍 Verifying deployments..."
	@echo "Checking Cloud Run service..."
	gcloud run services describe $(CONTAINER_NAME) --region=$(REGION)
	@echo "Checking Cloud Function..."
	gcloud functions describe $(FUNCTION_NAME) --region=$(REGION)
	@echo "Checking GKE deployments..."
	kubectl get pods

logs:
	@echo "📊 Fetching logs..."
	@echo "Cloud Run logs:"
	gcloud logging read "resource.type=cloud_run_revision" --limit=10
	@echo "Cloud Function logs:"
	gcloud logging read "resource.type=cloud_function" --limit=10