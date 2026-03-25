# 🏗️ Заняття 6 — Автоматизоване розгортання та налаштування ІТ-інфраструктури: IaC
### Lecture 6 — Automated Infrastructure Deployment & Configuration: IaC Tools
#### 5-й курс / 5th Year | AWS Academy Cloud Foundations

> **Тип / Type:** Лекція / Lecture
> **Тривалість / Duration:** ~90 хвилин / minutes

---

## 📋 Навчальні питання / Learning Topics

| # | 🇺🇦 Тема | 🇬🇧 Topic |
|---|---|---|
| **1** | Поняття інфраструктури як код (IaC) | Infrastructure as Code (IaC) concept |
| **2** | Terraform — інструмент розгортання інфраструктури | Terraform — infrastructure provisioning tool |
| **3** | Ansible — інструмент налаштування та управління | Ansible — configuration management tool |

---

# ═══════════════════════════════════════════════════════
# 📖 ПИТАННЯ 1 — ІНФРАСТРУКТУРА ЯК КОД / TOPIC 1 — IaC
# ═══════════════════════════════════════════════════════

## 1.1 Проблема ручного управління / The Problem with Manual Management

**🇺🇦** До появи IaC адміністратори налаштовували сервери вручну:
- Підключення по SSH до кожного сервера
- Виконання команд з пам'яті або особистих нотаток
- Відсутність документації реального стану
- "Сніжинки" (Snowflake Servers) — кожен сервер унікальний і незамінний

Наслідки: **"воно просто працює, не чіпай"**, неможливість відтворення, страх змін, людські помилки.

**🇬🇧** Before IaC, administrators configured servers manually:
- SSH into each server individually
- Running commands from memory or personal notes
- No documentation of actual state
- "Snowflake Servers" — each server unique and irreplaceable

Result: **"it just works, don't touch it"**, no reproducibility, fear of change, human errors.

```
❌ Ручний підхід / Manual approach:
┌──────────┐  SSH   ┌─────────┐
│  Admin   │───────▶│ Server1 │  (налаштовано вручну / manually configured)
│          │───────▶│ Server2 │  (трохи інакше / slightly different)
│          │───────▶│ Server3 │  (ще інакше / even more different)
└──────────┘        └─────────┘
   Проблема: жоден сервер не є ідентичним іншому!
   Problem: no two servers are identical!

✅ IaC підхід / IaC approach:
┌──────────────────┐  apply  ┌─────────┐
│  Код / Code      │────────▶│ Server1 │ ╗
│  (version ctrl)  │────────▶│ Server2 │ ╠═ ідентичні / identical
│  main.tf /       │────────▶│ Server3 │ ╝
│  playbook.yml    │         └─────────┘
└──────────────────┘
```

---

## 1.2 Що таке IaC / What is IaC

**🇺🇦** **Infrastructure as Code (IaC)** — практика управління та розгортання інфраструктури через машиночитані файли конфігурації (код), а не через ручні процеси чи інтерактивні інтерфейси.

Інфраструктура описується у текстових файлах → файли зберігаються у Git → зміни проходять через code review → інфраструктура розгортається автоматично.

**🇬🇧** **Infrastructure as Code (IaC)** is the practice of managing and provisioning infrastructure through machine-readable configuration files (code), rather than through manual processes or interactive interfaces.

Infrastructure is described in text files → files stored in Git → changes go through code review → infrastructure is deployed automatically.

---

## 1.3 Ключові принципи IaC / Core IaC Principles

### 🔁 Idempotency / Ідемпотентність

**🇺🇦** Застосування одного й того самого коду кілька разів дає **той самий результат**. Якщо ресурс вже існує у потрібному стані — нічого не змінюється.

**🇬🇧** Applying the same code multiple times yields **the same result**. If a resource already exists in the desired state — nothing changes.

```
Перший запуск  → сервер не існує → СТВОРИТИ
First run      → server doesn't exist → CREATE

Другий запуск  → сервер існує, стан відповідає коду → НІЧОГО
Second run     → server exists, state matches code → NOTHING

Третій запуск  → сервер існує, порт змінено у коді → ОНОВИТИ
Third run      → server exists, port changed in code → UPDATE
```

### 📄 Декларативний vs Імперативний / Declarative vs Imperative

**🇺🇦**
- **Декларативний** — описуєш **ЩО** хочеш отримати, інструмент сам вирішує ЯК. Приклад: Terraform, CloudFormation.
- **Імперативний** — описуєш **ЯК** досягти результату (крок за кроком). Приклад: Bash-скрипти, Python.

**🇬🇧**
- **Declarative** — you describe **WHAT** you want, the tool figures out HOW. Example: Terraform, CloudFormation.
- **Imperative** — you describe **HOW** to achieve the result (step by step). Example: Bash scripts, Python.

```yaml
# Декларативно / Declaratively (Terraform):
resource "aws_instance" "web" {
  ami           = "ami-12345"
  instance_type = "t2.micro"     # ← "Я хочу EC2 t2.micro" / "I want t2.micro EC2"
}
# Terraform сам вирішить: create? update? skip?

# Імперативно / Imperatively (Bash):
aws ec2 describe-instances ...   # ← спочатку перевір / first check
if [ $COUNT -eq 0 ]; then        # ← потім вирішуй / then decide
  aws ec2 run-instances ...      # ← потім виконуй / then execute
fi
```

### 🔄 Версіонування / Version Control

**🇺🇦** Код інфраструктури зберігається у Git. Це дає:
- Повну історію змін ("хто змінив, коли, навіщо")
- Можливість повернутись до будь-якого попереднього стану (`git revert`)
- Code review перед застосуванням
- Гілки для різних середовищ (dev/staging/prod)

**🇬🇧** Infrastructure code lives in Git. This provides:
- Full change history ("who changed, when, why")
- Ability to revert to any previous state (`git revert`)
- Code review before applying
- Branches for different environments (dev/staging/prod)

---

## 1.4 Переваги IaC / Benefits of IaC

