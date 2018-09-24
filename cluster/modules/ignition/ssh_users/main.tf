variable "hyperkube_image" {}

data "ignition_systemd_unit" "provision_ssh_users" {
    name    = "provision_ssh_users.service"
    enabled = true
    content = "${file("${path.module}/resources/provision_ssh_users.service")}"
}

output "provision_ssh_users_id" {
        value = "${data.ignition_systemd_unit.provision_ssh_users.id}"
}

data "ignition_file" "script_ssh_users" {

  filesystem    = "root"
  path          = "/opt/ssh/provision_ssh_users"
  mode          = 0755

  content {
    content     = "${file("${path.module}/resources/")}"
  }
}

output "script_ssh_users_id" {
        value = "${data.ignition_file.script_ssh_users.id}"
}

