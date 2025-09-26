#!/bin/bash

# Azure Setup Script for bang-sit722-v2 Project
# This script creates Azure Service Principal and required resources

set -e

echo "=========================================="
echo "Azure Setup for bang-sit722-v2 Project"
echo "=========================================="

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Azure CLI is not installed. Please install it first:"
    echo "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    exit 1
fi

# Check if user is logged in to Azure
if ! az account show &> /dev/null; then
    echo "Please log in to Azure CLI first:"
    echo "az login"
    exit 1
fi

# Get current subscription info
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "Current Azure Subscription:"
echo "  Name: $SUBSCRIPTION_NAME"
echo "  ID: $SUBSCRIPTION_ID"
echo "  Tenant ID: $TENANT_ID"
echo ""

read -p "Continue with this subscription? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please switch to the correct subscription using 'az account set --subscription <subscription-id>'"
    exit 1
fi

# Set variables
PROJECT_NAME="bang-sit722"
SP_NAME="sp-${PROJECT_NAME}-devops"
RESOURCE_GROUP_STAGING="${PROJECT_NAME}-staging-rg"
RESOURCE_GROUP_PRODUCTION="${PROJECT_NAME}-production-rg"
LOCATION="East US"

echo "Creating Azure resources with the following configuration:"
echo "  Project Name: $PROJECT_NAME"
echo "  Service Principal: $SP_NAME"
echo "  Staging Resource Group: $RESOURCE_GROUP_STAGING"
echo "  Production Resource Group: $RESOURCE_GROUP_PRODUCTION"
echo "  Location: $LOCATION"
echo ""

# Create Service Principal
echo "Creating Service Principal..."
SP_JSON=$(az ad sp create-for-rbac \
    --name "$SP_NAME" \
    --role Contributor \
    --scopes "/subscriptions/$SUBSCRIPTION_ID" \
    --sdk-auth)

if [ $? -eq 0 ]; then
    echo "Service Principal created successfully!"
    
    # Extract values from JSON
    CLIENT_ID=$(echo $SP_JSON | jq -r .clientId)
    CLIENT_SECRET=$(echo $SP_JSON | jq -r .clientSecret)
    
    echo ""
    echo "Service Principal Details:"
    echo "  Client ID: $CLIENT_ID"
    echo "  Client Secret: [HIDDEN]"
    echo "  Tenant ID: $TENANT_ID"
    echo "  Subscription ID: $SUBSCRIPTION_ID"
else
    echo "Failed to create Service Principal. It may already exist."
    echo "You can reset the credentials using:"
    echo "az ad sp credential reset --name $SP_NAME"
    exit 1
fi

# Create Resource Groups (optional, Terraform will create them)
echo ""
echo "Creating Resource Groups (will be managed by Terraform)..."

# Create staging resource group
if ! az group show --name "$RESOURCE_GROUP_STAGING" &> /dev/null; then
    az group create --name "$RESOURCE_GROUP_STAGING" --location "$LOCATION"
    echo "Created staging resource group: $RESOURCE_GROUP_STAGING"
else
    echo "Staging resource group already exists: $RESOURCE_GROUP_STAGING"
fi

# Create production resource group  
if ! az group show --name "$RESOURCE_GROUP_PRODUCTION" &> /dev/null; then
    az group create --name "$RESOURCE_GROUP_PRODUCTION" --location "$LOCATION"
    echo "Created production resource group: $RESOURCE_GROUP_PRODUCTION"
else
    echo "Production resource group already exists: $RESOURCE_GROUP_PRODUCTION"
fi

