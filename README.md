# Multi-Environment Terraform State Management Solution

A comprehensive solution to prevent cross-environment state corruption and accidental modifications to production infrastructure using Terragrunt, validation hooks, and CI/CD safeguards. It showcases how to addresses the critical problem where developers accidentally run `terraform apply` in the wrong environment directory, causing production resources to be modified when they intended to modify staging.

## The Problem

- Developers accidentally applying changes to the wrong environment
- No validation to prevent cross-environment state corruption
- Lack of clear feedback when incorrect state files are accessed
- Risk of production incidents from misconfigured operations

## Solution

The solution implements multiple layers of protection:

1. **Path-Based Environment Detection**: Environment is automatically extracted from directory structure
   - **Automatic environment detection** from directory path (`live/<env>/<region>/<app>`)
   - **Pre-Command Validation Hooks**: Scripts run before every Terraform operation to validate environment
   - **AWS_ROLE_ARN validation** ensures IAM role matches environment
2. **IAM Role-Based Access Control**: Separate IAM roles per environment with OIDC integration
3. **CI/CD Integration**: GitHub Actions workflows enforce branch-based environment restrictions
   - **GitHub Actions workflows** with environment-specific IAM roles
   - **Branch-based restrictions** (prod only from `main`, `release/*`, `hotfix/*`)
   - **OIDC authentication** eliminates long-lived credentials
     - Bootstrap project creates OIDC provider, that allows AWS to receive requests from GitHub for specific environment & depending on branch
     - IAM roles trust the OIDC provider
     - GitHub Actions workflows authenticate to AWS using those roles
4. **State Management/Isolation**: Per-environment DynamoDB lock tables and path-based state keys
   - **Centralized S3 backend** with versioning and encryption
   - **Per-environment DynamoDB lock tables** to prevent concurrent modifications: `<env>-terraform-locks` (one per environment)
   - **Path-based state keys** automatically isolate environments: `live/<env>/<region>/<app>/<module>/terraform.tfstate`
   - **Backend validation** ensures infrastructure exists before operations
   - **Encryption**: Server-side encryption enabled on S3 bucket

### Security Considerations

- **No long-lived credentials**: OIDC-based authentication
- **Least privilege IAM roles**: Environment-specific permissions
- **State encryption**: Server-side encryption on S3
- **Lock tables**: Prevent concurrent modifications. OpenTofu 1.10 improves this by replacing Lock tables with S3 lock files.
- **Branch restrictions**: Production changes only from protected branches

## Prerequisites

- **OpenTofu** >= 1.10.0
- **Terragrunt** >= 0.93.0
- **AWS CLI** configured with appropriate credentials
- **Git** for version control
- **Make** (optional, for convenience commands)

## Quick Start

Get up and running with this Terragrunt infrastructure in 5 minutes.

### Prerequisites Check

```shell
# Check Terragrunt
terragrunt --version  # Should be >= 0.93.0

# Check OpenTofu/Terraform
tofu version  # Should be >= 1.10.0

# Check AWS CLI
aws --version
aws sts get-caller-identity  # Should show your AWS account
```

### Step 1: Bootstrap Infrastructure (One-time only setup)

```shell
# Connect to AWS
export AWS_PROFILE=challange-operations-aws-profile
export AWS_REGION=eu-west-2
aws login
aws sts get-caller-identity

# Set Github Repo (required to create role for OIDC)
export GITHUB_REPO="sonalsinghai/challenge-operations"

# Navigate to bootstrap
cd infra/bootstrap
tofu fmt -recursive
tofu validate

# Initialize and apply
tofu init --upgrade
tofu plan -var="github_repo=$GITHUB_REPO"
tofu apply -var="github_repo=$GITHUB_REPO"
tofu output
```

**Important**: Note the `state_bucket_name` and `iam_role_arns` from the output and replace those in Terragrunt code.

### Step 2: Configure Environment Variables

```shell
# Connect to AWS
export AWS_PROFILE=challange-operations-aws-profile
export AWS_REGION=eu-west-2
aws login
aws sts get-caller-identity

# Set Github Repo (required to create role for OIDC)
export GITHUB_REPO="sonalsinghai/challenge-operations"

# Set state bucket (from bootstrap output)
export TF_STATE_BUCKET="sonal-terragrunt-state-bucket"
```

