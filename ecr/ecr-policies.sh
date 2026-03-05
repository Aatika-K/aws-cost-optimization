#!/bin/bash

# -------------------------------------------------------
# ECR Lifecycle Policy - Apply to All Repositories
# What it does:
#   - Deletes untagged images older than 7 days
#   - Keeps only the last 10 tagged images per repo
#   - Applies to ALL repositories in the specified region
# Usage:
#   chmod +x ecr-lifecycle.sh
#   ./ecr-lifecycle.sh
# -------------------------------------------------------

REGION="us-east-1"  # change: your AWS region

# Create the lifecycle policy JSON file
# Modify countNumber values below based on your needs
cat > lifecycle.json << 'EOF'
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Delete untagged images after 7 days",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 7
      },
      "action": { "type": "expire" }
    },
    {
      "rulePriority": 2,
      "description": "Keep only last 10 tagged images",
      "selection": {
        "tagStatus": "tagged",
        "tagPatternList": ["*"],
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": { "type": "expire" }
    }
  ]
}
EOF
# Note: countNumber 7  → change: days to keep untagged images
# Note: countNumber 10 → change: number of tagged images to keep per repo

echo "------------------------------------"
echo "Applying lifecycle policy to all ECR repositories in region: $REGION"
echo "------------------------------------"

# Loop through all ECR repositories in the region
# and apply the lifecycle policy to each one
for repo in $(aws ecr describe-repositories \
  --region $REGION \
  --query 'repositories[].repositoryName' \
  --output text); do

  echo "Applying lifecycle policy to: $repo"

  # Apply the lifecycle policy using the JSON file created above
  aws ecr put-lifecycle-policy \
    --region $REGION \
    --repository-name $repo \
    --lifecycle-policy-text file://lifecycle.json

done

echo "------------------------------------"
echo "Verifying lifecycle policies on all repositories..."
echo "------------------------------------"

# Loop through all repositories again
# and verify the policy was applied successfully
for repo in $(aws ecr describe-repositories \
  --region $REGION \
  --query 'repositories[].repositoryName' \
  --output text); do

  echo "Checking policy for: $repo"

  # Fetch and display the applied lifecycle policy for each repo
  aws ecr get-lifecycle-policy \
    --region $REGION \
    --repository-name $repo \
    --query 'lifecyclePolicyText' \
    --output text

done

# Cleanup the temporary lifecycle policy file
rm -f lifecycle.json

echo "------------------------------------"
echo "ECR Lifecycle policies applied successfully!"
echo "------------------------------------"
