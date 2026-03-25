output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_a_id" {
  description = "Subnet A ID (us-east-1a)"
  value       = aws_subnet.subnet_a.id
}

output "subnet_b_id" {
  description = "Subnet B ID (us-east-1b)"
  value       = aws_subnet.subnet_b.id
}

output "web_server_id" {
  description = "WebServer EC2 Instance ID"
  value       = aws_instance.web_server.id
}

output "app_server_id" {
  description = "AppServer EC2 Instance ID"
  value       = aws_instance.app_server.id
}

output "elastic_ip" {
  description = "Elastic IP address (associated with WebServer)"
  value       = aws_eip.web_server.public_ip
}

output "web_server_url" {
  description = "WebServer URL — wait ~2 min for Apache to install via user-data"
  value       = "http://${aws_eip.web_server.public_ip}"
}

output "app_server_public_ip" {
  description = "AppServer public IP (auto-assigned, changes on restart)"
  value       = aws_instance.app_server.public_ip
}
