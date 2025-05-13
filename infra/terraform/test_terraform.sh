#!/bin/bash
# Test: walidacja i planowanie Terraform
set -e

cd "$(dirname "$0")"
echo "== Terraform validate =="
terraform init -backend=false
terraform validate

echo "== Terraform plan =="
terraform plan -out=tfplan
