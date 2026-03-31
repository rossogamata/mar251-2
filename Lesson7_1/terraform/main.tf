# ══════════════════════════════════════════════════════════
#  Terraform — Docker on EC2 (AWS Academy Learner Lab)
#  Методології автоматизованого розгортання ІТ інфраструктури
# ══════════════════════════════════════════════════════════

# ── Дані про найновіший Amazon Linux 2023 AMI ──────────────
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── VPC ────────────────────────────────────────────────────
# Ізольована віртуальна мережа — основа будь-якої інфраструктури в AWS
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true  # дозволяє EC2 отримати DNS ім'я
  enable_dns_support   = true

  tags = { Name = "docker-lab-vpc" }
}

# ── Публічна підмережа ─────────────────────────────────────
# Підмережа, ресурси якої можуть отримати публічну IP адресу
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true  # EC2 у цій підмережі отримають публічну IP

  tags = { Name = "docker-lab-public-subnet" }
}

# ── Internet Gateway ───────────────────────────────────────
# Шлюз між VPC та інтернетом. Без нього EC2 не матиме доступу до мережі.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "docker-lab-igw" }
}

# ── Route Table ────────────────────────────────────────────
# Таблиця маршрутизації для публічної підмережі
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "docker-lab-public-rt" }
}

# ── Route ──────────────────────────────────────────────────
# Маршрут за замовчуванням: увесь трафік (0.0.0.0/0) → Internet Gateway
resource "aws_route" "default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# ── Асоціація Route Table з підмережею ─────────────────────
# Пов'язуємо таблицю маршрутизації з публічною підмережею
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ── Security Group ─────────────────────────────────────────
# Міжмережевий екран інстансу: дозволяємо SSH (22) та HTTP (80)
resource "aws_security_group" "docker_lab" {
  name        = "docker-lab-sg"
  description = "SSH + HTTP для Docker Lab"
  vpc_id      = aws_vpc.main.id

  # Дозволяємо вхідний SSH з будь-якої IP адреси
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Дозволяємо вхідний HTTP — для доступу до контейнера
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Дозволяємо весь вихідний трафік (для оновлень, docker pull тощо)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "docker-lab-sg" }
}

# ── EC2 Instance ───────────────────────────────────────────
# Сервер, на якому запустимо Docker контейнер
resource "aws_instance" "docker_host" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.docker_lab.id]
  key_name               = var.key_name

  # user_data — скрипт, який виконується при першому старті інстансу.
  # Встановлюємо Docker та одразу запускаємо наш контейнер.
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Оновлення пакетів
    dnf update -y

    # Встановлення Docker
    dnf install -y docker

    # Запуск та автозапуск сервісу Docker
    systemctl start docker
    systemctl enable docker

    # Додаємо ec2-user до групи docker (щоб не писати sudo перед кожною командою)
    usermod -aG docker ec2-user

    # Завантажуємо та запускаємо контейнер
    # -d      — запуск у фоні (detached mode)
    # --restart always — автоматичний перезапуск при падінні або перезавантаженні
    # -p 80:80 — пробрасовуємо порт хоста 80 на порт контейнера 80
    docker run -d \
      --name devops-landing \
      --restart always \
      -p 80:80 \
      ${var.container_image}
  EOF

  tags = { Name = "docker-lab-host" }
}
