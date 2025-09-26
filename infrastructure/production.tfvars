# Production environment configuration
project_name = "bang-sit722"
environment  = "production"
location     = "East US"

# Resource naming (will use defaults if not specified)
# resource_group_name = "bang-sit722-production-rg"
# acr_name           = "bangsit722productionacr"
# aks_cluster_name   = "bang-sit722-production-aks"

# AKS Configuration - More robust for production
kubernetes_version = "1.28.5"
node_count        = 3
vm_size           = "Standard_D2s_v3"  # Better performance for production
os_disk_size_gb   = 50

# Auto-scaling - Higher limits for production
enable_auto_scaling = true
min_node_count     = 2
max_node_count     = 10

# ACR Configuration - Premium for production features
acr_sku = "Standard"  # Can be upgraded to Premium for geo-replication

# Tags
tags = {
  Project     = "bang-sit722"
  Environment = "production"
  ManagedBy   = "terraform"
  Purpose     = "microservices-ecommerce"
  CriticalLevel = "high"
}