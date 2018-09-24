data "template_file" "apiserver" {
    template        = "${file("${path.module}/resources/kube-apiserver.yaml")}"

    vars = {
        hyperkube   = "${var.hyperkube_image}"
	cluster_cidr = "${var.cluster_cidr}"
    }
}


data "template_file" "scheduler" {
    template        = "${file("${path.module}/resources/kube-scheduler.yaml")}"

    vars = {
        hyperkube   = "${var.hyperkube_image}"
    }
}

data "template_file" "controller" {
    template        = "${file("${path.module}/resources/kube-controller-manager.yaml")}"

    vars = {
        proxy       = "${var.proxy}"
        hyperkube   = "${var.hyperkube_image}"
	pod_cidr    = "${var.pod_cidr}"
    }
}

data "ignition_file" "apiserver" {

  filesystem    = "root"
  path          = "/etc/kubernetes/manifests/kube-apiserver.yaml"
  mode          = 0755

  content {
    content     = "${data.template_file.apiserver.rendered}"
  }
}

data "ignition_file" "controller" {

  filesystem    = "root"
  path          = "/etc/kubernetes/manifests/kube-controller-manager.yaml"
  mode          = 0755

  content {
    content     = "${data.template_file.controller.rendered}"
  }
}

data "ignition_file" "scheduler" {

  filesystem    = "root"
  path          = "/etc/kubernetes/manifests/kube-scheduler.yaml"
  mode          = 0755

  content {
    content     = "${data.template_file.scheduler.rendered}"
  }
}



