variable "master_count" {}
variable "cluster_name" {}
variable "etcd_image" {}

# Service etcd3

# generation of the cluster definition
data "null_data_source" "etcd_cluster" {
  count                                         = "${var.master_count}"
  inputs = {
        initial_cluster                         = "master${count.index + 1}=https://master${count.index + 1}:2380"
        hostnames                               = "master${count.index + 1}"
  }
}


data "template_file" "etcd_service" {
        template                = "${file("${path.module}/resources/etcd3.service")}"

        vars = {
                etcd_cluster_token          =   "${var.cluster_name}"
                cluster_definition          =   "${join(",", data.null_data_source.etcd_cluster.*.inputs.initial_cluster)}"
                etcd_image                  =   "${var.etcd_image}"
  }
}

data "ignition_systemd_unit" "etcd_svc" {
        name    = "etcd3.service"
        enabled = true

        content = "${data.template_file.etcd_service.rendered}"
}


output "etcd_id" {
	value = "${data.ignition_systemd_unit.etcd_svc.id}"
}