| Перевага / Benefit | 🇺🇦 Пояснення | 🇬🇧 Explanation |
|---|---|---|
| **Відтворюваність** | Один і той самий код → ідентичне середовище | Same code → identical environment |
| **Швидкість** | Розгортання за хвилини замість годин/днів | Deploy in minutes instead of hours/days |
| **Масштабованість** | 1 сервер або 1000 — той самий код | 1 server or 1000 — the same code |
| **Аудит** | Git-log показує всі зміни | Git-log shows all changes |
| **Disaster Recovery** | Повне середовище відновлюється з коду | Full env restored from code |
| **Collaboration** | Команда працює з кодом, не з серверами | Team works with code, not servers |
| **Тестування** | Інфраструктуру можна тестувати (terratest) | Infrastructure can be tested |

---

## 1.5 Типи IaC-інструментів / Types of IaC Tools

```
┌─────────────────────────────────────────────────────────────────┐
│                    IaC ECOSYSTEM                                 │
├──────────────────────────┬──────────────────────────────────────┤
│  PROVISIONING            │  CONFIGURATION MANAGEMENT            │
│  (Розгортання ресурсів)  │  (Налаштування ресурсів)             │
│                          │                                      │
│  ┌─────────────────────┐ │  ┌────────────────────────────────┐  │
│  │  Terraform  ✅      │ │  │  Ansible       ✅              │  │
│  │  CloudFormation     │ │  │  Puppet                        │  │
│  │  Pulumi             │ │  │  Chef                          │  │
│  │  CDK                │ │  │  SaltStack                     │  │
│  └─────────────────────┘ │  └────────────────────────────────┘  │
│                          │                                      │
│  Що робить:              │  Що робить:                          │
│  • Створює VPC           │  • Встановлює пакети                │
│  • Запускає EC2          │  • Налаштовує конфіги               │
│  • Створює S3/RDS        │  • Управляє сервісами               │
│  • Налаштовує IAM        │  • Розгортає застосунки             │
└──────────────────────────┴──────────────────────────────────────┘
```

> 💡 **Terraform та Ansible — взаємодоповнюючі, не конкурентні інструменти!**
> 💡 **Terraform and Ansible complement each other — they are not competitors!**
> Terraform розгортає інфраструктуру → Ansible її налаштовує.
> Terraform provisions infrastructure → Ansible configures it.

---

# ═══════════════════════════════════════════════════════
# 🟣 ПИТАННЯ 2 — TERRAFORM / TOPIC 2 — TERRAFORM
# ═══════════════════════════════════════════════════════

## 2.1 Що таке Terraform / What is Terraform

**🇺🇦** **Terraform** — інструмент з відкритим вихідним кодом від HashiCorp для декларативного розгортання та управління інфраструктурою. Використовує власну мову **HCL (HashiCorp Configuration Language)**.

Terraform може управляти ресурсами у **понад 3000 провайдерів**: AWS, Azure, GCP, Kubernetes, GitHub, Cloudflare, PagerDuty тощо.

**🇬🇧** **Terraform** is an open-source tool from HashiCorp for declarative infrastructure provisioning and management. Uses its own language **HCL (HashiCorp Configuration Language)**.

Terraform can manage resources across **3000+ providers**: AWS, Azure, GCP, Kubernetes, GitHub, Cloudflare, PagerDuty, etc.

---

## 2.2 Ключові концепції Terraform / Terraform Key Concepts

### 🔌 Provider / Провайдер

**🇺🇦** Провайдер — плагін що дозволяє Terraform взаємодіяти з конкретним API (AWS, Azure тощо). Провайдер надає набір **ресурсів** та **джерел даних**.

**🇬🇧** A provider is a plugin that enables Terraform to interact with a specific API (AWS, Azure, etc.). A provider exposes a set of **resources** and **data sources**.

```hcl
# terraform/provider.tf

# Блок terraform — метаналаштування / terraform block — meta-configuration
terraform {
  required_version = ">= 1.5.0"  # мінімальна версія Terraform / min Terraform version

  required_providers {
    aws = {
      source  = "hashicorp/aws"   # реєстр провайдера / provider registry
      version = "~> 5.0"          # ~> 5.0 = будь-яка 5.x / any 5.x version
    }
  }

  # Backend — де зберігається Terraform State (tfstate)
  # Backend — where Terraform State (tfstate) is stored
  backend "s3" {
    bucket = "my-terraform-state"   # S3 bucket для стану / S3 bucket for state
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
    # dynamodb_table = "terraform-lock"  # блокування стану / state locking
  }
}

# Конфігурація AWS провайдера / AWS provider configuration
provider "aws" {
  region  = "us-east-1"
  profile = "academy"  # AWS CLI profile

  # Теги за замовчуванням для всіх ресурсів / Default tags for all resources
  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Environment = var.environment
      Project     = "AcademyLab"
    }
  }
}
```

### 📦 Resource / Ресурс

**🇺🇦** Resource — основний блок Terraform. Описує один об'єкт інфраструктури (EC2, S3, VPC тощо).

**🇬🇧** Resource is the fundamental block in Terraform. Describes a single infrastructure object (EC2, S3, VPC, etc.).

```hcl
# Синтаксис / Syntax:
# resource "<тип_провайдера>" "<локальна_назва>" { ... }
# resource "<provider_type>"  "<local_name>"     { ... }

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "academy-vpc"
  }
}

# Посилання на інший ресурс / Referencing another resource:
# aws_vpc.main.id — тип.назва.атрибут / type.name.attribute

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id         # посилання / reference
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-subnet-a"
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id  # з data source / from data source
  instance_type = var.instance_type             # зі змінної / from variable

  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.web.id]

  tags = {
    Name = "web-server"
  }
}
```

### 📊 Data Source / Джерело даних

**🇺🇦** Data Source — зчитує існуючі ресурси або дані без їх створення. Використовується для отримання актуальної інформації (наприклад, останній AMI).

**🇬🇧** Data Source — reads existing resources or data without creating them. Used to fetch current information (e.g., the latest AMI).

