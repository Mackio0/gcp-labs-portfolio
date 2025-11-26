# Cloud Run Lab: Hello World (Node.js)

This project demonstrates a basic containerized Node.js application deployed to Google Cloud Run. It covers the lifecycle of building a container image, pushing it to the registry, and deploying it as a serverless service.

# 🛠️ Setup & Configuration

Run these commands in Cloud Shell or your local terminal initialized with the Google Cloud SDK.

## 1. Environment Variables

Set these variables first so all subsequent commands work dynamically.

```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION="us-east4"
export IMAGE_NAME="helloworld"
export IMAGE_URI="gcr.io/${PROJECT_ID}/${IMAGE_NAME}"
```

## 2. Enable APIs

Ensure the necessary services are active.

```bash
gcloud services enable run.googleapis.com \
    cloudbuild.googleapis.com
```

## 3. 📦 Build & Publish

We use Cloud Build to build the Docker image and push it to the Container Registry.

```bash
# Submit the build
gcloud builds submit --tag $IMAGE_URI
```

Verification:

```bash
# List images to confirm successful push
gcloud container images list
```

## 4. 🧪 Local Testing (Optional)

To test the container locally (or inside Cloud Shell) before deploying:

```bash
# Configure docker auth
gcloud auth configure-docker

# Run the container detached
docker run -d -p 8080:8080 $IMAGE_URI
```

You can now preview the application on Web Preview port 8080.

## 5. 🚀 Deployment

Deploy the container to Cloud Run as a managed service.

```bash
gcloud run deploy $IMAGE_NAME \
    --image $IMAGE_URI \
    --region $REGION \
    --allow-unauthenticated
```

## 6. 🧹 Clean Up

To avoid incurring charges, remove the service and the container image.

```bash
# Delete the Service
gcloud run services delete $IMAGE_NAME --region $REGION --quiet

# Delete the Image
gcloud container images delete $IMAGE_URI --quiet
```
