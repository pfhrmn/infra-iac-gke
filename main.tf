resource "google_compute_network" "vpc" {
  name = "platform-vpc"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "platform-subnet"
  ip_cidr_range = "10.0.0.0/20"
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_container_cluster" "gke" {
  name     = "platform-cluster"
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 1

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

resource "google_container_node_pool" "default_pool" {
  name       = "default-pool"
  cluster    = google_container_cluster.gke.name
  location   = var.zone

  node_count = 2

  node_config {
    machine_type = "e2-medium"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

resource "google_service_account" "app_sa" {
  account_id   = "app-service-account"
  display_name = "App Service Account"
}

resource "google_project_iam_member" "app_sa_workload_identity" {
  project = var.project_id
  role    = "roles/iam.workloadIdentityUser"
  member  = "serviceAccount:${var.project_id}.svc.id.goog[default/app-sa]"
}

resource "kubernetes_service_account" "app_sa" {
  metadata {
    name      = "app-sa"
    namespace = "default"
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.app_sa.email
    }
  }
}

resource "google_dns_managed_zone" "platform_zone" {
  name        = "platform-zone"
  dns_name    = "platform.local."
  description = "DNS zone for platform services"
}
