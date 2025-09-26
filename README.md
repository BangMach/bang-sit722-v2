# bang-sit722-v2: DevOps Pipeline with Jenkins & Terraform

A comprehensive DevOps implementation for a microservices e-commerce application using Jenkins pipelines, Terraform infrastructure as code, and GitHub integration. This project demonstrates modern DevOps practices with Azure Kubernetes Service (AKS) and Azure Container Registry (ACR).

## 🏗️ Architecture Overview

```
GitHub Repository
    ↓ (Webhook/API Trigger)
Jenkins CI/CD Pipelines
    ↓ (Infrastructure as Code)
Terraform/OpenTofu
    ↓ (Provision Azure Resources)
Azure Cloud (ACR + AKS + Monitoring)
    ↓ (Container Orchestration)
Kubernetes Cluster
    ↓ (Microservices Deployment)
Production Application
```

## 🚀 Key Features

- **Hybrid CI/CD**: GitHub integration with Jenkins pipeline execution
- **Infrastructure as Code**: Complete Azure infrastructure managed by Terraform
- **Microservices Architecture**: Product, Order, Customer services with React frontend
- **Multiple Environments**: Staging (temporary) and Production (persistent) deployments
- **Advanced Deployment Strategies**: Rolling updates and blue-green deployments
- **Automated Testing**: Comprehensive test suites with parallel execution
- **Health Monitoring**: Automated health checks with rollback capabilities
- **Security First**: Azure RBAC, credential management, and vulnerability scanning

## 📋 Prerequisites

### Required Tools
- **Jenkins Server** with Docker support
- **Azure CLI** (2.30+)
- **Terraform/OpenTofu** (1.6+)
- **kubectl** (1.28+)
- **Docker** (20.10+)
- **Python** (3.10+)

### Azure Requirements
- Azure subscription with appropriate permissions
- Service Principal with Contributor role
- Resource quotas for AKS and ACR

## 🛠️ Quick Start

### 1. Repository Setup
```bash
git clone https://github.com/BangMach/bang-sit722-v2.git
cd bang-sit722-v2
```

### 2. Azure Infrastructure Setup
```bash
# Login to Azure
az login

# Run Azure setup script
chmod +x scripts/azure-setup.sh
./scripts/azure-setup.sh
```

### 3. Jenkins Server Setup
```bash
# Run Jenkins setup script
chmod +x scripts/setup-jenkins.sh
./scripts/setup-jenkins.sh
```

### 4. Configure Jenkins
1. Open Jenkins at `http://localhost:8080`
2. Use initial admin password from setup script
3. Install required plugins (see [Jenkins README](jenkins/README.md))
4. Add Azure credentials from azure-setup.sh output
5. Import pipeline jobs from `jenkins/` directory

### 5. Test Infrastructure Deployment
```bash
cd infrastructure
terraform init
terraform plan -var-file=staging.tfvars
terraform apply -var-file=staging.tfvars
```

### 6. Validate Deployment
```bash
chmod +x scripts/validate-deployment.sh
./scripts/validate-deployment.sh
```

## 📁 Project Structure

```
bang-sit722-v2/
├── .github/workflows/          # GitHub Actions for Jenkins integration
├── backend/                    # Microservices source code
│   ├── product_service/        # Product management service
│   ├── order_service/          # Order processing service
│   └── customer_service/       # Customer management service
├── frontend/                   # React frontend application
├── k8s/                       # Kubernetes manifests
├── infrastructure/            # Terraform configuration
│   ├── main.tf               # Main infrastructure definition
│   ├── variables.tf          # Variable definitions
│   ├── outputs.tf            # Output values
│   ├── staging.tfvars        # Staging environment config
│   └── production.tfvars     # Production environment config
├── jenkins/                   # Jenkins pipeline definitions
│   ├── Jenkinsfile.ci        # CI pipeline
│   ├── Jenkinsfile.cd-staging # CD staging pipeline
│   └── Jenkinsfile.cd-production # CD production pipeline
├── scripts/                   # Setup and utility scripts
│   ├── setup-jenkins.sh      # Jenkins installation script
│   ├── azure-setup.sh        # Azure resource setup script
│   └── validate-deployment.sh # Deployment validation script
└── planning.md               # Detailed project planning
```

## 🔄 CI/CD Pipeline Flow

### CI Pipeline (Testing Branch)
1. **Code Checkout**: Latest code from testing branch
2. **Infrastructure Setup**: Terraform plan and apply for staging
3. **Dependency Installation**: Python packages and tools
4. **Parallel Testing**: Product, Order, and Customer service tests
5. **Docker Build**: Multi-service container builds
6. **Image Push**: Tagged images to Azure Container Registry

### CD Staging Pipeline
1. **Environment Setup**: Configure staging environment
2. **Infrastructure Deployment**: Deploy databases and services
3. **Service Health Checks**: Validate all microservices
4. **Load Balancer Configuration**: Configure external access
5. **Frontend Deployment**: Deploy React frontend with service URLs
6. **Manual Testing Window**: 2-minute testing period
7. **Automatic Cleanup**: Destroy staging resources