```hcl
# data "<тип>" "<назва>" { ... }
# data "<type>" "<name>" { ... }

# Отримуємо найновіший AMI Amazon Linux 2023 / Get latest AL2023 AMI
data "aws_ami" "amazon_linux" {
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

# Отримуємо поточний акаунт / Get current account
data "aws_caller_identity" "current" {}

# Використання / Usage:
# data.aws_ami.amazon_linux.id
# data.aws_caller_identity.current.account_id
```

### 📝 Variables / Змінні

```hcl
# variables.tf — оголошення змінних / variable declarations

variable "environment" {
  description = "Deployment environment (dev/staging/prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "allowed_cidrs" {
  description = "List of CIDRs allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true  # ← не відображається в логах / not shown in logs
}
```

```hcl
# terraform.tfvars — значення змінних / variable values (НЕ комітити у Git з секретами!)
environment   = "prod"
instance_type = "t3.small"
allowed_cidrs = ["10.0.0.0/8", "192.168.1.0/24"]
tags = {
  Owner   = "DevOps Team"
  CostCenter = "IT-Infrastructure"
}
```

### 📤 Outputs / Виводи

```hcl
# outputs.tf — виводи значень після apply / output values after apply

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "RDS connection endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true  # приховуємо в логах / hidden in logs
}

# Використання: terraform output alb_dns_name
# Pass to Ansible: terraform output -raw alb_dns_name
```

---

## 2.3 Terraform State / Стан Terraform

**🇺🇦** **State (tfstate)** — файл у форматі JSON, що відображає реальний стан розгорнутих ресурсів. Terraform порівнює код з State, а State з реальною інфраструктурою.

**🇬🇧** **State (tfstate)** — a JSON file reflecting the actual state of deployed resources. Terraform compares code to State, and State to real infrastructure.

```
Terraform logic / Логіка Terraform:

  Код (HCL)     State (tfstate)   Реальність (AWS)
  ──────────    ───────────────   ────────────────
  t3.small   vs   t2.micro    →  PLAN: update instance_type
  port 443   vs   port 80     →  PLAN: update security group
  (new)      vs   (missing)   →  PLAN: create new resource
  (missing)  vs   exists      →  PLAN: destroy resource
```

```
⚠️  State зберігання / State storage:

  Local (default):
  └── terraform.tfstate     ← небезпечно для команди! / dangerous for teams!

  Remote (рекомендовано / recommended):
  └── S3 + DynamoDB locking  ← командна робота + захист від race condition
      (AWS)                     team collaboration + race condition protection
  └── Terraform Cloud
  └── GitLab / Azure Blob
```

---

## 2.4 Terraform Workflow — Цикл роботи

```
┌─────────────────────────────────────────────────────────────────┐
│                   TERRAFORM WORKFLOW                             │
│                                                                 │
│   1. Write      2. Init       3. Plan       4. Apply            │
│   ────────      ──────        ──────        ───────             │
│   Пишемо HCL   Завантаж.    Перегляд      Застосов.            │
│   Write HCL    providers    changes       changes               │
│                             (dry run)                           │
│                                                                 │
│   main.tf  →  terraform  →  terraform  →  terraform            │
│   vars.tf      init          plan          apply                │
│                                                                 │
│                             ↓ review ↓                          │
│                          (code review,                          │
│                           PR approval)                          │
│                                                                 │
│   5. Destroy (при потребі / when needed)                        │
│   ─────────                                                     │
│   terraform destroy  ← видаляє ВСЕ що у State / deletes all    │
└─────────────────────────────────────────────────────────────────┘
```

### Команди / Commands

```bash
# ── terraform init ────────────────────────────────────────────────
# 🇺🇦 Ініціалізація: завантажує провайдери, налаштовує backend
# 🇬🇧 Initialization: downloads providers, configures backend
terraform init

# ── terraform validate ────────────────────────────────────────────
# 🇺🇦 Перевіряє синтаксис HCL без звернення до API
# 🇬🇧 Checks HCL syntax without making API calls
terraform validate

# ── terraform fmt ─────────────────────────────────────────────────
# 🇺🇦 Форматує код по стандарту HashiCorp (аналог prettier)
# 🇬🇧 Formats code to HashiCorp standard (like prettier)
terraform fmt -recursive

# ── terraform plan ────────────────────────────────────────────────
# 🇺🇦 "Сухий запуск" — показує що БУДЕ зроблено без виконання
#     + create   зеленим  → буде створено
#     ~ update   жовтим   → буде змінено
#     - destroy  червоним → буде видалено
# 🇬🇧 "Dry run" — shows what WILL be done without executing
#     + create   green  → will be created
#     ~ update   yellow → will be changed
#     - destroy  red    → will be deleted
terraform plan
terraform plan -out=tfplan  # зберегти план / save plan to file

# ── terraform apply ───────────────────────────────────────────────
# 🇺🇦 Застосовує зміни (запитує підтвердження "yes")
# 🇬🇧 Applies changes (prompts for "yes" confirmation)
terraform apply
terraform apply tfplan       # застосувати збережений план / apply saved plan
terraform apply -auto-approve  # без підтвердження (CI/CD) / no prompt (CI/CD)

# ── terraform destroy ─────────────────────────────────────────────
# 🇺🇦 Видаляє ВСІ ресурси зі State (з підтвердженням!)
# 🇬🇧 Deletes ALL resources in State (with confirmation!)
terraform destroy

# ── terraform output ──────────────────────────────────────────────
terraform output                    # всі outputs / all outputs
terraform output alb_dns_name       # конкретний / specific
terraform output -raw alb_dns_name  # без лапок / without quotes

# ── terraform state ───────────────────────────────────────────────
terraform state list              # перелік ресурсів у State / list resources
terraform state show aws_vpc.main # деталі ресурсу / resource details
terraform state rm aws_vpc.main   # видалити з State без видалення ресурсу
                                  # remove from state without deleting resource

# ── terraform import ──────────────────────────────────────────────
# 🇺🇦 Імпортує існуючий ресурс в State (якщо створений вручну)
# 🇬🇧 Import existing resource into State (if created manually)
terraform import aws_vpc.main vpc-0abc1234
```

