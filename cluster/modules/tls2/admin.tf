# Certificate admin

resource "tls_private_key" "admin" {
    algorithm       = "RSA"
    ecdsa_curve     = "2048"
}


resource "tls_cert_request" "admin" {
    key_algorithm    = "${tls_private_key.admin.algorithm}"
    private_key_pem  = "${tls_private_key.admin.private_key_pem}"

    subject {
        common_name  = "admin"
        organization = "${var.organisation}"
    }
}

resource "tls_locally_signed_cert" "admin" {

    allowed_uses          = [ "digital_signature", "server_auth", "client_auth" ]

    ca_cert_pem           = "${tls_self_signed_cert.root.cert_pem}"
    ca_key_algorithm      = "${tls_private_key.root.algorithm}"
    ca_private_key_pem    = "${tls_private_key.root.private_key_pem}"

    cert_request_pem      = "${tls_cert_request.admin.cert_request_pem}"

    validity_period_hours = "${var.duration}"
}

data "ignition_file" "admin_cert" {
  filesystem = "root"
  path       = "/etc/kubernetes/certs/admin.crt"
  mode       = 0644

  content {
    content = "${tls_locally_signed_cert.admin.cert_pem}"
  }
}


data "ignition_file" "admin_key" {
  filesystem = "root"
  path       = "/etc/kubernetes/certs/admin.key"
  mode       = 0600

  content {
    content = "${tls_private_key.admin.private_key_pem}"
  }
}

