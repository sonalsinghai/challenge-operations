# Staging Environment - Base Configuration
# This is the entry point for staging/eu-west-2/app1
# Contains common/shared resources for this app in staging

# Include root configuration (provider, backend, hooks, common inputs)
include "root" {
  path = find_in_parent_folders("root.hcl") # Searches up the tree for root.hcl
}

# Module source - points to the "common" module
# Double slash (//) tells Terragrunt this is a Terraform module reference
terraform {
  source = "${get_parent_terragrunt_dir()}/modules//common"
}

# Module-specific inputs (override or supplement root inputs)
inputs = {
  env        = "staging"   # Environment identifier
  aws_region = "eu-west-2" # London region
  app_name   = "app1"      # Application identifier

  # Additional tags for cost tracking and ownership
  tags = {
    Environment = "staging"
    CostCenter  = "engineering"
    Team        = "platform"
  }
}

