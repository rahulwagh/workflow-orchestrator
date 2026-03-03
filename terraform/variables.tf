# ─── AWS Variables ───────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "aws_key_name" {
  description = "Name of the AWS key pair to create"
  type        = string
  default     = "flask-app-key"
}

variable "aws_public_key_path" {
  description = "Path to the SSH public key file for AWS EC2"
  type        = string
  default     = "/Users/rahulwagh/Downloads/aws-demo/rwagh_aws_key.pub"
}

variable "aws_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for the EC2 Flask app"
  type        = string
  default     = "/flask-app/ec2/app-logs"
}

variable "log_retention_days" {
  description = "Days to retain CloudWatch logs"
  type        = number
  default     = 7
}

# ─── GCP Variables ───────────────────────────────────────────────────────────

variable "gcp_project_id" {
  description = "GCP project ID (required)"
  type        = string
  default = "cl-demo-sandbox"
}

variable "gcp_region" {
  description = "GCP region to deploy resources"
  type        = string
  default     = "europe-north2"
}

variable "gcp_zone" {
  description = "GCP zone to deploy resources"
  type        = string
  default     = "europe-north2-a"
}

variable "gcp_machine_type" {
  description = "GCP VM machine type"
  type        = string
  default     = "e2-micro"
}

variable "gcp_ssh_user" {
  description = "SSH username for GCP VM"
  type        = string
  default     = "ubuntu"
}

variable "gcp_ssh_public_key_path" {
  description = "Path to the SSH public key file for GCP VM"
  type        = string
  default     = "/Users/rahulwagh/Downloads/aws-demo/rwagh_aws_key.pub"
}
