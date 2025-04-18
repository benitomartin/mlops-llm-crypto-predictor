# Makefile

.PHONY: dev all ruff mypy clean help

service ?= trades


################################################################################
## Kind Cluster
################################################################################

start-kind-cluster: ## Start the Kind cluster
	@echo "Starting the Kind cluster..."
	docker start rwml-34fa-control-plane
	@echo "Kind cluster started."

stop-kind-cluster: ## Stop the Kind cluster
	@echo "Stopping the Kind cluster..."
	docker stop rwml-34fa-control-plane
	@echo "Kind cluster stopped."


################################################################################
## Kafka UI
################################################################################

port-forward: ## Port forward the Kafka UI
	@echo "Port forwarding the Kafka UI..."
	kubectl -n kafka port-forward svc/kafka-ui 8182:8080

tmux-port-forward: ## Port forward the Kafka UI with tmux
	@echo "Port forwarding the Kafka UI with tmux..."
	tmux new-session -d 'kubectl -n kafka port-forward svc/kafka-ui 8182:8080'
	@echo "Port forwarding complete. You can access the Kafka UI at http://localhost:8182"


# ################################################################################
# ## Development
# ################################################################################

dev: ## Run the trades service
	uv run services/${service}/src/${service}/main.py

build-for-dev: ## Build the trades service for development
	@echo "Building ${service} service..."
	docker build --build-arg SERVICE_NAME=${service} -t ${service}:dev -f docker/Dockerfile .
	@echo "Build complete for ${service}:dev"

push-for-dev: ## Push the trades service to the docker registry of the Kind cluster
	@echo "Pushing ${service} service to the docker registry of the Kind cluster..."
	kind load docker-image ${service}:dev --name rwml-34fa
	@echo "Push complete for ${service}:dev"

deploy-for-dev: build-for-dev push-for-dev ## Deploy the trades service to the Kind cluster
	@echo "Deploying ${service} service to the Kind cluster..."
	kubectl delete -f deployments/dev/${service}/${service}.yaml --ignore-not-found
	@echo "Deployment deleted for ${service}"
	sleep 5
	@echo "Waiting 5 seconds..."

	@echo "Deploying ${service} service to the Kind cluster..."
	kubectl apply -f deployments/dev/${service}/${service}.yaml
	@echo "Deployment complete for ${service}"


################################################################################
## Production
################################################################################

## NOTE: # The linux/arm64 platform is not supported with non-root users creation as the Dockerfile is currently defined

build-and-push-for-prod: ## Build and push the trades service for production
	@echo "Building ${service} service for production..."
	@export BUILD_DATE=$$(date +%s) && \
	docker buildx build --push \
		--platform linux/amd64 \
		--build-arg SERVICE_NAME=${service} \
		-t ghcr.io/benitomartin/${service}:latest \
		-t ghcr.io/benitomartin/${service}:0.1.5-beta.$${BUILD_DATE} \
		-f docker/Dockerfile .

deploy-for-prod: ## Deploy the service to production
	@echo "Deploying ${service} service to production..."
	kubectl delete -f deployments/prod/${service}/${service}.yaml --ignore-not-found
	@echo "Deployment deleted for ${service}"
	sleep 5
	@echo "Waiting 5 seconds..."

	@echo "Deploying ${service} service to production..."
	kubectl apply -f deployments/prod/${service}/${service}.yaml
	@echo "Deployment complete for ${service}"

################################################################################
## Linting and Formatting
################################################################################

all: ruff mypy clean ## Run all linting and formatting commands

ruff: ## Run Ruff linter
	@echo "Running Ruff linter..."
	uv run ruff check . --fix --exit-non-zero-on-fix
	@echo "Ruff linter complete."

mypy: ## Run MyPy static type checker
	@echo "Running MyPy static type checker..."
	uv run mypy
	@echo "MyPy static type checker complete."

clean: ## Clean up cached generated files
	@echo "Cleaning up generated files..."
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type d -name ".ruff_cache" -exec rm -rf {} +
	find . -type d -name ".mypy_cache" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	@echo "Cleanup complete."


################################################################################
## Help Command
################################################################################

help: ## Display this help message
	@echo "Default target: $(.DEFAULT_GOAL)"
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help
