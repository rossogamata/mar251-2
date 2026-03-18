# ☁️ AWS — Заняття 5: Бази даних · Масштабування · Балансування навантаження
### Lab 5 — Databases · Scaling · Load Balancing
#### 5-й курс / 5th Year | AWS Academy Cloud Foundations | Labs 5 & 6

> **Середовище / Environment:** AWS Academy Learner Lab → CloudShell (`>_`)
> **Тривалість / Duration:** ~120 хвилин / minutes

---

## 📋 Навчальні питання / Learning Objectives

| Лаб / Lab | Тема / Topic | Сервіси / Services |
|---|---|---|
| **Lab 5** | 🗃️ Створення сервера БД / Database Server | **RDS MySQL**, **EC2**, **Parameter Group**, **Subnet Group** |
| **Lab 6** | ⚖️ Масштабування та балансування / Scaling & Balancing | **ALB**, **Target Group**, **ASG**, **Launch Template**, **CloudWatch** |

---

## 🗺️ Архітектура / Target Architecture

```
╔═══════════════════════════════════════════════════════════════════════╗
║  VPC: 10.0.0.0/16                                                     ║
║                                                                       ║
║  ┌─────────────────────────────────────────────────────────────────┐  ║
║  │  PUBLIC SUBNETS (10.0.1.0/24 / 10.0.2.0/24)                    │  ║
║  │                                                                 │  ║
║  │         ┌───────────────────────────────────┐                  │  ║
║  │         │   Application Load Balancer (ALB)  │ ←── Internet    │  ║
║  │         └──────────────┬────────────────────┘                  │  ║
║  │                        │ HTTP :80                               │  ║
║  │         ┌──────────────▼────────────────────┐                  │  ║
║  │         │        Target Group                │                  │  ║
║  │         │  ┌──────────┐  ┌──────────┐        │                  │  ║
║  │         │  │  EC2 #1  │  │  EC2 #2  │  ...   │  ← ASG          │  ║
║  │         │  └──────────┘  └──────────┘        │                  │  ║
║  │         └───────────────────────────────────-┘                  │  ║
║  └─────────────────────────────────────────────────────────────────┘  ║
║                                                                       ║
║  ┌─────────────────────────────────────────────────────────────────┐  ║
║  │  PRIVATE SUBNETS (10.0.3.0/24 / 10.0.4.0/24)                   │  ║
║  │                                                                 │  ║
║  │         ┌─────────────────────────────────────┐                │  ║
║  │         │    RDS MySQL  (Multi-AZ ready)        │               │  ║
║  │         │    Port 3306  ← EC2 instances only    │               │  ║
║  │         └─────────────────────────────────────┘                │  ║
║  └─────────────────────────────────────────────────────────────────┘  ║
╚═══════════════════════════════════════════════════════════════════════╝
```

---

## 🚀 Підготовка CloudShell / CloudShell Setup

```bash
# Запускаємо Learner Lab → натискаємо AWS → відкриваємо CloudShell ( >_ )
# Start Learner Lab → click AWS → open CloudShell ( >_ )

aws sts get-caller-identity

ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
export AWS_REGION="us-east-1"
echo "✅ Account: $ACCOUNT_ID | Region: $AWS_REGION"
```

---

# ════════════════════════════════════════════
# 🗃️  ЛАБ 5 — СТВОРЕННЯ СЕРВЕРА БД / LAB 5 — DATABASE SERVER
# ════════════════════════════════════════════

## Теорія / Theory — RDS

**🇺🇦** Amazon RDS (Relational Database Service) — повністю керована реляційна СУБД. AWS автоматично:
- встановлює патчі та оновлення ОС і СУБД
- робить автоматичні бекапи (до 35 днів зберігання)
- перемикається на резервний інстанс при збої (Multi-AZ)
- масштабує сховище автоматично (автоматичне масштабування сховища)

**🇬🇧** Amazon RDS (Relational Database Service) is a fully managed relational DB. AWS automatically:
- patches and updates OS and DB engine
- performs automated backups (up to 35-day retention)
- fails over to a standby instance on failure (Multi-AZ)
- scales storage automatically (storage autoscaling)

> **Ключові компоненти RDS / RDS Key Components:**
> | Компонент | 🇺🇦 Опис | 🇬🇧 Description |
> |---|---|---|
> | **DB Instance** | Сам сервер бази даних | The database server itself |
> | **DB Subnet Group** | Набір підмереж для розміщення БД | Set of subnets for DB placement |
> | **Parameter Group** | Налаштування конфігурації СУБД | DB engine configuration settings |
> | **Option Group** | Додаткові функції СУБД | Additional DB engine features |
> | **Security Group** | Firewall для доступу до порту БД | Firewall controlling DB port access |
> | **Read Replica** | Репліка тільки для читання | Read-only copy for scaling reads |
> | **Multi-AZ** | Синхронний резерв в іншій AZ | Synchronous standby in another AZ |

---

## 🏗️ Крок 1 — Мережева інфраструктура / Step 1 — Network Infrastructure

Спочатку створимо VPC з публічними та приватними підмережами. / First, create a VPC with public and private subnets.

```bash
# ── VPC ─────────────────────────────────────────────────────────────
# aws ec2 create-vpc
#   --cidr-block 10.0.0.0/16
#       🇺🇦 Весь адресний простір лабораторії: 65 536 адрес
#       🇬🇧 Full lab address space: 65,536 addresses

VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=lab5-vpc}]' \
  --query 'Vpc.VpcId' --output text)

aws ec2 modify-vpc-attribute --vpc-id $VPC_ID \
  --enable-dns-hostnames '{"Value":true}'
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID \
  --enable-dns-support '{"Value":true}'

echo "✅ VPC: $VPC_ID"
```

```bash
# ── Internet Gateway ─────────────────────────────────────────────────
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=lab5-igw}]' \
  --query 'InternetGateway.InternetGatewayId' --output text)

aws ec2 attach-internet-gateway \
  --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

echo "✅ IGW: $IGW_ID"
```

```bash
# ── Чотири підмережі / Four subnets ─────────────────────────────────
# Публічні (для EC2 та ALB) / Public (for EC2 and ALB)
# Приватні (для RDS) / Private (for RDS — best practice: DB never in public subnet!)

# PUBLIC A — us-east-1a
PUB_A=$(aws ec2 create-subnet --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=lab5-pub-a}]' \
  --query 'Subnet.SubnetId' --output text)

# PUBLIC B — us-east-1b
PUB_B=$(aws ec2 create-subnet --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 --availability-zone us-east-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=lab5-pub-b}]' \
  --query 'Subnet.SubnetId' --output text)

# PRIVATE A — us-east-1a  (для RDS / for RDS)
PRIV_A=$(aws ec2 create-subnet --vpc-id $VPC_ID \
  --cidr-block 10.0.3.0/24 --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=lab5-priv-a}]' \
  --query 'Subnet.SubnetId' --output text)

# PRIVATE B — us-east-1b  (для RDS / for RDS)
PRIV_B=$(aws ec2 create-subnet --vpc-id $VPC_ID \
  --cidr-block 10.0.4.0/24 --availability-zone us-east-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=lab5-priv-b}]' \
  --query 'Subnet.SubnetId' --output text)

# Вмикаємо авто-публічний IP тільки для публічних підмереж
# Enable auto-public-IP only for public subnets (NOT for private!)
aws ec2 modify-subnet-attribute --subnet-id $PUB_A --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id $PUB_B --map-public-ip-on-launch

echo "✅ Public:  $PUB_A / $PUB_B"
echo "✅ Private: $PRIV_A / $PRIV_B"
```

