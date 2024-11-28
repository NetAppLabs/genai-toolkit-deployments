resource "random_password" "jwt_security_token" {
  length           = 128
  special          = false
}

resource "random_password" "postgres_password" {
  length           = 16
  special          = false
}

provider "tls" {}

resource "tls_private_key" "private_rsa" {
  algorithm = "RSA"
  rsa_bits = 4096
}

locals {
  private_key_pem = tls_private_key.private_rsa.private_key_pem
  public_key_pem  = tls_private_key.private_rsa.public_key_pem
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_compute_firewall" "firewall" { 
  name    = "genai-toolkit-firewall"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8001"]
  }

  source_ranges = var.source_ip_ranges
  target_tags   = ["allow-from-my-ip"]
}

resource "google_compute_instance" "genai-toolkit-vm" {
  provider = google
  name = "genai-toolkit-vm"
  machine_type = "e2-standard-4"
  tags = ["allow-from-my-ip"]

  network_interface {
    network = var.network
    subnetwork = var.subnetwork
    access_config{

    }
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12-bookworm-v20240213"
      size  = 100
    }
  }

  metadata_startup_script = <<EOF
    echo '${base64encode(file("docker-compose.yml"))}' | base64 -d > /root/docker-compose.yml
    echo '${base64encode(file("bootstrap_script.sh"))}' | base64 -d > /root/bootstrap_script.sh
    chmod +x /root/bootstrap_script.sh
    export GCNV_VOLUMES="${join(",", var.gcnv_volumes)}"
    export ONTAP_VOLUMES="${join(",", var.ontap_volumes)}"
    mkdir -p /root/.auth-keys/private
    mkdir -p /root/.auth-keys/public
    echo "${local.private_key_pem}" > /root/.auth-keys/private/rs256.rsa
    echo "${local.public_key_pem}" > /root/.auth-keys/public/public_key.rsa
    sed -i "s/JWT_SECRET_KEY_PLACEHOLDER/${random_password.jwt_security_token.result}/g" /root/docker-compose.yml
    sed -i "s/POSTGRES_PASSWORD_PLACEHOLDER/${random_password.postgres_password.result}/g" /root/docker-compose.yml
    /root/bootstrap_script.sh
  EOF

  allow_stopping_for_update = true
}

resource "time_sleep" "wait_for_toolkit_to_start" {
  depends_on = [google_compute_instance.genai-toolkit-vm]

  create_duration = "4m"
}

output "app_url" {
  value = format("http://%s", google_compute_instance.genai-toolkit-vm.network_interface[0].access_config[0].nat_ip)
  description = "The URL for accessing the toolkit."
  depends_on = [time_sleep.wait_for_toolkit_to_start]
}
