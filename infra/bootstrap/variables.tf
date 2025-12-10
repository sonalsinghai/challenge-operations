variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-2"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "challenge-operations-terragrunt-state-bucket"
}

variable "environments" {
  description = "List of environments to create resources for"
  type        = list(string)
  default     = ["dev", "staging", "prod"]

  validation {
    condition     = length(var.environments) > 0
    error_message = "At least one environment must be specified"
  }
}

variable "github_repo" {
  description = "GitHub repository in format owner/repo-name (e.g., myorg/my-repo)"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "Infrastructure"
  }
}