```bash
# ── Route Table для публічних підмереж ──────────────────────────────
# Private subnets intentionally have NO route to IGW — DB cannot be reached from internet
# Приватні підмережі навмисно не мають маршруту до IGW — БД недоступна з інтернету

PUB_RT=$(aws ec2 create-route-table --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=lab5-rt-public}]' \
  --query 'RouteTable.RouteTableId' --output text)

aws ec2 create-route \
  --route-table-id $PUB_RT \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID

aws ec2 associate-route-table --route-table-id $PUB_RT --subnet-id $PUB_A
aws ec2 associate-route-table --route-table-id $PUB_RT --subnet-id $PUB_B

echo "✅ Route Table (public): $PUB_RT"
```

---

## 🔒 Крок 2 — Security Groups / Step 2 — Security Groups

```bash
# ── SG для EC2 (веб-сервери) / SG for EC2 (web servers) ─────────────
EC2_SG=$(aws ec2 create-security-group \
  --group-name "lab5-ec2-sg" \
  --description "Allow HTTP from ALB and SSH from anywhere" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

# HTTP з будь-якого місця (пізніше обмежимо до ALB)
# HTTP from anywhere (later we'll restrict to ALB only)
aws ec2 authorize-security-group-ingress \
  --group-id $EC2_SG --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress \
  --group-id $EC2_SG --protocol tcp --port 22 --cidr 0.0.0.0/0

echo "✅ EC2 Security Group: $EC2_SG"
```

```bash
# ── SG для RDS / SG for RDS ──────────────────────────────────────────
# Ключовий принцип безпеки: RDS приймає з'єднання ТІЛЬКИ від EC2
# Key security principle: RDS accepts connections ONLY from EC2
#
# --source-group $EC2_SG
#     🇺🇦 Замість конкретного IP (0.0.0.0/0) вказуємо Security Group як джерело.
#         Тільки ресурси з EC2_SG зможуть підключитись до RDS на порт 3306.
#         Це "SG-to-SG rule" — найбезпечніший підхід.
#     🇬🇧 Instead of a specific IP (0.0.0.0/0) we reference a Security Group as source.
#         Only resources with EC2_SG can reach RDS on port 3306.
#         This is a "SG-to-SG rule" — the most secure approach.

RDS_SG=$(aws ec2 create-security-group \
  --group-name "lab5-rds-sg" \
  --description "Allow MySQL only from EC2 SG" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $RDS_SG \
  --protocol tcp \
  --port 3306 \
  --source-group $EC2_SG

echo "✅ RDS Security Group: $RDS_SG"
echo "   MySQL port 3306 — allowed ONLY from EC2 SG (not from internet!)"
```

```bash
# ── SG для ALB / SG for ALB ──────────────────────────────────────────
ALB_SG=$(aws ec2 create-security-group \
  --group-name "lab5-alb-sg" \
  --description "Allow HTTP/HTTPS from internet" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG --protocol tcp --port 443 --cidr 0.0.0.0/0

echo "✅ ALB Security Group: $ALB_SG"
```

---

## ⚙️ Крок 3 — RDS Parameter Group / Step 3 — RDS Parameter Group

```bash
# Parameter Group — файл конфігурації СУБД (аналог my.cnf для MySQL)
# Дозволяє налаштувати сотні параметрів: кодування, таймаути, розміри буферів тощо
# Parameter Group = DB engine config file (like my.cnf for MySQL)
# Allows tuning hundreds of parameters: encoding, timeouts, buffer sizes, etc.

# aws rds create-db-parameter-group
#   --db-parameter-group-name lab5-mysql-params
#       🇺🇦 Унікальне ім'я групи параметрів в акаунті
#       🇬🇧 Unique parameter group name within the account
#
#   --db-parameter-group-family mysql8.0
#       🇺🇦 Сімейство — прив'язане до версії СУБД.
#           mysql8.0 = всі параметри для MySQL 8.x
#           Кожна версія СУБД має своє сімейство (mysql5.7, postgres14 тощо)
#       🇬🇧 Family — tied to the DB engine version.
#           mysql8.0 = all parameters for MySQL 8.x
#           Each engine version has its own family (mysql5.7, postgres14, etc.)
#
#   --description "..."
#       🇺🇦 Текстовий опис (обов'язковий!)
#       🇬🇧 Text description (required!)

aws rds create-db-parameter-group \
  --db-parameter-group-name "lab5-mysql-params" \
  --db-parameter-group-family "mysql8.0" \
  --description "Lab5 MySQL 8.0 Custom Parameter Group"

echo "✅ Parameter Group створено / created: lab5-mysql-params"
```

```bash
# Налаштовуємо кілька параметрів / Configure some parameters

# aws rds modify-db-parameter-group
#   --parameters 'ParameterName=...,ParameterValue=...,ApplyMethod=...'
#       🇺🇦 Список параметрів для зміни.
#           ApplyMethod:
#             immediate   — застосувати без перезапуску БД (динамічні параметри)
#             pending-reboot — застосувати після наступного перезапуску (статичні)
#       🇬🇧 List of parameters to change.
#           ApplyMethod:
#             immediate   — apply without DB restart (dynamic parameters)
#             pending-reboot — apply after next restart (static parameters)

aws rds modify-db-parameter-group \
  --db-parameter-group-name "lab5-mysql-params" \
  --parameters \
    'ParameterName=max_connections,ParameterValue=200,ApplyMethod=immediate' \
    'ParameterName=character_set_server,ParameterValue=utf8mb4,ApplyMethod=immediate' \
    'ParameterName=collation_server,ParameterValue=utf8mb4_unicode_ci,ApplyMethod=immediate' \
    'ParameterName=slow_query_log,ParameterValue=1,ApplyMethod=immediate' \
    'ParameterName=long_query_time,ParameterValue=2,ApplyMethod=immediate'

echo "✅ Параметри налаштовано / Parameters configured:"
echo "   max_connections      = 200      (макс. з'єднань / max connections)"
echo "   character_set_server = utf8mb4  (підтримка Unicode / Unicode support)"
echo "   slow_query_log       = 1        (лог повільних запитів / slow query log ON)"
echo "   long_query_time      = 2 сек    (поріг 'повільного' / slow threshold)"
```

---

## 📦 Крок 4 — DB Subnet Group / Step 4 — DB Subnet Group

```bash
# DB Subnet Group — визначає в яких підмережах RDS може розміщувати інстанси.
# Мінімум 2 підмережі в 2 різних AZ — вимога AWS для підтримки Multi-AZ.
# DB Subnet Group — defines which subnets RDS may use for instance placement.
# Minimum 2 subnets in 2 different AZs — AWS requirement for Multi-AZ support.

# ⚠️ Важливо / Important:
# Ми вказуємо ПРИВАТНІ підмережі (PRIV_A, PRIV_B) — не публічні!
# We specify PRIVATE subnets (PRIV_A, PRIV_B) — NOT public ones!
# БД ніколи не повинна бути у публічній підмережі (best practice)
# DB should NEVER be in a public subnet (security best practice)

aws rds create-db-subnet-group \
  --db-subnet-group-name "lab5-db-subnet-group" \
  --db-subnet-group-description "Lab5 — Private subnets for RDS (AZ: 1a + 1b)" \
  --subnet-ids "$PRIV_A" "$PRIV_B"

echo "✅ DB Subnet Group створено / created: lab5-db-subnet-group"
echo "   Subnets: $PRIV_A (us-east-1a) | $PRIV_B (us-east-1b)"
```

---

## 🐬 Крок 5 — Створення RDS MySQL / Step 5 — Create RDS MySQL

