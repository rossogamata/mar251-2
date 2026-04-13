output "instance_public_ip" {
  description = "Публічна IP адреса EC2 інстансу"
  value       = aws_instance.ansible_target.public_ip
}

output "instance_public_dns" {
  description = "Публічне DNS ім'я EC2 інстансу"
  value       = aws_instance.ansible_target.public_dns
}

output "ssh_command" {
  description = "Команда для підключення по SSH"
  value       = "ssh -i vockey.pem ec2-user@${aws_instance.ansible_target.public_ip}"
}

output "ansible_inventory_entry" {
  description = "Рядок для вставки в ansible/inventory/hosts.ini"
  value       = "${aws_instance.ansible_target.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=../vockey.pem"
}
