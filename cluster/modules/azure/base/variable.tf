variable "subscription_id" {
	description = "ID of the subscription to create the resource group"
}

variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "location" {}

variable "name" {
	description = "Name of the resource group to create"
}

variable "cidr" {
	description = "Adresses spaces to create the vnet"
}
variable "subnet_cidr" {
	
}
variable "environment" {}

variable "primary_block" {}


