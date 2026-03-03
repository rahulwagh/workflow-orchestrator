output "aws_ec2_public_ip" {
  description = "Public IP address of the AWS EC2 instance"
  value       = module.aws.public_ip
}

output "aws_app_url" {
  description = "URL to access the Flask app on AWS"
  value       = module.aws.app_url
}

output "aws_health_check_url" {
  description = "Health check URL for the Flask app on AWS"
  value       = module.aws.health_url
}

output "aws_ssh_command" {
  description = "SSH command to connect to the AWS EC2 instance"
  value       = module.aws.ssh_command
}

output "aws_cloudwatch_log_group" {
  description = "CloudWatch log group streaming Flask app logs"
  value       = module.aws.cloudwatch_log_group
}

output "aws_cloudwatch_log_stream" {
  description = "CloudWatch log stream (EC2 instance ID)"
  value       = module.aws.cloudwatch_log_stream
}

output "gcp_vm_external_ip" {
  description = "External IP address of the GCP VM instance"
  value       = module.gcp.external_ip
}

output "gcp_app_url" {
  description = "URL to access the Flask app on GCP"
  value       = module.gcp.app_url
}

output "gcp_health_check_url" {
  description = "Health check URL for the Flask app on GCP"
  value       = module.gcp.health_url
}

output "gcp_ssh_command" {
  description = "SSH command to connect to the GCP VM instance"
  value       = module.gcp.ssh_command
}
