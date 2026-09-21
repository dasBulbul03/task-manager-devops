# ========================================
# Terraform Main Configuration
# ========================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
}

# Current Amazon Linux 2023 AMI for the configured region (SSM public parameter)
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ========================================
# VPC Configuration
# ========================================

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# Database Subnet (second AZ - RDS requires subnets covering at least 2 AZs)
resource "aws_subnet" "db" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-db-subnet"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ========================================
# Security Groups
# ========================================

# EC2 Security Group
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # HTTP access for app
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Application port"
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.main.id

  # MySQL port from EC2 only
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
    description     = "MySQL from EC2"
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# ========================================
# Key Pair (Optional - create manually or use existing)
# ========================================

# Uncomment to create a new key pair
# resource "aws_key_pair" "deployer" {
#   key_name   = var.ssh_key_name
#   public_key = file("~/.ssh/id_rsa.pub")
#   
#   tags = {
#     Name = var.ssh_key_name
#   }
# }

# ========================================
# EC2 Instance
# ========================================

resource "aws_instance" "app_server" {
  ami           = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.ec2_instance_type
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = var.ssh_key_name
  iam_instance_profile   = aws_iam_instance_profile.app.name

  # User data - install Docker on Amazon Linux 2023 (AWS CLI v2 is pre-installed)
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              EOF

  tags = {
    Name = "${var.project_name}-ec2"
  }
}

# Elastic IP - stable public address that survives instance recreation.
# Keeps the SSH deploy target fixed even if the EC2 instance is rebuilt.
resource "aws_eip" "app" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-eip"
  }
}

resource "aws_eip_association" "app" {
  instance_id   = aws_instance.app_server.id
  allocation_id = aws_eip.app.id
}

# ========================================
# RDS MySQL Instance
# ========================================

resource "aws_db_instance" "mysql" {
  identifier     = "${var.project_name}-db"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 20
  storage_encrypted     = false

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = {
    Name = "${var.project_name}-rds"
  }
}

# RDS Subnet Group
# NOTE: uses a "-v2" name because an old "taskmanager-db-subnet-group" exists in an
# orphaned VPC (vpc-099f626db3351c21a) and AWS forbids moving a group across VPCs.
# The orphaned group is unused (no RDS instances) and is left untouched.
resource "aws_db_subnet_group" "main" {
  name = "${var.project_name}-db-subnet-group-v2"
  subnet_ids = [
    aws_subnet.public.id,
    aws_subnet.db.id
  ]

  tags = {
    Name = "${var.project_name}-db-subnet-group-v2"
  }
}

# ========================================
# ECR Repository
# ========================================

resource "aws_ecr_repository" "task_manager" {
  name                 = "task-manager"
  image_tag_mutability = "MUTABLE"
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-ecr"
  }
}

# Keep last 5 images so the previous good image is always available for rollback
resource "aws_ecr_lifecycle_policy" "task_manager" {
  repository = aws_ecr_repository.task_manager.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = { type = "expire" }
      }
    ]
  })
}

# ========================================
# IAM Role for EC2 (ECR pull access)
# ========================================

resource "aws_iam_role" "app_instance" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

# Managed policy scoped to pulling container images from ECR only
resource "aws_iam_role_policy_attachment" "app_instance_ecr" {
  role       = aws_iam_role.app_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.app_instance.name
}