```bash
# aws rds create-db-instance — основна команда / main command
#
#   --db-instance-identifier lab5-mysql
#       🇺🇦 Унікальний ідентифікатор інстансу в акаунті (до 63 символів, a-z, 0-9, -)
#       🇬🇧 Unique instance identifier in account (up to 63 chars, a-z, 0-9, -)
#
#   --db-instance-class db.t3.micro
#       🇺🇦 Клас інстансу = обчислювальні ресурси:
#           db.t3.micro = 2 vCPU, 1 GB RAM — Free Tier
#           db.t3.small = 2 vCPU, 2 GB RAM
#           db.m5.large = 2 vCPU, 8 GB RAM (продакшн)
#       🇬🇧 Instance class = compute resources:
#           db.t3.micro = 2 vCPU, 1 GB RAM — Free Tier
#           db.t3.small = 2 vCPU, 2 GB RAM
#           db.m5.large = 2 vCPU, 8 GB RAM (production)
#
#   --engine mysql / --engine-version 8.0
#       🇺🇦 Тип та версія СУБД
#       🇬🇧 Database engine type and version
#
#   --master-username admin / --master-user-password Lab5Pass!
#       🇺🇦 Головний користувач (root) та його пароль
#           Пароль: мін. 8 символів, великі+малі+цифри+спецсимволи
#       🇬🇧 Master (root) user and password
#           Password: min 8 chars, upper+lower+digits+special chars
#
#   --allocated-storage 20
#       🇺🇦 Початковий розмір сховища в ГБ (20 ГБ — мінімум для Free Tier MySQL)
#       🇬🇧 Initial storage in GB (20 GB — minimum for Free Tier MySQL)
#
#   --max-allocated-storage 100
#       🇺🇦 Максимум для автоматичного масштабування сховища.
#           RDS автоматично збільшить диск якщо < 10% залишилось, до цього ліміту.
#       🇬🇧 Maximum for automatic storage scaling.
#           RDS auto-expands disk when <10% free space remains, up to this limit.
#
#   --db-subnet-group-name lab5-db-subnet-group
#       🇺🇦 В яких підмережах розмістити БД (приватні підмережі)
#       🇬🇧 Which subnets to place the DB in (private subnets)
#
#   --vpc-security-group-ids $RDS_SG
#       🇺🇦 Security Group що контролює доступ до порту 3306
#       🇬🇧 Security Group controlling access to port 3306
#
#   --db-parameter-group-name lab5-mysql-params
#       🇺🇦 Кастомна група параметрів (наша з utf8mb4 та slow log)
#       🇬🇧 Our custom parameter group (utf8mb4 and slow log enabled)
#
#   --db-name labdb
#       🇺🇦 Ім'я початкової схеми (database) яка буде створена автоматично
#       🇬🇧 Name of the initial database schema created automatically
#
#   --backup-retention-period 7
#       🇺🇦 Зберігати автоматичні бекапи 7 днів (0 = вимкнути, максимум 35)
#       🇬🇧 Retain automated backups for 7 days (0 = disable, max 35)
#
#   --preferred-backup-window "02:00-03:00"
#       🇺🇦 Вікно автоматичного бекапу (UTC). Бажано в нічні години.
#       🇬🇧 Automated backup window (UTC). Best during off-peak hours.
#
#   --preferred-maintenance-window "mon:04:00-mon:05:00"
#       🇺🇦 Вікно технічного обслуговування (патчі ОС та СУБД)
#       🇬🇧 Maintenance window (OS and DB patches)
#
#   --no-multi-az
#       🇺🇦 Single-AZ для лабораторії (дешевше).
#           Multi-AZ: --multi-az — синхронний резерв в іншій AZ, автоматичний failover
#       🇬🇧 Single-AZ for the lab (cheaper).
#           Multi-AZ: --multi-az — sync standby in another AZ, auto failover
#
#   --no-publicly-accessible
#       🇺🇦 БД НЕ отримує публічний IP — доступна тільки з VPC (best practice!)
#       🇬🇧 DB does NOT get a public IP — accessible only within the VPC (best practice!)
#
#   --storage-type gp3
#       🇺🇦 Тип сховища: gp3 = General Purpose SSD v3 (найкраще за ціна/якість)
#       🇬🇧 Storage type: gp3 = General Purpose SSD v3 (best price/performance)
#
#   --deletion-protection
#       🇺🇦 Захист від випадкового видалення — CLI поверне помилку при спробі delete
#       🇬🇧 Protection against accidental deletion — CLI returns error on delete attempt

aws rds create-db-instance \
  --db-instance-identifier "lab5-mysql" \
  --db-instance-class "db.t3.micro" \
  --engine mysql \
  --engine-version "8.0" \
  --master-username admin \
  --master-user-password "Lab5Pass!" \
  --allocated-storage 20 \
  --max-allocated-storage 100 \
  --storage-type gp3 \
  --db-subnet-group-name "lab5-db-subnet-group" \
  --vpc-security-group-ids "$RDS_SG" \
  --db-parameter-group-name "lab5-mysql-params" \
  --db-name "labdb" \
  --backup-retention-period 7 \
  --preferred-backup-window "02:00-03:00" \
  --preferred-maintenance-window "mon:04:00-mon:05:00" \
  --no-multi-az \
  --no-publicly-accessible \
  --deletion-protection \
  --tags Key=Name,Value=lab5-mysql Key=Env,Value=lab

echo "✅ RDS MySQL створюється / being created: lab5-mysql"
echo "⏳ Очікуйте ~10-15 хвилин / Wait ~10-15 minutes for status 'available'"
echo "   Продовжуємо налаштування EC2 поки RDS стартує..."
echo "   Continue with EC2 setup while RDS is starting..."
```

```bash
# Перевірка статусу / Check status
aws rds describe-db-instances \
  --db-instance-identifier "lab5-mysql" \
  --query 'DBInstances[0].{
    ID:DBInstanceIdentifier,
    Status:DBInstanceStatus,
    Class:DBInstanceClass,
    Engine:Engine,
    Storage:AllocatedStorage
  }' \
  --output table
```

---

## 💻 Крок 6 — EC2 з клієнтом MySQL / Step 6 — EC2 with MySQL Client

```bash
# Знаходимо останній AMI Amazon Linux 2023 / Find latest Amazon Linux 2023 AMI
LATEST_AMI=$(aws ec2 describe-images \
  --owners amazon \
  --filters \
    "Name=name,Values=al2023-ami-2023*-x86_64" \
    "Name=state,Values=available" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --output text)

echo "AMI: $LATEST_AMI"
```

```bash
# Запускаємо EC2 (Bastion + MySQL client) у публічній підмережі
# Launch EC2 (Bastion + MySQL client) in the public subnet

# --user-data
#     🇺🇦 Bootstrap-скрипт. Встановлюємо mysql клієнт та тестові утиліти.
#         Скрипт виконується один раз при першому старті інстансу від root.
#     🇬🇧 Bootstrap script. Install mysql client and test utilities.
#         Runs once on first boot as root.

BASTION_ID=$(aws ec2 run-instances \
  --image-id "$LATEST_AMI" \
  --instance-type t2.micro \
  --subnet-id "$PUB_A" \
  --security-group-ids "$EC2_SG" \
  --tag-specifications \
    'ResourceType=instance,Tags=[{Key=Name,Value=lab5-bastion}]' \
  --user-data '#!/bin/bash
yum update -y
# Встановлюємо mysql-клієнт (не сервер!) для підключення до RDS
# Install mysql CLIENT (not server!) for connecting to RDS
yum install -y mysql
# Утиліти для тестування навантаження
# Utilities for load testing
yum install -y sysbench
echo "MySQL client ready" > /tmp/setup_done.txt' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "⏳ Запускаємо Bastion EC2 / Launching Bastion EC2..."
aws ec2 wait instance-running --instance-ids "$BASTION_ID"

BASTION_IP=$(aws ec2 describe-instances \
  --instance-ids "$BASTION_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "✅ Bastion: $BASTION_ID | Public IP: $BASTION_IP"
```

