#!/bin/bash
# Backend validation script
# Ensures the S3 backend and DynamoDB table exist before operations

set -euo pipefail

# Skip if SKIP_BACKEND_CHECK is set (for validate command)
if [ "${SKIP_BACKEND_CHECK:-false}" = "true" ]; then
  echo "Skipping backend validation (SKIP_BACKEND_CHECK=true)"
  exit 0
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the terragrunt directory from argument
TERRAGRUNT_DIR="${1:-$(pwd)}"

# Extract environment from path
if [[ ! "$TERRAGRUNT_DIR" =~ live/([^/]+)/ ]]; then
  echo -e "${RED}ERROR: Invalid path structure${NC}"
  exit 1
fi

ENV="${BASH_REMATCH[1]}"
STATE_BUCKET="${TF_STATE_BUCKET:-challenge-operations-terragrunt-state-bucket}"
DYNAMODB_TABLE="${ENV}-terraform-locks"
AWS_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-eu-west-2}}"

echo "Validating backend configuration..."
echo "  Environment: $ENV"
echo "  State bucket: $STATE_BUCKET"
echo "  DynamoDB table: $DYNAMODB_TABLE"
echo "  Region: $AWS_REGION"

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
  echo -e "${YELLOW}WARNING: AWS CLI not found. Skipping backend validation.${NC}"
  exit 0
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
  echo -e "${YELLOW}WARNING: AWS credentials not configured. Skipping backend validation.${NC}"
  exit 0
fi

# Check if S3 bucket exists
if ! aws s3api head-bucket --bucket "$STATE_BUCKET" --region "$AWS_REGION" 2>/dev/null; then
  echo -e "${RED}ERROR: S3 state bucket does not exist: $STATE_BUCKET${NC}"
  echo "Please run the bootstrap module first to create the bucket."
  exit 1
fi
echo -e "${GREEN}✓ S3 bucket exists: $STATE_BUCKET${NC}"

# Check if DynamoDB table exists
if ! aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION" &> /dev/null; then
  echo -e "${RED}ERROR: DynamoDB lock table does not exist: $DYNAMODB_TABLE${NC}"
  echo "Please run the bootstrap module first to create the table."
  exit 1
fi
echo -e "${GREEN}✓ DynamoDB table exists: $DYNAMODB_TABLE${NC}"

# Verify bucket versioning is enabled
VERSIONING=$(aws s3api get-bucket-versioning --bucket "$STATE_BUCKET" --region "$AWS_REGION" --query 'Status' --output text 2>/dev/null || echo "None")
if [ "$VERSIONING" != "Enabled" ]; then
  echo -e "${YELLOW}WARNING: S3 bucket versioning is not enabled${NC}"
fi

# Verify bucket encryption
ENCRYPTION=$(aws s3api get-bucket-encryption --bucket "$STATE_BUCKET" --region "$AWS_REGION" --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' --output text 2>/dev/null || echo "None")
if [ "$ENCRYPTION" == "None" ] || [ -z "$ENCRYPTION" ]; then
  echo -e "${YELLOW}WARNING: S3 bucket encryption may not be configured${NC}"
fi

echo -e "${GREEN}✓ Backend validation passed${NC}"
exit 0

