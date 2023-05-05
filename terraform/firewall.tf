resource "google_compute_firewall" "default" {
  name    = "${var.project_id}-firewall"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_tags = ["web"]
}