---

## 2.5 Повний приклад: AWS інфраструктура / Full Example: AWS Infrastructure

```hcl
# main.tf — повна конфігурація / complete configuration

# ── Мережа / Network ────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = { Name = "${var.environment}-vpc" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.environment}-igw" }
}

# Динамічне створення підмереж / Dynamic subnet creation
# count — кількість копій ресурсу / number of resource copies
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)   # скільки CIDRів — стільки підмереж

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "${var.environment}-public-${count.index + 1}" }
}

# ── Обчислення / Compute ────────────────────────────────────────────
resource "aws_launch_template" "web" {
  name_prefix   = "${var.environment}-web-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    echo "<h1>Deployed by Terraform | $(hostname)</h1>" > /var/www/html/index.html
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = { Name = "${var.environment}-web" }
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${var.environment}-asg"
  vpc_zone_identifier = aws_subnet.public[*].id  # всі публічні підмережі
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  min_size            = var.asg_min
  max_size            = var.asg_max
  desired_capacity    = var.asg_desired

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
}

# ── Балансувальник / Load Balancer ──────────────────────────────────
resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "web" {
  name     = "${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# ── База даних / Database ───────────────────────────────────────────
resource "aws_db_instance" "main" {
  identifier        = "${var.environment}-mysql"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "appdb"
  username = "admin"
  password = var.db_password  # sensitive змінна / sensitive variable

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true   # для лабораторії / for lab use
  deletion_protection    = var.environment == "prod" ? true : false
  # умовний вираз / conditional: якщо prod → true, інакше → false
}
```

---

## 2.6 Terraform Modules / Модулі

**🇺🇦** **Модуль** — це директорія з HCL-файлами, яку можна перевикористовувати. Аналог функцій у програмуванні. Дозволяє стандартизувати інфраструктуру та не дублювати код.

**🇬🇧** **A module** is a directory of HCL files that can be reused. Like functions in programming. Enables standardized infrastructure and avoids code duplication.

```
project/
├── main.tf              ← Root module / Кореневий модуль
├── variables.tf
├── outputs.tf
└── modules/
    ├── vpc/             ← VPC module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── ec2/             ← EC2 module
    └── rds/             ← RDS module
```

```hcl
# Використання модуля / Using a module:
module "vpc" {
  source = "./modules/vpc"  # локальний / local

  # або з Terraform Registry / or from Terraform Registry:
  # source  = "terraform-aws-modules/vpc/aws"
  # version = "5.0.0"

  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  environment          = var.environment
}

# Отримуємо outputs модуля / Access module outputs:
resource "aws_instance" "web" {
  subnet_id = module.vpc.public_subnet_ids[0]
}
```

---

## 2.7 Terraform у CI/CD

```
┌─────────────────────────────────────────────────────────────────┐
│               TERRAFORM CI/CD PIPELINE                          │
│                                                                 │
│  Git Push → GitHub Actions / GitLab CI                         │
│      │                                                         │
│      ▼                                                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  PR / Merge Request:                                    │   │
│  │    terraform fmt --check  (форматування / formatting)   │   │
│  │    terraform validate     (синтаксис / syntax)          │   │
│  │    terraform plan         (план змін / change plan)     │   │
│  │    ← plan додається до PR як коментар / added to PR    │   │
│  └─────────────────────────────────────────────────────────┘   │
│      │                                                         │
│      ▼  (після approve / after approval)                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Merge to main:                                         │   │
│  │    terraform apply -auto-approve                        │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

```yaml
# .github/workflows/terraform.yml — приклад / example

name: Terraform CI/CD

on:
  pull_request:
    paths: ['terraform/**']
  push:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.7.0

      - name: Terraform Init
        run: terraform init
        working-directory: terraform/

      - name: Terraform Plan (on PR)
        if: github.event_name == 'pull_request'
        run: terraform plan -no-color
        working-directory: terraform/

      - name: Terraform Apply (on merge)
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve
        working-directory: terraform/
        env:
          TF_VAR_db_password: ${{ secrets.DB_PASSWORD }}
```

---

# ═══════════════════════════════════════════════════════
# 🔴 ПИТАННЯ 3 — ANSIBLE / TOPIC 3 — ANSIBLE
# ═══════════════════════════════════════════════════════

## 3.1 Що таке Ansible / What is Ansible

**🇺🇦** **Ansible** — інструмент автоматизації з відкритим вихідним кодом від Red Hat для:
- **Configuration Management** — налаштування ОС та ПЗ
- **Application Deployment** — розгортання застосунків
- **Orchestration** — координація складних процесів
- **Ad-hoc automation** — разові завдання на кількох серверах

Головна перевага: **agentless** — не потрібно встановлювати агент на керовані сервери. Ansible підключається по **SSH** (Linux) або **WinRM** (Windows).

**🇬🇧** **Ansible** is an open-source automation tool from Red Hat for:
- **Configuration Management** — OS and software configuration
- **Application Deployment** — deploying applications
- **Orchestration** — coordinating complex workflows
- **Ad-hoc automation** — one-off tasks on multiple servers

Key advantage: **agentless** — no agent needed on managed servers. Ansible connects via **SSH** (Linux) or **WinRM** (Windows).

---

## 3.2 Архітектура Ansible / Ansible Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    ANSIBLE ARCHITECTURE                          │
│                                                                 │
│  ┌────────────────────┐                                         │
│  │   Control Node     │  ← Де встановлено Ansible / Where       │
│  │   (ваш ноутбук,   │     Ansible is installed                 │
│  │    CI/CD runner)  │                                          │
│  │                    │                                         │
│  │  ┌──────────────┐  │                                         │
│  │  │  Inventory   │  │  SSH / WinRM   ┌──────────┐            │
│  │  │  Playbook    │──┼───────────────▶│ Server 1 │            │
│  │  │  Roles       │  │                ├──────────┤            │
│  │  │  Variables   │──┼───────────────▶│ Server 2 │            │
│  │  └──────────────┘  │                ├──────────┤            │
│  └────────────────────┘  ───────────▶  │ Server N │            │
│                                        └──────────┘            │
│                                        Managed Nodes           │
│                                        (без агентів / agentless)│
└─────────────────────────────────────────────────────────────────┘
```

