output "cluster_name" {
  description = "Name of the GKE cluster."
  value       = google_container_cluster.gke.name
}

output "cluster_endpoint" {
  description = "GKE cluster API endpoint."
  value       = google_container_cluster.gke.endpoint
}

output "cluster_location" {
  description = "Zone/region the GKE cluster runs in."
  value       = google_container_cluster.gke.location
}

output "cluster_ca" {
  description = "Base64-encoded cluster CA certificate (used to build a kubeconfig)."
  value       = google_container_cluster.gke.master_auth[0].cluster_ca_certificate
  sensitive   = true
}
