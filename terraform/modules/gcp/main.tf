# ─── VPC Network ──────────────────────────────────────────────────────────────

resource "google_compute_network" "main" {
  name                    = "flask-app-vpc"
  auto_create_subnetworks = false
}

# ─── Subnet ───────────────────────────────────────────────────────────────────

resource "google_compute_subnetwork" "public" {
  name          = "flask-app-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id
}

# ─── Firewall Rules ───────────────────────────────────────────────────────────

resource "google_compute_firewall" "allow_ssh" {
  name    = "flask-app-allow-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["flask-app"]
}

resource "google_compute_firewall" "allow_flask" {
  name    = "flask-app-allow-flask"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["5000"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["flask-app"]
}

resource "google_compute_firewall" "allow_egress" {
  name    = "flask-app-allow-egress"
  network = google_compute_network.main.name

  allow {
    protocol = "all"
  }

  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]
  target_tags        = ["flask-app"]
}

# ─── Cloud Router ─────────────────────────────────────────────────────────────

resource "google_compute_router" "main" {
  name    = "flask-app-router"
  region  = var.region
  network = google_compute_network.main.id
}

# ─── Cloud NAT ────────────────────────────────────────────────────────────────

resource "google_compute_router_nat" "main" {
  name                               = "flask-app-nat"
  router                             = google_compute_router.main.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# ─── VM Instance ──────────────────────────────────────────────────────────────

resource "google_compute_instance" "flask_app" {
  name         = "flask-app-vm"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["flask-app"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.main.id
    subnetwork = google_compute_subnetwork.public.id

    access_config {
      # Ephemeral external IP
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  metadata_startup_script = templatefile("${path.root}/scripts/gcp_startup.sh.tpl", {
    app_py = file("${path.root}/app/app.py")
  })
}
