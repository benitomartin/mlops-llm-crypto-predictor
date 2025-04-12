# Makefile

.PHONY: all ruff mypy clean help

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
## Development
################################################################################

dev: ##	Run the trades service
	uv run services/${service}/src/${service}/main.py

build-for-dev: ## Build the trades service for development
	@echo "Building ${service} service..."	
	docker build -t ${service}:dev -f docker/${service}.Dockerfile .
	@echo "Build complete for ${service}:dev"

################################################################################
## Production
################################################################################



################################################################################
## Linting and Formatting
################################################################################


all: ## Run all linting and formatting commands
	@echo "Running all linting and formatting commands..." 
	ruff mypy clean
	@echo "All linting and formatting commands complete."

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
