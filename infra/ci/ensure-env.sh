#!/bin/bash
# Environment validation script
# Ensures that the environment being targeted matches the folder structure
# and prevents cross-environment state corruption

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the terragrunt directory from argument
TERRAGRUNT_DIR="${1:-$(pwd)}"

# Extract environment from path
# Expected format: .../live/<env>/<region>/<app>
if [[ ! "$TERRAGRUNT_DIR" =~ live/([^/]+)/ ]]; then
  echo -e "${RED}ERROR: Invalid path structure. Expected: .../live/<env>/<region>/<app>${NC}"
  echo "Current path: $TERRAGRUNT_DIR"
  exit 1
fi

FOLDER_ENV="${BASH_REMATCH[1]}"

# Validate environment name
if [[ ! "$FOLDER_ENV" =~ ^(dev|staging|prod)$ ]]; then
  echo -e "${RED}ERROR: Invalid environment name: $FOLDER_ENV${NC}"
  echo "Valid environments: dev, staging, prod"
  exit 1
fi

echo -e "${GREEN}✓ Environment from folder: $FOLDER_ENV${NC}"

# Check TF_VAR_env if set
if [ -n "${TF_VAR_env:-}" ]; then
  if [ "$TF_VAR_env" != "$FOLDER_ENV" ]; then
    echo -e "${RED}ERROR: Environment mismatch!${NC}"
    echo "  Folder environment: $FOLDER_ENV"
    echo "  TF_VAR_env: $TF_VAR_env"
    echo ""
    echo "Please unset TF_VAR_env or set it to match the folder environment."
    exit 1
  fi
  echo -e "${GREEN}✓ TF_VAR_env matches folder environment${NC}"
fi

# Validate AWS_ROLE_ARN if set (OIDC scenario)
if [ -n "${AWS_ROLE_ARN:-}" ]; then
  if [[ ! "$AWS_ROLE_ARN" =~ /terragrunt-${FOLDER_ENV}-role$ ]]; then
    echo -e "${RED}ERROR: AWS_ROLE_ARN does not match environment!${NC}"
    echo "  Folder environment: $FOLDER_ENV"
    echo "  AWS_ROLE_ARN: $AWS_ROLE_ARN"
    echo "  Expected role suffix: terragrunt-${FOLDER_ENV}-role"
    exit 1
  fi
  echo -e "${GREEN}✓ AWS_ROLE_ARN matches environment${NC}"
fi

# GitHub Actions specific validations
if [ -n "${GITHUB_ACTIONS:-}" ]; then
  GITHUB_REF="${GITHUB_REF:-}"
  GITHUB_BASE_REF="${GITHUB_BASE_REF:-}"
  
  # For prod environment, enforce branch restrictions
  if [ "$FOLDER_ENV" == "prod" ]; then
    # Check if we're on main, release/*, or hotfix/* branch
    if [[ ! "$GITHUB_REF" =~ ^refs/heads/(main|release/|hotfix/) ]] && \
       [[ ! "$GITHUB_BASE_REF" =~ ^(main|release/|hotfix/) ]]; then
      echo -e "${RED}ERROR: Production changes are only allowed from main, release/*, or hotfix/* branches${NC}"
      echo "  Current branch/ref: $GITHUB_REF"
      echo "  Base ref: $GITHUB_BASE_REF"
      exit 1
    fi
    echo -e "${GREEN}✓ Production branch validation passed${NC}"
  fi
  
  # For staging, prefer develop branch
  if [ "$FOLDER_ENV" == "staging" ]; then
    if [[ ! "$GITHUB_REF" =~ ^refs/heads/(develop|feature/|staging/) ]] && \
       [[ ! "$GITHUB_BASE_REF" =~ ^(develop|feature/|staging/) ]]; then
      echo -e "${YELLOW}WARNING: Staging changes should typically come from develop or feature branches${NC}"
      echo "  Current branch/ref: $GITHUB_REF"
    fi
  fi
fi

# Validate AWS credentials are set
if [ -z "${AWS_REGION:-}" ] && [ -z "${AWS_DEFAULT_REGION:-}" ]; then
  echo -e "${YELLOW}WARNING: AWS_REGION not set${NC}"
fi

echo -e "${GREEN}✓ Environment validation passed for: $FOLDER_ENV${NC}"
exit 0

