module "aws" {
  source = "./modules/aws"

  region                    = var.aws_region
  key_name                  = var.aws_key_name
  public_key_path           = var.aws_public_key_path
  instance_type             = var.aws_instance_type
  cloudwatch_log_group_name = var.cloudwatch_log_group_name
  log_retention_days        = var.log_retention_days
}

module "gcp" {
  source = "./modules/gcp"

  project_id          = var.gcp_project_id
  region              = var.gcp_region
  zone                = var.gcp_zone
  machine_type        = var.gcp_machine_type
  ssh_user            = var.gcp_ssh_user
  ssh_public_key_path = var.gcp_ssh_public_key_path
}
