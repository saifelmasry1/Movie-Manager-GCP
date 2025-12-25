# Movie Manager - GCP Migration

This project has been migrated from AWS to Google Cloud Platform (GCP).

## Architecture Mapping

| Component | AWS Source | GCP Target |
|-----------|------------|------------|
| **Compute** | Amazon EKS (Managed) | Google Kubernetes Engine (GKE) Standard |
| **Registry** | Amazon ECR | Google Artifact Registry |
| **Networking** | AWS VPC + ALB | GCP VPC + GCE Ingress (Global) |
| **Storage** | EBS (gp3) | GCE Persistent Disk (pd-balanced) |
| **CI/CD** | Jenkins on EC2 | Jenkins (same workflow, adapted for GCP) |
| **Monitoring** | kube-prometheus-stack | Managed Service for Prometheus |
| **IaC** | Terraform (EKS module) | Terraform (google provider) |
| **Ops** | Ansible | Ansible (Runbooks) |

## Prerequisites

1. **Google Cloud Project**
   - Create a project.
   - Note the `PROJECT_ID`.

2. **Tools Installed**
   - `gcloud` CLI
   - `terraform`
   - `kubectl`
   - `ansible`

3. **Authentication**
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

## Deployment Guide

### 1. Setup & Auth
```bash
gcloud auth login
gcloud auth application-default login
```

### 2. Infrastructure Provisioning (Terraform)
```bash
cd infra/gcp
cp terraform.tfvars.template terraform.tfvars
# edit terraform.tfvars with your project_id (and optional region/cluster_name)
terraform init
terraform apply
```

### 3. Configure Cluster Access
```bash
gcloud container clusters get-credentials movie-manager-gke \
  --region us-central1 \
  --project YOUR_PROJECT_ID
```

### 4. Deploy Application
To trigger the full CI/CD pipeline (Build + Push + Deploy):
```bash
```

### 6. Validation
```bash
kubectl get ingress movie-manager-ingress
kubectl get pvc mongo-pvc
kubectl rollout status deployment/movie-manager-frontend --timeout=300s
kubectl rollout status deployment/movie-manager-backend --timeout=300s
kubectl rollout status deployment/mongo --timeout=300s
```

## Troubleshooting

- **Ingress IP Pending**: It can take 5-10 minutes for GCE Ingress to provision a Load Balancer.
- **Mongo PVC Pending**: Check if `pd-balanced` StorageClass is created.
- **Drift**: Use `ansible-playbook playbooks/90-troubleshoot.yml`.