---

## 3.3 Ключові компоненти / Key Components

### 📋 Inventory / Інвентар

**🇺🇦** Inventory — список хостів (серверів) якими управляє Ansible. Може бути статичним (файл) або динамічним (скрипт/плагін що отримує список з AWS EC2, тощо).

**🇬🇧** Inventory — list of hosts (servers) managed by Ansible. Can be static (file) or dynamic (script/plugin fetching from AWS EC2, etc.).

```ini
# inventory/hosts.ini — статичний / static

# Одиночні хости / Standalone hosts
mail.example.com

# Група серверів / Server group
[webservers]
web1.example.com
web2.example.com
192.168.1.10

# Параметри підключення / Connection parameters
[webservers:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/academy.pem

# Група DB серверів / DB servers group
[dbservers]
db1.example.com   ansible_port=2222

# Мета-група / Meta-group (містить інші групи / contains other groups)
[production:children]
webservers
dbservers
```

```yaml
# inventory/hosts.yml — YAML формат (рекомендований) / YAML format (recommended)

all:
  children:
    webservers:
      hosts:
        web1:
          ansible_host: 10.0.1.10
        web2:
          ansible_host: 10.0.1.11
      vars:
        ansible_user: ec2-user
        ansible_ssh_private_key_file: ~/.ssh/academy.pem
        http_port: 80

    dbservers:
      hosts:
        db1:
          ansible_host: 10.0.3.10
          ansible_port: 3306
```

```yaml
# inventory/aws_ec2.yml — Динамічний інвентар для AWS / Dynamic inventory for AWS
# Автоматично отримує EC2 інстанси з AWS API
# Automatically fetches EC2 instances from AWS API

plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
filters:
  instance-state-name: running
  tag:ManagedBy: Ansible        # тільки інстанси з цим тегом / only tagged instances
keyed_groups:
  - key: tags.Role              # групи по тегу Role / groups by Role tag
    prefix: role
  - key: placement.region
    prefix: region
```

### 🎭 Playbook / Збірник завдань

**🇺🇦** Playbook — основний файл Ansible. Описує **що** і **на яких хостах** потрібно виконати. Написаний у форматі YAML. Складається з одного або кількох **plays**.

**🇬🇧** Playbook — the main Ansible file. Describes **what** to do and **on which hosts**. Written in YAML. Consists of one or more **plays**.

```yaml
# playbooks/webserver.yml

---
# Play 1: Налаштування веб-серверів / Configure web servers
- name: Configure and deploy web servers
  hosts: webservers         # на яких хостах / which hosts
  become: true              # виконувати від sudo / run as sudo
  gather_facts: true        # зібрати інфо про систему / gather system info

  vars:                     # змінні рівня play / play-level variables
    http_port: 80
    app_user: www-data
    deploy_version: "1.2.3"

  pre_tasks:                # виконуються перед roles / run before roles
    - name: Update package cache
      ansible.builtin.package:
        update_cache: true
      when: ansible_os_family == "RedHat"

  roles:                    # підключаємо ролі / include roles
    - common
    - webserver
    - monitoring

  tasks:                    # конкретні завдання / specific tasks
    - name: Ensure Apache is installed
      ansible.builtin.package:
        name: httpd
        state: present      # present=встановити, absent=видалити / install or remove

    - name: Ensure Apache is running and enabled
      ansible.builtin.service:
        name: httpd
        state: started      # started/stopped/restarted/reloaded
        enabled: true       # автозапуск / auto-start on boot

    - name: Deploy configuration file
      ansible.builtin.template:
        src: templates/httpd.conf.j2   # Jinja2 шаблон / Jinja2 template
        dest: /etc/httpd/conf/httpd.conf
        owner: root
        group: root
        mode: '0644'
      notify: Restart Apache  # тригер handler / trigger handler

    - name: Open firewall port
      ansible.posix.firewalld:
        port: "{{ http_port }}/tcp"    # {{ }} — Jinja2 вираз / Jinja2 expression
        permanent: true
        state: enabled

  handlers:                 # виконуються при notify, один раз в кінці / run on notify, once at end
    - name: Restart Apache
      ansible.builtin.service:
        name: httpd
        state: restarted

# Play 2: Налаштування баз даних / Configure databases
- name: Configure database servers
  hosts: dbservers
  become: true

  tasks:
    - name: Install MySQL
      ansible.builtin.package:
        name: "{{ item }}"
        state: present
      loop:                 # цикл по списку / loop over list
        - mysql-server
        - mysql-client
        - python3-pymysql   # потрібно для модуля mysql_db
```

### 🧩 Modules / Модулі

**🇺🇦** Модуль — одиниця роботи в Ansible. Кожен модуль виконує конкретну задачу: встановити пакет, скопіювати файл, запустити сервіс, виконати SQL-запит тощо. Ansible має **понад 6000 вбудованих модулів**.

**🇬🇧** A module is a unit of work in Ansible. Each module performs a specific task: install a package, copy a file, start a service, run SQL, etc. Ansible has **6000+ built-in modules**.

