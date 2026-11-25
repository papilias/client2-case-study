variable "cluster_name" {
  description = "Sanitized AKS cluster name"
  type        = string
  default     = "aks-regulated-payments-prod"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "uksouth"
}

variable "resource_group_name" {
  description = "Target Resource Group managed under CCoE governance"
  type        = string
  default     = "rg-regulated-payments-prod"
}

variable "dns_prefix" {
  description = "AKS DNS prefix"
  type        = string
  default     = "aks-reg-pay"
}

variable "kubernetes_version" {
  description = "Supported Kubernetes version"
  type        = string
  default     = "1.30.6"
}

variable "aks_subnet_id" {
  description = "Private VNet subnet ID for AKS nodes"
  type        = string
  default     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-core/subnets/snet-aks"
}

variable "common_tags" {
  description = "Governance and compliance tags"
  type        = map(string)
  default = {
    Environment = "Production"
    Compliance  = "PCI-DSS-FIPS-140-3"
    ManagedBy   = "Terraform"
  }
}
