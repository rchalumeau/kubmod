# Certificate apiserver

resource "tls_private_key" "apiserver" {
    algorithm       = "RSA"
    ecdsa_curve     = "2048"
}


resource "tls_cert_request" "apiserver" {
    key_algorithm    = "${tls_private_key.apiserver.algorithm}"
    private_key_pem  = "${tls_private_key.apiserver.private_key_pem}"

    dns_names        = [ "master","kubernetes","kubernetes.default", "kubernetes.default.svc", "kubernetes.default.svc.local" ]
    ip_addresses     = [ "10.0.0.1", "${var.internal_loadbalancer}", "${var.bastion}" ]
    subject {
        common_name  = "apiserver"
        organization = "${var.organisation}"
    }
}

resource "tls_locally_signed_cert" "apiserver" {

    allowed_uses          = [ "digital_signature", "server_auth", "client_auth" ]

    ca_cert_pem           = "${tls_self_signed_cert.root.cert_pem}"
    ca_key_algorithm      = "${tls_private_key.root.algorithm}"
    ca_private_key_pem    = "${tls_private_key.root.private_key_pem}"

    cert_request_pem      = "${tls_cert_request.apiserver.cert_request_pem}"

    validity_period_hours = "${var.duration}"
}

data "ignition_file" "apiserver_cert" {
  filesystem = "root"
  path       = "/etc/kubernetes/certs/apiserver.crt"
  mode       = 0644

  content {
    content = "${tls_locally_signed_cert.apiserver.cert_pem}"
  }
}


data "ignition_file" "apiserver_key" {
  filesystem = "root"
  path       = "/etc/kubernetes/certs/apiserver.key"
  mode       = 0600

  content {
    content = "${tls_private_key.apiserver.private_key_pem}"
  }
}

resource "local_file" "apiserver_cert" {
  content  = "${tls_locally_signed_cert.apiserver.cert_pem}"
  filename = "output/master/certs/apiserver.crt"
}

resource "local_file" "apiserver_key" {
  content  = "${tls_private_key.apiserver.private_key_pem}"
  filename = "output/master/certs/apiserver.key"
}
