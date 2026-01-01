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
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Auth GCP') {
      steps {
        withCredentials([file(credentialsId: 'gcp-sa-json', variable: 'GCP_SA_KEY')]) {
          sh '''
            gcloud auth activate-service-account --key-file="$GCP_SA_KEY"
            gcloud config set project "$PROJECT_ID"
            gcloud auth configure-docker "$AR_HOST" -q
          '''
        }
      }
    }

    stage('Build Images') {
      steps {
        sh '''
          docker build -t "$FRONT_IMAGE:$TAG" -t "$FRONT_IMAGE:latest" app/frontend
          docker build -t "$BACK_IMAGE:$TAG"  -t "$BACK_IMAGE:latest"  app/backend
        '''
      }
    }

    stage('Push Images') {
      steps {
        sh '''
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
          gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID"
        '''
      }
    }

    stage('Render K8s Manifests') {
      steps {
        sh '''
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
          kubectl apply -f rendered-k8s/
        '''
      }
    }

    stage('Mongo Seed') {
      steps {
        sh '''
          kubectl delete job mongo-seed-movies --ignore-not-found
          kubectl apply -f rendered-k8s/mongo-seed-job.yaml
          kubectl wait --for=condition=complete job/mongo-seed-movies --timeout=300s
        '''
      }
    }
  }

  post {
    always {
      sh 'kubectl get pods,svc,ingress || true'
    }
  }
}
