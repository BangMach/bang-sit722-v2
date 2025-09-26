# Jenkins Pipeline Configuration

This directory contains Jenkins pipeline configurations to replace GitHub Actions with Jenkins-based CI/CD pipelines while maintaining integration with GitHub for triggering.

## Pipeline Structure

### 1. CI Pipeline (`Jenkinsfile.ci`)
- **Trigger**: Pushes to `testing` branch
- **Purpose**: Run tests, build Docker images, deploy infrastructure, push to ACR
- **Stages**:
  - Checkout code
  - Setup infrastructure (Terraform)
  - Install dependencies
  - Run parallel tests (Product, Order, Customer services)
  - Deploy infrastructure if tests pass
  - Build and push Docker images

### 2. CD Staging Pipeline (`Jenkinsfile.cd-staging`)
- **Trigger**: After successful CI pipeline or manual trigger
- **Purpose**: Deploy to staging environment, run tests, cleanup
- **Stages**:
  - Setup environment
  - Deploy infrastructure and services
  - Health checks
  - Manual testing window (2 minutes)
  - Automatic cleanup

### 3. CD Production Pipeline (`Jenkinsfile.cd-production`)
- **Trigger**: Pull request merge to `main` branch or manual trigger
- **Purpose**: Deploy to production with rollback capabilities
- **Stages**:
  - Pre-deployment validation
  - Infrastructure setup
  - Backup current state
  - Deploy with rolling or blue-green strategy
  - Health checks with automatic rollback on failure
  - Post-deployment monitoring

## Jenkins Setup

### Prerequisites

1. **Jenkins Server** with the following plugins:
   - Pipeline
   - Blue Ocean (optional, for better UI)
   - Azure CLI
   - Docker Pipeline
   - Kubernetes CLI
   - Email Extension
   - Credentials Binding

2. **Required Tools on Jenkins Server**:
   - Docker
   - Azure CLI
   - kubectl
   - Terraform/OpenTofu
   - Python 3.10+
   - Git

### Jenkins Job Configuration

#### 1. Create CI Pipeline Job

```bash
# Job Name: bang-sit722-ci
# Type: Pipeline
# Pipeline Definition: Pipeline script from SCM
# SCM: Git
# Repository URL: https://github.com/BangMach/bang-sit722-v2.git
# Script Path: jenkins/Jenkinsfile.ci
# Branches: testing
```

#### 2. Create CD Staging Pipeline Job

```bash
# Job Name: bang-sit722-cd-staging
# Type: Pipeline
# Pipeline Definition: Pipeline script from SCM
# SCM: Git
# Repository URL: https://github.com/BangMach/bang-sit722-v2.git
# Script Path: jenkins/Jenkinsfile.cd-staging
# Build Triggers: Build after other projects are built (bang-sit722-ci)
```

#### 3. Create CD Production Pipeline Job

```bash
# Job Name: bang-sit722-cd-production
# Type: Pipeline
# Pipeline Definition: Pipeline script from SCM
# SCM: Git
# Repository URL: https://github.com/BangMach/bang-sit722-v2.git
# Script Path: jenkins/Jenkinsfile.cd-production
# Branches: main
```

### Required Jenkins Credentials

Configure the following credentials in Jenkins (Manage Jenkins → Manage Credentials):

#### 1. Azure Service Principal (`azure-service-principal`)
```
Type: Azure Service Principal
ID: azure-service-principal
Description: Azure Service Principal for infrastructure deployment
Subscription ID: <your-subscription-id>
Client ID: <service-principal-client-id>
Client Secret: <service-principal-client-secret>
Tenant ID: <your-tenant-id>
```

#### 2. ACR Credentials
```
Type: Secret text
ID: acr-login-server
Secret: <acr-name>.azurecr.io

Type: Secret text
ID: azure-container-registry
Secret: <acr-name>
```

#### 3. Environment-specific Credentials
```
Type: Secret text
ID: staging-resource-group
Secret: <staging-resource-group-name>

Type: Secret text
ID: staging-aks-cluster
Secret: <staging-aks-cluster-name>

Type: Secret text
ID: production-resource-group
Secret: <production-resource-group-name>

Type: Secret text
ID: production-aks-cluster
Secret: <production-aks-cluster-name>
```

### GitHub Integration Setup

