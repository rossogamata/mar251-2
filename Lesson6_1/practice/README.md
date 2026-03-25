# 🏗️ Практика — Terraform: відтворення інфраструктури Заняття 3.1
### Practice — Terraform: reproducing Lesson 3.1 infrastructure

> **Тривалість / Duration:** ~120 хвилин / minutes
> **Середовище / Environment:** AWS Academy Learner Lab + Terraform (локально / locally)

---

## 🗺️ Що розгортаємо / What we deploy

```
┌──────────────────────────────────────────────────────────────┐
│  VPC: 10.0.0.0/16  (academy-vpc)                             │
│                                                              │
│  ┌───────────────────────┐    ┌───────────────────────────┐  │
│  │  Subnet-A             │    │  Subnet-B                 │  │
│  │  10.0.1.0/24          │    │  10.0.2.0/24              │  │
│  │  us-east-1a           │    │  us-east-1b               │  │
│  │                       │    │                           │  │
│  │  ┌─────────────────┐  │    │  ┌─────────────────────┐  │  │
│  │  │ EC2: WebServer  │  │    │  │  EC2: AppServer     │  │  │
│  │  │ ← EIP (static)  │  │    │  │  ← auto public IP   │  │  │
│  │  └─────────────────┘  │    │  └─────────────────────┘  │  │
│  └───────────────────────┘    └───────────────────────────┘  │
│                                                              │
│  [Internet Gateway]   [Route Table]   [Network ACL]          │
└──────────────────────────────────────────────────────────────┘
```

**Ресурси / Resources:** VPC · IGW · 2× Subnet · Route Table · Network ACL · Security Group · 2× EC2 (Apache) · Elastic IP

---

## ⚙️ Передумови / Prerequisites (встановити один раз)

### Terraform (WSL / Linux)

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y
terraform version
```

### AWS CLI (WSL / Linux)

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip awscliv2.zip && sudo ./aws/install
aws --version
```

---

## 🔑 Підключення до AWS Academy щоразу перед лабою

### 1. Запустити лабораторію

AWS Academy → **Start Lab** → дочекатись зеленого індикатора ●

### 2. Отримати тимчасові credentials

AWS Academy → **AWS Details** → **Show** → скопіювати три значення:
```
aws_access_key_id     = ASIA...
aws_secret_access_key = ...
aws_session_token     = IQoJ...
```

### 3. Налаштувати профіль `academy`

```bash
aws configure --profile academy
# AWS Access Key ID:     ASIA...
# AWS Secret Access Key: ...
# Default region name:   us-east-1
# Default output format: json
```

Після цього **обов'язково** додати session token вручну:

```bash
aws configure set aws_session_token "ВСТАВИТИ_ТОКЕН_СЮДИ" --profile academy
```

### 4. Перевірити підключення

```bash
aws sts get-caller-identity --profile academy
```

Очікуваний результат — JSON з `UserId` та `Account`:
```json
{
    "UserId": "AROA...",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/..."
}
```

---

## 🚀 Запуск Terraform

```bash
cd Lesson6_1/practice/

# Завантажити провайдер AWS (~30 сек)
terraform init

# Переглянути план змін (нічого не створює)
terraform plan

# Розгорнути інфраструктуру (~2-3 хв)
terraform apply
# Підтвердити: yes
```

Після `apply` Terraform виведе outputs:

```
elastic_ip         = "54.123.x.x"
web_server_url     = "http://54.123.x.x"
web_server_id      = "i-0abc..."
app_server_id      = "i-0def..."
...
```

> ⏳ Зачекайте ~2–3 хв після `apply` — `user-data` встановлює Apache на обох інстансах.
> Потім відкрийте `web_server_url` у браузері.

---

## 🔄 Переміщення Elastic IP (завдання зі Step 9 у Lesson 3.1)

Після розгортання EIP прив'язаний до WebServer. Щоб перемістити його на AppServer — відредагуйте [ec2.tf](ec2.tf):

```hcl
# Було / Before:
resource "aws_eip" "web_server" {
  instance = aws_instance.web_server.id
  ...
}

# Стало / After:
resource "aws_eip" "web_server" {
  instance = aws_instance.app_server.id
  ...
}
```

```bash
terraform apply   # Terraform відв'яже EIP від WebServer та прив'яже до AppServer
```

---

## 🧹 Видалення інфраструктури (обов'язково!)

```bash
terraform destroy
# Підтвердити: yes
```

> ⚠️ Виконуйте `destroy` наприкінці **кожної** лаби.
> Ресурси (особливо EC2 та EIP) витрачають кредити навіть коли Lab зупинений.

---

## ⚠️ Обмеження AWS Academy Learner Lab

| Обмеження | Деталь |
|---|---|
| **Тимчасові credentials** | Діють ~4 год. Якщо Lab зупинився — повторити кроки 2–3 вище |
| **Session token** | Обов'язковий третій параметр. Без нього `terraform plan` поверне `InvalidClientTokenId` |
| **IAM** | Не можна створювати IAM users/roles з довільними policy. Для EC2 IAM role — використовувати лише `LabRole` |
| **State file** | Зберігається локально (`terraform.tfstate`). Не видаляти вручну — Terraform відстежує через нього стан ресурсів |
| **Деякі сервіси** | EKS, деякі Lambda triggers можуть бути заблоковані policy лабораторії |

---

## 📁 Структура файлів

```
practice/
├── provider.tf    # Terraform version + AWS provider
├── variables.tf   # Змінні (region, CIDR, instance_type)
├── vpc.tf         # VPC, IGW, Subnets, Route Table
├── security.tf    # Network ACL, Security Group
├── ec2.tf         # AMI data source, EC2 instances, Elastic IP
├── outputs.tf     # Outputs (IP-адреси, IDs)
└── README.md      # Цей файл
```

---

*Terraform відтворює ту саму інфраструктуру що була створена вручну через AWS CLI у Занятті 3.1*
