output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.flask_app.public_ip
}

output "app_url" {
  description = "URL to access the Flask app"
  value       = "http://${aws_instance.flask_app.public_ip}:5000"
}

output "health_url" {
  description = "Health check URL for the Flask app"
  value       = "http://${aws_instance.flask_app.public_ip}:5000/health"
}

output "ssh_command" {
  description = "SSH command to connect to the EC2 instance"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.flask_app.public_ip}"
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name for the Flask app"
  value       = aws_cloudwatch_log_group.flask_app.name
}

output "cloudwatch_log_stream" {
  description = "CloudWatch log stream (EC2 instance ID)"
  value       = aws_instance.flask_app.id
}
