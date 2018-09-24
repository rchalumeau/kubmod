output "ca"                { value = "${tls_self_signed_cert.root.cert_pem}" }

output "ca_ignition_id"    { value = "${data.ignition_file.ca.id}" }

output "apiserver_cert_id" { value = "${data.ignition_file.apiserver_cert.id}" }
output "apiserver_key_id"  { value = "${data.ignition_file.apiserver_key.id}" }

output "client_cert_id"    { value = "${data.ignition_file.client_cert.id}" }
output "client_key_id"     { value = "${data.ignition_file.client_key.id}" }

output "admin_cert_id"     { value = "${data.ignition_file.admin_cert.id}" }
output "admin_key_id"      { value = "${data.ignition_file.admin_key.id}" }

output "etcd_cert_id"      { value = "${data.ignition_file.etcd_cert.id}" }
output "etcd_key_id"       { value = "${data.ignition_file.etcd_key.id}" }

