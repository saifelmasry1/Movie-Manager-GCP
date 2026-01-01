pipeline {
  agent any

  environment {
    PROJECT_ID   = 'movie-manager-gcp'
    REGION       = 'us-central1'
    CLUSTER_NAME = 'movie-manager-gke'
    REPO         = 'movie-manager-repo'
    AR_HOST      = 'us-central1-docker.pkg.dev'

    FRONT_IMAGE  = "${AR_HOST}/${PROJECT_ID}/${REPO}/movie-manager-frontend"
    BACK_IMAGE   = "${AR_HOST}/${PROJECT_ID}/${REPO}/movie-manager-backend"

    TAG          = "${env.BUILD_NUMBER}"

    // خلي كل build مستقل عن Home بتاع Jenkins
    CLOUDSDK_CONFIG = "${WORKSPACE}/.gcloud"
    KUBECONFIG      = "${WORKSPACE}/kubeconfig"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Auth GCP (VM Service Account)') {
      steps {
        sh '''
          set -euo pipefail
          mkdir -p "$CLOUDSDK_CONFIG"

          # على GCE المفروض ده يطلع حساب الـ Service Account
          gcloud auth list || true

          gcloud config set project "$PROJECT_ID"
          gcloud config set compute/region "$REGION"

          # يخلي docker يقدر يعمل push على Artifact Registry
          gcloud auth configure-docker "$AR_HOST" -q
        '''
      }
    }

    stage('Build Images') {
      steps {
        sh '''
          set -euo pipefail
          docker build -t "$FRONT_IMAGE:$TAG" -t "$FRONT_IMAGE:latest" app/frontend
          docker build -t "$BACK_IMAGE:$TAG"  -t "$BACK_IMAGE:latest"  app/backend
        '''
      }
    }

    stage('Push Images') {
      steps {
        sh '''
          set -euo pipefail
          docker push "$FRONT_IMAGE:$TAG"
          docker push "$FRONT_IMAGE:latest"
          docker push "$BACK_IMAGE:$TAG"
          docker push "$BACK_IMAGE:latest"
        '''
      }
    }

    stage('Get GKE Credentials') {
      steps {
        sh '''
          set -euo pipefail
          mkdir -p "$(dirname "$KUBECONFIG")"

          gcloud container clusters get-credentials "$CLUSTER_NAME" \
            --region "$REGION" --project "$PROJECT_ID"

          kubectl get nodes
        '''
      }
    }

    stage('Render K8s Manifests') {
      steps {
        sh '''
          set -euo pipefail
          rm -rf rendered-k8s && mkdir -p rendered-k8s
          for f in k8s/*.yaml; do
            envsubst < "$f" > "rendered-k8s/$(basename "$f")"
          done
        '''
      }
    }

    stage('Deploy to GKE') {
      steps {
        sh '''
          set -euo pipefail
          kubectl apply -f rendered-k8s/
        '''
      }
    }

    stage('Mongo Seed') {
      steps {
        sh '''
          set -euo pipefail
          kubectl delete job mongo-seed-movies --ignore-not-found
          kubectl apply -f rendered-k8s/mongo-seed-job.yaml
          kubectl wait --for=condition=complete job/mongo-seed-movies --timeout=300s
        '''
      }
    }
  }

  post {
    always {
      sh '''
        export KUBECONFIG="${WORKSPACE}/kubeconfig"
        kubectl get pods,svc,ingress -A || true
      '''
    }
  }
}
