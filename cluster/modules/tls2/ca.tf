resource "tls_private_key" "root" {
    algorithm       = "RSA"
    ecdsa_curve     = "2048"
}


# Root certificate
resource "tls_self_signed_cert" "root" {
    allowed_uses       = [
          "key_encipherment",
          "digital_signature",
          "cert_signing"
      ]
      is_ca_certificate   = true
      key_algorithm     = "${tls_private_key.root.algorithm}"
      private_key_pem     = "${tls_private_key.root.private_key_pem}"
      subject {
          common_name     = "Root certificate"
          organization     = "${var.organisation}"
      }
      validity_period_hours   = "${var.duration}"
}

data "ignition_file" "ca" {

  filesystem       = "root"
  path             = "/etc/kubernetes/certs/ca.crt"
  mode             = 0644

  content {
      content      = "${tls_self_signed_cert.root.cert_pem}"
  }
}

resource "local_file" "ca" {
  content          = "${tls_self_signed_cert.root.cert_pem}"
  filename         = "output/bastion/certs/ca.crt"
}

