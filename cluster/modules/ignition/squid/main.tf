variable "squid_image" {}

data "template_file" "squid" {

  template = "${file("${path.module}/resources/squid.yaml")}"
  vars {
        squid_image = "${var.squid_image}"
  }
}

data "ignition_file" "squid" {
  filesystem = "root"
  path       = "/etc/kubernetes/manifests/squid.yaml"
  mode       = 0644

  content {
    content = "${data.template_file.squid.rendered}"
  }
}

data "ignition_file" "whitelist" {
  filesystem = "root"
  path       = "/etc/squid/sites.whitelist"
  mode       = 0644

  content {
    content = "${file("${path.module}/resources/sites.whitelist.default")}"
  }
}


output "squid_id" {
	value = "${data.ignition_file.squid.id}"
}

output "whitelist_id" {
        value = "${data.ignition_file.whitelist.id}"
}