```yaml
# Найпоширеніші модулі / Most common modules:

# 📦 Управління пакетами / Package management
- name: Install packages
  ansible.builtin.package:   # universal — вибирає apt/yum/dnf автоматично
    name: [nginx, curl, git]
    state: present

- name: Install specific version
  ansible.builtin.yum:
    name: httpd-2.4.6
    state: present

# 📁 Файли та директорії / Files and directories
- name: Create directory
  ansible.builtin.file:
    path: /var/www/app
    state: directory         # directory / file / absent / link
    owner: www-data
    group: www-data
    mode: '0755'

- name: Copy file
  ansible.builtin.copy:
    src: files/app.conf      # відносно playbook / relative to playbook
    dest: /etc/app/app.conf
    backup: true             # зберегти стару версію / keep old version

- name: Render template
  ansible.builtin.template:
    src: templates/nginx.conf.j2
    dest: /etc/nginx/nginx.conf

# 🔧 Сервіси / Services
- name: Manage service
  ansible.builtin.service:
    name: nginx
    state: started
    enabled: true

# 💻 Команди / Commands
- name: Run command
  ansible.builtin.command:
    cmd: /usr/bin/app --init
    creates: /var/app/.initialized  # пропустити якщо файл існує / skip if file exists

- name: Run shell command
  ansible.builtin.shell:
    cmd: "echo $(date) >> /var/log/deploy.log"

# 🗄️ База даних / Database
- name: Create database
  community.mysql.mysql_db:
    name: appdb
    state: present
    login_host: "{{ rds_endpoint }}"
    login_user: admin
    login_password: "{{ db_password }}"

# 👤 Користувачі / Users
- name: Create system user
  ansible.builtin.user:
    name: deploy
    shell: /bin/bash
    groups: sudo
    append: true

# 🔑 SSH ключі / SSH keys
- name: Add authorized key
  ansible.posix.authorized_key:
    user: ec2-user
    key: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"

# 🌐 Завантаження / Download
- name: Download artifact
  ansible.builtin.get_url:
    url: "https://releases.example.com/app-{{ deploy_version }}.tar.gz"
    dest: /tmp/app.tar.gz
    checksum: "sha256:abc123..."

# ⏱️ Чекати / Wait
- name: Wait for service to be ready
  ansible.builtin.wait_for:
    host: "{{ rds_endpoint }}"
    port: 3306
    timeout: 300
```

### 🎯 Roles / Ролі

**🇺🇦** Role — стандартизована структура директорій для організації завдань, змінних, шаблонів і файлів. Аналог класу або пакету у програмуванні. Дозволяє перевикористовувати логіку налаштування.

**🇬🇧** A role is a standardized directory structure for organizing tasks, variables, templates, and files. Like a class or package in programming. Enables reuse of configuration logic.

```
roles/
└── webserver/                  ← назва ролі / role name
    ├── tasks/
    │   ├── main.yml            ← головний файл завдань / main tasks file
    │   ├── install.yml         ← підзавдання / sub-tasks (include_tasks)
    │   └── configure.yml
    ├── handlers/
    │   └── main.yml            ← handlers (restart, reload)
    ├── templates/
    │   ├── nginx.conf.j2       ← Jinja2 шаблони / Jinja2 templates
    │   └── vhost.conf.j2
    ├── files/
    │   └── index.html          ← статичні файли / static files
    ├── vars/
    │   └── main.yml            ← змінні ролі (вищий пріоритет) / role vars
    ├── defaults/
    │   └── main.yml            ← змінні за замовчуванням (нижчий пріоритет)
    │                             default variables (lower priority)
    ├── meta/
    │   └── main.yml            ← залежності ролі / role dependencies
    └── README.md
```

```yaml
# roles/webserver/tasks/main.yml
---
- name: Install web server
  ansible.builtin.include_tasks: install.yml

- name: Configure web server
  ansible.builtin.include_tasks: configure.yml
  tags: [configure]

# roles/webserver/defaults/main.yml
---
http_port: 80
max_connections: 1000
worker_processes: auto

# roles/webserver/templates/nginx.conf.j2
worker_processes {{ worker_processes }};

events {
    worker_connections {{ max_connections }};
}

http {
    server {
        listen {{ http_port }};
        server_name {{ ansible_hostname }};

        location / {
            root /var/www/html;
        }
    }
}

# roles/webserver/meta/main.yml — залежності / dependencies
---
dependencies:
  - role: common      # спочатку запуститься common / common runs first
  - role: firewall
    vars:
      open_ports: ["{{ http_port }}/tcp"]
```

### 🗃️ Variables та Precedence / Змінні та пріоритет

**🇺🇦** В Ansible є **22 рівні пріоритету змінних**. Важливо знати основні:

**🇬🇧** Ansible has **22 variable precedence levels**. The key ones:

```
Від найнижчого до найвищого / From lowest to highest priority:

1.  role defaults         (roles/x/defaults/main.yml)
2.  inventory vars        (group_vars/, host_vars/)
3.  playbook vars         (vars: у playbook)
4.  role vars             (roles/x/vars/main.yml)
5.  extra vars            (ansible-playbook -e "key=value")  ← НАЙВИЩИЙ / HIGHEST
```

```
project/
├── group_vars/
│   ├── all.yml           ← змінні для всіх хостів / vars for all hosts
│   ├── webservers.yml    ← змінні для групи / vars for group
│   └── production.yml
├── host_vars/
│   ├── web1.yml          ← змінні для конкретного хоста / vars for specific host
│   └── db1.yml
└── playbooks/
```

```yaml
# group_vars/all.yml
---
ntp_server: "pool.ntp.org"
log_level: "info"
ansible_python_interpreter: /usr/bin/python3

# group_vars/webservers.yml
---
http_port: 80
document_root: /var/www/html

# host_vars/web1.yml — перевизначає group_vars / overrides group_vars
---
http_port: 8080   # цей хост слухає на 8080 / this host listens on 8080
```

---

## 3.4 Ansible Ad-hoc команди / Ad-hoc Commands

**🇺🇦** Ad-hoc — одноразові команди без playbook. Зручні для швидких перевірок або разових дій.

**🇬🇧** Ad-hoc — one-off commands without a playbook. Useful for quick checks or one-time actions.

```bash
# Синтаксис / Syntax:
# ansible <hosts> -m <module> -a "<args>" [options]

# Перевірка зв'язку / Connectivity check
ansible all -m ping

# Збір фактів / Gather facts
ansible webservers -m setup
ansible webservers -m setup -a "filter=ansible_*ip*"

# Виконати команду / Run command
ansible webservers -m command -a "uptime"
ansible webservers -m shell -a "df -h | grep /dev/xvda"

# Встановити пакет / Install package
ansible webservers -m package -a "name=htop state=present" --become

# Перезапустити сервіс / Restart service
ansible webservers -m service -a "name=httpd state=restarted" --become

# Скопіювати файл / Copy file
ansible webservers -m copy \
  -a "src=./config.txt dest=/etc/app/config.txt mode=0644" \
  --become

# Виконати на конкретному хості / Run on specific host
ansible web1.example.com -m command -a "hostname"

# Задати змінні / Pass variables
ansible webservers -m template \
  -a "src=nginx.j2 dest=/etc/nginx/nginx.conf" \
  -e "http_port=8080" \
  --become
```

