variable "registry" {}
variable "registry_credentials" {}

# Docker root login to bsm registry
data "template_file" "dockercfg" {

  template      = "${file("${path.module}/resources/dockercfg.json")}"

    vars {
      registry  = "${var.registry}"
      auth      = "${base64encode(var.registry_credentials)}"
    }
}

data "ignition_file" "docker_bsm_login" {

  filesystem    = "root"
  path          = "/root/.docker/config.json"
  mode          = 0644

  content {
    content     = "${data.template_file.dockercfg.rendered}"
  }
}

# Docker Log rotate and proxy
data "ignition_systemd_unit" "docker_dropin_logrotate" {
  name          = "docker.service"
  enabled       = true

  dropin = [
    {
      name      = "10-dockeropts.conf"
      content   = "${file("${path.module}/resources/10-dockeropts.conf")}"
    }
  ]
}

output "docker_logrotate_id" {
	value	= "${data.ignition_systemd_unit.docker_dropin_logrotate.id}"
}

output "docker_authent_id" {
        value   = "${data.ignition_file.docker_bsm_login.id}"
}


