# Terraform Workspaces Guide

This project uses Terraform workspaces to manage multiple environments (dev, staging, prod) using the same codebase.

## What are Workspaces?

Workspaces allow you to manage multiple distinct sets of infrastructure resources using the same Terraform configuration. Each workspace has its own state file stored separately in S3.

## Workspace Naming Convention

Resources are automatically named using the workspace name:
- Lambda: `{project_name}-sqs-to-s3-{workspace}`
- S3 Bucket: `{project_name}-output-{workspace}`
- SQS Queue: `{project_name}-queue-{workspace}`
- IAM Role: `{project_name}-lambda-role-{workspace}`

### Examples:
- **dev workspace**: `terraform-lab-sqs-to-s3-dev`
- **staging workspace**: `terraform-lab-sqs-to-s3-staging`
- **prod workspace**: `terraform-lab-sqs-to-s3-prod`

## Setup

### 1. Deploy Prerequisites First

Before using workspaces, deploy the S3 backend and DynamoDB table:

```bash
cd prerequisites
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
cd ..
```

### 2. Configure Backend in Main Project

Add the backend configuration to your `main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-states-utn-demo"
    key            = "terraform-lab/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
    profile        = "zlab"
  }
}
```

### 3. Initialize Backend

```bash
terraform init -migrate-state
```

## Working with Workspaces

### List Available Workspaces

```bash
terraform workspace list
```

### Create a New Workspace

```bash
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
```

### Switch Between Workspaces

```bash
terraform workspace select dev
```

### Show Current Workspace

```bash
terraform workspace show
```

### Deploy to Specific Environment

```bash
# Switch to dev
terraform workspace select dev
terraform plan
terraform apply

# Switch to prod
terraform workspace select prod
terraform plan
terraform apply
```

## State Storage

Each workspace's state is stored separately in S3:
- Bucket: `terraform-states-utn-demo`
- Key pattern: `env:/{workspace}/terraform-lab/terraform.tfstate`

Examples:
- dev: `s3://terraform-states-utn-demo/env:/dev/terraform-lab/terraform.tfstate`
- prod: `s3://terraform-states-utn-demo/env:/prod/terraform-lab/terraform.tfstate`

## Best Practices

1. **Always verify your workspace** before running `terraform apply`:
   ```bash
   terraform workspace show
   ```

2. **Use meaningful workspace names**: dev, staging, prod (avoid ambiguous names)

3. **Don't delete the default workspace**: It's created automatically and used if no workspace is selected

4. **Review resources before applying**:
   ```bash
   terraform plan | grep "will be created"
   ```
   Verify that resource names include the correct workspace suffix

5. **State locking**: DynamoDB automatically prevents concurrent modifications across all workspaces

## Common Workflows

### Creating a New Environment

```bash
# Create and switch to new workspace
terraform workspace new staging

# Deploy infrastructure
terraform plan
terraform apply
```

### Updating an Existing Environment

```bash
# Switch to workspace
terraform workspace select prod

# Review changes
terraform plan

# Apply changes
terraform apply
```

### Destroying an Environment

```bash
# Switch to workspace
terraform workspace select dev

# Destroy all resources
terraform destroy

# Delete workspace (optional, only after destroy)
terraform workspace select default
terraform workspace delete dev
```

## Troubleshooting

### Wrong workspace selected

```bash
# Check current workspace
terraform workspace show

# Switch to correct one
terraform workspace select prod
```

### State locked

If someone else is running terraform or a previous run was interrupted:

```bash
# View locks in DynamoDB table
aws dynamodb scan --table-name terraform-state-locks --profile zlab

# Force unlock (only if you're sure no one else is running terraform)
terraform force-unlock <lock-id>
```

### Cannot find workspace

Make sure you've initialized the backend:

```bash
terraform init
```

## Variable Configuration

The following variables are workspace-independent (set in `terraform.tfvars`):
- `aws_region`: AWS region to deploy resources
- `project_name`: Base name for all resources

Workspace-specific naming is automatically handled via `terraform.workspace`.