---

## 3.5 Ansible Vault — шифрування секретів / Secrets Encryption

**🇺🇦** Ansible Vault шифрує файли та рядки з чутливими даними (паролі, ключі API). Зашифровані файли можна безпечно зберігати у Git.

**🇬🇧** Ansible Vault encrypts files and strings containing sensitive data (passwords, API keys). Encrypted files can be safely stored in Git.

```bash
# Зашифрувати файл / Encrypt a file
ansible-vault encrypt group_vars/all/secrets.yml

# Редагувати зашифрований файл / Edit encrypted file
ansible-vault edit group_vars/all/secrets.yml

# Зашифрувати рядок / Encrypt a single string
ansible-vault encrypt_string 'MySecretPassword' --name 'db_password'
# Результат / Output:
# db_password: !vault |
#   $ANSIBLE_VAULT;1.1;AES256
#   3338323938363136303831313938313...

# Запустити playbook з vault / Run playbook with vault
ansible-playbook site.yml --ask-vault-pass
# або / or (рекомендовано для CI/CD):
ansible-playbook site.yml --vault-password-file ~/.vault_pass
```

```yaml
# group_vars/all/secrets.yml (зашифровано vault / encrypted with vault)
---
db_password: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  3338323938363136303831313938313...

aws_secret_key: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  6565383934343736343065666666363...
```

---

## 3.6 Повний приклад: розгортання застосунку / Full Example: App Deployment

```yaml
# site.yml — головний playbook / main playbook

---
- name: Provision infrastructure info
  hosts: localhost
  gather_facts: false
  tasks:
    - name: Get Terraform outputs
      ansible.builtin.shell: |
        terraform output -json
      register: tf_output
      args:
        chdir: ../terraform/

    - name: Set facts from Terraform
      ansible.builtin.set_fact:
        rds_endpoint: "{{ (tf_output.stdout | from_json).rds_endpoint.value }}"
        alb_dns: "{{ (tf_output.stdout | from_json).alb_dns_name.value }}"

- name: Configure web servers
  hosts: role_web      # динамічний інвентар / dynamic inventory from AWS tags
  become: true
  vars_files:
    - group_vars/all/secrets.yml   # vault-зашифровано / vault-encrypted

  roles:
    - role: common
    - role: webserver
    - role: app_deploy
      vars:
        app_version: "{{ lookup('env', 'APP_VERSION') | default('latest') }}"
        db_host: "{{ hostvars['localhost']['rds_endpoint'] }}"

  post_tasks:
    - name: Verify deployment
      ansible.builtin.uri:
        url: "http://{{ ansible_host }}/health"
        status_code: 200
      retries: 5
      delay: 10
```

```bash
# Запуск / Run:
ansible-playbook site.yml \
  -i inventory/aws_ec2.yml \
  --vault-password-file ~/.vault_pass \
  --extra-vars "APP_VERSION=1.2.3" \
  --tags "deploy" \
  --limit "role_web"    # тільки веб-сервери / only web servers
```

---

## 3.7 Ansible Galaxy — реєстр ролей / Role Registry

**🇺🇦** Ansible Galaxy — публічний реєстр ролей, колекцій та плагінів. Дозволяє використовувати готові ролі замість написання з нуля.

**🇬🇧** Ansible Galaxy — public registry of roles, collections, and plugins. Use ready-made roles instead of writing from scratch.

```bash
# Встановити роль / Install a role
ansible-galaxy role install geerlingguy.apache
ansible-galaxy role install geerlingguy.mysql

# Встановити колекцію / Install a collection
ansible-galaxy collection install community.mysql
ansible-galaxy collection install amazon.aws

# requirements.yml — список залежностей / dependency list
# (аналог package.json або requirements.txt / like package.json or requirements.txt)
```

```yaml
# requirements.yml
---
roles:
  - name: geerlingguy.apache
    version: "3.2.0"
  - name: geerlingguy.mysql
    version: "4.3.2"

collections:
  - name: community.mysql
    version: "3.8.0"
  - name: amazon.aws
    version: "7.0.0"
```

```bash
# Встановити всі залежності / Install all dependencies
ansible-galaxy install -r requirements.yml
```

---

# ═══════════════════════════════════════════════════════
# ⚔️  TERRAFORM vs ANSIBLE / ПОРІВНЯННЯ
# ═══════════════════════════════════════════════════════

## Порівняння інструментів / Tool Comparison

| Критерій / Criteria | 🟣 Terraform | 🔴 Ansible |
|---|---|---|
| **Призначення / Purpose** | Provisioning інфраструктури | Configuration Management |
| **Мова / Language** | HCL (HashiCorp Config Language) | YAML |
| **Підхід / Approach** | Декларативний / Declarative | Декларативний + Процедурний |
| **State** | Зберігає State / Stores state | Без стану / Stateless |
| **Агент / Agent** | Без агента / Agentless | Без агента / Agentless |
| **Підключення** | API (AWS SDK) | SSH / WinRM |
| **Idempotency** | Вбудована / Built-in | Залежить від модуля / Module-dependent |
| **Масштаб / Scale** | Регіон / хмара | Сервер / застосунок |
| **Що створює** | VPC, EC2, RDS, S3, IAM... | Файли, пакети, сервіси, конфіги |
| **Rollback** | Через State / Via state | Обмежений / Limited |
| **Крива навчання** | Середня / Medium | Низька / Low |

---

## Коли що використовувати / When to Use Which

