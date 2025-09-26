# Staging environment configuration
project_name = "bang-sit722"
environment  = "staging"
location     = "East US"

# Resource naming (will use defaults if not specified)
# resource_group_name = "bang-sit722-staging-rg"
# acr_name           = "bangsit722stagingacr"
# aks_cluster_name   = "bang-sit722-staging-aks"

# AKS Configuration
kubernetes_version = "1.28.5"
node_count        = 2
vm_size           = "Standard_B2s"
os_disk_size_gb   = 30

# Auto-scaling
enable_auto_scaling = true
min_node_count     = 1
max_node_count     = 3

# ACR Configuration
acr_sku = "Standard"

# Tags
tags = {
  Project     = "bang-sit722"
  Environment = "staging"
  ManagedBy   = "terraform"
  Purpose     = "microservices-ecommerce"
}