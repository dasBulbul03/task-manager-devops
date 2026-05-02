# ========================================
# Terraform Outputs
# ========================================

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.app_server.public_dns
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint"
  value       = aws_db_instance.mysql.endpoint
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.mysql.db_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "security_group_id" {
  description = "EC2 Security Group ID"
  value       = aws_security_group.ec2.id
}

output "connection_info" {
  description = "Connection information for SSH and app access"
  value       = <<-EOT
    SSH Command: ssh ubuntu@${aws_instance.app_server.public_ip}
    App URL: http://${aws_instance.app_server.public_ip}:8080
    RDS Endpoint: ${aws_db_instance.mysql.endpoint}
  EOT
}