#provider

provider "azurerm" {
version = "~> 2.38.0"
features { }
} 

#resourcegroup

resource "azurerm_resource_group" "mygrp"{

name = "myrws"
location = "canadacentral"
}
#securitygroup

resource "azurerm_network_security_group" "group1"{
    name = "acceptencerule"
    location = azurerm_resource_group.mygrp.location
    resource_group_name = azurerm_resource_group.mygrp.name
    security_rule{
        name = "group1"
        priority = 100
        direction = "inbound"
        access = "allow"
        protocol = "tcp"
        source_port_range = "*"
        destination_port_range = "*"
        source_address_prefix = "*"
        destination_address_prefix = "*"

    }
}
#ddos plan
resource "azurerm_network_ddos_protection_plan" "ddos1"{
    name = "ddos1"
    location = azurerm_resource_group.mygrp.location
    resource_group_name = azurerm_resource_group.mygrp.name  
}
#routetable
resource "azurerm_route_table" "route1"{
    name = "acceptencerule"
    location = azurerm_resource_group.mygrp.location
    resource_group_name = azurerm_resource_group.mygrp.name
    route {
        name = "route1"
        address_prefix = "10.1.0.0/16"
        next_hop_type = "vnetlocal"
    }

}

#vpc
resource "azurerm_virtual_network" "vpc1" {
    name = "vpc1"
    location = azurerm_resource_group.mygrp.location
    resource_group_name = azurerm_resource_group.mygrp.name
    address_space = ["10.0.0.0/16"]
    ddos_protection_plan {
        id = azurerm_network_ddos_protection_plan.ddos1.id
        enable = true

    }

    
}
#subnet

resource "azurerm_subnet" "sub1"{
    name = "sub1"
    virtual_network_name = azurerm_virtual_network.vpc1.name
    resource_group_name = azurerm_resource_group.mygrp.name
    address_prefixes = ["10.0.1.0/24"]
}
#subnetandsecuritygroupassociation
resource "azurerm_subnet_network_security_group_association" "sgsn"{
    subnet_id = azurerm_subnet.sub1.id
    network_security_group_id = azurerm_network_security_group.group1.id
}

resource "azurerm_subnet" "internal"{
    name = "internal"
    virtual_network_name = azurerm_virtual_network.vpc1.name
    resource_group_name = azurerm_resource_group.mygrp.name
    address_prefixes = ["10.0.2.0/24"]
}
#routetableassociation
resource "azurerm_subnet_route_table_association" "sra1"{
    subnet_id = azurerm_subnet.sub1.id
    route_table_id = azurerm_route_table.route1.id
}
#network interface
resource "azurerm_network_interface" "net1"{
    name = "int1"
    location = azurerm_resource_group.mygrp.location
    resource_group_name = azurerm_resource_group.mygrp.name
    ip_configuration {
        name = "pub"
        subnet_id = azurerm_subnet.sub1.id
        private_ip_address_allocation = "Dynamic"
    
    }

}
resource "azurerm_virtual_machine" "ubuntu1" {
  name                  = "ubuntu1"
  location              = azurerm_resource_group.mygrp.location
  resource_group_name   = azurerm_resource_group.mygrp.name
  network_interface_ids = [azurerm_network_interface.net1.id]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}
