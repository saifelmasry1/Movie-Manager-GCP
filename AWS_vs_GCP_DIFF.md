# AWS vs GCP Migration Diff

## Key Architectural Differences

### 1. Networking Model
- **AWS**: Used AWS VPC with specific subnets for EKS. Ingress was handled by AWS Load Balancer Controller (ALB).
- **GCP**: Uses VPC-native GKE clusters. Ingress is handled by GCE Ingress Controller, which spins up a Global HTTP(S) Load Balancer.

### 2. Identity & Access
- **AWS**: IAM Users/Roles map to K8s RBAC via `aws-auth` ConfigMap.
- **GCP**: Workload Identity Federation. Google Service Accounts (GSA) map to Kubernetes Service Accounts (KSA).

### 3. Container Registry
- **AWS**: ECR (Region-specific).
- **GCP**: Artifact Registry (Region-specific, Docker format). New repo `movie-manager-repo` created.

### 4. Storage
- **SC**: `gp3` (EBS) -> `pd-balanced` (GCE PD).
- **Access**: `ReadWriteOnce` remains the same.
- **Performance**: `pd-balanced` offers a good mix of SSD performance and cost, similar to `gp3`.

### 5. CI/CD Pipeline
- **AWS**: Jenkins on EC2 (existing setup).
- **GCP**: Jenkins remains the ONLY deployment runner. Pipeline updated to:
  - authenticate to GCP using Service Account JSON
  - push images to Artifact Registry
  - deploy to GKE using kubectl
  - run Mongo seed job

### 6. Monitoring
- **AWS**: User-managed `kube-prometheus-stack` (Helm).
- **GCP**: Managed Service for Prometheus (GMP). Zero-config monitoring for system components.

## Rationale for Changes

- **GKE Standard** was chosen over Autopilot to maintain similar control to EKS (Node pools, etc).
- **GCE Ingress** provides global reach out-of-the-box.
