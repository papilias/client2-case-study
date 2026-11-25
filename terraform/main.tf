terraform {
  required_version = ">= 1.7.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_kubernetes_cluster" "aks_regulated" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Standard"

  default_node_pool {
    name                         = "systempool"
    node_count                   = 2
    vm_size                      = "Standard_D4ds_v5"
    os_sku                       = "AzureLinux"
    fips_enabled                 = true
    vnet_subnet_id               = var.aks_subnet_id
    only_critical_addons_enabled = true

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
  }

  tags = var.common_tags
}

resource "azurerm_kubernetes_cluster_node_pool" "payment_workload_pool" {
  name                  = "workloadpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_regulated.id
  vm_size               = "Standard_D4ds_v5"
  os_sku                = "AzureLinux"
  fips_enabled          = true
  vnet_subnet_id        = var.aks_subnet_id
  enable_auto_scaling   = true
  min_count             = 2
  max_count             = 6

  node_labels = {
    "workload-tier" = "pci-regulated"
    "fips-enabled"  = "true"
  }

  upgrade_settings {
    max_surge = "1"
  }

  tags = var.common_tags
}
