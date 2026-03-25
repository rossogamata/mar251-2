# ─────────────────────────────────────────────
# AMI — latest Amazon Linux 2023
# ─────────────────────────────────────────────

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ─────────────────────────────────────────────
# EC2 Instances
# ─────────────────────────────────────────────

resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet_a.id
  vpc_security_group_ids = [aws_security_group.main.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>WebServer — Subnet A ($(hostname -I))</h1>" > /var/www/html/index.html
  EOF

  tags = { Name = "WebServer" }
}

resource "aws_instance" "mat251_252_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet_b.id
  vpc_security_group_ids = [aws_security_group.main.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>AppServer — Subnet B ($(hostname -I))</h1>" > /var/www/html/index.html
  EOF

  tags = { Name = "AppServer" }
}

# ─────────────────────────────────────────────
# Elastic IP — allocated and associated with WebServer
# ─────────────────────────────────────────────

resource "aws_eip" "web_server" {
  instance = aws_instance.web_server.id
  domain   = "vpc"

  # EIP depends on IGW being attached first
  depends_on = [aws_internet_gateway.main]

  tags = { Name = "academy-eip" }
}
