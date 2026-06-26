# --- Monitoring (Bonus) -----------------------------------------------------
# Managed Prometheus ist am Cluster aktiviert (siehe monitoring_config in
# google_container_cluster.gke). Dieses Cloud-Monitoring-Dashboard visualisiert
# pro Tenant-Namespace: CPU, Speicher, Container-Restarts und laufende Pods.
#
# Das JSON wurde aus dem laufenden Projekt exportiert und ist damit als Code
# reproduzierbar (Dashboard-as-Code). Siehe auch docs/monitoring im GitOps-Repo.

resource "google_monitoring_dashboard" "tenant_app" {
  dashboard_json = file("${path.module}/monitoring/tenant-app-dashboard.json")
}
