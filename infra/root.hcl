# Root Terragrunt Configuration
# This file provides common configuration shared across all environments (dev/staging/prod)
# It handles: provider setup, remote state, locals extraction, hooks, and common inputs

# Auto-generate provider.tf in each module directory
# This ensures consistent Terraform and AWS provider versions across all modules
generate "provider" {
  path      = "provider.tf"          # Generated file name
  if_exists = "overwrite_terragrunt" # Always overwrite to ensure latest config
  contents  = <<EOF
terraform {
  required_version = ">= 1.10.0"            
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"                    
    }
  }
}

provider "aws" {
  region = var.aws_region                   
  
  default_tags {
    tags = {
      Source    = "https://github.com/sonalsinghai/challenge-operations"
      ManagedBy = "Terragrunt"
      Project   = "Infrastructure"
    }
  }
}
EOF
}

# S3 Backend Configuration
# State files stored in S3 with DynamoDB locking to prevent concurrent modifications
remote_state {
  backend = "s3"

  config = {
    bucket         = local.state_bucket_name                                    # Centralized bucket name
    key            = "${path_relative_to_include()}/terraform.tfstate"          # Unique path per module
    region         = get_env("AWS_REGION", "eu-west-2")                         # S3 bucket region
    encrypt        = true                                                       # Server-side encryption
    dynamodb_table = "${local.env}-terraform-locks"                             # Per-env lock table
  }

  # Auto-generate backend.tf in each module directory
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Local Variables - Auto-extracted from Directory Path
locals {
  terragrunt_dir = get_terragrunt_dir() # Current directory path

  # State bucket configuration - centralized
  state_bucket_name = get_env("TF_STATE_BUCKET", "challenge-operations-terragrunt-state-bucket")

  # Extract environment name from path (dev/staging/prod)
  env_match = regex(".*/live/([^/]+)/", local.terragrunt_dir)
  env       = try(local.env_match[0], "unknown")

  # Extract AWS region from path
  region_match = regex(".*/live/[^/]+/([^/]+)/", local.terragrunt_dir)
  region       = try(local.region_match[0], "eu-west-2")

  # Extract application name (last directory in path)
  app_name = basename(local.terragrunt_dir)

  # Tags applied to all resources via provider default_tags
  common_tags = {
    Environment = local.env
    ManagedBy   = "Terragrunt"
    Project     = "Infrastructure"
  }
}

terraform {
  # Pre-command Validation Hooks
  # These run before Terraform commands to catch configuration errors early

  # Hook 1: Validate environment matches directory path
  # Prevents accidentally running commands in wrong environment
  before_hook "validate_environment" {
    commands     = ["init", "plan", "apply", "destroy"]
    execute      = ["bash", "${get_parent_terragrunt_dir()}/ci/ensure-env.sh", get_terragrunt_dir()]
    run_on_error = false # Stop if validation fails
  }

  # Hook 2: Validate S3 backend and DynamoDB table exist
  # Ensures backend infrastructure is ready before operations
  # Set SKIP_BACKEND_CHECK=true env var to skip (useful for validation)
  before_hook "validate_backend" {
    commands     = ["init", "plan", "apply"]
    execute      = ["bash", "${get_parent_terragrunt_dir()}/ci/check-backend.sh", get_terragrunt_dir()]
    run_on_error = false
  }
}

# Common Inputs - Automatically passed to all Terraform modules
# These values are auto-extracted from the directory path (see locals above)
inputs = {
  env        = local.env      # Environment: dev/staging/prod
  aws_region = local.region   # AWS region from path
  app_name   = local.app_name # Application name from directory

  tags = local.common_tags # Common resource tags
}