#### 1. GitHub Secrets Configuration

Add the following secrets to your GitHub repository:

```
JENKINS_URL: https://your-jenkins-server.com
JENKINS_API_TOKEN: <jenkins-api-token>
```

#### 2. Create Jenkins API Token

1. Go to Jenkins → User → Configure
2. Add new API Token
3. Copy the token and add it to GitHub secrets

#### 3. Configure Webhooks (Optional)

For real-time triggering, configure GitHub webhooks:

1. Go to GitHub repository → Settings → Webhooks
2. Add webhook: `https://your-jenkins-server.com/github-webhook/`
3. Content type: `application/json`
4. Events: `Push`, `Pull requests`

## Usage

### Automatic Triggers

1. **CI Pipeline**: Automatically triggered on push to `testing` branch
2. **CD Staging**: Automatically triggered after successful CI pipeline
3. **CD Production**: Automatically triggered on PR merge to `main` branch

### Manual Triggers

#### Via GitHub Actions
Use the workflow dispatch feature in the GitHub Actions tab:
1. Go to Actions → Jenkins Integration Pipeline
2. Click "Run workflow"
3. Select pipeline type, image tag, etc.

#### Via Jenkins Interface
1. Go to Jenkins job
2. Click "Build with Parameters"
3. Fill in required parameters

### Parameter Options

#### CI Pipeline
- `BRANCH_NAME`: Branch to build
- `COMMIT_SHA`: Specific commit to build
- `GITHUB_RUN_ID`: GitHub Actions run ID (for tracking)

#### CD Staging Pipeline
- `DEPLOY_ACTION`: `deploy` or `destroy`
- `CI_BUILD_NUMBER`: Specific CI build to deploy

#### CD Production Pipeline
- `IMAGE_TAG`: Docker image tag to deploy
- `ROLLBACK`: Boolean flag for rollback
- `DEPLOYMENT_STRATEGY`: `rolling` or `blue-green`

## Monitoring and Troubleshooting

### Build Monitoring

1. **Jenkins Blue Ocean**: Better visual interface for pipeline monitoring
2. **Build History**: Check build history for trends
3. **Console Output**: Detailed logs for troubleshooting

### Common Issues

#### 1. Terraform State Lock
```bash
# If terraform state is locked, manually unlock:
terraform force-unlock <lock-id>
```

#### 2. Docker Registry Login Issues
```bash
# Check ACR credentials and login manually:
az acr login --name <acr-name>
```

#### 3. Kubernetes Connection Issues
```bash
# Verify kubectl context:
kubectl config current-context
kubectl get nodes
```

### Health Checks

Each pipeline includes health checks:
- Service availability checks
- Database connectivity tests
- Load balancer readiness checks

### Rollback Procedures

#### Automatic Rollback
- Triggered on health check failures
- Uses previous deployment backup
- Falls back to Kubernetes rollout undo

#### Manual Rollback
```bash
# Trigger production rollback:
curl -X POST \
  -H "Authorization: Bearer <jenkins-api-token>" \
  -d '{"parameter": [{"name": "ROLLBACK", "value": true}]}' \
  "<jenkins-url>/job/bang-sit722-cd-production/buildWithParameters"
```

## Security Considerations

1. **Credential Management**: Use Jenkins credential store, not hardcoded values
2. **Network Security**: Secure Jenkins server with HTTPS and firewall rules
3. **Access Control**: Configure role-based access control in Jenkins
4. **Secret Scanning**: Ensure no secrets are committed to code
5. **Container Security**: Scan Docker images for vulnerabilities

## Migration from GitHub Actions

### Benefits of Jenkins Integration

1. **Centralized CI/CD**: Single Jenkins instance for multiple projects
2. **Advanced Pipeline Features**: More complex pipeline logic and conditions
3. **Resource Management**: Better control over build resources
4. **Plugin Ecosystem**: Extensive plugin support
5. **Enterprise Features**: Better suited for enterprise environments

### GitHub Actions Integration

The new setup maintains GitHub integration while using Jenkins for execution:
- GitHub triggers Jenkins pipelines
- Jenkins handles the actual CI/CD work
- Results reported back to GitHub
- Maintains GitHub security and access control

This hybrid approach provides the best of both worlds: GitHub's integration capabilities with Jenkins' advanced pipeline features.