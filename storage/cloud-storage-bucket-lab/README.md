# Cloud Storage: Qwik Start - CLI/SDK

This repository contains the commands and workflow for the Cloud Storage: Qwik Start - CLI/SDK lab. This project demonstrates how to perform basic Google Cloud Storage operations using the gcloud storage commands and gsutil command-line tools within Google Cloud Shell.

## Overview

- In this lab, I utilized the Google Cloud SDK to perform the following operations:
- Creating a Cloud Storage bucket.
- Uploading and downloading objects.
- Copying objects between buckets and folders.
- Listing bucket contents and object details.
- Managing Access Control Lists (ACLs) to make objects public and private.

## Prerequisites

- Google Cloud Platform Account
- Google Cloud Shell (Pre-installed with gcloud and gsutil)
- Active Project ID

## Configuration
Before running the commands, ensure the region is set correctly for the project:

```bash
gcloud config set compute/region "us-east-1"
```

## Command Reference
Replace <YOUR-BUCKET-NAME> with your unique bucket identifier.

1. Create a Bucket
Creates a new standard storage bucket. Note: Bucket names must be globally unique.

```bash
gcloud storage buckets create gs://<YOUR-BUCKET-NAME>
```

2. Upload Objects
First, retrieve a sample image (Ada Lovelace) to the local environment, then upload it to the bucket.

```bash
# Download sample image
curl https://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Ada_Lovelace_portrait.jpg/800px-Ada_Lovelace_portrait.jpg --output ada.jpg

# Upload to bucket
gcloud storage cp ada.jpg gs://<YOUR-BUCKET-NAME>

# Clean up local file
rm ada.jpg
```

3. Download Objects
Download the file from the bucket back to the local Cloud Shell environment.

```bash
gcloud storage cp -r gs://<YOUR-BUCKET-NAME>/ada.jpg .
```

4. Create Folders & Copy Objects
Cloud Storage uses a flat namespace, but "folders" can be simulated. The trailing slash / is required.

```bash
gcloud storage cp gs://<YOUR-BUCKET-NAME>/ada.jpg gs://<YOUR-BUCKET-NAME>/image-folder/
```

5. List & Inspect Objects
List all contents of the bucket and view specific file details (size, creation date, etc.).

```bash
# List contents
gcloud storage ls gs://<YOUR-BUCKET-NAME>

# List object details
gcloud storage ls -l gs://<YOUR-BUCKET-NAME>/ada.jpg
```

6. Manage Access (ACLs)
Using gsutil to manage Access Control Lists.

Make Object Public:

```bash
gsutil acl ch -u AllUsers:R gs://<YOUR-BUCKET-NAME>/ada.jpg
```

Remove Public Access:

```bash
gsutil acl ch -d AllUsers gs://<YOUR-BUCKET-NAME>/ada.jpg
```

7. Clean Up
Remove the object from the bucket.

```bash
gcloud storage rm gs://<YOUR-BUCKET-NAME>/ada.jpg
```

## Key Concepts & Rules

### Bucket Naming Rules

- Globally unique namespace.
- Lowercase letters, numbers, dashes, underscores, and dots.
- No sensitive info (names are public).
- Cannot start with "goog" or contain "google".

### Knowledge Check

- Storage Class: Each bucket has a default storage class that can be specified upon creation.
- ACL (Access Control List): A mechanism to define who has access to buckets and objects.
- Revoking Public Access: To stop sharing an object publicly, remove the permission entry for allUsers.

**Disclaimer: This is a log of commands run during a Google Cloud Skills Boost lab. Do not include sensitive Project IDs or credentials in public repositories.**
