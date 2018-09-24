# Certificate etcd

resource "tls_private_key" "etcd" {
    algorithm        = "RSA"
    ecdsa_curve      = "2048"
}


resource "tls_cert_request" "etcd" {
    key_algorithm    = "${tls_private_key.etcd.algorithm}"
    private_key_pem  = "${tls_private_key.etcd.private_key_pem}"

    dns_names        = [ "${split(",", var.etcd_cluster)}", "localhost" ]
    ip_addresses     = [ "127.0.0.1", "${var.internal_loadbalancer}" ]
    subject {
        common_name  = "etcd peer"
        organization = "${var.organisation}"
    }
}

resource "tls_locally_signed_cert" "etcd" {

    allowed_uses          = [ "digital_signature", "server_auth", "client_auth" ]

    ca_cert_pem           = "${tls_self_signed_cert.root.cert_pem}"
    ca_key_algorithm      = "${tls_private_key.root.algorithm}"
    ca_private_key_pem    = "${tls_private_key.root.private_key_pem}"

    cert_request_pem      = "${tls_cert_request.etcd.cert_request_pem}"

    validity_period_hours = "${var.duration}"
}

data "ignition_file" "etcd_cert" {
  filesystem = "root"
  path       = "/etc/kubernetes/certs/peer.crt"
  mode       = 0644

  content {
      content = "${tls_locally_signed_cert.etcd.cert_pem}"
  }
}


data "ignition_file" "etcd_key" {
  filesystem = "root"
  path       = "/etc/kubernetes/certs/peer.key"
  mode       = 0600

  content {
      content = "${tls_private_key.etcd.private_key_pem}"
  }
}

