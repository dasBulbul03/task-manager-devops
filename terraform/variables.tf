# ========================================
# Terraform Variables
# ========================================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "taskmanager"
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ec2_ami" {
  description = "Ubuntu AMI ID for ap-south-1"
  type        = string
  default     = "ami-0c6b2c08837b3b10d"  # Ubuntu 22.04 LTS in ap-south-1
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t2.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "taskdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "ssh_key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "taskmanager-key"
}