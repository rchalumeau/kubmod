variable "hyperkube_image" {}

data "template_file" "kubectl" {
    template        = "${file("${path.module}/resources/extract_kubectl.service")}"

    vars = {
        hyperkube_image   = "${var.hyperkube_image}"
    }
}

data "ignition_systemd_unit" "kubectl" {
    name    = "extract_kubectl.service"
    enabled = true
    content = "${data.template_file.kubectl.rendered}"
}

output "kubectl_id" {
        value = "${data.ignition_systemd_unit.kubectl.id}"
}

data "ignition_file" "aliases" {

  filesystem    = "root"
  path          = "/etc/profile.d/kubectl_aliases.sh"
  mode          = 0755

  content {
    content     = "${file("${path.module}/resources/kubectl_aliases")}"
  }
}

output "alias_id" {
        value = "${data.ignition_file.aliases.id}"
}