---

## 🔗 Крок 7 — Підключення до RDS / Step 7 — Connect to RDS

```bash
# Чекаємо RDS / Wait for RDS (якщо ще не готово / if not ready yet)
echo "⏳ Waiting for RDS to become available..."
aws rds wait db-instance-available --db-instance-identifier "lab5-mysql"

# Отримуємо Endpoint / Get the Endpoint
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier "lab5-mysql" \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

RDS_PORT=$(aws rds describe-db-instances \
  --db-instance-identifier "lab5-mysql" \
  --query 'DBInstances[0].Endpoint.Port' \
  --output text)

echo "✅ RDS готово / RDS ready!"
echo "   Endpoint: $RDS_ENDPOINT"
echo "   Port:     $RDS_PORT"
```

```bash
# Тест підключення прямо з CloudShell через SSM або через mysql-клієнт
# Connection test from CloudShell (if mysql client is available):

# Перевіряємо чи є mysql клієнт в CloudShell
# Check if mysql client is available in CloudShell
which mysql 2>/dev/null || sudo yum install -y mysql 2>/dev/null || \
  sudo apt-get install -y mysql-client 2>/dev/null

# Підключаємось до RDS / Connect to RDS
# mysql
#   -h $RDS_ENDPOINT   → hostname (endpoint RDS інстансу)
#                        hostname (RDS instance endpoint)
#   -P $RDS_PORT       → порт (3306 за замовчуванням) / port (3306 default)
#   -u admin           → ім'я користувача / username
#   -p                 → запит пароля інтерактивно / prompt for password

echo "Підключення до RDS / Connecting to RDS:"
echo "mysql -h $RDS_ENDPOINT -P $RDS_PORT -u admin -p labdb"
echo ""
echo "Після підключення виконайте / After connecting run:"
cat << 'SQLCMDS'
-- Перевіряємо версію / Check version
SELECT VERSION();

-- Переглядаємо бази даних / List databases
SHOW DATABASES;

-- Використовуємо нашу БД / Use our database
USE labdb;

-- Створюємо тестову таблицю / Create test table
CREATE TABLE cadets (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(100) NOT NULL,
  unit       VARCHAR(50),
  score      INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Додаємо тестові дані / Insert test data
INSERT INTO cadets (name, unit, score) VALUES
  ('Іваненко І.І.', 'Взвод 1', 95),
  ('Петренко П.П.', 'Взвод 1', 88),
  ('Сидоренко С.С.','Взвод 2', 76),
  ('Коваленко К.К.','Взвод 2', 91);

-- Перевіряємо / Verify
SELECT * FROM cadets ORDER BY score DESC;

-- Статистика / Stats
SELECT unit, COUNT(*) AS total, AVG(score) AS avg_score
FROM cadets GROUP BY unit;

EXIT;
SQLCMDS
```

---

## 📸 Крок 8 — Snapshot та відновлення / Step 8 — Snapshot and Restore

```bash
# Ручний snapshot — "знімок" стану БД в певний момент
# Manual snapshot — point-in-time copy of the DB

# aws rds create-db-snapshot
#   --db-instance-identifier lab5-mysql
#       🇺🇦 З якого інстансу робимо знімок
#       🇬🇧 Which DB instance to snapshot
#
#   --db-snapshot-identifier lab5-snap-manual-1
#       🇺🇦 Унікальне ім'я snapshot у вашому акаунті
#       🇬🇧 Unique snapshot name in your account

aws rds create-db-snapshot \
  --db-instance-identifier "lab5-mysql" \
  --db-snapshot-identifier "lab5-snap-manual-1" \
  --tags Key=Name,Value=lab5-manual-snap

echo "✅ Snapshot розпочато / started: lab5-snap-manual-1"
echo "   Стан 'creating' → 'available' через ~5 хв / State 'creating' → 'available'"
```

```bash
# Перегляд всіх snapshot для нашого інстансу / List all snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier "lab5-mysql" \
  --query 'DBSnapshots[*].{
    ID:DBSnapshotIdentifier,
    Status:Status,
    Type:SnapshotType,
    Created:SnapshotCreateTime
  }' \
  --output table
```

```bash
# Відновлення з snapshot у НОВИЙ інстанс / Restore snapshot to a NEW instance
# (Демонстрація концепції — реальне відновлення займає ~15 хв)
# (Concept demo — actual restore takes ~15 min)
#
# aws rds restore-db-instance-from-db-snapshot
#   --db-instance-identifier lab5-mysql-restored
#       🇺🇦 Ім'я НОВОГО інстансу (не можна відновити поверх існуючого!)
#       🇬🇧 Name for the NEW instance (cannot overwrite existing instance!)
#   --db-snapshot-identifier lab5-snap-manual-1
#       🇺🇦 З якого snapshot відновлюємо
#       🇬🇧 Which snapshot to restore from

echo "Команда для відновлення / Restore command (demo — do NOT run in lab):"
echo ""
echo "aws rds restore-db-instance-from-db-snapshot \\"
echo "  --db-instance-identifier lab5-mysql-restored \\"
echo "  --db-snapshot-identifier lab5-snap-manual-1 \\"
echo "  --db-instance-class db.t3.micro \\"
echo "  --db-subnet-group-name lab5-db-subnet-group \\"
echo "  --vpc-security-group-ids $RDS_SG \\"
echo "  --no-publicly-accessible"
```

---

# ════════════════════════════════════════════
# ⚖️  ЛАБ 6 — МАСШТАБУВАННЯ ТА БАЛАНСУВАННЯ / LAB 6 — SCALING & LOAD BALANCING
# ════════════════════════════════════════════

## Теорія / Theory — ALB + ASG

**🇺🇦** Балансування навантаження та автоматичне масштабування — два взаємопов'язані механізми:
- **ALB (Application Load Balancer)** — розподіляє вхідний HTTP/HTTPS трафік між кількома EC2-інстансами. Працює на L7 (рівень застосунку). Може маршрутизувати по URL, заголовках, методах.
- **Target Group** — логічна група EC2-інстансів за якою ALB відстежує стан (health check) і між якими балансує трафік.
- **Auto Scaling Group (ASG)** — автоматично додає/видаляє EC2 залежно від навантаження. Інтегрується з ALB — нові інстанси автоматично реєструються в Target Group.

**🇬🇧** Load balancing and auto scaling are two interconnected mechanisms:
- **ALB** — distributes incoming HTTP/HTTPS traffic across EC2 instances. Operates at L7 (application layer). Can route by URL path, headers, methods.
- **Target Group** — logical group of EC2 instances that ALB health-checks and load-balances across.
- **Auto Scaling Group (ASG)** — automatically adds/removes EC2 based on load. Integrates with ALB — new instances auto-register to the Target Group.

> ```
> Internet → ALB → Target Group → EC2 #1
>                               → EC2 #2   ← ASG manages these
>                               → EC2 #N
> ```

---

## 🎯 Крок 9 — Target Group / Step 9 — Target Group

