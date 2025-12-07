output "state_bucket_name" {
  description = "Name of the S3 state bucket"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 state bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_tables" {
  description = "Map of DynamoDB table names for state locking"
  value = {
    for env, table in aws_dynamodb_table.terraform_locks : env => table.name
  }
}

output "iam_role_arns" {
  description = "Map of IAM role ARNs for each environment"
  value = {
    for env, role in aws_iam_role.terragrunt_env_role : env => role.arn
  }
}

output "iam_role_names" {
  description = "Map of IAM role names for each environment"
  value = {
    for env, role in aws_iam_role.terragrunt_env_role : env => role.name
  }
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

