#!/bin/bash

# Steps following https://cloud.google.com/run/docs/tutorials/pubsub
# Before running this steps ensure that the topics and notifications for the
# storage buckets already exist

PROJECT_ID=peskas
PROJECT_NUMBER=906077803519
_RUN_NAME_="data-transformation"
TIMOR_BUCKET=timor
TIMOR_TOPIC="timor-raw-structured-update"
PELAGIC_BUCKET="pelagic-data-systems-raw"
PELAGIC_TOPIC="pelagic-raw-update"

# 1. Create topics
# For Timor
gcloud pubsub topics create ${TIMOR_TOPIC} \
   --project=${PROJECT_ID}
# For Pelagic
gcloud pubsub topics create ${PELAGIC_TOPIC} \
  --project=${PROJECT_ID}

# 2. Setup notifications from the buckets. Only when new data is added
# For Timor we're only interested in the structured data for now
gsutil notification create \
   -t ${TIMOR_TOPIC} \
   -f json \
   -e OBJECT_FINALIZE \
   -p catch_timor_structured \
   gs://${TIMOR_BUCKET}
# For Pelagic
gsutil notification create \
   -t ${PELAGIC_TOPIC} \
   -f json \
   -e OBJECT_FINALIZE \
   -p pelagic-data_ \
   gs://${PELAGIC_BUCKET}

# 3. Enable Pub/Sub to create authentication tokens in your project
gcloud projects add-iam-policy-binding $PROJECT_ID \
   --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-pubsub.iam.gserviceaccount.com \
   --role=roles/iam.serviceAccountTokenCreator

# 4. Create or select a service account to represent the Pub/Sub subscription identity.
gcloud iam service-accounts create cloud-run-pubsub-invoker \
   --display-name "Cloud Run Pub/Sub Invoker"

# 5 .Give the invoker service account permission to invoke your pubsub-tutorial service:
gcloud run services add-iam-policy-binding ${_RUN_NAME_} \
   --member=serviceAccount:cloud-run-pubsub-invoker@${PROJECT_ID}.iam.gserviceaccount.com \
   --role=roles/run.invoker --platform managed

# 6. Create a Pub/Sub subscription with the service account
# For timor raw
gcloud pubsub subscriptions create timor-raw-storage-subscription \
   --topic ${TIMOR_TOPIC} \
   --topic-project=${PROJECT_ID} \
   --push-endpoint=https://data-transformation-rbfn4deujq-de.a.run.app/transform-data-pubsub \
   --push-auth-service-account=cloud-run-pubsub-invoker@${PROJECT_ID}.iam.gserviceaccount.com \
   --ack-deadline=600 \
   --min-retry-delay=60s \
   --max-retry-delay=600s
# For pelagic raw
gcloud pubsub subscriptions create pelagic-raw-storage-subscription \
   --topic ${PELAGIC_TOPIC} \
   --topic-project=${PROJECT_ID} \
   --push-endpoint=https://data-transformation-rbfn4deujq-de.a.run.app/transform-data-pubsub \
   --push-auth-service-account=cloud-run-pubsub-invoker@${PROJECT_ID}.iam.gserviceaccount.com \
   --ack-deadline=600 \
   --min-retry-delay=60s \
   --max-retry-delay=600s
