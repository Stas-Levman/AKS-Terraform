resource "azurerm_resource_group" "web-app-k8s" {
  name     = "web-app-k8s"
  location = "East US"
}

resource "azurerm_virtual_network" "aks-vnet" {
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.web-app-k8s.location
  name                = "aks-vnet"
  resource_group_name = azurerm_resource_group.web-app-k8s.name
}

resource "azurerm_subnet" "aks-subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.web-app-k8s.name
  virtual_network_name = azurerm_resource_group.web-app-k8s.location
  address_prefixes     = ["10.0.1.0/24"]
}


resource "azurerm_subnet" "agent-subnet" {
  name                 = "agent-subnet"
  resource_group_name  = azurerm_resource_group.web-app-k8s.name
  virtual_network_name = azurerm_resource_group.web-app-k8s.location
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_container_registry" "registry" {
  name                          = "staslRegistry"
  resource_group_name           = azurerm_resource_group.web-app-k8s.name
  location                      = azurerm_resource_group.web-app-k8s.location
  sku                           = "Premium"
  admin_enabled                 = true
  public_network_access_enabled = false
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = "web-app-aks"
  location            = azurerm_resource_group.web-app-k8s.location
  resource_group_name = azurerm_resource_group.web-app-k8s.name
  dns_prefix          = "app-k8s"
  private_cluster_enabled = true
  node_resource_group = "web-app-k8s-resources"


  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_B2s"
    vnet_subnet_id = azurerm_subnet.aks-subnet.id
    os_disk_size_gb = "30"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
}

resource "azurerm_role_assignment" "role-assignment" {
  principal_id                     = azurerm_kubernetes_cluster.cluster.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.registry.id
  skip_service_principal_aad_check = true
}