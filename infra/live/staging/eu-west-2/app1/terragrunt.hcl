# Staging Environment - Base Configuration
# This is the entry point for staging/eu-west-2/app1
# Contains common/shared resources for this app in staging

# Include root configuration (provider, backend, hooks, common inputs)
include "root" {
  path = find_in_parent_folders("root.hcl") # Searches up the tree for root.hcl
  expose = true  # Expose root locals to this file
}

# Define locals to access included root values
locals {
  # Access root.hcl locals through include.root.locals
  env        = include.root.locals.env
  aws_region = include.root.locals.region
  app_name   = include.root.locals.app_name
}

# Module source - points to the "common" module
# Double slash (//) tells Terragrunt this is a Terraform module reference
terraform {
  source = "${get_parent_terragrunt_dir()}/modules//common"
}

# Module-specific inputs (override or supplement root inputs)
inputs = {
  env        = local.env   # Environment identifier
  aws_region = local.aws_region # London region
  app_name   = local.app_name      # Application identifier

  # Additional tags for cost tracking and ownership
  tags = {
    Environment = local.env
    CostCenter  = "engineering"
    Team        = "platform"
  }
}

