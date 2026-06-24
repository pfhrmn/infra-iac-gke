# Reconciliation der im Betrieb angelegten Ressourcen, damit die Plattform
# vollständig über IaC reproduzierbar ist ("keine Klicks"-Purity).
#
# Hinweis: Diese Ressourcen existieren in der laufenden Umgebung bereits (live
# angelegt). Für ein bestehendes Projekt per `terraform import` übernehmen; für
# eine frische Bereitstellung werden sie von Terraform erzeugt.

# --- benötigte APIs --------------------------------------------------------
resource "google_project_service" "apis" {
  for_each = toset([
    "container.googleapis.com",
    "dns.googleapis.com",
    "secretmanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
  ])
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# --- zusätzlicher Node-Pool (Kapazität für Plattform + Tenants) -------------
# pd-standard, da die regionale SSD-Quota durch die pd-balanced-Nodes belegt war.
resource "google_container_node_pool" "boost_pool" {
  name     = "boost-pool"
  cluster  = google_container_cluster.gke.name
  location = var.zone

  node_count = 1

  node_config {
    machine_type = "e2-standard-2"
    disk_type    = "pd-standard"
    disk_size_gb = 40
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}

# --- delegierte DNS-Zone für die Plattform ---------------------------------
# NS dieser Zone (ns-cloud-aX.googledomains.com) sind beim it-n.at-Registrar eingetragen.
resource "google_dns_managed_zone" "gcloud_it_n_at" {
  name        = "gcloud-it-n-at"
  dns_name    = "gcloud.it-n.at."
  description = "Delegated subdomain gcloud.it-n.at for the platform"
  visibility  = "public"
}

# --- Artifact Registry für die Tenant-App-Images ---------------------------
resource "google_artifact_registry_repository" "apps" {
  location      = var.region
  repository_id = "apps"
  format        = "DOCKER"
  description   = "Tenant application images (backend/frontend)"
}

# --- ExternalDNS- + cert-manager-Identität (Cloud DNS via Workload Identity)
resource "google_service_account" "externaldns" {
  account_id   = "externaldns-sa"
  display_name = "ExternalDNS Service Account"
}

resource "google_project_iam_member" "externaldns_dns_admin" {
  project = var.project_id
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.externaldns.email}"
}

# WI-Binding korrekt auf der GSA (nicht projektweit) – nutzbar von ExternalDNS
resource "google_service_account_iam_member" "externaldns_wi" {
  service_account_id = google_service_account.externaldns.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[external-dns/external-dns]"
}

# dieselbe GSA wird von cert-manager (DNS-01) mitgenutzt
resource "google_service_account_iam_member" "certmanager_wi" {
  service_account_id = google_service_account.externaldns.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[cert-manager/cert-manager]"
}

# --- External-Secrets-Identität (GCP Secret Manager via Workload Identity) --
resource "google_service_account" "eso" {
  account_id   = "eso-sa"
  display_name = "ESO Service Account"
}

resource "google_project_iam_member" "eso_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.eso.email}"
}

resource "google_service_account_iam_member" "eso_wi" {
  service_account_id = google_service_account.eso.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[external-secrets/eso-sa]"
}
