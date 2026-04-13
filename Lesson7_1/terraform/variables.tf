variable "aws_region" {
  description = "AWS регіон для розгортання ресурсів"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR блок для VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR блок для публічної підмережі"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "Тип EC2 інстансу"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Ім'я EC2 Key Pair для SSH доступу (в AWS Academy використовуй 'vockey')"
  type        = string
  default     = "vockey"
}

variable "container_image" {
  description = "Docker image для запуску (наприклад: rossogamata/devops-landing:latest)"
  type        = string
  default     = "rossogamata/devops-landing:latest"
}

variable "container_port" {
  description = "Порт, на якому контейнер слухає трафік"
  type        = number
  default     = 80
}
