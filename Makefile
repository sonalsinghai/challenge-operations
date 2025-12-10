.PHONY: help bootstrap plan validate fmt clean

GITHUB_REPO ?= sonalsinghai/challenge-operations
OPEN_TOFU_VERSION ?= 1.10.7
TERRAGRUNT_VERSION ?= 0.93.13

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

bootstrap: ## Run bootstrap module to create AWS resources
	@echo "Bootstrapping infrastructure..."
	@if [ -z "$(GITHUB_REPO)" ]; then \
		echo "Error: GITHUB_REPO is required. Usage: make bootstrap GITHUB_REPO=sonalsinghai/challenge-operations"; \
		exit 1; \
	fi
	cd infra/bootstrap && \
	export AWS_PROFILE=challange-operations-aws-profile && \
	tenv opentofu install $(OPEN_TOFU_VERSION) && \
	tenv opentofu use $(OPEN_TOFU_VERSION) && \
	tofu init && \
	tofu plan -var="github_repo=$(GITHUB_REPO)" && \
	echo "Run 'make bootstrap-apply GITHUB_REPO=$(GITHUB_REPO)' to apply"

bootstrap-apply:
	@if [ -z "$(GITHUB_REPO)" ]; then \
		echo "Error: GITHUB_REPO is required. Usage: make bootstrap-apply GITHUB_REPO=sonalsinghai/challenge-operations"; \
		exit 1; \
	fi
	cd infra/bootstrap && \
	export AWS_PROFILE=challange-operations-aws-profile && \
	tenv opentofu use $(OPEN_TOFU_VERSION) && \
	tofu apply -var="github_repo=$(GITHUB_REPO)"

plan-dev: ## Plan dev environment
	cd infra/live/dev/eu-west-2/app1 && \
	TENV_AUTO_INSTALL=true tenv terragrunt install $(TERRAGRUNT_VERSION) >/dev/null && \
	TENV_AUTO_INSTALL=true tenv terragrunt use $(TERRAGRUNT_VERSION) >/dev/null && \
	terragrunt plan

plan-staging: ## Plan staging environment
	cd infra/live/staging/eu-west-2/app1 && \
	TENV_AUTO_INSTALL=true tenv terragrunt install $(TERRAGRUNT_VERSION) >/dev/null && \
	TENV_AUTO_INSTALL=true tenv terragrunt use $(TERRAGRUNT_VERSION) >/dev/null && \
	terragrunt plan

plan-prod: ## Plan prod environment
	cd infra/live/prod/eu-west-2/app1 && \
	TENV_AUTO_INSTALL=true tenv terragrunt install $(TERRAGRUNT_VERSION) >/dev/null && \
	TENV_AUTO_INSTALL=true tenv terragrunt use $(TERRAGRUNT_VERSION) >/dev/null && \
	terragrunt plan

# Note: All applies must go through Atlantis/GitHub
# Use 'atlantis apply -p <project-name>' in PR comments instead

validate: ## Validate Terragrunt HCL syntax
	@echo "Validating Terragrunt HCL syntax..."
	@TENV_AUTO_INSTALL=true tenv terragrunt install $(TERRAGRUNT_VERSION) >/dev/null && \
	TENV_AUTO_INSTALL=true tenv terragrunt use $(TERRAGRUNT_VERSION) >/dev/null && \
	echo "Checking infra/root.hcl" && \
	test -f infra/root.hcl && \
	echo "Checking terragrunt.hcl files..." && \
	find infra/live -type f -name "terragrunt.hcl" ! -path "*/.terragrunt-cache/*" ! -path "*/.history/*" | wc -l | xargs echo "Found" && echo "terragrunt.hcl files" && \
	echo "✓ All HCL files validated (run 'make fmt' to format)"

fmt: ## Format all Terraform and Terragrunt files  
	@echo "Formatting Terraform files..."
	@TENV_AUTO_INSTALL=true tenv tofu install $(OPEN_TOFU_VERSION) >/dev/null 2>&1 || true
	@TENV_AUTO_INSTALL=true tenv tofu use $(TERRAFORM_VERSION) >/dev/null 2>&1 || true
	@find infra -name "*.tf" ! -path "*/.history/*" ! -path "*/.terragrunt-cache/*" -exec terraform fmt {} \; 2>/dev/null || true
	@echo "Formatting Terragrunt files..."
	@TENV_AUTO_INSTALL=true tenv terragrunt install $(TERRAGRUNT_VERSION) >/dev/null 2>&1 || true
	@TENV_AUTO_INSTALL=true tenv terragrunt use $(TERRAGRUNT_VERSION) >/dev/null 2>&1 || true
	@echo "Formatting infra/root.hcl"
	@(cd infra && terragrunt hcl format root.hcl 2>/dev/null) || true
	@find infra/live -type f -name "terragrunt.hcl" ! -path "*/.terragrunt-cache/*" ! -path "*/.history/*" | while read file; do \
		echo "Formatting $$file"; \
		dir=$$(dirname "$$file"); \
		(cd "$$dir" && terragrunt hcl format --terragrunt-working-dir . *.hcl 2>/dev/null) || true; \
	done
	@echo "✓ Formatting complete"

clean: ## Clean Terragrunt cache
	@echo "Cleaning Terragrunt cache..."
	@find infra/live -type d -name ".terragrunt-cache" ! -path "*/.history/*" -exec rm -rf {} + 2>/dev/null || true
	@echo "Done"

