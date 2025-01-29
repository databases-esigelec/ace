# main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  credentials = file(var.credentials)
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "container.googleapis.com",      # GKE
    "cloudfunctions.googleapis.com", # Cloud Functions
    "run.googleapis.com",           # Cloud Run
    "spanner.googleapis.com",       # Cloud Spanner
    "pubsub.googleapis.com",        # Pub/Sub
    "cloudbuild.googleapis.com",    # Cloud Build
    "artifactregistry.googleapis.com"
  ])

  service = each.key
  disable_dependent_services = true
}

# GCS bucket for processed images
resource "google_storage_bucket" "processed_images" {
  name     = "${var.project_id}-processed-images"
  location = var.region
  uniform_bucket_level_access = true
}

# Pub/Sub topic
resource "google_pubsub_topic" "image_processed" {
  name = "image-processed"
}

# Cloud Spanner
resource "google_spanner_instance" "image_metadata" {
  name         = "image-metadata"
  config       = "regional-${var.region}"
  display_name = "Image Metadata Instance"
  num_nodes    = 1
}

resource "google_spanner_database" "image_db" {
  instance = google_spanner_instance.image_metadata.name
  name     = "image-db"
  ddl = [
    "CREATE TABLE ImageMetadata (ImageId STRING(36) NOT NULL, OriginalName STRING(1024), ProcessingStatus STRING(20), StoragePath STRING(2048), ProcessedAt TIMESTAMP, Tags ARRAY<STRING>) PRIMARY KEY (ImageId)"
  ]
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "image-processing-cluster"
  location = var.zone

  initial_node_count = 1

  node_config {
    machine_type = "e2-medium"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

# Service Accounts
resource "google_service_account" "image_processor" {
  account_id   = "image-processor"
  display_name = "Image Processor Service Account"
}

resource "google_service_account" "metadata_processor" {
  account_id   = "metadata-processor"
  display_name = "Metadata Processor Service Account"
}

resource "google_service_account" "frontend" {
  account_id   = "frontend-sa"
  display_name = "Frontend Service Account"
}

# IAM bindings
resource "google_project_iam_member" "image_processor_storage" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.image_processor.email}"
}

resource "google_project_iam_member" "image_processor_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.image_processor.email}"
}

resource "google_project_iam_member" "metadata_processor_spanner" {
  project = var.project_id
  role    = "roles/spanner.databaseUser"
  member  = "serviceAccount:${google_service_account.metadata_processor.email}"
}

# Cloud Run service
resource "google_cloud_run_service" "image_processor" {
  name     = "image-processor"
  location = var.region


  template {
    spec {
      containers {

        image = "gcr.io/${var.project_id}/image-processor:latest"

        resources {
          limits = {
            memory = "1Gi"
            cpu    = "1000m"
          }
        }
        env {
          name  = "STORAGE_BUCKET"
          value = google_storage_bucket.processed_images.name
        }
      }
      service_account_name = google_service_account.image_processor.email
      timeout_seconds = 300
    }
  }

  depends_on = [google_project_service.required_apis]
}

# Cloud Function
data "archive_file" "function_source" {
  type        = "zip"
  output_path = "${path.module}/function-source.zip"
  source_dir  = "${dirname(path.cwd)}/metadata_processor"
}


resource "google_storage_bucket" "function_source" {
  name     = "${var.project_id}-function-source"
  location = var.region
}

# Upload the source code to GCS
resource "google_storage_bucket_object" "function_source" {
  name   = "function-source-${data.archive_file.function_source.output_md5}.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.function_source.output_path
}

resource "google_cloudfunctions2_function" "metadata_processor" {
  name     = "process-metadata"
  location = var.region

  build_config {
    runtime     = "python39"
    entry_point = "process_metadata"
    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.function_source.name
      }
    }
  }

  service_config {
    max_instance_count = 10
    available_memory   = "256M"
    timeout_seconds    = 60
    service_account_email = google_service_account.metadata_processor.email
  }

  event_trigger {
    trigger_region = var.region
    event_type    = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic  = google_pubsub_topic.image_processed.id
  }
}