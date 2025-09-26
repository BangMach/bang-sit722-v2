# Infrastructure as Code (Terraform/OpenTofu)

This directory contains Terraform/OpenTofu configuration for deploying Azure infrastructure required for the bang-sit722 microservices application.

## Resources Created

- **Resource Group**: Container for all resources
- **Azure Container Registry (ACR)**: For storing Docker images
- **Azure Kubernetes Service (AKS)**: For orchestrating containers
- **Log Analytics Workspace**: For monitoring and logging
- **Application Insights**: For application performance monitoring

## Prerequisites

1. **Azure CLI** installed and configured
2. **Terraform** or **OpenTofu** installed (>= 1.6)
3. **Azure Service Principal** with appropriate permissions

## Authentication

You can authenticate using:
1. Azure CLI: `az login`
2. Service Principal (for CI/CD):
   ```bash
   export ARM_CLIENT_ID="<service-principal-id>"
   export ARM_CLIENT_SECRET="<service-principal-secret>"
   export ARM_SUBSCRIPTION_ID="<subscription-id>"
   export ARM_TENANT_ID="<tenant-id>"
   ```

## Usage

### Initialize Terraform
```bash
terraform init
```

### Plan Deployment
For staging:
```bash
terraform plan -var-file="staging.tfvars"
```

For production:
```bash
terraform plan -var-file="production.tfvars"
```

### Apply Configuration
For staging:
```bash
terraform apply -var-file="staging.tfvars"
```

For production:
```bash
terraform apply -var-file="production.tfvars"
```

### Destroy Resources
```bash
terraform destroy -var-file="staging.tfvars"
```

## Environment Configuration

- **staging.tfvars**: Configuration for staging environment
- **production.tfvars**: Configuration for production environment

## Output Values

After deployment, the following outputs are available:
- `resource_group_name`: Name of the created resource group
- `acr_login_server`: ACR login server URL
- `aks_cluster_name`: Name of the AKS cluster
- `application_insights_connection_string`: For application monitoring

## CI/CD Integration

This configuration is designed to work with:
1. **Jenkins pipelines** for automated deployment
2. **GitHub Actions** for triggering Jenkins jobs
3. **Azure DevOps** (alternative option)

## Security Considerations

- ACR admin credentials are enabled for CI/CD simplicity
- Consider using managed identities in production
- Sensitive outputs are marked as sensitive
- Use Azure Key Vault for storing secrets in production

## Customization

To customize resource names, modify the variables in the `.tfvars` files or set them via environment variables:
```bash
export TF_VAR_project_name="my-project"
export TF_VAR_environment="staging"
```

## State Management

For production use, configure remote state storage:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "terraformstatestorage"
    container_name       = "tfstate"
    key                  = "bang-sit722.terraform.tfstate"
  }
}
```