variable "cloud_provider" {
	description = "one of azure or aws"
}

variable "az_subscription_id" {
	description = "if azure, id of the subscription"
	default = ""
}

variable "az_client_id" {
        description = "if azure, id of terraform aad"
        default = ""
}

variable "az_client_secret" {
        description = "if azure, client secret"
        default = ""
}

variable "az_tenant_id" {
        description = "if azure, id of the tenant"
        default = ""
}


variable "aws_access_key"{
        description = "if aws, access key"
        default = ""
}

variable "aws_secret_key" {
        description = "if aws, secret key"
        default = ""
}


variable "location" {}
variable "cluster_name" {}

variable "worker_count" {}
variable "worker_size" {}
variable "worker_disk_type" {}

variable "storekeeper_count" { default = 0 }
variable "storekeeper_size" { default = "Standard_D2s_v3" }
variable "storekeeper_disk_type" { default = "Premium_LRS" } 

variable "master_count" { default = 1 }
variable "master_size" { default = "Standard_D2s_v3" }
variable "master_disk_type" { default = "Premium_LRS" }

variable "bastion_count" { default = 1 }
variable "bastion_size" { default = "Standard_D1_v2" }
variable "bastion_disk_type" { default = "Standard_LRS" }

variable "proxy_count" { default = 1 }
variable "proxy_size" { default = "Standard_D1_v2" }
variable "proxy_disk_type" {  default = "Standard_LRS" }

variable "ingress_count" { default = 1 }
variable "ingress_size" { default = "Standard_D1_v2" }
variable "ingress_disk_type" {  default = "Standard_LRS" }


#variable "os" { type = "map" }
variable "boot_user" { default = "custadm" }

variable "registry" { default = "docker.bsm.utility.valapp.com" }
variable "registry_credentials" {}
variable "environment" {}

#variable "proxy_ports" { type="map" }

# Store the version used for provisionning (terraform docker image)
variable "version" { default= "tbc" }

variable "coreos_version" {}
