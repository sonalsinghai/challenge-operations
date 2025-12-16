# Bootstrap Module

This module creates the foundational AWS resources required for Terragrunt to operate:

- **S3 Bucket**: Stores Terraform state files for all environments
- **DynamoDB Tables**: One table per environment for state locking
- **IAM Roles**: One role per environment with GitHub OIDC trust relationship
- **OIDC Provider**: GitHub OIDC provider for secure authentication

## Usage

Before using Terragrunt, you must bootstrap the infrastructure:

```shell
cd infra/bootstrap

export AWS_PROFILE=challange-operations-aws-profile

# Verify it's active
aws sts get-caller-identity

tenv opentofu install 1.10.7
tenv opentofu use 1.10.7

# Code formatting
tofu fmt -recursive

# Initialize Terraform
tofu init --upgrade

# Validate code
tofu validate

# Review the plan
tofu plan -var="github_repo=sonalsinghai/challenge-operations"

# Apply (creates all resources)
tofu apply -var="github_repo=sonalsinghai/challenge-operations"
```

## Variables

- `github_repo`: Your GitHub repository in format `owner/repo-name` (required)
- `state_bucket_name`: Name of the S3 bucket (default: `sonal-terragrunt-state-bucket`)
- `aws_region`: AWS region (default: `eu-west-2`)
- `environments`: List of environments (default: `["dev", "staging", "prod"]`)

## Outputs

After applying, note the outputs:

- `state_bucket_name`: Use this as `TF_STATE_BUCKET` environment variable
- `iam_role_arns`: Use these in GitHub Actions workflows
- `dynamodb_tables`: DynamoDB table names (auto-configured in Terragrunt)

## Important Notes

1. **One-time setup**: This module should only be run once to create the foundational resources.

2. **GitHub Repository**: You must provide your GitHub repository name in the format `owner/repo-name`.

3. **IAM Permissions**: The bootstrap process requires AWS credentials with permissions to create:
   - S3 buckets
   - DynamoDB tables
   - IAM roles and policies
   - OIDC providers

4. **After Bootstrap**: Once complete, update your GitHub Actions workflows with the role ARNs from the outputs.
