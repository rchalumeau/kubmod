locals {
	proxy_url = "http://${var.http_proxy}:3128"
}

data "template_file" "kubelet" {
    template        = "${file("${path.module}/resources/kubelet.service")}"

    vars = {
	wait_for_proxy = "${ var.http_proxy == "" ? "" : "ExecStartPre=-/usr/bin/sh -c 'until curl ${local.proxy_url}; do echo waiting for proxy to be up...; sleep 10; done'" }"
        hyperkube   = "${var.hyperkube_image}"
        dns         = "${var.dns_address}"
        pause_image = "${var.pause_image}"
        provider    = "${var.cloud_provider}"
        schedule    = "${var.schedule}"
        role        = "${var.name}"
	noproxy     = "${ var.noproxy == "" ? "" : "-e no_proxy=127.0.0.1,${var.noproxy}" }"
	proxy	    = "${ var.http_proxy == "" ? "" : "-e https_proxy=${local.proxy_url}" }"
    }
}

data "ignition_systemd_unit" "kubelet" {
    name    = "kubelet.service"
    enabled = true
    content = "${data.template_file.kubelet.rendered}"
}

