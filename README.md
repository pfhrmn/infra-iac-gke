# 📘 infra-iac-gke

Dieses Repository enthält die Infrastructure-as-Code (IaC) Konfiguration für die Plattform.  
Die Infrastruktur wird vollständig mit **Terraform** in Google Cloud bereitgestellt und bildet die Grundlage für das GitOps‑Repository (*platform-gitops*).

---

## Zweck dieses Repositories

Dieses Repository stellt die komplette Basisinfrastruktur bereit, die später von ArgoCD und dem GitOps‑Workflow genutzt wird.

Es provisioniert:

- ein **Netzwerk** (VPC + Subnet) und einen **GKE‑Cluster** (zonal, Workload Identity)
- die **Node‑Pools** (e2-medium + e2-standard-2)
- die **Cloud‑DNS‑Zone** `gcloud.it-n.at` (delegierte Subdomain)
- eine **Artifact Registry** für die Tenant‑App‑Images
- **Service Accounts + Workload‑Identity‑Bindings** für ExternalDNS, cert-manager und den External Secrets Operator
- das **Cloud‑Monitoring‑Dashboard** (Bonus, siehe [`monitoring.tf`](monitoring.tf))

DNS‑Einträge (A‑Records) und TLS‑Zertifikate werden anschließend automatisiert über ExternalDNS und cert-manager im GitOps‑Repo erzeugt – nicht über Terraform.

Damit wird die gesamte Infrastruktur automatisiert, reproduzierbar und versioniert bereitgestellt.

---

## Terraform ausführen

Um die Infrastruktur zu erstellen, werden folgende Schritte ausgeführt:

```bash
terraform init
terraform plan
terraform apply
```

---

## Screenshots / Nachweis

![Produktions-Tenant](docs/screenshots/production.jpg)

*Die von dieser IaC bereitgestellte Plattform – Produktions-Tenant live unter https://production.gcloud.it-n.at*

![Pods](docs/screenshots/pods.jpg)

*Laufende Pods im provisionierten Cluster (kubectl get pods -A)*
