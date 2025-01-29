# outputs.tf
output "gke_cluster_name" {
  value = google_container_cluster.primary.name
}

output "cloud_run_url" {
  value = google_cloud_run_service.image_processor.status[0].url
}

output "gcs_bucket_name" {
  value = google_storage_bucket.processed_images.name
}

output "spanner_instance" {
  value = google_spanner_instance.image_metadata.name
}

output "pubsub_topic" {
  value = google_pubsub_topic.image_processed.name
}