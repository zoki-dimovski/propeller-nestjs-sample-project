#!/usr/bin/env bash

# Create IAM service account if you don't have created one already.
export PROJECT_ID=my-project-id
export SERVICE_ACCOUNT=my-service-account
gcloud iam service-accounts create "${SERVICE_ACCOUNT}" \
  --project "${PROJECT_ID}"

# Enable IAM API of not enabled already
gcloud services enable iamcredentials.googleapis.com \
  --project "${PROJECT_ID}"

# Create a workload identity pool that will manage the GitHub Action's roles in Google Cloud's permission system.
export WORKLOAD_IDENTITY_POOL=my-pool
gcloud iam workload-identity-pools create "${WORKLOAD_IDENTITY_POOL}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="${WORKLOAD_IDENTITY_POOL}"

# Get the unique identifier of that pool.
gcloud iam workload-identity-pools describe "${WORKLOAD_IDENTITY_POOL}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --format="value(name)"

# Export the returned value to a new variable.
export WORKLOAD_IDENTITY_POOL_ID=whatever-you-got-back

# Create a provider within the pool for GitHub to access.
export WORKLOAD_PROVIDER=my-provider
gcloud iam workload-identity-pools providers create-oidc "${WORKLOAD_PROVIDER}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="${WORKLOAD_IDENTITY_POOL}" \
  --display-name="${WORKLOAD_PROVIDER}" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Allow a GitHub Action based in your repository to login to the service account via the provider.
export REPO=my-username/my-repo
gcloud iam service-accounts add-iam-policy-binding "${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${WORKLOAD_IDENTITY_POOL_ID}/attribute.repository/${REPO}"

# Ask Google to return the identifier of that provider.
# Thsi will return a string that you should save for later. We'll use it in our GitHub Action.
gcloud iam workload-identity-pools providers describe "${WORKLOAD_PROVIDER}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="${WORKLOAD_IDENTITY_POOL}" \
  --format="value(name)"

# Finally, we need to make sure that the service account we created at the start has permission to muck around with Google Artifact Registry.
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.admin"


# To verify that worked, you can ask Google print out the permissions assigned to the service account.
gcloud projects get-iam-policy $PROJECT_ID \
    --flatten="bindings[].members" \
    --format='table(bindings.role)' \
    --filter="bindings.members:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com"