```bash
# Target Group — група "цілей" для ALB.
# ALB перевіряє здоров'я кожного інстансу через health check
# і направляє трафік тільки до "healthy" інстансів.
#
# Target Group = group of "targets" for the ALB.
# ALB checks each instance's health via health check
# and routes traffic only to "healthy" instances.

# aws elbv2 create-target-group
#   --name lab5-tg
#       🇺🇦 Ім'я групи (до 32 символів)
#       🇬🇧 Group name (up to 32 characters)
#
#   --protocol HTTP
#       🇺🇦 Протокол для трафіку до інстансів (HTTP або HTTPS)
#       🇬🇧 Protocol for traffic to instances (HTTP or HTTPS)
#
#   --port 80
#       🇺🇦 Порт на якому інстанси слухають (наш веб-сервер на 80)
#       🇬🇧 Port on which instances listen (our web server on 80)
#
#   --target-type instance
#       🇺🇦 Тип цілі:
#           instance — EC2 за Instance ID (найчастіше)
#           ip       — конкретна IP (для контейнерів/Lambda)
#           lambda   — Lambda-функція
#       🇬🇧 Target type:
#           instance — EC2 by Instance ID (most common)
#           ip       — specific IP (for containers/Lambda)
#           lambda   — Lambda function
#
#   --vpc-id $VPC_ID
#       🇺🇦 VPC де знаходяться інстанси
#       🇬🇧 VPC where instances reside
#
#   --health-check-protocol HTTP
#       🇺🇦 Яким протоколом ALB перевіряє стан інстансів
#       🇬🇧 Protocol ALB uses to check instance health
#
#   --health-check-path /
#       🇺🇦 URL-шлях для health check запиту (GET /)
#           Інстанс "healthy" якщо відповідає кодом 200
#       🇬🇧 URL path for the health check request (GET /)
#           Instance is "healthy" if it returns status code 200
#
#   --health-check-interval-seconds 30
#       🇺🇦 Як часто ALB перевіряє стан (раз на 30 секунд)
#       🇬🇧 How often ALB checks health (every 30 seconds)
#
#   --healthy-threshold-count 2
#       🇺🇦 Скільки успішних перевірок підряд = "healthy"
#           2 × 30с = 60 сек до визнання "здоровим"
#       🇬🇧 How many consecutive successes = "healthy"
#           2 × 30s = 60 sec to become healthy
#
#   --unhealthy-threshold-count 3
#       🇺🇦 Скільки невдалих перевірок підряд = "unhealthy"
#           3 × 30с = 90 сек до виключення з балансування
#       🇬🇧 How many consecutive failures = "unhealthy"
#           3 × 30s = 90 sec until removed from load balancing

TG_ARN=$(aws elbv2 create-target-group \
  --name "lab5-tg" \
  --protocol HTTP \
  --port 80 \
  --target-type instance \
  --vpc-id "$VPC_ID" \
  --health-check-protocol HTTP \
  --health-check-path "/" \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3 \
  --matcher HttpCode=200 \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

echo "✅ Target Group створено / created: $TG_ARN"
```

---

## ⚖️ Крок 10 — Application Load Balancer / Step 10 — ALB

```bash
# aws elbv2 create-load-balancer
#   --name lab5-alb
#       🇺🇦 Ім'я ALB (до 32 символів, a-z, 0-9, -)
#       🇬🇧 ALB name (up to 32 chars, a-z, 0-9, -)
#
#   --type application
#       🇺🇦 Тип балансувальника:
#           application (ALB) — HTTP/HTTPS, L7, path-based routing
#           network (NLB)     — TCP/UDP, L4, ultra-low latency
#           gateway (GWLB)    — для мережевих appliances (firewall, IDS)
#       🇬🇧 Load balancer type:
#           application (ALB) — HTTP/HTTPS, L7, path-based routing
#           network (NLB)     — TCP/UDP, L4, ultra-low latency
#           gateway (GWLB)    — for network appliances (firewall, IDS)
#
#   --scheme internet-facing
#       🇺🇦 Схема:
#           internet-facing — публічний ALB, доступний з інтернету
#           internal        — приватний ALB, доступний тільки всередині VPC
#       🇬🇧 Scheme:
#           internet-facing — public ALB, accessible from internet
#           internal        — private ALB, accessible only within VPC
#
#   --subnets $PUB_A $PUB_B
#       🇺🇦 Підмережі де розміщуються вузли ALB.
#           ОБОВ'ЯЗКОВО: щонайменше 2 підмережі в різних AZ!
#           ALB розміщується ВО ВСІХ вказаних AZ одночасно
#       🇬🇧 Subnets where ALB nodes are placed.
#           REQUIRED: at least 2 subnets in different AZs!
#           ALB is deployed in ALL specified AZs simultaneously
#
#   --security-groups $ALB_SG
#       🇺🇦 SG що контролює вхідний трафік до ALB
#       🇬🇧 SG controlling inbound traffic to the ALB
#
#   --ip-address-type ipv4
#       🇺🇦 Тип IP: ipv4 або dualstack (IPv4 + IPv6)
#       🇬🇧 IP address type: ipv4 or dualstack (IPv4 + IPv6)

ALB_ARN=$(aws elbv2 create-load-balancer \
  --name "lab5-alb" \
  --type application \
  --scheme internet-facing \
  --subnets "$PUB_A" "$PUB_B" \
  --security-groups "$ALB_SG" \
  --ip-address-type ipv4 \
  --tags Key=Name,Value=lab5-alb \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)

ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns "$ALB_ARN" \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

echo "✅ ALB створено / created!"
echo "   ARN: $ALB_ARN"
echo "   DNS: $ALB_DNS"
echo "   🌐 http://$ALB_DNS  (буде доступний після реєстрації цілей)"
```

```bash
# Створюємо Listener — "слухач" на порту 80
# Create Listener — listens on port 80 and forwards to Target Group

# aws elbv2 create-listener
#   --load-balancer-arn $ALB_ARN  → до якого ALB прикріплюємо listener
#   --protocol HTTP               → слухаємо HTTP
#   --port 80                     → на порту 80
#   --default-actions Type=forward,TargetGroupArn=$TG_ARN
#       🇺🇦 Дія за замовчуванням: перенаправляти весь трафік до Target Group
#           Альтернативи: redirect (301/302), fixed-response (власна відповідь)
#       🇬🇧 Default action: forward all traffic to the Target Group
#           Alternatives: redirect (301/302), fixed-response (custom response)

LISTENER_ARN=$(aws elbv2 create-listener \
  --load-balancer-arn "$ALB_ARN" \
  --protocol HTTP \
  --port 80 \
  --default-actions "Type=forward,TargetGroupArn=${TG_ARN}" \
  --query 'Listeners[0].ListenerArn' \
  --output text)

echo "✅ Listener HTTP:80 → Target Group створено / created"
echo "   ARN: $LISTENER_ARN"
```

---

## 📋 Крок 11 — Launch Template для ASG / Step 11 — Launch Template

