#!/bin/bash

# Steps following https://cloud.google.com/run/docs/tutorials/pubsub

PROJECT_ID=peskas
PROJECT_NUMBER=906077803519
_RUN_NAME_="data-transformation"

# 1. Enable Pub/Sub to create authentication tokens in your project

gcloud projects add-iam-policy-binding $PROJECT_ID \
     --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-pubsub.iam.gserviceaccount.com \
     --role=roles/iam.serviceAccountTokenCreator

# 2. Create or select a service account to represent the Pub/Sub subscription identity.

gcloud iam service-accounts create cloud-run-pubsub-invoker \
     --display-name "Cloud Run Pub/Sub Invoker"

# 3. Create a Pub/Sub subscription with the service account

# a.Give the invoker service account permission to invoke your pubsub-tutorial service:
gcloud run services add-iam-policy-binding ${_RUN_NAME_} \
   --member=serviceAccount:cloud-run-pubsub-invoker@${PROJECT_ID}.iam.gserviceaccount.com \
   --role=roles/run.invoker --platform managed

# b. Create a Pub/Sub subscription with the service account
# For timor raw
gcloud pubsub subscriptions create timor-raw-storage-subscription --topic timor-raw-storage \
   --push-endpoint=https://data-transformation-rbfn4deujq-de.a.run.app/transform-timor-pubsub \
   --push-auth-service-account=cloud-run-pubsub-invoker@${PROJECT_ID}.iam.gserviceaccount.com
# For pelagic raw
gcloud pubsub subscriptions create pelagic-raw-storage-subscription --topic pelagic-raw-storage \
   --push-endpoint=https://data-transformation-rbfn4deujq-de.a.run.app/pelagic-timor-pubsub \
   --push-auth-service-account=cloud-run-pubsub-invoker@${PROJECT_ID}.iam.gserviceaccount.com