```
┌────────────────────────────────────────────────────────────────────┐
│                  ВИБІР ІНСТРУМЕНТУ / TOOL SELECTION                │
│                                                                    │
│  Задача                         Інструмент / Tool                  │
│  ──────                         ─────────────────                  │
│  Створити VPC / Create VPC    → Terraform                          │
│  Запустити EC2 / Launch EC2   → Terraform                          │
│  Налаштувати nginx / Configure→ Ansible                            │
│  Розгорнути додаток / Deploy  → Ansible                            │
│  Оновити конфіг / Update cfg  → Ansible                            │
│  Знищити середовище / Destroy → Terraform destroy                  │
│  Встановити патчі / Patches   → Ansible                            │
│  Мігрувати БД / Migrate DB    → Ansible + community.mysql          │
│  Terraform + EC2 → налаштувати│ → Обидва! / Both!                  │
└────────────────────────────────────────────────────────────────────┘
```

---

## Інтеграція Terraform + Ansible / Integration

```
┌─────────────────────────────────────────────────────────────────┐
│            TERRAFORM + ANSIBLE WORKFLOW                          │
│                                                                 │
│  1. Terraform plan / apply                                      │
│     └─→ Створює VPC, EC2, RDS, ALB                              │
│          Creates VPC, EC2, RDS, ALB                             │
│                   │                                             │
│                   ▼                                             │
│  2. terraform output                                            │
│     └─→ Отримуємо: EC2 IPs, RDS endpoint, ALB DNS              │
│          Get: EC2 IPs, RDS endpoint, ALB DNS                    │
│                   │                                             │
│                   ▼                                             │
│  3. ansible-playbook                                            │
│     └─→ Підключаємось до EC2 по SSH                             │
│          Connect to EC2 via SSH                                 │
│          Встановлюємо: nginx, app, конфіги                      │
│          Install: nginx, app, configs                           │
│          Налаштовуємо: підключення до RDS                       │
│          Configure: RDS connection string                       │
│                   │                                             │
│                   ▼                                             │
│  4. Production ready! 🚀                                        │
└─────────────────────────────────────────────────────────────────┘
```

```bash
#!/bin/bash
# deploy.sh — повний цикл розгортання / full deployment cycle

set -euo pipefail

echo "=== Step 1: Terraform ===" 
cd terraform/
terraform init
terraform apply -auto-approve

# Отримуємо output Terraform / Get Terraform outputs
EC2_IPS=$(terraform output -json ec2_public_ips)
RDS_EP=$(terraform output -raw rds_endpoint)

echo "=== Step 2: Generate Ansible inventory ==="
cd ../ansible/

# Динамічно генеруємо inventory з Terraform outputs
# Dynamically generate inventory from Terraform outputs
python3 scripts/tf_to_inventory.py \
  --ec2-ips "$EC2_IPS" \
  --rds-endpoint "$RDS_EP" \
  > inventory/dynamic_hosts.yml

echo "=== Step 3: Ansible ===" 
ansible-playbook site.yml \
  -i inventory/dynamic_hosts.yml \
  --vault-password-file ~/.vault_pass \
  --extra-vars "rds_endpoint=$RDS_EP"

echo "=== Deployment complete! ==="
```

---

## Інші IaC-інструменти / Other IaC Tools

| Інструмент | Компанія | Особливість | Коли вибирати |
|---|---|---|---|
| **CloudFormation** | AWS | Нативна інтеграція AWS, JSON/YAML | Лише AWS, глибока інтеграція |
| **CDK** | AWS | IaC на Python/TypeScript/Java | Розробники, складна логіка |
| **Pulumi** | Pulumi | IaC на Python/Go/TypeScript | Multi-cloud, програмісти |
| **Chef** | Progress | Ruby DSL, агент на сервері | Enterprise, складні рецепти |
| **Puppet** | Puppet | Декларативний, агент | Enterprise, великі парки |
| **SaltStack** | VMware | Python, event-driven | Великі масштаби, real-time |

---

## 📊 Підсумок лекції / Lecture Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                  КЛЮЧОВІ ТЕЗИ / KEY TAKEAWAYS                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  IaC:                                                           │
│  ✅ Інфраструктура = код у Git / Infrastructure = code in Git   │
│  ✅ Idempotency = безпечне повторне застосування                │
│  ✅ Declarative > Imperative для інфраструктури                 │
│                                                                 │
│  Terraform:                                                     │
│  ✅ Provisioning: VPC, EC2, RDS, S3, IAM...                     │
│  ✅ Plan → Review → Apply (безпечний workflow)                   │
│  ✅ State = "пам'ять" Terraform про реальні ресурси             │
│  ✅ Modules = повторне використання / reuse                      │
│                                                                 │
│  Ansible:                                                       │
│  ✅ Configuration: пакети, конфіги, сервіси, деплой             │
│  ✅ Agentless = тільки SSH, жодних агентів                      │
│  ✅ Playbook > Role > Task > Module                              │
│  ✅ Vault = шифрування секретів / secrets encryption            │
│                                                                 │
│  Разом / Together:                                              │
│  🚀 Terraform розгортає → Ansible налаштовує                    │
│     Terraform provisions → Ansible configures                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📚 Додаткові матеріали / Further Reading

| Ресурс | Посилання / Link |
|---|---|
| Terraform Documentation | https://developer.hashicorp.com/terraform/docs |
| Terraform Registry | https://registry.terraform.io |
| Ansible Documentation | https://docs.ansible.com |
| Ansible Galaxy | https://galaxy.ansible.com |
| AWS Provider Docs | https://registry.terraform.io/providers/hashicorp/aws |
| Terraform Best Practices | https://www.terraform-best-practices.com |
| AWS CloudFormation | https://docs.aws.amazon.com/cloudformation/ |

---

## 🎯 Самоперевірка / Self-Assessment

```bash
curl -O https://raw.githubusercontent.com/YOUR_REPO/main/check.sh
chmod +x check.sh && ./check.sh
```

---

*Підготовлено для курсу «Хмарні технології» | 5-й курс | Заняття 6 — Лекція*
*Prepared for Cloud Technologies course | 5th Year | Lecture 6* 🇺🇦
