# Deployment Scripts

This directory contains helper scripts for setting up and managing the bang-sit722-v2 DevOps pipeline.

## Scripts Overview

### 1. `setup-jenkins.sh`
**Purpose**: Automated Jenkins server setup with all required tools and dependencies.

**What it does**:
- Installs Java 11 (required for Jenkins)
- Installs and configures Jenkins
- Installs Docker and adds jenkins user to docker group
- Installs Azure CLI
- Installs kubectl for Kubernetes management
- Installs Terraform for infrastructure as code
- Installs Python 3.10 and pip
- Creates sample Jenkins job configurations
- Provides next steps for manual configuration

**Usage**:
```bash
chmod +x scripts/setup-jenkins.sh
./scripts/setup-jenkins.sh
```

**Requirements**:
- Ubuntu/Debian-based system
- User with sudo privileges
- Internet connection

### 2. `azure-setup.sh`
**Purpose**: Automated Azure resource setup and Service Principal creation.

**What it does**:
- Creates Azure Service Principal with appropriate permissions
- Creates resource groups for staging and production
- Optionally creates storage account for Terraform remote state
- Generates all required credentials and configuration
- Provides detailed setup instructions for Jenkins and GitHub

**Usage**:
```bash
chmod +x scripts/azure-setup.sh
./scripts/azure-setup.sh
```

**Prerequisites**:
- Azure CLI installed and logged in (`az login`)
- Appropriate Azure subscription permissions
- `jq` installed for JSON parsing

### 3. `validate-deployment.sh`
**Purpose**: Comprehensive deployment validation and health checking.

**What it does**:
- Validates Kubernetes deployments and pod status
- Checks LoadBalancer service IPs
- Performs health checks on all microservices
- Validates resource usage and metrics
- Provides troubleshooting information
- Reports overall deployment status

**Usage**:
```bash
chmod +x scripts/validate-deployment.sh
./scripts/validate-deployment.sh
```

**Prerequisites**:
- kubectl configured with access to the target cluster
- curl installed
- Target applications deployed with health endpoints

## Setup Workflow

### Complete Setup Process

1. **Initial System Setup**:
   ```bash
   # Install required packages
   sudo apt update
   sudo apt install -y curl jq git
   
   # Clone the repository
   git clone https://github.com/BangMach/bang-sit722-v2.git
   cd bang-sit722-v2
   ```

2. **Azure Setup**:
   ```bash
   # Login to Azure
   az login
   
   # Run Azure setup
   chmod +x scripts/azure-setup.sh
   ./scripts/azure-setup.sh
   ```

3. **Jenkins Setup**:
   ```bash
   # Run Jenkins setup
   chmod +x scripts/setup-jenkins.sh
   ./scripts/setup-jenkins.sh
   ```

4. **Configure Jenkins**:
   - Open http://localhost:8080
   - Use initial admin password from setup script
   - Install suggested plugins plus required additional plugins
   - Add credentials from azure-setup.sh output
   - Import Jenkins jobs from jenkins/ directory

5. **Test Infrastructure**:
   ```bash
   # Test Terraform configuration
   cd infrastructure
   terraform init
   terraform plan -var-file=staging.tfvars
   ```

6. **Validate Deployment**:
   ```bash
   # After deploying via Jenkins pipeline
   chmod +x scripts/validate-deployment.sh
   ./scripts/validate-deployment.sh
   ```

## Configuration Files Generated

### `azure-config.txt`
Contains sensitive Azure configuration information:
- Service Principal credentials
- Resource group names
- Storage account details (if created)

**⚠️ Security Note**: This file contains sensitive information. Do not commit to version control.

### Jenkins Job Configurations
Sample XML configurations for importing into Jenkins:
- `~/jenkins-jobs/bang-sit722-ci-job.xml`

## Common Issues and Solutions

### Azure Setup Issues

**Issue**: Service Principal already exists
```bash
# Solution: Reset credentials
az ad sp credential reset --name sp-bang-sit722-devops
```

**Issue**: Insufficient permissions
```bash
# Solution: Check Azure subscription role
az role assignment list --assignee $(az account show --query user.name -o tsv)
```

### Jenkins Setup Issues

**Issue**: Jenkins won't start
```bash
# Check Jenkins status
sudo systemctl status jenkins

# Check Jenkins logs
sudo journalctl -u jenkins -f
```

**Issue**: Docker permission denied
```bash
# Ensure jenkins user is in docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Deployment Validation Issues

**Issue**: kubectl connection failed
```bash
# Check kubectl configuration
kubectl config current-context
kubectl config view

# Get cluster credentials (if using AKS)
az aks get-credentials --resource-group <rg-name> --name <cluster-name>
```

**Issue**: Services not accessible
```bash
# Check service status
kubectl get services
kubectl describe service <service-name>

# Check pod status
kubectl get pods
kubectl logs <pod-name>
```

## Environment Variables

The scripts use and generate various environment variables:

### For Terraform
```bash
export ARM_CLIENT_ID="<service-principal-client-id>"
export ARM_CLIENT_SECRET="<service-principal-client-secret>"
export ARM_SUBSCRIPTION_ID="<azure-subscription-id>"
export ARM_TENANT_ID="<azure-tenant-id>"
```

### For Jenkins
Set these as Jenkins credentials:
- `azure-service-principal`: Azure Service Principal
- `acr-login-server`: ACR login server URL
- `azure-container-registry`: ACR name
- `staging-resource-group`: Staging resource group name
- `production-resource-group`: Production resource group name

## Security Considerations

1. **Credential Management**:
   - Use Jenkins credential store, not hardcoded values
   - Rotate Service Principal credentials regularly
   - Use Azure managed identities where possible

2. **Network Security**:
   - Configure Jenkins with HTTPS in production
   - Use firewall rules to restrict access
   - Enable Azure Network Security Groups

3. **Access Control**:
   - Implement role-based access control in Jenkins
   - Use principle of least privilege for Azure permissions
   - Enable audit logging

## Monitoring and Maintenance

### Regular Tasks
- Update Jenkins plugins monthly
- Rotate Azure Service Principal credentials quarterly
- Review and update Terraform configurations
- Monitor resource usage and costs

### Health Monitoring
- Use the validation script in CI/CD pipelines
- Set up Azure Monitor alerts
- Configure Jenkins build notifications
- Implement log aggregation and monitoring

## Support and Troubleshooting

For additional help:
1. Check Jenkins logs: `/var/log/jenkins/jenkins.log`
2. Review Azure Activity Log in Azure Portal
3. Use `kubectl describe` and `kubectl logs` for Kubernetes issues
4. Consult the main project documentation in the repository root