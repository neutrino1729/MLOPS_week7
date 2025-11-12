#!/bin/bash

PROJECT_ID="theta-index-472515-d8"
REGION="us-central1"
ZONE="us-central1-a"
CLUSTER_NAME="iris-cluster"
REPO_NAME="iris-repo"
SA_NAME="github-actions-sa"

echo "Setting up GCP resources..."

# Set project
gcloud config set project $PROJECT_ID

# Enable APIs
echo "Enabling required APIs..."
gcloud services enable \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  compute.googleapis.com

# Create Artifact Registry
echo "Creating Artifact Registry..."
gcloud artifacts repositories create $REPO_NAME \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker repo for Iris API" || echo "Repository exists"

# Create GKE cluster
echo "Creating GKE cluster..."
gcloud container clusters create $CLUSTER_NAME \
  --zone=$ZONE \
  --num-nodes=2 \
  --enable-autoscaling \
  --min-nodes=1 \
  --max-nodes=5 \
  --machine-type=e2-medium || echo "Cluster exists"

# Create service account
echo "Creating service account..."
gcloud iam service-accounts create $SA_NAME \
  --display-name="GitHub Actions SA" || echo "SA exists"

# Grant permissions
echo "Granting permissions..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/container.developer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectViewer"

# Create key
echo "Creating service account key..."
gcloud iam service-accounts keys create ~/gcp-key.json \
  --iam-account=$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com

echo "========================================"
echo "Setup complete!"
echo "Copy the JSON below to GitHub secrets as GCP_SA_KEY:"
echo "========================================"
cat ~/gcp-key.json
