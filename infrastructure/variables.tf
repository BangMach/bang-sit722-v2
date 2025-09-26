# Variables for Terraform configuration

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "bang-sit722"
}

variable "environment" {
  description = "Environment (staging or production)"
  type        = string
  default     = "staging"
  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be either 'staging' or 'production'."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = null
}

variable "acr_name" {
  description = "Azure Container Registry name"
  type        = string
  default     = null
}

variable "acr_sku" {
  description = "Azure Container Registry SKU"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be Basic, Standard, or Premium."
  }
}

variable "aks_cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = null
}

variable "aks_dns_prefix" {
  description = "DNS prefix for AKS cluster"
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28.5"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "VM size for nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 30
}

variable "enable_auto_scaling" {
  description = "Enable auto scaling for the node pool"
  type        = bool
  default     = true
}

variable "min_node_count" {
  description = "Minimum number of nodes for auto scaling"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes for auto scaling"
  type        = number
  default     = 5
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "bang-sit722"
    Environment = "staging"
    ManagedBy   = "terraform"
  }
}

# Locals for resource naming
locals {
  resource_group_name = var.resource_group_name != null ? var.resource_group_name : "${var.project_name}-${var.environment}-rg"
  acr_name           = var.acr_name != null ? var.acr_name : "${replace(var.project_name, "-", "")}${var.environment}acr"
  aks_cluster_name   = var.aks_cluster_name != null ? var.aks_cluster_name : "${var.project_name}-${var.environment}-aks"
  aks_dns_prefix     = var.aks_dns_prefix != null ? var.aks_dns_prefix : "${var.project_name}-${var.environment}"
}