# Production EKS Cluster Configuration
# Creates Kubernetes cluster with managed node groups
# Depends on VPC module for networking

# Include root configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Dependency: EKS requires VPC to be created first
# Terragrunt will ensure VPC is deployed before EKS
dependency "vpc" {
  config_path = "../vpc" # Relative path to VPC module

  # Mock outputs used during 'terragrunt validate' and 'terragrunt plan'
  # Allows planning before VPC exists
  mock_outputs = {
    vpc_id             = "vpc-mock"
    private_subnet_ids = ["subnet-mock1", "subnet-mock2"]
  }

  # Only use mocks for these commands (actual values required for apply)
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# Module source - EKS module
terraform {
  source = "${get_parent_terragrunt_dir()}/modules//eks"
}

# EKS-specific inputs
inputs = {
  env        = "prod"
  aws_region = "eu-west-2"
  app_name   = "app1"

  # VPC configuration from dependency
  vpc_id     = dependency.vpc.outputs.vpc_id             # VPC where cluster runs
  subnet_ids = dependency.vpc.outputs.private_subnet_ids # Private subnets for nodes

  # EKS cluster sizing
  cluster_version           = "1.34"       # Kubernetes version
  node_group_instance_types = ["t3.large"] # 2 vCPU, 8GB RAM
  node_group_desired_size   = 3            # Normal capacity
  node_group_min_size       = 2            # Minimum for HA
  node_group_max_size       = 6            # Max for auto-scaling

  tags = {
    Environment = "prod"
    CostCenter  = "engineering"
    Team        = "platform"
  }
}

