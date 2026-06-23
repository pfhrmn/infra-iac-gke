resource "google_compute_network" "vpc" {
  name = "platform-vpc"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "platform-subnet"
  ip_cidr_range = "10.0.0.0/20"
  region        = var.region
  network       = google_compute_network.vpc.id
}