### Step 3: Test Locally (Plan Only)

```shell
# Navigate to dev environment
cd infra/live/dev/eu-west-2/app1

# Run plan (validation hooks run automatically)
# Note: Only plan is allowed locally - all applies must go through GitHub
terragrunt plan
```

### Step 4: Make Your First Change

```shell
# Create a branch
git checkout -b feature/test-change

# Edit a Terragrunt config
vim infra/live/dev/eu-west-2/app1/terragrunt.hcl

# Test locally
cd infra/live/dev/eu-west-2/app1
terragrunt plan

# Commit and push
git add .
git commit -m "Test infrastructure change"
git push origin feature/test-change
```

### Step 5: Create Pull Request and Deploy

```shell
# Create and push your branch (from Step 4)
git push origin feature/test-change
```

1. **Open a Pull Request** on GitHub targeting `develop` or `main`
2. **GitHub Actions automatically runs** `terragrunt plan` for all environments
   - Workflow: `.github/workflows/terragrunt-plan.yaml`
   - Runs for dev, staging, and prod (based on changed files)
   - Posts plan results as PR comments
3. **Review the plan output** in GitHub Actions logs and PR comments
4. **Get PR approval** from team members
5. **Merge the PR** to trigger apply:
   - Merging to `develop` → applies to dev and staging
   - Merging to `main` → applies to prod

**Important**: All applies are automated through GitHub Actions workflows after merge. Local applies are disabled for safety.

### Common Commands

```shell
# Plan a specific environment
make plan-dev
make plan-staging
make plan-prod

# Format code
make fmt

# Validate configurations
make validate

# Clean cache
make clean
```

### IAM Roles

Each environment has a dedicated IAM role with OIDC trust:

- **dev**: `terragrunt-dev-role` - Allows all branches
- **staging**: `terragrunt-staging-role` - Allows `develop`, `feature/*`, `staging/*`
- **prod**: `terragrunt-prod-role` - Allows `main`, `release/*`, `hotfix/*`

## How It Works

### 1. Environment Detection

The `root.hcl` file automatically extracts environment from the directory path:

```hcl
locals {
  env_match = regex(".*/live/([^/]+)/", local.terragrunt_dir)
  env       = try(local.env_match[0], "unknown")
}
```

### 2. Pre-Command Validation

Before any Terraform operation (`init`, `plan`, `apply`, `destroy`), Terragrunt hooks execute validation scripts:

```hcl
before_hook "validate_environment" {
  commands     = ["init", "plan", "apply", "destroy"]
  execute      = ["bash", "${get_parent_terragrunt_dir()}/ci/ensure-env.sh", get_terragrunt_dir()]
  run_on_error = false
}
```

The `ensure-env.sh` script:
- Extracts environment from directory path
- Validates `AWS_ROLE_ARN` matches environment
- Enforces branch restrictions in CI/CD

### 3. Backend Validation

Before `init`, `plan`, or `apply`, the backend validation script:
- Checks S3 bucket exists
- Checks DynamoDB lock table exists
- Verifies versioning and encryption are enabled

### 4. CI/CD Integration

**GitHub Actions** workflows:
- Use environment-specific IAM roles via OIDC
- Enforce branch-based restrictions
- Run validation hooks automatically
- Comment plan results on PRs

## Testing Strategy

### Manual Testing

1. **Test Environment Validation**
   ```shell
   # Should pass
   cd infra/live/dev/eu-west-2/app1
   terragrunt plan
   
   # Should pass
   cd infra/live/prod/eu-west-2/app1
   terragrunt plan
   
   # Should fail, prd is not a valid one
   cd infra/live/prd/eu-west-2/app1
   terragrunt plan
   ```

2. **Test Backend Validation**
   ```shell
   # Should fail if bucket doesn't exist
   cd infra/live/dev/eu-west-2/app1
   export TF_STATE_BUCKET=non-existent-bucket
   terragrunt plan  # Error: Backend validation failed
   ```

3. **Test IAM Role Validation**
   ```shell
   # Should fail if role doesn't match
   cd infra/live/prod/eu-west-2/app1
   export AWS_ROLE_ARN=arn:aws:iam::123456789012:role/terragrunt-dev-role
   terragrunt plan  # Error: AWS_ROLE_ARN does not match environment
   ```
