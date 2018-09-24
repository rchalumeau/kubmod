data "template_file" "kubeconfig" {

  template     = "${ var.name == "master" ? file("${path.module}/resources/kubeconfig_master.yaml") : file("${path.module}/resources/kubeconfig.yaml")}"

  vars {
    name       = "localcluster"
    user       = "kube-${var.cert_name}"
    cert_name  = "${var.cert_name}"
    api        = "${var.api_url}"
  }
}

data "ignition_file" "kubeconfig" {

  filesystem   = "root"
  path         = "/etc/kubernetes/kubeconfig.yaml"
  mode         = 0644

  content {
    content    = "${data.template_file.kubeconfig.rendered}"
  }
}

data "template_file" "kubeconfig_extern" {

  template     = "${file("${path.module}/resources/kubeconfig_extern.yaml")}"

  vars {
    name       = "localcluster"
    user       = "kube-${var.cert_name}"
    cert_name  = "${var.cert_name}"
    api        = "${ var.name == "master" ? "${var.api_url}" : "${var.bastion_public_ip}" }"
  }
}

resource "local_file" "kubeconfig" {
  content      = "${data.template_file.kubeconfig_extern.rendered}"
  filename     = "output/kubeconfig_${var.name}.yaml"
}
