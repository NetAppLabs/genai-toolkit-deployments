# Declare Provider Azure
provider "azurerm" {
  features {}
  subscription_id = var.subscription
}

# Create a Public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "genai-toolkit-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
}

# Create a Network Interface
resource "azurerm_network_interface" "genai-toolkit_nic" {
  name                = "genai-toolkit-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "genai-toolkit-ip-config"
    subnet_id                     = var.subnetid
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "http_nsg" {
  name                = "http-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "8001"]
    source_address_prefix      = "${var.source_ip_range}"
    destination_address_prefix = "*"
  }
}

# Associate Network Security Group with Network Interface
resource "azurerm_network_interface_security_group_association" "genai-toolkit_nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.genai-toolkit_nic.id
  network_security_group_id = azurerm_network_security_group.http_nsg.id
}

# Create a Virtual Machine
resource "azurerm_linux_virtual_machine" "genai-toolkit_vm" {
  name                  = "genai-vm"
  location              = var.location
  resource_group_name   = var.resource_group_name
  size                  = "Standard_DS2_v2"
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.genai-toolkit_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-12"
    sku       = "12"
    version   = "latest"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.admin_ssh_key_file_location)
  }

  custom_data = base64encode(<<-EOF
    #cloud-config
    write_files:
      - path: /root/env_vars.sh
        permissions: '0755'
        content: |
          #!/bin/bash
          export OPENAI_API_KEY="${var.openai_api_key}"
          export OPENAI_ENDPOINT="${var.openai_endpoint}"
          export ANF_VOLUMES="${join(",", var.anf_volumes)}"
          export ONTAP_VOLUMES="${join(",", var.ontap_volumes)}"
      - path: /root/bootstrap_script.sh
        permissions: '0755'
        content: |
          ${indent(8, file("${path.module}/bootstrap_script.sh"))}
      - path: /root/docker-compose.yml
        permissions: '0644'
        encoding: b64
        content: ${base64encode(file("${path.module}/docker-compose.yml"))}
      - path: /root/credentials.json
        permissions: '0644'
        content: |
          ${indent(8, file(var.google_service_account_file_path))}
    runcmd:
      - /root/bootstrap_script.sh
  EOF
  )
}


# Wait for two minutes for the infrastructure to complete building.
resource "time_sleep" "wait_toolkit_to_start" {
  depends_on = [azurerm_linux_virtual_machine.genai-toolkit_vm]

  create_duration = "240s"
}

# Display the URL to be copied
output "app_url" {
  value       = format("http://%s", azurerm_public_ip.public_ip.ip_address)
  description = "The URL for accessing the app."
  depends_on  = [time_sleep.wait_toolkit_to_start]
}
