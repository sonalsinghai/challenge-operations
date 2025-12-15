# Development VPC Configuration
# Creates VPC, subnets, NAT gateways, and networking resources
# CIDR: 10.1.0.0/16 (65,536 IPs)

# Include root configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true  # Expose root locals to this file
}

# Define locals to access included root values
locals {
  # Access root.hcl locals through include.root.locals
  env        = include.root.locals.env
  aws_region = include.root.locals.region
  app_name   = include.root.locals.app_name
}

# Module source - VPC module
terraform {
  source = "${get_parent_terragrunt_dir()}/modules//vpc"
}

# VPC-specific inputs
inputs = {
  env        = "dev"
  aws_region = "eu-west-2"
  app_name   = "app1"
  vpc_cidr   = "10.1.0.0/16" # Development VPC CIDR block

  tags = {
    Environment = "dev"
    CostCenter  = "engineering"
    Team        = "platform"
  }
}

