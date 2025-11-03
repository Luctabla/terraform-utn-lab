# Terraform Backend Prerequisites

This directory contains the Terraform configuration to set up the infrastructure needed for remote state management.

## What This Creates

- **S3 Bucket**: Stores Terraform state files with versioning and encryption enabled
- **DynamoDB Table**: Manages state locking to prevent concurrent modifications

## Prerequisites

- AWS CLI configured with the appropriate profile (default: `zlab`)
- Terraform >= 1.0

## Setup Instructions

### 1. Configure Variables

Copy the example tfvars file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your desired values:
- `state_bucket_name`: Must be globally unique across all AWS accounts
- `aws_region`: AWS region where the backend resources will be created
- `dynamodb_table_name`: Name for the state lock table

### 2. Deploy the Backend Infrastructure

```bash
cd prerequisites
terraform init
terraform plan
terraform apply
```

### 3. Note the Outputs

After successful deployment, note the output values. You'll need these to configure the backend in your main Terraform project.

```bash
terraform output
```

## Using the Remote Backend

Once the prerequisites are deployed, update your main `main.tf` to use the remote backend:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-states-utn-demo"  # Use your bucket name
    key            = "project-name/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
    profile        = "zlab"
  }
}
```

Then migrate your existing state:

```bash
terraform init -migrate-state
```

## Important Notes

- The S3 bucket has versioning enabled for state file history
- The bucket is encrypted with AES256 by default
- Public access is completely blocked on the bucket
- The DynamoDB table uses PAY_PER_REQUEST billing mode
- This infrastructure should be deployed once and rarely modified
- Keep the state file for this prerequisites project local or in a separate location

## Security Features

- S3 bucket encryption at rest
- S3 bucket versioning for state history
- S3 public access blocked
- DynamoDB table for state locking to prevent concurrent modifications

## Cleanup

To destroy the backend infrastructure (only do this if you're sure no projects are using it):

```bash
terraform destroy
```

**Warning**: Make sure all projects using this backend have migrated their state elsewhere before destroying these resources.
