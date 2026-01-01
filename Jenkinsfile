pipeline {
  agent any

  options {
    skipDefaultCheckout(true)
    timestamps()
  }

  environment {
    PROJECT_ID   = 'movie-manager-gcp'
    REGION       = 'us-central1'
    CLUSTER_NAME = 'movie-manager-gke'
    REPO         = 'movie-manager-repo'
    AR_HOST      = 'us-central1-docker.pkg.dev'

    FRONT_IMAGE  = "${AR_HOST}/${PROJECT_ID}/${REPO}/movie-manager-frontend"
    BACK_IMAGE   = "${AR_HOST}/${PROJECT_ID}/${REPO}/movie-manager-backend"

    TAG          = "${env.BUILD_NUMBER}"

    CLOUDSDK_CONFIG = "${WORKSPACE}/.gcloud"
    KUBECONFIG      = "${WORKSPACE}/kubeconfig"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Auth GCP (VM Service Account)') {
      steps {
        sh(label: 'gcloud auth', script: '''#!/usr/bin/env bash
          set -euo pipefail
          mkdir -p "$CLOUDSDK_CONFIG"

          # (Optional) show current account
          gcloud auth list || true

          gcloud config set project "$PROJECT_ID"
          gcloud config set compute/region "$REGION"

          # Artifact Registry docker auth
          gcloud auth configure-docker "$AR_HOST" -q
        ''')
      }
    }

    stage('Build Images') {
      steps {
        sh(label: 'docker build', script: '''#!/usr/bin/env bash
          set -euo pipefail

          docker build -t "$FRONT_IMAGE:$TAG" -t "$FRONT_IMAGE:latest" app/frontend
          docker build -t "$BACK_IMAGE:$TAG"  -t "$BACK_IMAGE:latest"  app/backend
        ''')
      }
    }

    stage('Push Images') {
      steps {
        sh(label: 'docker push', script: '''#!/usr/bin/env bash
          set -euo pipefail

          docker push "$FRONT_IMAGE:$TAG"
          docker push "$FRONT_IMAGE:latest"
          docker push "$BACK_IMAGE:$TAG"
          docker push "$BACK_IMAGE:latest"
        ''')
      }
    }

    stage('Get GKE Credentials') {
      steps {
        sh(label: 'get-credentials', script: '''#!/usr/bin/env bash
          set -euo pipefail

          mkdir -p "$CLOUDSDK_CONFIG"
          export CLOUDSDK_CONFIG="$CLOUDSDK_CONFIG"
          export KUBECONFIG="$KUBECONFIG"

          gcloud config set project "$PROJECT_ID"
          gcloud config set compute/region "$REGION"

          gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID"
          kubectl get nodes
        ''')
      }
    }

    stage('Render K8s Manifests') {
      steps {
        sh(label: 'render manifests', script: '''#!/usr/bin/env bash
          set -euo pipefail

          rm -rf rendered-k8s && mkdir -p rendered-k8s

          shopt -s nullglob
          files=(k8s/*.yaml)

          if [ ${#files[@]} -eq 0 ]; then
            echo "ERROR: No k8s/*.yaml files found!" >&2
            exit 1
          fi

          for f in "${files[@]}"; do
            out="rendered-k8s/$(basename "$f")"
            envsubst < "$f" > "$out"
            echo "Rendered: $f -> $out"
          done

          echo "Rendered files:"
          ls -la rendered-k8s
        ''')
      }
    }

    stage('Deploy to GKE') {
      steps {
        sh(label: 'kubectl apply', script: '''#!/usr/bin/env bash
          set -euo pipefail
          export KUBECONFIG="$KUBECONFIG"

          kubectl apply -f rendered-k8s/
        ''')
      }
    }

    stage('Mongo Seed') {
      steps {
        sh(label: 'mongo seed', script: '''#!/usr/bin/env bash
          set -euo pipefail
          export KUBECONFIG="$KUBECONFIG"

          kubectl delete job mongo-seed-movies --ignore-not-found
          kubectl apply -f rendered-k8s/mongo-seed-job.yaml
          kubectl wait --for=condition=complete job/mongo-seed-movies --timeout=300s
        ''')
      }
    }
  }

  post {
    always {
      sh(label: 'post status', script: '''#!/usr/bin/env bash
        set +e
        if [ -f "$KUBECONFIG" ]; then
          export KUBECONFIG="$KUBECONFIG"
          kubectl get pods,svc,ingress -A -o wide || true
        else
          echo "KUBECONFIG not found (pipeline failed before get-credentials). Skipping kubectl post actions."
        fi
      ''')
    }
  }
}
