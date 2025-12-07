# Bootstrap Module
# Creates the foundational AWS resources needed for Terragrunt:
# - S3 bucket for Terraform state
# - DynamoDB tables for state locking (one per environment)
# - IAM roles for GitHub OIDC (one per environment)

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
      ManagedBy = "Terraform"
      Project   = "Infrastructure"
    }
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Data source for current region
data "aws_region" "current" {}

# S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "sonal-${var.state_bucket_name}"

  tags = merge(
    var.tags,
    {
      Name        = "Terraform State Bucket"
      Description = "Stores Terraform state files for all environments"
    }
  )
}

# Enable versioning on state bucket
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle configuration to prevent accidental deletion
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "prevent-deletion"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# DynamoDB tables for state locking (one per environment)
resource "aws_dynamodb_table" "terraform_locks" {
  for_each = toset(var.environments)

  name         = "${each.value}-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(
    var.tags,
    {
      Name        = "${each.value} Terraform Locks"
      Environment = each.value
    }
  )
}

# GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = var.tags
}

# IAM roles for each environment with OIDC trust
resource "aws_iam_role" "terragrunt_env_role" {
  for_each = toset(var.environments)

  name = "terragrunt-${each.value}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = local.oidc_conditions[each.value]
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "Terragrunt ${each.value} Role"
      Environment = each.value
    }
  )
}

# OIDC conditions for each environment
locals {
  github_repo = var.github_repo # Format: owner/repo-name

  oidc_conditions = {
    dev = [
      "repo:${local.github_repo}:*" # Dev allows all branches
    ]
    staging = [
      "repo:${local.github_repo}:ref:refs/heads/develop",
      "repo:${local.github_repo}:ref:refs/heads/feature/*",
      "repo:${local.github_repo}:ref:refs/heads/staging/*"
    ]
    prod = [
      "repo:${local.github_repo}:ref:refs/heads/main",
      "repo:${local.github_repo}:ref:refs/heads/release/*",
      "repo:${local.github_repo}:ref:refs/heads/hotfix/*"
    ]
  }
}

# IAM policies for each environment role
resource "aws_iam_role_policy" "terragrunt_env_policy" {
  for_each = toset(var.environments)

  name = "terragrunt-${each.value}-policy"
  role = aws_iam_role.terragrunt_env_role[each.value].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/live/${each.value}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = [
          aws_dynamodb_table.terraform_locks[each.value].arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}

# Additional policy for Terraform operations (can be extended)
resource "aws_iam_role_policy" "terragrunt_env_terraform_policy" {
  for_each = toset(var.environments)

  name = "terragrunt-${each.value}-terraform-policy"
  role = aws_iam_role.terragrunt_env_role[each.value].id

  # This is a base policy - extend with specific permissions as needed
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "eks:*",
          "iam:*",
          "vpc:*",
          "logs:*",
          "cloudwatch:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      }
    ]
  })
}
