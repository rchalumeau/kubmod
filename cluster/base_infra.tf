provider "azurerm" {
	version            = "~> 1.1"    

	subscription_id    = "${var.az_subscription_id}"
	client_id          = "${var.az_client_id}"
	client_secret      = "${var.az_client_secret}"
	tenant_id          = "${var.az_tenant_id}"
}


provider "aws" {
    version            = "~> 1.8"

    access_key         = "${var.aws_access_key}"
    secret_key         = "${var.aws_secret_key}"
    region             = "${var.location}"
}

# Force versions of providers to avoid uncontrolled upgrades
provider "ignition"    { version = "~> 1.0" }
provider "tls"         { version = "~> 1.0" }
provider "template"    { version = "~> 1.0" }
provider "null"        { version = "~> 1.0" }

# Initialisation of the core components of Azure infrastructure (resource group, vm and cloud config file)
module "base" {
    source             = "./modules/azure/base"

    name               = "${var.cluster_name}"
    location           = "${var.location}"
    environment        = "${var.environment}"

    subscription_id    = "${var.az_subscription_id}"
    client_id          = "${var.az_client_id}"
    client_secret      = "${var.az_client_secret}"
    tenant_id          = "${var.az_tenant_id}"

    cidr               = "${local.net_cidr}"
    subnet_cidr        = "${local.vm_cidr}"    
    primary_block      = "worker"
}

# Docker configuration
module "docker" {
    source                  = "./modules/ignition/docker"
    registry                = "${var.registry}"
    registry_credentials    = "${var.registry_credentials}"
}

# Kubeconfig for the nodes (except masters)
module "kubeconfig_node" {
        source              = "./modules/ignition/kubeconfig"
        name                = "node"
        api_url             = "${local.master_loadbalancer}"
        bastion_public_ip   = "${module.bastion_ip.ip}"
        cert_name           = "client"
}

# udev configuration for Azure storage
module "udev" {
    source                  = "./modules/ignition/udev"
}

module "kubectl" {
    source                  = "./modules/ignition/kubectl" 
    hyperkube_image         = "${local.images["hyperkube"]}"
} 
