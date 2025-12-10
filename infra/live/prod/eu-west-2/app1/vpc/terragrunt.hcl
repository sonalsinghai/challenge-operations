# Production VPC Configuration
# Creates VPC, subnets, NAT gateways, and networking resources
# CIDR: 10.3.0.0/16 (65,536 IPs)

# Include root configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Module source - VPC module
terraform {
  source = "${get_parent_terragrunt_dir()}/modules//vpc"
}

# VPC-specific inputs
inputs = {
  env        = "prod"
  aws_region = "eu-west-2"
  app_name   = "app1"
  vpc_cidr   = "10.3.0.0/16" # Production VPC CIDR block

  tags = {
    Environment = "prod"
    CostCenter  = "engineering"
    Team        = "platform"
  }
}