# Create storage account for Terraform state (optional)
STORAGE_ACCOUNT_NAME="${PROJECT_NAME//-/}tfstate$(date +%s | tail -c 6)"
echo ""
read -p "Create storage account for Terraform remote state? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    TERRAFORM_RG="${PROJECT_NAME}-terraform-rg"
    
    # Create resource group for Terraform state
    az group create --name "$TERRAFORM_RG" --location "$LOCATION"
    
    # Create storage account
    az storage account create \
        --resource-group "$TERRAFORM_RG" \
        --name "$STORAGE_ACCOUNT_NAME" \
        --sku Standard_LRS \
        --encryption-services blob
    
    # Create container
    az storage container create \
        --name tfstate \
        --account-name "$STORAGE_ACCOUNT_NAME"
    
    echo "Terraform state storage created:"
    echo "  Resource Group: $TERRAFORM_RG"
    echo "  Storage Account: $STORAGE_ACCOUNT_NAME"
    echo "  Container: tfstate"
fi

# Generate outputs for Jenkins and GitHub
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Add the following secrets to your Jenkins credentials:"
echo ""
echo "1. Azure Service Principal (ID: azure-service-principal):"
echo "   Subscription ID: $SUBSCRIPTION_ID"
echo "   Client ID: $CLIENT_ID"
echo "   Client Secret: [Use the value from above]"
echo "   Tenant ID: $TENANT_ID"
echo ""
echo "2. Additional Jenkins Credentials:"
echo "   - acr-login-server: [Will be created by Terraform]"
echo "   - azure-container-registry: [Will be created by Terraform]"
echo "   - staging-resource-group: $RESOURCE_GROUP_STAGING"
echo "   - production-resource-group: $RESOURCE_GROUP_PRODUCTION"
echo "   - staging-aks-cluster: ${PROJECT_NAME}-staging-aks"
echo "   - production-aks-cluster: ${PROJECT_NAME}-production-aks"
echo ""
echo "3. GitHub Secrets (for Jenkins integration):"
echo "   JENKINS_URL: http://your-jenkins-server:8080"
echo "   JENKINS_API_TOKEN: [Create this in Jenkins User Configuration]"
echo ""
echo "4. Environment Variables for Terraform:"
echo "   export ARM_CLIENT_ID=\"$CLIENT_ID\""
echo "   export ARM_CLIENT_SECRET=\"[CLIENT_SECRET]\""
echo "   export ARM_SUBSCRIPTION_ID=\"$SUBSCRIPTION_ID\""
echo "   export ARM_TENANT_ID=\"$TENANT_ID\""
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "5. Terraform Backend Configuration (add to main.tf):"
    echo "   terraform {"
    echo "     backend \"azurerm\" {"
    echo "       resource_group_name  = \"$TERRAFORM_RG\""
    echo "       storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
    echo "       container_name       = \"tfstate\""
    echo "       key                  = \"bang-sit722.terraform.tfstate\""
    echo "     }"
    echo "   }"
    echo ""
fi

echo "Next Steps:"
echo "1. Configure Jenkins with the credentials above"
echo "2. Test Terraform deployment: cd infrastructure && terraform init && terraform plan -var-file=staging.tfvars"
echo "3. Set up GitHub secrets for Jenkins integration"
echo "4. Import Jenkins jobs from the jenkins/ directory"
echo "5. Test the complete pipeline"
echo ""
echo "=========================================="

# Save configuration to file
cat > azure-config.txt << EOF
Azure Configuration for bang-sit722-v2
Generated on: $(date)

Service Principal: $SP_NAME
Client ID: $CLIENT_ID
Tenant ID: $TENANT_ID
Subscription ID: $SUBSCRIPTION_ID

Resource Groups:
- Staging: $RESOURCE_GROUP_STAGING
- Production: $RESOURCE_GROUP_PRODUCTION
EOF

if [[ $REPLY =~ ^[Yy]$ ]]; then
    cat >> azure-config.txt << EOF
- Terraform: $TERRAFORM_RG

Terraform State Storage:
- Storage Account: $STORAGE_ACCOUNT_NAME
- Container: tfstate
EOF
fi

echo "Configuration saved to: azure-config.txt"
echo "Keep this file secure and do not commit it to version control!"