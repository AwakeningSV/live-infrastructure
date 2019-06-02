provider "azurerm" {
    subscription_id = "${var.azure_subscription_id}"
    tenant_id = "${var.azure_tenant_id}"
    version = "~> 1.20.0"
}

provider "cloudflare" {
    email = "${var.cf_email}"
    token = "${var.cf_token}"
    version = "~> 1.9.0"
}

data "template_file" "av_cloud_config" {
    template = "${file("ignition.json")}"
    vars {
        publish_secret = "${var.publish_secret}"
    }
}

resource "azurerm_resource_group" "live" {
    name = "LiveVideo"
    location = "${var.azure_region}"
}

resource "azurerm_virtual_network" "av_net" {
    name = "av-net"
    address_space = ["10.0.0.0/16"]
    location = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.live.name}"
}

resource "azurerm_subnet" "av_mgmt" {
    name = "av-management"
    address_prefix = "10.0.254.0/24"
    resource_group_name = "${azurerm_resource_group.live.name}"
    virtual_network_name = "${azurerm_virtual_network.av_net.name}"
}

resource "azurerm_public_ip" "av_public" {
    name = "av-public"
    location = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.live.name}"
    public_ip_address_allocation = "static"
    domain_name_label = "livevideo-av"
}

resource "azurerm_network_interface" "av_nic" {
    name = "av-${count.index}-nic"
    location = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.live.name}"

    ip_configuration {
        name = "av-${count.index}"
        subnet_id = "${azurerm_subnet.av_mgmt.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id = "${azurerm_public_ip.av_public.id}"
    }
}

resource "azurerm_storage_account" "av_storage" {
    name = "${var.azure_storage_prefix}av"
    location = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.live.name}"
    account_tier = "Standard"
    account_replication_type = "LRS"
}

resource "azurerm_storage_container" "av_storage_container" {
    name = "vhds"
    resource_group_name = "${azurerm_resource_group.live.name}"
    storage_account_name = "${azurerm_storage_account.av_storage.name}"
    container_access_type = "private"
}

resource "azurerm_virtual_machine" "av_vm" {
    count = 1

    name = "av${count.index}.${var.cf_domain}"
    location = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.live.name}"
    network_interface_ids = ["${azurerm_network_interface.av_nic.id}"]
    vm_size = "Standard_F8S"

    delete_data_disks_on_termination = "true"
    delete_os_disk_on_termination = "true"

    storage_image_reference {
        publisher = "CoreOS"
        offer = "CoreOS"
        sku = "Stable"
        version = "latest"
    }

    storage_os_disk {
        name = "av${count.index}-disk"
        vhd_uri = "${azurerm_storage_account.av_storage.primary_blob_endpoint}${azurerm_storage_container.av_storage_container.name}/${azurerm_resource_group.live.name}-av${count.index}.vhd"
        caching = "ReadWrite"
        create_option = "FromImage"
    }

    os_profile {
        computer_name = "av${count.index}"
        admin_username = "core"
        admin_password = "Password1234!"
        custom_data = "${base64encode(data.template_file.av_cloud_config.rendered)}"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path = "/home/core/.ssh/authorized_keys"
            key_data = "${file("${var.ssh_key_file}")}"
        }
    }
}

resource "cloudflare_record" "av0" {
    domain = "${var.cf_domain}"
    name = "av0"
    value = "${azurerm_public_ip.av_public.ip_address}"
    type = "A"
    ttl = 120
    proxied = false
}

resource "cloudflare_record" "live" {
    domain = "${var.cf_domain}"
    name = "live-backend"
    value = "${azurerm_public_ip.av_public.ip_address}"
    type = "A"
    ttl = 120
    proxied = false
}
