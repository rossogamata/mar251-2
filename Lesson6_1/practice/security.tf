# ─────────────────────────────────────────────
# Network ACL (subnet-level, stateless)
# ─────────────────────────────────────────────

resource "aws_network_acl" "main" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]

  # ── INBOUND RULES ──────────────────────────

  # Rule 100 — SSH
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    from_port  = 22
    to_port    = 22
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Rule 110 — HTTP
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Rule 120 — ICMP (ping)
  ingress {
    rule_no    = 120
    protocol   = "icmp"
    from_port  = -1
    to_port    = -1
    icmp_type  = -1
    icmp_code  = -1
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Rule 130 — Ephemeral ports (NACL is stateless — responses need explicit rule)
  ingress {
    rule_no    = 130
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # ── OUTBOUND RULES ─────────────────────────

  # Rule 100 — All outbound
  egress {
    rule_no    = 100
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  tags = { Name = "academy-nacl" }
}

# ─────────────────────────────────────────────
# Security Group (instance-level, stateful)
# ─────────────────────────────────────────────

resource "aws_security_group" "main" {
  name        = "academy-sg"
  description = "Security Group for Academy Lab"
  vpc_id      = aws_vpc.main.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ICMP (ping)
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound (SG is stateful — this covers responses automatically,
  # but explicit egress rule is good practice)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "academy-sg" }
}
