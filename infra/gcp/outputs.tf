output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  value     = google_container_cluster.primary.endpoint
  sensitive = true
}

output "repository_url" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.name}"
}


output "jenkins_public_ip" {
  value = google_compute_address.jenkins.address
}

output "jenkins_url" {
  value = "http://${google_compute_address.jenkins.address}:8080"
}

output "jenkins_ssh_cmd" {
  value = "gcloud compute ssh ${google_compute_instance.jenkins.name} --zone ${var.zone}"
}
