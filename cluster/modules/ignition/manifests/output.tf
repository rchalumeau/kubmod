output "apiserver_id" {
	value = "${data.ignition_file.apiserver.id}"
}
output "scheduler_id" {
        value = "${data.ignition_file.scheduler.id}"
}
output "controller_id" {
        value = "${data.ignition_file.controller.id}"
}

