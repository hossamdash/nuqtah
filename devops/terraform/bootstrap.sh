#!/bin/sh
set -e

# Start k3s (lightweight Kubernetes)
sudo systemctl start k3s.service

# Start Kumo (lightweight AWS emulator, drop-in replacement for LocalStack)
# Data is persisted in a named volume so the S3 state bucket survives restarts
docker run -d \
  --name kumo \
  -p 4566:4566 \
  -v kumo-data:/data \
  -e KUMO_DATA_DIR=/data \
  ghcr.io/sivchari/kumo:latest

# Wait for Kumo to be ready
sleep 3

PROFILE="kumo"
ENDPOINT="http://localhost:4566"
REGION="eu-west-1"
BUCKET="nuqtah-terraform-state"

# Configure an AWS CLI profile pointing at Kumo
aws configure set profile.kumo.aws_access_key_id     test
aws configure set profile.kumo.aws_secret_access_key test
aws configure set profile.kumo.region                "$REGION"

# Create the S3 bucket for Terraform remote state
aws --profile "$PROFILE" --endpoint-url "$ENDPOINT" \
  s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

# Enable versioning so Terraform state history is kept
aws --profile "$PROFILE" --endpoint-url "$ENDPOINT" \
  s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

echo "✓ k3s started"
echo "✓ Kumo running on $ENDPOINT"
echo "✓ S3 state bucket '$BUCKET' created"
echo ""
echo "Next steps:"
echo "  cd devops/terraform/k8s"
echo "  terraform init"
echo "  terraform apply"
