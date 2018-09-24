# Kubelet services
output "kubelet_id" {
	value = "${data.ignition_systemd_unit.kubelet.id}"
}