```bash
# Launch Template — шаблон конфігурації інстансів для Auto Scaling
# Launch Template = instance configuration blueprint for Auto Scaling

# Веб-застосунок з унікальною ідентифікацією інстансу
# Web app that shows the instance's unique identity
WEB_USERDATA=$(cat << 'ENDUSERDATA'
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# Отримуємо метадані інстансу / Get instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# Створюємо динамічну сторінку / Create dynamic page
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
  <title>Lab 5 — AWS Load Balancing</title>
  <style>
    body { font-family: Arial, sans-serif; text-align: center;
           background: #1a1a2e; color: #eee; padding: 50px; }
    .card { background: #16213e; border-radius: 12px;
            padding: 30px; display: inline-block; }
    .badge { background: #0f3460; border-radius: 6px;
             padding: 6px 14px; margin: 6px; display: inline-block; }
    h1 { color: #e94560; }
    h2 { color: #00b4d8; }
  </style>
</head>
<body>
  <div class="card">
    <h1>🛡️ AWS Academy | Lab 5</h1>
    <h2>Auto Scaling + Load Balancing</h2>
    <hr>
    <p><span class="badge">Instance ID</span> $INSTANCE_ID</p>
    <p><span class="badge">Availability Zone</span> $AZ</p>
    <p><span class="badge">Private IP</span> $PRIVATE_IP</p>
    <p><em>Оновіть сторінку — ALB переключить на інший інстанс!</em></p>
    <p><em>Refresh — ALB will switch to another instance!</em></p>
  </div>
</body>
</html>
EOF

# Health check endpoint / Endpoint для перевірки стану
echo "OK" > /var/www/html/health
ENDUSERDATA
)

# aws ec2 create-launch-template
#   --launch-template-name lab5-lt
#       🇺🇦 Ім'я шаблону (унікальне в акаунті)
#       🇬🇧 Template name (unique in account)
#
#   --version-description "v1"
#       🇺🇦 Опис версії. Шаблони підтримують версіонування:
#           $Latest — завжди найновіша версія
#           $Default — версія позначена як default
#           1, 2, 3... — конкретна версія номер
#       🇬🇧 Version description. Templates support versioning:
#           $Latest — always the newest version
#           $Default — version marked as default
#           1, 2, 3... — specific version number

LT_ID=$(aws ec2 create-launch-template \
  --launch-template-name "lab5-lt" \
  --version-description "v1 — Web server with instance identity page" \
  --launch-template-data "{
    \"ImageId\": \"${LATEST_AMI}\",
    \"InstanceType\": \"t2.micro\",
    \"SecurityGroupIds\": [\"${EC2_SG}\"],
    \"UserData\": \"$(echo "$WEB_USERDATA" | base64 -w0)\",
    \"TagSpecifications\": [{
      \"ResourceType\": \"instance\",
      \"Tags\": [
        {\"Key\":\"Name\",\"Value\":\"lab5-asg-instance\"},
        {\"Key\":\"ManagedBy\",\"Value\":\"ASG\"}
      ]
    }],
    \"Monitoring\": {\"Enabled\": true}
  }" \
  --query 'LaunchTemplate.LaunchTemplateId' \
  --output text)

echo "✅ Launch Template створено / created: $LT_ID"
```

---

## ⚖️ Крок 12 — Auto Scaling Group / Step 12 — Auto Scaling Group

```bash
# Отримуємо список підмереж для ASG (через кому)
# Get comma-separated subnet list for ASG
ASG_SUBNETS="${PUB_A},${PUB_B}"

# aws autoscaling create-auto-scaling-group
#
#   --launch-template LaunchTemplateId=$LT_ID,Version='$Latest'
#       🇺🇦 Посилання на шаблон + версію.
#           $Latest — ASG завжди використовує найновішу версію шаблону
#       🇬🇧 Reference to template + version.
#           $Latest — ASG always uses the newest template version
#
#   --min-size 2
#       🇺🇦 Мінімум 2 інстанси — забезпечує High Availability:
#           якщо один впаде, другий продовжує обслуговувати трафік
#       🇬🇧 Minimum 2 instances — ensures High Availability:
#           if one fails, the other continues serving traffic
#
#   --max-size 6
#       🇺🇦 Максимум 6 — обмежує витрати при пікових навантаженнях
#       🇬🇧 Maximum 6 — limits costs during peak load
#
#   --desired-capacity 2
#       🇺🇦 Стартова кількість інстансів. ASG відразу запустить 2 VM.
#       🇬🇧 Starting instance count. ASG immediately launches 2 VMs.
#
#   --vpc-zone-identifier "$ASG_SUBNETS"
#       🇺🇦 Підмережі через кому. ASG рівномірно розподіляє між AZ
#           (1 інстанс в us-east-1a, 1 інстанс в us-east-1b)
#       🇬🇧 Comma-separated subnets. ASG distributes evenly across AZs
#           (1 instance in us-east-1a, 1 instance in us-east-1b)
#
#   --target-group-arns $TG_ARN
#       🇺🇦 Ключова інтеграція! Новий інстанс автоматично реєструється
#           в Target Group і ALB починає направляти до нього трафік.
#           При видаленні — автоматично знімається з реєстрації.
#       🇬🇧 Key integration! A new instance automatically registers
#           with the Target Group and ALB starts routing traffic to it.
#           On removal — automatically deregistered.
#
#   --health-check-type ELB
#       🇺🇦 Тип health check для ASG:
#           EC2  — перевіряє тільки чи запущений інстанс (системна перевірка)
#           ELB  — перевіряє чи інстанс проходить health check ALB Target Group
#                  (рекомендований! перевіряє що застосунок відповідає)
#       🇬🇧 Health check type for ASG:
#           EC2  — checks only if instance is running (system check)
#           ELB  — checks if instance passes ALB Target Group health check
#                  (recommended! verifies the application responds)
#
#   --health-check-grace-period 120
#       🇺🇦 Затримка перед першою перевіркою (120 сек після запуску).
#           Час для: завантаження ОС + виконання user-data + старт Apache
#       🇬🇧 Delay before first health check (120 sec after launch).
#           Time for: OS boot + user-data execution + Apache start

aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name "lab5-asg" \
  --launch-template "LaunchTemplateId=${LT_ID},Version=\$Latest" \
  --min-size 2 \
  --max-size 6 \
  --desired-capacity 2 \
  --vpc-zone-identifier "$ASG_SUBNETS" \
  --target-group-arns "$TG_ARN" \
  --health-check-type ELB \
  --health-check-grace-period 120 \
  --tags \
    "Key=Name,Value=lab5-asg-instance,PropagateAtLaunch=true" \
    "Key=Env,Value=lab,PropagateAtLaunch=true"

echo "✅ Auto Scaling Group створено / created: lab5-asg"
echo "⏳ ASG запускає 2 інстанси / ASG launching 2 instances..."
```

---

## 📈 Крок 13 — Scaling Policies / Step 13 — Scaling Policies

```bash
# ── Target Tracking Policy: CPU ──────────────────────────────────────
# Найпростіший спосіб: вказуємо цільове значення, AWS сам розраховує кроки
# Simplest approach: specify the target, AWS auto-calculates scale steps

# aws autoscaling put-scaling-policy
#   --policy-type TargetTrackingScaling
#       🇺🇦 AWS автоматично додає/видаляє інстанси щоб утримати CPU ~60%
#           Масштабування вгору: якщо CPU > 60% — додає інстанс
#           Масштабування вниз: якщо CPU < 60% стабільно — видаляє
#       🇬🇧 AWS auto adds/removes instances to maintain CPU ~60%
#           Scale out: if CPU > 60% — adds instance
#           Scale in: if CPU < 60% consistently — removes instance

POLICY_ARN=$(aws autoscaling put-scaling-policy \
  --auto-scaling-group-name "lab5-asg" \
  --policy-name "lab5-cpu-target-tracking" \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ASGAverageCPUUtilization"
    },
    "TargetValue": 60.0,
    "ScaleInCooldown": 180,
    "ScaleOutCooldown": 60,
    "DisableScaleIn": false
  }' \
  --query 'PolicyARN' \
  --output text)

# ScaleOutCooldown: 60 сек
#     🇺🇦 Мінімальна пауза між додаванням інстансів (короткий — реагуємо швидко)
#     🇬🇧 Minimum pause between adding instances (short — react quickly)
# ScaleInCooldown: 180 сек
#     🇺🇦 Мінімальна пауза між видаленням інстансів (довший — не видаляємо передчасно)
#     🇬🇧 Minimum pause between removing instances (longer — don't remove prematurely)

echo "✅ CPU Target Tracking Policy (target: 60%)"
echo "   ARN: $POLICY_ARN"
```

