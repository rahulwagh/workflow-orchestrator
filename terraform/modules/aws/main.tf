# ─── IAM Role for EC2 (CloudWatch Agent) ─────────────────────────────────────

resource "aws_iam_role" "flask_app" {
  name = "flask-app-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "flask-app-ec2-role"
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.flask_app.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "flask_app" {
  name = "flask-app-ec2-profile"
  role = aws_iam_role.flask_app.name
}

# ─── CloudWatch Log Group ─────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "flask_app" {
  name              = var.cloudwatch_log_group_name
  retention_in_days = var.log_retention_days

  tags = {
    Name = "flask-app-logs"
  }
}

# ─── CloudWatch Metric Filters ────────────────────────────────────────────────
#
# Each filter watches the log group for a pattern and increments a custom
# metric in the "FlaskApp/Logs" namespace whenever a matching line arrives.
# Kestra's io.kestra.plugin.aws.cloudwatch.Query can then query these metrics.

resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "flask-app-error-count"
  log_group_name = aws_cloudwatch_log_group.flask_app.name
  pattern        = "\"[ERROR]\""

  metric_transformation {
    name      = "ErrorCount"
    namespace = "FlaskApp/Logs"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "warning_count" {
  name           = "flask-app-warning-count"
  log_group_name = aws_cloudwatch_log_group.flask_app.name
  pattern        = "\"[WARNING]\""

  metric_transformation {
    name      = "WarningCount"
    namespace = "FlaskApp/Logs"
    value     = "1"
  }
}

# ─── VPC ─────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "flask-app-vpc"
  }
}

# ─── Internet Gateway ─────────────────────────────────────────────────────────

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "flask-app-igw"
  }
}

# ─── Public Subnet ────────────────────────────────────────────────────────────

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "flask-app-public-subnet"
  }
}

# ─── Route Table ──────────────────────────────────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "flask-app-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ─── Security Group ───────────────────────────────────────────────────────────

resource "aws_security_group" "flask_app" {
  name        = "flask-app-sg"
  description = "Security group for Flask app EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Flask app port"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "flask-app-sg"
  }
}

# ─── Key Pair ─────────────────────────────────────────────────────────────────

resource "aws_key_pair" "flask_app" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# ─── AMI Lookup (Ubuntu 22.04 LTS) ───────────────────────────────────────────

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ─── EC2 Instance ─────────────────────────────────────────────────────────────

resource "aws_instance" "flask_app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.flask_app.id]
  key_name               = aws_key_pair.flask_app.key_name
  iam_instance_profile   = aws_iam_instance_profile.flask_app.name

  user_data = templatefile("${path.root}/scripts/aws_user_data.sh.tpl", {
    app_py               = file("${path.root}/app/app.py")
    cloudwatch_log_group = aws_cloudwatch_log_group.flask_app.name
    region               = var.region
  })

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
  }

  tags = {
    Name = "flask-app-ec2"
  }
}
