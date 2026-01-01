variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "GKE Cluster Name"
  type        = string
  default     = "movie-manager-gke"
}


variable "zone" {
  type        = string
  description = "GCP zone for resources like Jenkins VM"
  default     = "us-central1-a"
}

variable "jenkins_allowed_cidrs" {
  type        = list(string)
  description = "CIDR ranges allowed to access Jenkins (8080) and SSH (22)"
  default     = ["0.0.0.0/0"] # غيّرها لـ your-ip/32 عشان الأمان
}

variable "jenkins_instance_name" {
  type    = string
  default = "jenkins-vm"
}

variable "jenkins_machine_type" {
  type    = string
  default = "e2-standard-2"
}

variable "jenkins_disk_size_gb" {
  type    = number
  default = 50
}

variable "jenkins_network_name" {
  type        = string
  description = "VPC network name (e.g. default or your custom VPC name)"
  default     = "default"
}

variable "jenkins_subnet_name" {
  type        = string
  description = "Subnetwork name (leave empty for auto-mode networks like default)"
  default     = ""
}