```bash
# ── Step Scaling Policy: мережевий трафік / Network traffic ──────────
# Додатковий приклад: StepScaling — різні кроки залежно від рівня перевищення
# Additional example: StepScaling — different steps based on breach magnitude

# Спочатку створюємо CloudWatch Alarm для Network трафіку
# First create a CloudWatch Alarm for network traffic

aws cloudwatch put-metric-alarm \
  --alarm-name "lab5-high-network" \
  --alarm-description "Network traffic > 5MB/min for 5 minutes" \
  --metric-name NetworkIn \
  --namespace AWS/EC2 \
  --dimensions "Name=AutoScalingGroupName,Value=lab5-asg" \
  --statistic Sum \
  --period 60 \
  --evaluation-periods 5 \
  --threshold 5000000 \
  --comparison-operator GreaterThanThreshold \
  --treat-missing-data notBreaching

# Тепер Step Scaling Policy / Now Step Scaling Policy
# --step-adjustments
#     🇺🇦 Масив кроків. Кожен крок: діапазон перевищення → дія
#         MetricIntervalLowerBound/UpperBound визначають діапазон відносно порогу
#     🇬🇧 Array of steps. Each step: breach range → action
#         MetricIntervalLowerBound/UpperBound define range relative to threshold

STEP_POLICY_ARN=$(aws autoscaling put-scaling-policy \
  --auto-scaling-group-name "lab5-asg" \
  --policy-name "lab5-network-step-out" \
  --policy-type StepScaling \
  --adjustment-type ChangeInCapacity \
  --step-adjustments \
    'MetricIntervalLowerBound=0,MetricIntervalUpperBound=2000000,ScalingAdjustment=1' \
    'MetricIntervalLowerBound=2000000,ScalingAdjustment=2' \
  --query 'PolicyARN' --output text)

echo "✅ Step Scaling Policy (network-based):"
echo "   Перевищення 0–2MB → додати 1 інстанс / 0–2MB over → add 1 instance"
echo "   Перевищення >2MB  → додати 2 інстанси / >2MB over → add 2 instances"
```

---

## 🔔 Крок 14 — SNS + CloudWatch Notifications / Step 14 — Notifications

```bash
# SNS Topic для сповіщень ASG
# SNS Topic for ASG notifications

SNS_ARN=$(aws sns create-topic \
  --name "lab5-asg-notifications" \
  --query 'TopicArn' --output text)

aws sns subscribe \
  --topic-arn "$SNS_ARN" \
  --protocol email \
  --notification-endpoint "your-email@example.com"

echo "✅ SNS Topic: $SNS_ARN"
echo "⚠️  Підтвердіть підписку на email! / Confirm email subscription!"
```

```bash
# Підписуємо ASG на SNS — отримуємо сповіщення при кожній зміні
# Subscribe ASG to SNS — receive notifications on every scaling event

# aws autoscaling put-notification-configuration
#   --notification-types
#       🇺🇦 Типи подій про які хочемо отримувати сповіщення:
#           autoscaling:EC2_INSTANCE_LAUNCH         — інстанс запущено
#           autoscaling:EC2_INSTANCE_LAUNCH_ERROR   — помилка запуску
#           autoscaling:EC2_INSTANCE_TERMINATE      — інстанс завершено
#           autoscaling:EC2_INSTANCE_TERMINATE_ERROR— помилка завершення
#       🇬🇧 Event types to receive notifications for:
#           autoscaling:EC2_INSTANCE_LAUNCH         — instance launched
#           autoscaling:EC2_INSTANCE_LAUNCH_ERROR   — launch failed
#           autoscaling:EC2_INSTANCE_TERMINATE      — instance terminated
#           autoscaling:EC2_INSTANCE_TERMINATE_ERROR— termination failed

aws autoscaling put-notification-configuration \
  --auto-scaling-group-name "lab5-asg" \
  --topic-arn "$SNS_ARN" \
  --notification-types \
    "autoscaling:EC2_INSTANCE_LAUNCH" \
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR" \
    "autoscaling:EC2_INSTANCE_TERMINATE" \
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"

echo "✅ ASG notifications → SNS налаштовано / configured"
```

---

## 🧪 Крок 15 — Тестування та перевірка / Step 15 — Testing & Verification

### 15.1 Перевірка ALB / Verify ALB

```bash
# Чекаємо поки ALB стане активним / Wait for ALB to become active
echo "⏳ Waiting for ALB to become active..."
aws elbv2 wait load-balancer-available --load-balancer-arns "$ALB_ARN"

echo "✅ ALB активний / active!"
echo "🌐 Відкрийте у браузері / Open in browser: http://$ALB_DNS"
echo "   Оновлюйте сторінку — Instance ID та AZ змінюватимуться!"
echo "   Refresh the page — Instance ID and AZ will change!"
```

```bash
# Перевірка стану Target Group / Check Target Group health
aws elbv2 describe-target-health \
  --target-group-arn "$TG_ARN" \
  --query 'TargetHealthDescriptions[*].{
    Instance:Target.Id,
    Port:Target.Port,
    Health:TargetHealth.State,
    Description:TargetHealth.Description
  }' \
  --output table

# Стани / States:
# initial     — щойно зареєстровано, health check ще не пройдено
# healthy     — проходить health check, ALB направляє трафік
# unhealthy   — не проходить health check, ALB НЕ направляє трафік
# draining    — видаляється, ALB завершує активні з'єднання
```

### 15.2 Тест балансування / Load Balancing Test

```bash
# Надсилаємо 10 запитів і спостерігаємо розподіл між інстансами
# Send 10 requests and observe distribution across instances

echo "Тестуємо балансування / Testing load balancing (10 requests):"
for i in $(seq 1 10); do
  RESPONSE=$(curl -s "http://$ALB_DNS" | grep -oP '(?<=<p><span class="badge">Instance ID</span> )i-[a-z0-9]+')
  echo "  Запит $i / Request $i → $RESPONSE"
  sleep 1
done
echo ""
echo "Якщо бачите різні Instance ID — ALB балансує трафік!"
echo "If you see different Instance IDs — ALB is distributing traffic!"
```

### 15.3 Тест масштабування / Scaling Test

```bash
# Демонструємо ручне масштабування / Demonstrate manual scaling

echo "=== Поточний стан ASG / Current ASG state ==="
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "lab5-asg" \
  --query 'AutoScalingGroups[0].{
    Min:MinSize, Max:MaxSize,
    Desired:DesiredCapacity,
    Running:length(Instances[?LifecycleState==`InService`])
  }' --output table

echo ""
echo "=== Масштабуємо вгору до 4 / Scale OUT to 4 ==="

# aws autoscaling set-desired-capacity
#   🇺🇦 Безпосередньо встановлюємо бажану кількість.
#       ASG сам визначить які інстанси додати і в яких AZ
#   🇬🇧 Directly set the desired count.
#       ASG determines which instances to add and in which AZs

aws autoscaling set-desired-capacity \
  --auto-scaling-group-name "lab5-asg" \
  --desired-capacity 4

echo "✅ Desired → 4. Чекаємо запуску / Waiting for new instances..."
sleep 90

# Перевіряємо Target Group — нові інстанси повинні зареєструватись
# Check Target Group — new instances should auto-register
aws elbv2 describe-target-health \
  --target-group-arn "$TG_ARN" \
  --query 'TargetHealthDescriptions[*].{Instance:Target.Id,Health:TargetHealth.State}' \
  --output table

echo ""
echo "=== Масштабуємо вниз до 2 / Scale IN back to 2 ==="
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name "lab5-asg" \
  --desired-capacity 2

echo "✅ Desired → 2. ASG видалить 2 інстанси / ASG will terminate 2 instances"
```

