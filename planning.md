# DevOps Pipeline Implementation Plan for Task10_2D

## Overview
This plan outlines the implementation of a two-stage DevOps pipeline (Staging and Production) for the Task10_2D repository, a microservices e-commerce application deployed on Azure Kubernetes Service (AKS). The pipeline will use GitHub Actions for CI/CD, triggered by pushes to specific branches. Staging is temporary and destroyed after testing; Production is persistent. Incorporates Azure deployment best practices: use managed identities for secure access, infrastructure as code with Bicep/ARM, enable Azure Policy, and monitor with Azure Monitor.

## Implementation Phases

### Phase 1: Repository Setup and CI Pipeline (Stage 1)
- Create a new GitHub repository.
- Push the downloaded code to the remote repository.
- Create a GitHub Actions workflow for CI: Triggered on push to 'testing' branch.
- Workflow steps: Lint code, run unit tests for all services (product_service, order_service, customer_service), build Docker images, push to Azure Container Registry (ACR) if tests pass.

### Phase 2: Staging Deployment (Stage 2)
- Add a second job in the workflow: After image push to ACR, use Azure CLI to create temporary staging AKS resources (e.g., namespace, deployments).
- Have to get the image name from the ACR and deploying to AKS
- Deploy images to staging AKS.
- Perform manual or trivial acceptance tests (e.g., health checks via API calls).
- Destroy staging resources after testing.

### Phase 3: Production Deployment
- On pull request merge to 'main' branch, trigger a separate workflow.
- Deploy to existing production AKS environment using the latest images from ACR.
- Include rollback on failure (e.g., redeploy previous version).

## Technical Details

### Tools and Technologies
- **CI/CD Platform**: GitHub Actions (YAML workflows).
- **Containerization**: Docker (existing Dockerfiles).
- **Registry**: Azure Container Registry (ACR) for storing images.
- **Orchestration**: Azure Kubernetes Service (AKS) with existing Kubernetes manifests.
- **Infrastructure as Code**: Bicep templates for staging resources.
- **Secrets Management**: GitHub Secrets for Azure credentials (use managed identities where possible).
- **Monitoring**: Azure Application Insights for logs and metrics.
- **Security**: Azure Defender for containers, vulnerability scans in pipeline.

### Pipeline Structure
- **Workflow 1 (testing branch)**:
  - Jobs: Test, Build & Push.
  - Test: Run pytest on backend services, mock Azure Blob Storage.
  - Build: Docker build for each service, tag with commit SHA.
  - Push: Upload to ACR.
  - Staging: Create AKS namespace/deployments via Bicep, deploy, test, destroy.
- **Workflow 2 (main branch)**:
  - Job: Deploy to Prod AKS, monitor health.

### Best Practices Incorporated
- Secure access with Azure managed identities.
- Use Bicep for declarative infrastructure.
- Enable Azure Policy for compliance.
- Monitor deployments with Azure Monitor.
- Implement canary or blue-green for Prod if needed.

## Testing Steps

### Unit Testing

### Integration Testing
- In pipeline: Test API endpoints (e.g., product creation, order placement) against local Docker containers.
- Verify RabbitMQ message publishing/consuming.

### Acceptance Testing (Staging)
- Manual: Access frontend, add product, place order, check status updates.
- Trivial: API health checks, database connectivity.

### Production Testing
- Post-deployment: Automated smoke tests (e.g., via GitHub Actions), monitor Application Insights for errors.
- Rollback: If failures detected, redeploy previous image tag.