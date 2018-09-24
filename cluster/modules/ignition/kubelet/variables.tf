variable "name" {}

variable "hyperkube_image" {}
variable "pause_image" {}

variable "dns_address" {}
variable "cloud_provider" {}
variable "noproxy" { default = "" }
variable "http_proxy" { default = "" }

variable "schedule" { default = "false" }