### CD Production Pipeline
1. **Pre-deployment Validation**: Security and readiness checks
2. **State Backup**: Backup current production state
3. **Rolling Deployment**: Deploy with zero-downtime strategy
4. **Health Monitoring**: Continuous health validation
5. **Automatic Rollback**: Rollback on failure detection
6. **Post-deployment Monitoring**: Ongoing health tracking

## 🏢 Environments

### Staging Environment
- **Purpose**: Temporary testing and validation
- **Lifecycle**: Created per deployment, destroyed after testing
- **Resources**: Minimal configuration for cost efficiency
- **Access**: Internal testing only

### Production Environment
- **Purpose**: Live application serving real users
- **Lifecycle**: Persistent, managed through deployments
- **Resources**: High availability, scalable configuration
- **Access**: Public-facing with proper security

## 🔧 Configuration

### Environment Variables
#### For Terraform:
```bash
export ARM_CLIENT_ID="<service-principal-client-id>"
export ARM_CLIENT_SECRET="<service-principal-client-secret>"
export ARM_SUBSCRIPTION_ID="<azure-subscription-id>"
export ARM_TENANT_ID="<azure-tenant-id>"
```

#### For Jenkins:
Configure as Jenkins credentials:
- `azure-service-principal`: Azure authentication
- `acr-login-server`: Container registry URL
- `azure-container-registry`: Registry name
- Environment-specific resource names

### GitHub Secrets
```
JENKINS_URL: http://your-jenkins-server:8080
JENKINS_API_TOKEN: <jenkins-api-token>
```

## 🎯 Deployment Strategies

### Rolling Deployment
- **Zero Downtime**: Gradual replacement of old instances
- **Health Checks**: Continuous validation during deployment
- **Automatic Rollback**: On health check failure

### Blue-Green Deployment
- **Full Environment Switch**: Complete new environment deployment
- **Traffic Switching**: Instant traffic cutover
- **Easy Rollback**: Switch back to previous environment

## 📊 Monitoring & Observability

### Built-in Monitoring
- **Azure Application Insights**: Application performance monitoring
- **Azure Log Analytics**: Centralized logging
- **Kubernetes Health Checks**: Container and service health
- **Jenkins Build Monitoring**: Pipeline execution tracking

### Health Endpoints
All services expose health endpoints:
- Product Service: `http://<ip>:8000/health`
- Order Service: `http://<ip>:8001/health`
- Customer Service: `http://<ip>:8002/health`

## 🔐 Security Features

### Infrastructure Security
- **Azure RBAC**: Role-based access control
- **Service Principal Authentication**: Secure Azure access
- **Network Security Groups**: Traffic filtering
- **Private Container Registry**: Secure image storage

### Pipeline Security
- **Credential Management**: Jenkins credential store
- **Secrets Scanning**: No hardcoded secrets
- **Container Vulnerability Scanning**: Image security validation
- **Access Control**: Role-based pipeline permissions

### Application Security
- **HTTPS Communication**: Encrypted traffic
- **Database Security**: Connection encryption
- **Environment Isolation**: Separate staging/production

## 🚨 Troubleshooting

### Common Issues

#### Jenkins Connection Issues
```bash
# Check Jenkins status
sudo systemctl status jenkins

# Restart Jenkins
sudo systemctl restart jenkins
```

#### Azure Authentication Issues
```bash
# Verify Azure login
az account show

# Reset service principal credentials
az ad sp credential reset --name sp-bang-sit722-devops
```

#### Kubernetes Deployment Issues
```bash
# Check cluster connection
kubectl cluster-info

# View pod logs
kubectl logs <pod-name>

# Describe resources
kubectl describe pod <pod-name>
```

### Validation Commands
```bash
# Validate infrastructure
terraform validate

# Check pipeline syntax
jenkins-cli validate-pipeline < jenkins/Jenkinsfile.ci

# Test deployment health
./scripts/validate-deployment.sh
```

## 📈 Performance & Scaling

### Auto-scaling Configuration
- **Horizontal Pod Autoscaler**: CPU-based scaling
- **Cluster Autoscaler**: Node-based scaling
- **Load Balancer**: Traffic distribution

### Resource Optimization
- **Resource Requests/Limits**: Efficient resource usage
- **Image Optimization**: Multi-stage builds
- **Database Connection Pooling**: Efficient database access

## 🔄 Maintenance

### Regular Tasks
- **Update Dependencies**: Monthly package updates
- **Rotate Credentials**: Quarterly credential rotation
- **Review Costs**: Monthly Azure cost analysis
- **Security Updates**: Ongoing vulnerability patches

### Backup Procedures
- **Database Backups**: Automated daily backups
- **Configuration Backups**: Infrastructure state backups
- **Application State**: Deployment state preservation

## 📚 Documentation

- [Infrastructure Documentation](infrastructure/README.md)
- [Jenkins Pipeline Documentation](jenkins/README.md)
- [Setup Scripts Documentation](scripts/README.md)
- [Project Planning](planning.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test thoroughly
4. Submit a pull request

## 📄 License

This project is for educational purposes as part of the SIT722 DevOps course.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review the documentation in respective directories
3. Check Jenkins console logs for pipeline issues
4. Review Azure Activity Log for infrastructure issues

---

**Built with ❤️ for modern DevOps practices**
