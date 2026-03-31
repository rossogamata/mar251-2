output "instance_public_ip" {
  description = "Публічна IP адреса EC2 інстансу"
  value       = aws_instance.docker_host.public_ip
}

output "instance_public_dns" {
  description = "Публічне DNS ім'я EC2 інстансу"
  value       = aws_instance.docker_host.public_dns
}

output "ssh_command" {
  description = "Команда для підключення по SSH"
  value       = "ssh -i vockey.pem ec2-user@${aws_instance.docker_host.public_ip}"
}

output "app_url" {
  description = "URL для доступу до застосунку"
  value       = "http://${aws_instance.docker_host.public_ip}"
}
