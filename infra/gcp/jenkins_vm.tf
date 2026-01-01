############################################
# Jenkins VM (Compute Engine) + Firewall
############################################

data "google_client_config" "current" {}

locals {
  project_id = data.google_client_config.current.project
}

# (اختياري) لو عايز IP ثابت لـ Jenkins
resource "google_compute_address" "jenkins" {
  name   = "jenkins-ip"
  region = var.region
}

# Service Account للـ Jenkins VM (هيبقى هوية الـ VM بدل ما تستخدم key file)
resource "google_service_account" "jenkins" {
  account_id   = "jenkins-sa"
  display_name = "Jenkins VM Service Account"
}

# صلاحيات push على Artifact Registry
resource "google_project_iam_member" "jenkins_ar_writer" {
  project = local.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

# صلاحيات GKE (عشان gcloud get-credentials + tokens)
resource "google_project_iam_member" "jenkins_gke" {
  project = local.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

# Firewall: افتح 8080 و 22 من CIDRs اللي انت هتحطها
resource "google_compute_firewall" "jenkins_allow" {
  name    = "allow-jenkins"
  network = var.jenkins_network_name

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.jenkins_allowed_cidrs
  target_tags   = ["jenkins"]
}

# Jenkins VM
resource "google_compute_instance" "jenkins" {
  name         = var.jenkins_instance_name
  zone         = var.zone
  machine_type = var.jenkins_machine_type
  tags         = ["jenkins"]

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
      size  = var.jenkins_disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    # لو انت على default network: خليها "default"
    network = var.jenkins_network_name

    # لو network auto-mode، تقدر تسيب subnetwork = null
    subnetwork = var.jenkins_subnet_name != "" ? var.jenkins_subnet_name : null

    access_config {
      nat_ip = google_compute_address.jenkins.address
    }
  }

  service_account {
    email  = google_service_account.jenkins.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata_startup_script = file("${path.module}/scripts/jenkins_startup.sh")
}