---

## 📊 Крок 16 — Фінальний огляд / Step 16 — Final Summary

```bash
echo "══════════════════════════════════════════════════════════════"
echo "     ПІДСУМОК ЗАНЯТТЯ 5 / LAB 5 SUMMARY                      "
echo "══════════════════════════════════════════════════════════════"

echo -e "\n🗃️  LAB 5: RDS MySQL"
aws rds describe-db-instances \
  --db-instance-identifier "lab5-mysql" \
  --query 'DBInstances[0].{
    ID:DBInstanceIdentifier,
    Status:DBInstanceStatus,
    Endpoint:Endpoint.Address,
    Class:DBInstanceClass
  }' --output table 2>/dev/null || echo "  RDS not found"

echo -e "\n⚖️  LAB 6: ALB"
aws elbv2 describe-load-balancers \
  --load-balancer-arns "$ALB_ARN" \
  --query 'LoadBalancers[0].{
    Name:LoadBalancerName,
    DNS:DNSName,
    State:State.Code
  }' --output table 2>/dev/null || echo "  ALB not found"

echo -e "\n🎯  Target Group Health"
aws elbv2 describe-target-health \
  --target-group-arn "$TG_ARN" \
  --query 'TargetHealthDescriptions[*].{
    Instance:Target.Id,
    Health:TargetHealth.State
  }' --output table 2>/dev/null

echo -e "\n⚙️  Auto Scaling Group"
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "lab5-asg" \
  --query 'AutoScalingGroups[0].{
    Name:AutoScalingGroupName,
    Min:MinSize, Max:MaxSize, Desired:DesiredCapacity
  }' --output table 2>/dev/null
```

---

## 💾 Збережіть змінні / Save Variables

```bash
cat << EOF
=== ЗБЕРЕЖІТЬ / SAVE THESE VALUES ===
VPC_ID=$VPC_ID
PUB_A=$PUB_A
PUB_B=$PUB_B
PRIV_A=$PRIV_A
PRIV_B=$PRIV_B
PUB_RT=$PUB_RT
IGW_ID=$IGW_ID
EC2_SG=$EC2_SG
RDS_SG=$RDS_SG
ALB_SG=$ALB_SG
RDS_ENDPOINT=$RDS_ENDPOINT
TG_ARN=$TG_ARN
ALB_ARN=$ALB_ARN
ALB_DNS=$ALB_DNS
LISTENER_ARN=$LISTENER_ARN
LT_ID=$LT_ID
SNS_ARN=$SNS_ARN
BASTION_ID=$BASTION_ID
EOF
```

---

## 🧹 Крок 17 — Очищення / Step 17 — Cleanup

> ⚠️ **Порядок важливий!** Видаляємо у зворотному порядку залежностей.
> ⚠️ **Order matters!** Delete in reverse dependency order.

```bash
# 1. Вимикаємо захист від видалення RDS / Disable RDS deletion protection
aws rds modify-db-instance \
  --db-instance-identifier "lab5-mysql" \
  --no-deletion-protection --apply-immediately
echo "✅ RDS deletion protection disabled"

# 2. Видаляємо ASG (примусово) / Delete ASG (force)
aws autoscaling delete-auto-scaling-group \
  --auto-scaling-group-name "lab5-asg" --force-delete
echo "✅ ASG deletion started"

# 3. Видаляємо ALB та Listener
aws elbv2 delete-listener --listener-arn "$LISTENER_ARN"
aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN"
echo "✅ ALB deleted"

# 4. Видаляємо Target Group (після ALB!)
sleep 10
aws elbv2 delete-target-group --target-group-arn "$TG_ARN"
echo "✅ Target Group deleted"

# 5. Видаляємо Launch Template
aws ec2 delete-launch-template --launch-template-id "$LT_ID"
echo "✅ Launch Template deleted"

# 6. Видаляємо SNS
aws sns delete-topic --topic-arn "$SNS_ARN"
echo "✅ SNS Topic deleted"

# 7. Видаляємо CloudWatch Alarm
aws cloudwatch delete-alarms --alarm-names "lab5-high-network"
echo "✅ CloudWatch Alarm deleted"

# 8. Видаляємо RDS (без фінального snapshot)
aws rds delete-db-instance \
  --db-instance-identifier "lab5-mysql" \
  --skip-final-snapshot
echo "⏳ RDS deletion started (~10 min)"

# 9. Видаляємо Bastion EC2
aws ec2 terminate-instances --instance-ids "$BASTION_ID"
echo "✅ Bastion terminated"

# 10. Чистимо мережу / Network cleanup
sleep 10
aws ec2 delete-subnet --subnet-id $PUB_A
aws ec2 delete-subnet --subnet-id $PUB_B
aws ec2 delete-subnet --subnet-id $PRIV_A
aws ec2 delete-subnet --subnet-id $PRIV_B
aws ec2 delete-route-table --route-table-id $PUB_RT
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
aws ec2 delete-security-group --group-id $ALB_SG
aws ec2 delete-security-group --group-id $EC2_SG
aws ec2 delete-security-group --group-id $RDS_SG
aws rds delete-db-subnet-group --db-subnet-group-name "lab5-db-subnet-group"
aws rds delete-db-parameter-group --db-parameter-group-name "lab5-mysql-params"

# VPC — останньою / VPC — last
aws ec2 delete-vpc --vpc-id $VPC_ID

echo ""
echo "🎉 Cleanup complete! Дякуємо! 🇺🇦"
```

---

## 📚 Ключові концепції / Key Concepts

| Компонент | 🇺🇦 Опис | 🇬🇧 Description |
|---|---|---|
| **RDS** | Керована реляційна БД | Managed relational DB |
| **DB Subnet Group** | Приватні підмережі для БД | Private subnets for DB |
| **Parameter Group** | Конфігурація СУБД (my.cnf) | DB engine config |
| **DB Snapshot** | Резервна копія стану БД | Point-in-time DB backup |
| **Multi-AZ** | Авто-failover через синхронну репліку | Auto-failover via sync replica |
| **ALB** | HTTP/HTTPS балансувальник L7 | HTTP/HTTPS load balancer L7 |
| **Target Group** | Реєстр цілей + health checks | Target registry + health checks |
| **Listener** | Правило ALB для порту/протоколу | ALB rule for port/protocol |
| **Launch Template** | Шаблон конфігурації EC2 | EC2 config blueprint |
| **ASG** | Автоматична зміна кількості EC2 | Automatic EC2 count management |
| **Target Tracking** | Підтримка цільової метрики | Maintain target metric value |
| **Step Scaling** | Різні кроки при різних рівнях | Different steps per breach level |
| **Health Check (ELB)** | Перевірка застосунку через ALB | App check via ALB |
| **Cooldown** | Пауза між операціями масштабування | Pause between scaling operations |

---

## 🎯 Самоперевірка / Self-Assessment

```bash
curl -O https://raw.githubusercontent.com/rossogamata/main/check.sh
chmod +x check.sh && ./check.sh
```

---

*Підготовлено для AWS Academy Learner Lab | Хмарні технології — 5 курс | Заняття 5*
*Prepared for AWS Academy Learner Lab | Cloud Technologies — 5th Year | Lab 5* 🇺🇦
