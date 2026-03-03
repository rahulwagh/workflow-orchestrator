output "external_ip" {
  description = "External IP address of the GCP VM instance"
  value       = google_compute_instance.flask_app.network_interface[0].access_config[0].nat_ip
}

output "app_url" {
  description = "URL to access the Flask app"
  value       = "http://${google_compute_instance.flask_app.network_interface[0].access_config[0].nat_ip}:5000"
}

output "health_url" {
  description = "Health check URL for the Flask app"
  value       = "http://${google_compute_instance.flask_app.network_interface[0].access_config[0].nat_ip}:5000/health"
}

output "ssh_command" {
  description = "SSH command to connect to the GCP VM instance"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${google_compute_instance.flask_app.network_interface[0].access_config[0].nat_ip}"
}
