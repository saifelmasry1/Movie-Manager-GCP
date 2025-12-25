# Migration Report

## Files Audit

### Infrastructure (`infra/gcp/`)
- **Added**: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`.
- **Purpose**: Provision VPC, GKE, AR.
- **Difference**: Replaces `infra/eks` terraform modules.

### Kubernetes (`k8s/`)
- **Modified**: `movie-manager-ingress.yaml` (GCE annotations).
- **Modified**: `mongo-pvc.yaml` (StorageClass `pd-balanced`).
- **Modified**: `movie-manager-backend.yaml` & `frontend.yaml` (Image paths).
- **Added**: `storage-class.yaml`.
- **Retained**: `mongo.yaml`, `mongo-seed-*.yaml`.

### CI/CD (`Jenkinsfile`)
- **Added**: `Jenkinsfile` (Root directory).
- **Purpose**: Defines the single source of truth for the deployment pipeline (Build -> Push -> Deploy -> Seed).

### Ansible (`ansible/`)
- **Removed**: Ansible directory deleted. Deployment is handled strictly by Jenkins and kubectl/Terraform.

## Validation Checklist

- [ ] Terraform Apply Successful
- [ ] GKE Cluster Active
- [ ] Node Pool (2 nodes) Ready
- [ ] Artifact Registry Created
- [ ] Jenkins Pipeline Success
- [ ] Ingress IP Allocated
- [ ] Frontend Accessible via IP
- [ ] Backend Accessible via `/api`
- [ ] Mongo PVC Bound
- [ ] Mongo Seed Job Completed

## Rollback Plan

Since this migration is in a new isolated environment (new Project/VPC), rollback simply implies:
1. Routing DNS back to AWS ALB.
2. Destroying GCP resources via `terraform destroy`.
