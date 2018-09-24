# Certificate apiserver

resource "tls_private_key" "client" {
    algorithm        = "RSA"
    ecdsa_curve      = "2048"
}


resource "tls_cert_request" "client" {
    key_algorithm    = "${tls_private_key.client.algorithm}"
    private_key_pem  = "${tls_private_key.client.private_key_pem}"

    subject {
        common_name  = "client"
        organization = "${var.organisation}"
    }
}

resource "tls_locally_signed_cert" "client" {

    allowed_uses          = [ "digital_signature", "server_auth", "client_auth" ]

    ca_cert_pem           = "${tls_self_signed_cert.root.cert_pem}"
    ca_key_algorithm      = "${tls_private_key.root.algorithm}"
    ca_private_key_pem    = "${tls_private_key.root.private_key_pem}"

    cert_request_pem      = "${tls_cert_request.client.cert_request_pem}"

    validity_period_hours = "${var.duration}"
}

data "ignition_file" "client_cert" {
  filesystem = "root"
  path       = "/etc/kubernetes/certs/client.crt"
  mode       = 0644

  content {
    content = "${tls_locally_signed_cert.client.cert_pem}"
  }
}


data "ignition_file" "client_key" {
  filesystem = "root"
  path       = "/etc/kubernetes/certs/client.key"
  mode       = 0644

  content {
    content = "${tls_private_key.client.private_key_pem}"
  }
}

resource "local_file" "client_cert" {
  content = "${tls_locally_signed_cert.client.cert_pem}"
  filename  = "output/bastion/certs/client.crt"
}

resource "local_file" "client_key" {
  content = "${tls_private_key.client.private_key_pem}"
  filename  = "output/bastion/certs/client.key"
}
