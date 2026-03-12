# ☁️ AWS — Заняття 4: Зберігання · Бази даних · Масштабування · Моніторинг
### Cloud Technologies Lab 4 — Storage · Databases · Auto Scaling · Monitoring
#### 5-й курс / 5th Year | AWS Academy Learner Lab (CloudShell)

> **Тривалість / Duration:** ~120 хвилин / minutes
> **Середовище / Environment:** AWS Academy Learner Lab → CloudShell (`>_`)

---

## 📋 Навчальні питання / Learning Objectives

| # | Тема / Topic | Сервіси / Services |
|---|---|---|
| **1** | 🗄️ Зберігання даних / Data Storage | **S3**, **EBS** |
| **2** | 🗃️ Бази даних / Databases | **RDS** (MySQL), **DynamoDB** |
| **3** | 📈 Масштабування та моніторинг / Scaling & Monitoring | **Auto Scaling**, **CloudWatch**, **SNS** |

---

## 🗺️ Архітектура заняття / Lab Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│  AWS REGION: us-east-1                                             │
│                                                                    │
│  ┌──────────────────┐    ┌───────────────────────────────────────┐ │
│  │  STORAGE         │    │  AUTO SCALING GROUP                   │ │
│  │                  │    │  ┌─────────┐ ┌─────────┐ ┌─────────┐ │ │
│  │  📦 S3 Bucket    │    │  │  EC2 #1 │ │  EC2 #2 │ │  EC2 #3 │ │ │
│  │  (objects/files) │    │  │ (t2.micro)│(t2.micro)│(scale-out)│ │ │
│  │                  │    │  └─────────┘ └─────────┘ └─────────┘ │ │
│  │  💾 EBS Volume   │    │  Launch Template + Scaling Policies   │ │
│  │  (block storage) │    └───────────────────────────────────────┘ │
│  └──────────────────┘                  ↕ CloudWatch Alarm          │
│                                        ↕ SNS Notification          │
│  ┌──────────────────────────────────┐                              │
│  │  DATABASES                       │                              │
│  │  🐬 RDS MySQL  │  🔑 DynamoDB   │                              │
│  │  (relational)  │  (NoSQL/key-val)│                              │
│  └──────────────────────────────────┘                              │
└────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Підготовка / Preparation

Запустіть Learner Lab → відкрийте **CloudShell** (`>_`). / Start Learner Lab → open **CloudShell** (`>_`).

```bash
# Перевірка середовища / Verify environment
aws sts get-caller-identity

# Збережемо регіон та AccountID у змінні для зручності
# Save region and AccountID into variables for convenience
export AWS_REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
echo "Account: $ACCOUNT_ID  |  Region: $AWS_REGION"
```

---

# 🗄️ ПИТАННЯ 1 — ЗБЕРІГАННЯ ДАНИХ / TOPIC 1 — DATA STORAGE

## Теорія / Theory

**🇺🇦** AWS пропонує кілька рівнів зберігання:
- **S3** (Simple Storage Service) — об'єктне сховище. Зберігає файли як "об'єкти" у "бакетах". Безмежна ємність, 99.999999999% довговічність. Ідеально для статики, резервних копій, Data Lake.
- **EBS** (Elastic Block Store) — блочне сховище. Аналог жорсткого диску. Прикріплюється до EC2-інстансу. Швидкий доступ, підходить для ОС та баз даних.
- **EFS** (Elastic File System) — мережева файлова система. Спільний доступ для кількох EC2 одночасно.

**🇬🇧** AWS offers several storage tiers:
- **S3** — Object storage. Files are "objects" inside "buckets". Unlimited capacity, 11 nines of durability. Best for static files, backups, Data Lakes.
- **EBS** — Block storage. Like a hard drive. Attached to an EC2 instance. Fast access, best for OS and databases.
- **EFS** — Network file system. Shared access across multiple EC2 simultaneously.

> | | S3 | EBS | EFS |
> |---|---|---|---|
> | Тип / Type | Object | Block | File |
> | Доступ / Access | HTTP/API | Mounted to 1 EC2 | Mounted to many EC2 |
> | Використання / Use | Files, backups | OS disk, DB | Shared config, media |
> | Ціна / Price | Per GB stored | Per GB provisioned | Per GB used |

---

## 📦 Крок 1 — Amazon S3 / Step 1 — Amazon S3

### 1.1 Створення бакету / Create a bucket

```bash
# Ім'я бакету повинно бути глобально унікальним у всьому AWS
# Bucket name must be globally unique across all of AWS
# Додаємо AccountID щоб гарантувати унікальність
# We append AccountID to guarantee uniqueness

BUCKET_NAME="academy-lab4-${ACCOUNT_ID}"
echo "Bucket name / Ім'я бакету: $BUCKET_NAME"
```

```bash
# aws s3api create-bucket
#   --bucket $BUCKET_NAME
#       🇺🇦 Ім'я бакету — глобально унікальне (лише малі літери, цифри, тире)
#       🇬🇧 Bucket name — globally unique (lowercase letters, digits, hyphens only)
#
#   --region $AWS_REGION
#       🇺🇦 Регіон де фізично зберігатимуться дані
#       🇬🇧 The AWS region where the data will physically reside
#
#   Увага: для us-east-1 НЕ вказуємо --create-bucket-configuration
#   Note: for us-east-1 do NOT add --create-bucket-configuration (it's the default)

aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$AWS_REGION"

echo "✅ S3 bucket створено / created: $BUCKET_NAME"
```

### 1.2 Вмикаємо версіонування / Enable versioning

```bash
# Версіонування — кожна нова версія об'єкта зберігається окремо.
# Дозволяє відновити попередню версію файлу.
# Versioning — every overwrite creates a new version.
# Allows restoring previous versions of any file.

# aws s3api put-bucket-versioning
#   --bucket $BUCKET_NAME        → до якого бакету застосовуємо / target bucket
#   --versioning-configuration   → конфігурація у форматі JSON
#     Status=Enabled             → вмикаємо / enable versioning

aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

echo "✅ Versioning увімкнено / enabled"
```

### 1.3 Завантажуємо об'єкти / Upload objects

```bash
# Створюємо тестові файли прямо в CloudShell
# Create test files directly in CloudShell

echo "Hello from WebServer — version 1" > index.html
echo "SELECT * FROM users;" > query.sql
echo "server: nginx" > config.yaml

# aws s3 cp (висока абстракція — копіює файли) / high-level command
#   <source>         → локальний файл або s3:// / local file or s3://
#   <destination>    → s3://<bucket>/<key> — "ключ" це шлях до об'єкта
#                      s3://<bucket>/<key> — "key" is the object path
#   --storage-class  → клас зберігання (STANDARD, STANDARD_IA, GLACIER...)
#                      storage class (STANDARD, STANDARD_IA, GLACIER...)

aws s3 cp index.html  "s3://${BUCKET_NAME}/web/index.html"  --storage-class STANDARD
aws s3 cp query.sql   "s3://${BUCKET_NAME}/db/query.sql"
aws s3 cp config.yaml "s3://${BUCKET_NAME}/config/config.yaml"

echo "✅ Файли завантажено / Files uploaded"
```

```bash
# Перегляд вмісту бакету / List bucket contents
# aws s3 ls s3://<bucket> --recursive
#   --recursive  → рекурсивно показує всі об'єкти у всіх "папках"
#                  recursively show all objects in all "folders"
#   "Папки" в S3 — це ілюзія! Насправді це просто префікс у імені об'єкта.
#   "Folders" in S3 are virtual! They are just a prefix in the object key.

aws s3 ls "s3://${BUCKET_NAME}" --recursive

echo "✅ Перелік об'єктів / Objects listed"
```

### 1.4 Версіонування в дії / Versioning in action

```bash
# Перезаписуємо файл — стара версія зберігається автоматично
# Overwrite the file — the old version is kept automatically

echo "Hello from WebServer — version 2 (UPDATED)" > index.html
aws s3 cp index.html "s3://${BUCKET_NAME}/web/index.html"
echo "✅ Файл оновлено / File updated (version 2)"
```

```bash
# Переглядаємо всі версії об'єкта
# List all versions of an object

# aws s3api list-object-versions
#   --bucket $BUCKET_NAME           → бакет / bucket
#   --prefix "web/index.html"       → фільтруємо по префіксу (конкретний файл)
#                                     filter by prefix (specific file)

aws s3api list-object-versions \
  --bucket "$BUCKET_NAME" \
  --prefix "web/index.html" \
  --query 'Versions[*].{VersionId:VersionId,LastModified:LastModified,IsLatest:IsLatest}' \
  --output table

echo "✅ Версії відображено / Versions shown"
```

### 1.5 Lifecycle Policy — автоматичне управління даними

```bash
# Lifecycle Policy — правила що автоматично переміщують або видаляють об'єкти
# через певний час. Дозволяє знизити витрати.
# Lifecycle Policy — rules that automatically transition or expire objects
# after a certain time. Reduces storage costs.
#
# Рівні зберігання (від дорогого до дешевого) / Storage tiers (expensive → cheap):
# STANDARD (миттєвий доступ) → STANDARD_IA (рідкий доступ) → GLACIER (архів)

cat > lifecycle.json << 'EOF'
{
  "Rules": [
    {
      "ID": "MoveToIA-then-Glacier",
      "Status": "Enabled",
      "Filter": {"Prefix": ""},
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 90,
          "StorageClass": "GLACIER"
        }
      ],
      "Expiration": {
        "Days": 365
      }
    }
  ]
}
EOF

# aws s3api put-bucket-lifecycle-configuration
#   --bucket $BUCKET_NAME                        → цільовий бакет / target bucket
#   --lifecycle-configuration file://lifecycle.json
#       🇺🇦 file:// — читаємо конфігурацію з локального JSON файлу
#       🇬🇧 file:// prefix — read configuration from a local JSON file

aws s3api put-bucket-lifecycle-configuration \
  --bucket "$BUCKET_NAME" \
  --lifecycle-configuration file://lifecycle.json

echo "✅ Lifecycle policy налаштовано / configured:"
echo "   Day 0–29   → STANDARD"
echo "   Day 30–89  → STANDARD_IA  (cheaper, <1s retrieval)"
echo "   Day 90–364 → GLACIER      (cheapest, minutes retrieval)"
echo "   Day 365    → DELETED automatically"
```

---

## 💾 Крок 2 — Amazon EBS / Step 2 — Amazon EBS

**🇺🇦** EBS — блочне сховище, аналог SSD/HDD для EC2. Том EBS існує незалежно від інстансу — можна відкріпити від одного і прикріпити до іншого. Дані зберігаються навіть після зупинки EC2.

**🇬🇧** EBS is block storage — like an SSD/HDD for EC2. An EBS volume exists independently from the instance — you can detach it from one and attach to another. Data persists even after stopping EC2.

### 2.1 Створення тому / Create a volume

```bash
# aws ec2 create-volume
#   --volume-type gp3
#       🇺🇦 Тип тому: gp3 = General Purpose SSD v3, найкраще співвідношення ціна/якість
#           Типи: gp2, gp3 (SSD загального призначення)
#                 io1, io2 (високопродуктивний SSD для БД)
#                 st1 (Throughput HDD для великих даних)
#                 sc1 (Cold HDD для архівів)
#       🇬🇧 Volume type: gp3 = General Purpose SSD v3, best price/performance
#           Types: gp2/gp3 (general SSD), io1/io2 (high-perf DB SSD),
#                  st1 (throughput HDD), sc1 (cold HDD archive)
#
#   --size 10
#       🇺🇦 Розмір тому в гігабайтах (мінімум 1 ГБ для gp3)
#       🇬🇧 Volume size in gigabytes (minimum 1 GB for gp3)
#
#   --availability-zone us-east-1a
#       🇺🇦 EBS том повинен бути в тій самій AZ що й EC2-інстанс!
#           Не можна прикріпити том з us-east-1a до інстансу в us-east-1b
#       🇬🇧 EBS volume MUST be in the same AZ as the target EC2 instance!
#           Cannot attach a volume from us-east-1a to an instance in us-east-1b

EBS_ID=$(aws ec2 create-volume \
  --volume-type gp3 \
  --size 10 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=academy-data-vol}]' \
  --query 'VolumeId' \
  --output text)

echo "✅ EBS Volume створено / created: $EBS_ID"
```

```bash
# Перевіряємо статус тому / Check volume status
# aws ec2 describe-volumes
#   --volume-ids $EBS_ID             → фільтруємо по ID нашого тому / our volume
#   --query '...'                    → витягуємо потрібні поля / extract relevant fields

aws ec2 describe-volumes \
  --volume-ids "$EBS_ID" \
  --query 'Volumes[0].{ID:VolumeId,Type:VolumeType,Size:Size,State:State,AZ:AvailabilityZone}' \
  --output table

# State "available" = том вільний, готовий до прикріплення
# State "available" = volume is free and ready to attach
```

### 2.2 Прикріплення тому до EC2 / Attach volume to EC2

> ⚠️ **Для цього кроку потрібен запущений EC2-інстанс у us-east-1a.** / **This step requires a running EC2 instance in us-east-1a.**
> Якщо є інстанс з попереднього заняття — підставте його ID. / If you have an instance from the previous lab, use its ID.

```bash
# Якщо немає інстансу — створіть мінімальний для демонстрації:
# If you don't have an instance — create a minimal one for demo:

# Знаходимо AMI / Find AMI
DEMO_AMI=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-2023*-x86_64" "Name=state,Values=available" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text)

# Знаходимо default VPC та subnet / Find default VPC and subnet
DEFAULT_VPC=$(aws ec2 describe-vpcs \
  --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)
DEFAULT_SUBNET=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$DEFAULT_VPC" "Name=availabilityZone,Values=us-east-1a" \
  --query 'Subnets[0].SubnetId' --output text)

DEMO_INSTANCE=$(aws ec2 run-instances \
  --image-id "$DEMO_AMI" --instance-type t2.micro \
  --subnet-id "$DEFAULT_SUBNET" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ebs-demo}]' \
  --query 'Instances[0].InstanceId' --output text)

echo "⏳ Чекаємо запуску / Waiting for instance..."
aws ec2 wait instance-running --instance-ids "$DEMO_INSTANCE"
echo "✅ Demo instance: $DEMO_INSTANCE"
```

```bash
# aws ec2 attach-volume
#   --volume-id $EBS_ID
#       🇺🇦 ID тому який прикріплюємо
#       🇬🇧 The volume to attach
#
#   --instance-id $DEMO_INSTANCE
#       🇺🇦 EC2-інстанс до якого прикріплюємо (повинен бути в тій самій AZ!)
#       🇬🇧 Target EC2 instance (MUST be in the same AZ!)
#
#   --device /dev/sdf
#       🇺🇦 Ім'я пристрою всередині EC2 (Linux побачить як /dev/xvdf або /dev/nvme1n1)
#           /dev/sda1 зарезервований для root-тому ОС
#       🇬🇧 Device name inside the EC2 (Linux will see it as /dev/xvdf or /dev/nvme1n1)
#           /dev/sda1 is reserved for the root OS volume

aws ec2 attach-volume \
  --volume-id "$EBS_ID" \
  --instance-id "$DEMO_INSTANCE" \
  --device /dev/sdf

echo "✅ EBS том прикріплено / Volume attached"
echo "   Всередині EC2 том з'явиться як /dev/xvdf або /dev/nvme1n1"
echo "   Inside EC2 the volume appears as /dev/xvdf or /dev/nvme1n1"
```

```bash
# Після прикріплення — ось як ініціалізувати том у Linux (виконується на самому EC2):
# After attaching — here's how to initialize the volume on the EC2 (run ON the instance):

cat << 'ONINSTANCE'
# ── Виконувати на EC2-інстансі / Run ON the EC2 instance ──
# Знайти новий пристрій / Find the new device:
  lsblk

# Відформатувати (лише перший раз!) / Format (first time only!):
  sudo mkfs -t ext4 /dev/xvdf

# Створити точку монтування і змонтувати / Create mount point and mount:
  sudo mkdir /data
  sudo mount /dev/xvdf /data
  df -h /data

# Зробити монтування постійним (після перезавантаження) / Persist mount after reboot:
  echo "/dev/xvdf /data ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
ONINSTANCE
```

### 2.3 Знімок (Snapshot) EBS / EBS Snapshot

```bash
# Snapshot — "фотографія" стану тому в певний момент часу.
# Зберігається в S3 (автоматично, ви не бачите бакет).
# Використовується для: резервних копій, клонування томів між AZ/регіонами.
#
# Snapshot = point-in-time copy of an EBS volume.
# Stored in S3 internally (managed by AWS, no bucket visible to you).
# Used for: backups, cloning volumes across AZs/regions.

# aws ec2 create-snapshot
#   --volume-id $EBS_ID
#       🇺🇦 ID тому з якого робимо знімок (том може бути прикріплений — live snapshot)
#       🇬🇧 Volume to snapshot (can be attached — AWS does live snapshot safely)
#
#   --description "..."
#       🇺🇦 Текстовий опис — для ідентифікації серед інших знімків
#       🇬🇧 Text description — for identifying this snapshot later

SNAPSHOT_ID=$(aws ec2 create-snapshot \
  --volume-id "$EBS_ID" \
  --description "Academy Lab4 — initial snapshot" \
  --tag-specifications 'ResourceType=snapshot,Tags=[{Key=Name,Value=academy-snap-1}]' \
  --query 'SnapshotId' \
  --output text)

echo "✅ Snapshot розпочато / Snapshot started: $SNAPSHOT_ID"
echo "   (Статус 'pending' → 'completed' через кілька хвилин)"
echo "   (Status 'pending' → 'completed' in a few minutes)"
```

---

# 🗃️ ПИТАННЯ 2 — БАЗИ ДАНИХ / TOPIC 2 — DATABASES

## Теорія / Theory

**🇺🇦** AWS пропонує:
- **RDS** (Relational Database Service) — керована реляційна БД: MySQL, PostgreSQL, MariaDB, Oracle, MSSQL. AWS управляє патчами, бекапами, failover.
- **DynamoDB** — безсерверна NoSQL БД типу "ключ-значення" та документна. Горизонтально масштабується до будь-яких навантажень. Мілісекундна затримка.
- **ElastiCache** — кешування у пам'яті (Redis, Memcached).
- **Aurora** — хмарна реляційна БД від AWS, сумісна з MySQL/PostgreSQL, 5× швидша.

**🇬🇧** AWS offers:
- **RDS** — Managed relational DB: MySQL, PostgreSQL, MariaDB, Oracle, MSSQL. AWS handles patches, backups, failover.
- **DynamoDB** — Serverless NoSQL key-value and document database. Horizontally scales to any load. Millisecond latency.
- **ElastiCache** — In-memory caching (Redis, Memcached).
- **Aurora** — AWS cloud-native relational DB, MySQL/PostgreSQL compatible, 5× faster.

---

## 🐬 Крок 3 — Amazon RDS (MySQL) / Step 3 — Amazon RDS

### 3.1 Subnet Group — обов'язковий крок для RDS

```bash
# RDS потребує DB Subnet Group — набір підмереж у різних AZ
# для забезпечення Multi-AZ відмовостійкості.
# RDS requires a DB Subnet Group — a set of subnets across multiple AZs
# to support Multi-AZ failover.

# Знаходимо підмережі default VPC у двох AZ
# Find subnets of the default VPC in two AZs

DEFAULT_VPC=$(aws ec2 describe-vpcs \
  --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)

SUB_1A=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$DEFAULT_VPC" "Name=availabilityZone,Values=us-east-1a" \
  --query 'Subnets[0].SubnetId' --output text)

SUB_1B=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$DEFAULT_VPC" "Name=availabilityZone,Values=us-east-1b" \
  --query 'Subnets[0].SubnetId' --output text)

echo "VPC: $DEFAULT_VPC"
echo "Subnet 1a: $SUB_1A | Subnet 1b: $SUB_1B"
```

```bash
# aws rds create-db-subnet-group
#   --db-subnet-group-name           → ім'я групи підмереж / subnet group name
#   --db-subnet-group-description    → опис (обов'язковий!) / description (required!)
#   --subnet-ids $SUB_1A $SUB_1B
#       🇺🇦 Перелік ID підмереж через пробіл.
#           Мінімум 2 підмережі у 2 різних AZ — вимога RDS
#       🇬🇧 Space-separated list of subnet IDs.
#           Minimum 2 subnets in 2 different AZs — RDS requirement

aws rds create-db-subnet-group \
  --db-subnet-group-name "academy-db-subnet-group" \
  --db-subnet-group-description "Academy Lab4 DB Subnet Group" \
  --subnet-ids "$SUB_1A" "$SUB_1B"

echo "✅ DB Subnet Group створено / created"
```

### 3.2 Security Group для RDS / Security Group for RDS

```bash
# Окрема SG для бази даних — дозволяємо тільки MySQL порт (3306)
# Separate SG for the database — allow only MySQL port (3306)

RDS_SG_ID=$(aws ec2 create-security-group \
  --group-name "academy-rds-sg" \
  --description "SG for RDS MySQL" \
  --vpc-id "$DEFAULT_VPC" \
  --query 'GroupId' --output text)

# Дозволяємо MySQL (3306) звідусіль (в продакшені — тільки з EC2 SG!)
# Allow MySQL (3306) from anywhere (in production — only from EC2 SG!)
# --port 3306  → стандартний порт MySQL / standard MySQL port

aws ec2 authorize-security-group-ingress \
  --group-id "$RDS_SG_ID" \
  --protocol tcp --port 3306 --cidr 0.0.0.0/0

echo "✅ RDS Security Group: $RDS_SG_ID"
```

### 3.3 Створення RDS MySQL / Create RDS MySQL instance

```bash
# aws rds create-db-instance
#   --db-instance-identifier academy-mysql
#       🇺🇦 Унікальне ім'я інстансу в межах акаунту та регіону
#       🇬🇧 Unique name for this DB instance within the account and region
#
#   --db-instance-class db.t3.micro
#       🇺🇦 Розмір VM для БД. db.t3.micro входить у Free Tier.
#           Аналог EC2 instance type але для керованих БД
#       🇬🇧 DB VM size. db.t3.micro is Free Tier eligible.
#           Similar to EC2 instance type but for managed databases
#
#   --engine mysql
#       🇺🇦 Тип СУБД. Варіанти: mysql, postgres, mariadb, oracle-se2, sqlserver-ex
#       🇬🇧 DB engine. Options: mysql, postgres, mariadb, oracle-se2, sqlserver-ex
#
#   --engine-version 8.0
#       🇺🇦 Версія MySQL. AWS підтримує кілька версій одночасно
#       🇬🇧 MySQL version. AWS supports multiple versions simultaneously
#
#   --master-username admin
#       🇺🇦 Ім'я головного (root) користувача БД
#       🇬🇧 Master (root) database username
#
#   --master-user-password Academy2024!
#       🇺🇦 Пароль (мін. 8 символів, великі+малі літери+цифри)
#       🇬🇧 Password (min 8 chars, upper+lower+digits required)
#
#   --allocated-storage 20
#       🇺🇦 Початковий розмір сховища в ГБ (мінімум 20 для MySQL Free Tier)
#       🇬🇧 Initial storage size in GB (minimum 20 for MySQL Free Tier)
#
#   --no-multi-az
#       🇺🇦 Вимикаємо Multi-AZ (дорого, не потрібно для лабораторної роботи)
#           Multi-AZ = автоматичний failover на резервний інстанс в іншій AZ
#       🇬🇧 Disable Multi-AZ (expensive, not needed for a lab)
#           Multi-AZ = automatic failover to a standby instance in another AZ
#
#   --no-publicly-accessible
#       🇺🇦 БД НЕ доступна з інтернету — тільки зсередини VPC (best practice!)
#       🇬🇧 DB is NOT accessible from the internet — only from within VPC (best practice!)
#
#   --backup-retention-period 1
#       🇺🇦 Зберігати автоматичні бекапи 1 день (0 = вимкнути бекапи)
#       🇬🇧 Keep automated backups for 1 day (0 = disable backups)

aws rds create-db-instance \
  --db-instance-identifier "academy-mysql" \
  --db-instance-class "db.t3.micro" \
  --engine mysql \
  --engine-version "8.0" \
  --master-username admin \
  --master-user-password "Academy2024!" \
  --allocated-storage 20 \
  --db-subnet-group-name "academy-db-subnet-group" \
  --vpc-security-group-ids "$RDS_SG_ID" \
  --no-multi-az \
  --no-publicly-accessible \
  --backup-retention-period 1 \
  --db-name "academydb" \
  --tags Key=Name,Value=academy-mysql

echo "✅ RDS MySQL створюється / being created: academy-mysql"
echo "⏳ Зачекайте ~5-10 хвилин поки статус стане 'available'"
echo "⏳ Wait ~5-10 minutes until status becomes 'available'"
```

```bash
# Перевіряємо статус / Check status
aws rds describe-db-instances \
  --db-instance-identifier "academy-mysql" \
  --query 'DBInstances[0].{ID:DBInstanceIdentifier,Status:DBInstanceStatus,Engine:Engine,Class:DBInstanceClass}' \
  --output table
```

```bash
# Чекаємо availability (можна продовжити з DynamoDB поки чекаємо RDS)
# Wait for availability (continue with DynamoDB while waiting)
echo "⏳ Waiting for RDS (run DynamoDB steps in parallel)..."
aws rds wait db-instance-available --db-instance-identifier "academy-mysql"

# Отримуємо endpoint для підключення / Get the endpoint for connection
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier "academy-mysql" \
  --query 'DBInstances[0].Endpoint.Address' --output text)

echo "✅ RDS готово / ready!"
echo "   Endpoint: $RDS_ENDPOINT"
echo "   Підключення (з EC2) / Connect (from EC2):"
echo "   mysql -h $RDS_ENDPOINT -u admin -p academydb"
```

---

## 🔑 Крок 4 — Amazon DynamoDB / Step 4 — Amazon DynamoDB

**🇺🇦** DynamoDB — безсерверна (serverless) NoSQL БД. Не потрібно налаштовувати сервер. Схема гнучка — кожен запис може мати різні атрибути. Ідеально для: сесій користувачів, IoT-даних, каталогів, ігрових таблиць лідерів.

**🇬🇧** DynamoDB is a serverless NoSQL DB. No server to configure. Schema is flexible — each item can have different attributes. Best for: user sessions, IoT data, catalogs, game leaderboards.

### 4.1 Створення таблиці / Create a table

```bash
# aws dynamodb create-table
#   --table-name CadetRecords
#       🇺🇦 Ім'я таблиці — унікальне в межах акаунту та регіону
#       🇬🇧 Table name — unique within the account and region
#
#   --attribute-definitions
#       🇺🇦 Визначаємо атрибути які є частиною ключа.
#           ТІЛЬКИ ключові атрибути! Решта не потребують оголошення (гнучка схема)
#       🇬🇧 Define attributes that are part of the key.
#           KEY attributes ONLY! Others don't need declaration (flexible schema)
#       AttributeName=CadetId  → ім'я атрибута / attribute name
#       AttributeType=S        → тип: S=String, N=Number, B=Binary
#
#   --key-schema
#       🇺🇦 Первинний ключ таблиці:
#           HASH (Partition Key) — головний ключ, визначає розподіл даних по серверах
#           RANGE (Sort Key) — необов'язковий, дозволяє запити по діапазону
#       🇬🇧 Table primary key:
#           HASH (Partition Key) — main key, determines data distribution
#           RANGE (Sort Key) — optional, enables range queries
#
#   --billing-mode PAY_PER_REQUEST
#       🇺🇦 Модель оплати:
#           PAY_PER_REQUEST — платите тільки за фактичні запити (підходить для лабораторії)
#           PROVISIONED    — резервуєте конкретну кількість RCU/WCU (для передбачуваного навантаження)
#       🇬🇧 Billing mode:
#           PAY_PER_REQUEST — pay only for actual requests (good for lab)
#           PROVISIONED    — reserve specific RCU/WCU capacity (for predictable load)

aws dynamodb create-table \
  --table-name "CadetRecords" \
  --attribute-definitions \
    AttributeName=CadetId,AttributeType=S \
    AttributeName=Subject,AttributeType=S \
  --key-schema \
    AttributeName=CadetId,KeyType=HASH \
    AttributeName=Subject,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST \
  --tags Key=Name,Value=academy-dynamodb

echo "✅ DynamoDB table створено / created: CadetRecords"
```

### 4.2 Запис даних / Write items

```bash
# aws dynamodb put-item
#   --table-name CadetRecords        → таблиця / table
#   --item '{...}'
#       🇺🇦 JSON об'єкт з атрибутами. Кожен атрибут: "Ім'я": {"Тип": "Значення"}
#           Типи: S=String, N=Number, BOOL=Boolean, L=List, M=Map
#       🇬🇧 JSON object with attributes. Each: "Name": {"Type": "Value"}
#           Types: S=String, N=Number, BOOL=Boolean, L=List, M=Map

aws dynamodb put-item \
  --table-name "CadetRecords" \
  --item '{
    "CadetId":  {"S": "C-001"},
    "Subject":  {"S": "Cloud Technologies"},
    "FullName": {"S": "Іваненко Іван Іванович"},
    "Score":    {"N": "95"},
    "Passed":   {"BOOL": true},
    "Labs":     {"L": [{"S":"Lab1"},{"S":"Lab2"},{"S":"Lab3"},{"S":"Lab4"}]}
  }'

aws dynamodb put-item \
  --table-name "CadetRecords" \
  --item '{
    "CadetId":  {"S": "C-002"},
    "Subject":  {"S": "Cloud Technologies"},
    "FullName": {"S": "Петренко Петро Петрович"},
    "Score":    {"N": "88"},
    "Passed":   {"BOOL": true},
    "Labs":     {"L": [{"S":"Lab1"},{"S":"Lab2"},{"S":"Lab3"}]}
  }'

aws dynamodb put-item \
  --table-name "CadetRecords" \
  --item '{
    "CadetId":  {"S": "C-003"},
    "Subject":  {"S": "Network Technologies"},
    "FullName": {"S": "Сидоренко Сидір Сидорович"},
    "Score":    {"N": "72"},
    "Passed":   {"BOOL": true}
  }'

echo "✅ 3 записи додано / 3 items added"
```

### 4.3 Читання даних / Read items

```bash
# Отримати конкретний запис / Get a specific item
# aws dynamodb get-item
#   --key '{...}'  → вказуємо повний первинний ключ (HASH + RANGE якщо є)
#                    specify the full primary key (HASH + RANGE if defined)

aws dynamodb get-item \
  --table-name "CadetRecords" \
  --key '{
    "CadetId": {"S": "C-001"},
    "Subject":  {"S": "Cloud Technologies"}
  }' \
  --query 'Item.{Name:FullName.S,Score:Score.N,Passed:Passed.BOOL}'

echo ""
```

```bash
# Запит по партиційному ключу / Query by partition key
# aws dynamodb query — ефективно (читає тільки потрібний розділ)
#   --key-condition-expression
#       🇺🇦 Умова для ключових атрибутів (ефективно — використовує індекс)
#           :cadetid — named parameter що замінює реальне значення нижче
#       🇬🇧 Condition for key attributes (efficient — uses the index)
#           :cadetid — named parameter substituted with the real value below
#
#   --expression-attribute-values → значення для named parameters
#                                   values for the named parameters

aws dynamodb query \
  --table-name "CadetRecords" \
  --key-condition-expression "CadetId = :cid" \
  --expression-attribute-values '{":cid": {"S": "C-001"}}' \
  --query 'Items[*].{Name:FullName.S,Subject:Subject.S,Score:Score.N}'

echo ""
```

```bash
# Сканування всієї таблиці / Full table scan (використовуйте обережно!)
# aws dynamodb scan — зчитує ВСЮ таблицю (дорого для великих таблиць!)
#   scan vs query: query — ефективний, читає по ключу
#                  scan  — повний перебір, читає кожен запис
# scan vs query: query is efficient (uses index), scan reads everything (costly!)

aws dynamodb scan \
  --table-name "CadetRecords" \
  --query 'Items[*].{CadetId:CadetId.S,Subject:Subject.S,Score:Score.N}' \
  --output table

echo "✅ Scan complete / Сканування завершено"
```

### 4.4 Оновлення запису / Update an item

```bash
# aws dynamodb update-item
#   --update-expression "SET Score = :newScore, Grade = :grade"
#       🇺🇦 SET — оновлюємо або додаємо атрибут
#           REMOVE — видаляємо атрибут
#           ADD — додаємо до числового значення
#       🇬🇧 SET — update or add an attribute
#           REMOVE — delete an attribute
#           ADD — increment a numeric value
#
#   --condition-expression "Score < :newScore"
#       🇺🇦 Оновлення відбудеться ТІЛЬКИ якщо умова виконується (optimistic locking)
#       🇬🇧 Update happens ONLY IF condition is true (optimistic locking)

aws dynamodb update-item \
  --table-name "CadetRecords" \
  --key '{"CadetId": {"S":"C-001"}, "Subject": {"S":"Cloud Technologies"}}' \
  --update-expression "SET Score = :s, Grade = :g" \
  --expression-attribute-values '{
    ":s": {"N": "98"},
    ":g": {"S": "A+"}
  }' \
  --return-values ALL_NEW \
  --query 'Attributes.{Name:FullName.S,NewScore:Score.N,Grade:Grade.S}'

echo "✅ Record updated / Запис оновлено"
```

---

# 📈 ПИТАННЯ 3 — МАСШТАБУВАННЯ ТА МОНІТОРИНГ / TOPIC 3 — SCALING & MONITORING

## Теорія / Theory

**🇺🇦**
- **Auto Scaling Group (ASG)** — автоматично збільшує або зменшує кількість EC2-інстансів залежно від навантаження. Підтримує мінімальну/максимальну/бажану кількість.
- **Launch Template** — шаблон налаштувань нового інстансу (AMI, тип, SG, user-data).
- **CloudWatch** — сервіс моніторингу. Збирає метрики (CPU, мережа, диск), зберігає логи, генерує алерти.
- **SNS (Simple Notification Service)** — сервіс сповіщень. Розсилає повідомлення на email/SMS/Lambda при спрацюванні алерту.

**🇬🇧**
- **Auto Scaling Group (ASG)** — automatically increases or decreases EC2 instance count based on load. Enforces min/max/desired capacity.
- **Launch Template** — blueprint for new instances (AMI, type, SG, user-data).
- **CloudWatch** — monitoring service. Collects metrics (CPU, network, disk), stores logs, triggers alarms.
- **SNS (Simple Notification Service)** — notification service. Sends messages to email/SMS/Lambda when an alarm fires.

---

## 🔔 Крок 5 — SNS: Сповіщення / Step 5 — SNS Notifications

```bash
# Створюємо SNS Topic — "канал" куди CloudWatch надсилатиме алерти
# Create SNS Topic — "channel" where CloudWatch will send alerts

# aws sns create-topic
#   --name academy-alerts
#       🇺🇦 Ім'я топіку. SNS Topic — посередник між відправником і підписниками.
#           Один топік може мати багато підписників (email, SMS, Lambda, SQS тощо)
#       🇬🇧 Topic name. SNS Topic — broker between publisher and subscribers.
#           One topic can have many subscribers (email, SMS, Lambda, SQS etc.)

SNS_ARN=$(aws sns create-topic \
  --name "academy-alerts" \
  --query 'TopicArn' \
  --output text)

echo "✅ SNS Topic створено / created: $SNS_ARN"
```

```bash
# Підписуємось на email-сповіщення / Subscribe to email notifications
# (Замініть на реальний email! / Replace with a real email!)

# aws sns subscribe
#   --topic-arn $SNS_ARN         → до якого топіку підписуємось
#                                   which topic to subscribe to
#   --protocol email             → тип сповіщення: email, sms, lambda, sqs, https
#                                   notification protocol
#   --notification-endpoint      → email-адреса підписника
#                                   subscriber email address

aws sns subscribe \
  --topic-arn "$SNS_ARN" \
  --protocol email \
  --notification-endpoint "your-email@example.com"

echo "✅ Email підписку надіслано / Email subscription sent"
echo "⚠️  Підтвердьте підписку у листі! / Confirm subscription in your email!"
```

---

## 📊 Крок 6 — CloudWatch Alarm / Step 6 — CloudWatch Alarm

```bash
# aws cloudwatch put-metric-alarm
#   --alarm-name "High-CPU-Alarm"
#       🇺🇦 Унікальне ім'я алерту / Unique alarm name
#
#   --alarm-description "..."
#       🇺🇦 Опис що відбувається при спрацюванні
#       🇬🇧 Description of what this alarm monitors
#
#   --metric-name CPUUtilization
#       🇺🇦 Яку метрику відстежуємо.
#           Вбудовані метрики EC2: CPUUtilization, NetworkIn, NetworkOut,
#           DiskReadBytes, DiskWriteBytes, StatusCheckFailed
#       🇬🇧 Which metric to monitor.
#           Built-in EC2 metrics: CPUUtilization, NetworkIn, NetworkOut,
#           DiskReadBytes, DiskWriteBytes, StatusCheckFailed
#
#   --namespace AWS/EC2
#       🇺🇦 Простір імен метрики. Кожен сервіс AWS має свій namespace:
#           AWS/EC2, AWS/RDS, AWS/DynamoDB, AWS/S3, AWS/ELB тощо
#       🇬🇧 Metric namespace. Each AWS service has its own:
#           AWS/EC2, AWS/RDS, AWS/DynamoDB, AWS/S3, AWS/ELB etc.
#
#   --statistic Average
#       🇺🇦 Статистична функція: Average, Sum, Minimum, Maximum, SampleCount
#       🇬🇧 Statistical function: Average, Sum, Minimum, Maximum, SampleCount
#
#   --period 300
#       🇺🇦 Інтервал збору в секундах (300 = 5 хвилин)
#           Мінімум 60 сек для стандартних метрик EC2
#       🇬🇧 Collection interval in seconds (300 = 5 minutes)
#           Minimum 60 sec for standard EC2 metrics
#
#   --evaluation-periods 2
#       🇺🇦 Скільки послідовних періодів умова має виконуватись перед спрацюванням
#           2 × 300с = потрібно 10 хвилин перевищення щоб алерт спрацював
#       🇬🇧 How many consecutive periods the condition must hold before alarming
#           2 × 300s = needs 10 minutes of breach before alarm fires
#
#   --threshold 70
#       🇺🇦 Порогове значення для спрацювання (70% завантаження CPU)
#       🇬🇧 Threshold value to trigger the alarm (70% CPU utilization)
#
#   --comparison-operator GreaterThanOrEqualToThreshold
#       🇺🇦 Оператор порівняння:
#           GreaterThanOrEqualToThreshold (>=), GreaterThanThreshold (>)
#           LessThanOrEqualToThreshold (<=), LessThanThreshold (<)
#       🇬🇧 Comparison operator:
#           GreaterThanOrEqualToThreshold (>=), GreaterThanThreshold (>)
#           LessThanOrEqualToThreshold (<=), LessThanThreshold (<)
#
#   --alarm-actions $SNS_ARN
#       🇺🇦 Що робити коли алерт спрацював: надіслати в SNS Topic
#           Також можна: запустити EC2, виконати Lambda, тощо
#       🇬🇧 What to do when alarm fires: send to SNS Topic
#           Also possible: start EC2, invoke Lambda, trigger ASG action

aws cloudwatch put-metric-alarm \
  --alarm-name "Academy-High-CPU" \
  --alarm-description "CPU > 70% for 10 minutes — scale out needed" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 70 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --alarm-actions "$SNS_ARN" \
  --ok-actions "$SNS_ARN" \
  --treat-missing-data notBreaching

echo "✅ CloudWatch Alarm створено / created: Academy-High-CPU"
```

```bash
# Перевіряємо стан алерту / Check alarm state
# aws cloudwatch describe-alarms
#   --alarm-names "Academy-High-CPU"  → фільтруємо конкретний алерт
#   Стани / States: OK | ALARM | INSUFFICIENT_DATA

aws cloudwatch describe-alarms \
  --alarm-names "Academy-High-CPU" \
  --query 'MetricAlarms[0].{Name:AlarmName,State:StateValue,Threshold:Threshold,Metric:MetricName}' \
  --output table
```

---

## 🚀 Крок 7 — Launch Template / Step 7 — Launch Template

```bash
# Launch Template — шаблон налаштувань для нових EC2-інстансів в ASG
# Launch Template — configuration blueprint for new EC2 instances in the ASG

# Знаходимо AMI та SG default VPC / Find AMI and default VPC SG
LATEST_AMI=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-2023*-x86_64" "Name=state,Values=available" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text)

DEFAULT_SG=$(aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$DEFAULT_VPC" "Name=group-name,Values=default" \
  --query 'SecurityGroups[0].GroupId' --output text)

echo "AMI: $LATEST_AMI | Default SG: $DEFAULT_SG"
```

```bash
# aws ec2 create-launch-template
#   --launch-template-name       → ім'я шаблону / template name
#   --version-description        → опис версії (шаблони версіонуються!)
#                                   version description (templates are versioned!)
#   --launch-template-data '{}'
#       🇺🇦 JSON об'єкт з усіма параметрами нового інстансу.
#           Те саме що вказуємо в run-instances, але у форматі шаблону
#       🇬🇧 JSON object with all parameters for new instances.
#           Same as run-instances parameters but in template format

aws ec2 create-launch-template \
  --launch-template-name "academy-asg-template" \
  --version-description "Lab4 Auto Scaling Template v1" \
  --launch-template-data "{
    \"ImageId\": \"${LATEST_AMI}\",
    \"InstanceType\": \"t2.micro\",
    \"SecurityGroupIds\": [\"${DEFAULT_SG}\"],
    \"TagSpecifications\": [{
      \"ResourceType\": \"instance\",
      \"Tags\": [{\"Key\": \"Name\", \"Value\": \"ASG-Instance\"},
                 {\"Key\": \"ManagedBy\", \"Value\": \"AutoScaling\"}]
    }],
    \"UserData\": \"$(echo '#!/bin/bash
yum update -y
yum install -y stress httpd
systemctl start httpd
echo "<h1>ASG Instance - $(hostname)</h1>" > /var/www/html/index.html' | base64 -w0)\"
  }"

LT_ID=$(aws ec2 describe-launch-templates \
  --launch-template-names "academy-asg-template" \
  --query 'LaunchTemplates[0].LaunchTemplateId' --output text)

echo "✅ Launch Template створено / created: $LT_ID"
```

---

## ⚖️ Крок 8 — Auto Scaling Group / Step 8 — Auto Scaling Group

```bash
# Отримуємо всі підмережі default VPC для ASG
# Get all subnets of default VPC for ASG

ALL_SUBNETS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$DEFAULT_VPC" \
  --query 'Subnets[*].SubnetId' \
  --output text | tr '\t' ',')

echo "Subnets for ASG: $ALL_SUBNETS"
```

```bash
# aws autoscaling create-auto-scaling-group
#   --auto-scaling-group-name       → унікальне ім'я ASG / unique ASG name
#
#   --launch-template
#       LaunchTemplateId=$LT_ID     → ID шаблону запуску / launch template ID
#       Version='$Latest'           → завжди використовувати найновішу версію шаблону
#                                     always use the latest template version
#
#   --min-size 1
#       🇺🇦 Мінімальна кількість інстансів — ASG НІКОЛИ не опуститься нижче
#       🇬🇧 Minimum instance count — ASG will NEVER go below this
#
#   --max-size 4
#       🇺🇦 Максимальна кількість — ASG НІКОЛИ не перевищить
#           (захист від необмеженого масштабування і витрат)
#       🇬🇧 Maximum instance count — ASG will NEVER exceed this
#           (protects against unlimited scaling and costs)
#
#   --desired-capacity 2
#       🇺🇦 Бажана кількість — скільки інстансів ASG підтримуватиме зараз
#           Між min і max. ASG запустить або зупинить інстанси до досягнення
#       🇬🇧 Desired count — how many instances ASG maintains right now
#           Between min and max. ASG starts or stops instances to reach this
#
#   --vpc-zone-identifier
#       🇺🇦 Список підмереж через кому. ASG рівномірно розподіляє інстанси між ними
#       🇬🇧 Comma-separated subnet list. ASG distributes instances evenly across them
#
#   --health-check-type EC2
#       🇺🇦 Тип перевірки стану:
#           EC2   — перевіряє чи інстанс запущений (system status check)
#           ELB   — перевіряє чи інстанс проходить health check балансувальника
#       🇬🇧 Health check type:
#           EC2   — checks if instance is running (system status check)
#           ELB   — checks if instance passes load balancer health check
#
#   --health-check-grace-period 120
#       🇺🇦 Скільки секунд чекати після запуску перш ніж починати health checks
#           (час для завантаження ОС та застосунку)
#       🇬🇧 Seconds to wait after launch before starting health checks
#           (time for OS and application to boot)

aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name "academy-asg" \
  --launch-template "LaunchTemplateId=${LT_ID},Version=\$Latest" \
  --min-size 1 \
  --max-size 4 \
  --desired-capacity 2 \
  --vpc-zone-identifier "$ALL_SUBNETS" \
  --health-check-type EC2 \
  --health-check-grace-period 120 \
  --tags \
    "Key=Name,Value=academy-asg,PropagateAtLaunch=true" \
    "Key=Environment,Value=lab,PropagateAtLaunch=true"

echo "✅ Auto Scaling Group створено / created: academy-asg"
echo "⏳ ASG запускає 2 інстанси / ASG is launching 2 instances..."
```

### 8.1 Scaling Policies — автоматичні правила масштабування

```bash
# Scaling Policy: SCALE OUT — додаємо інстанс при підвищенні CPU
# Scaling Policy: SCALE OUT — add instance when CPU is high

# aws autoscaling put-scaling-policy
#   --policy-type TargetTrackingScaling
#       🇺🇦 Тип правила:
#           TargetTrackingScaling — підтримує цільове значення метрики (рекомендований!)
#           SimpleScaling         — додає/видаляє фіксовану кількість після alarm
#           StepScaling           — різні кроки залежно від розміру перевищення
#       🇬🇧 Policy type:
#           TargetTrackingScaling — maintains a target metric value (recommended!)
#           SimpleScaling         — adds/removes fixed count after alarm
#           StepScaling           — different steps based on breach magnitude
#
#   --target-tracking-configuration
#       PredefinedMetricType=ASGAverageCPUUtilization
#           🇺🇦 Вбудована метрика для ASG: середнє CPU по всіх інстансах групи
#           🇬🇧 Built-in ASG metric: average CPU across all group instances
#       TargetValue=60.0
#           🇺🇦 ASG буде масштабувати щоб CPU не перевищувало 60%
#               При CPU > 60% — додає інстанси; при CPU < 60% — видаляє
#           🇬🇧 ASG will scale to keep CPU around 60%
#               CPU > 60% — adds instances; CPU < 60% — removes instances

aws autoscaling put-scaling-policy \
  --auto-scaling-group-name "academy-asg" \
  --policy-name "academy-cpu-tracking" \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ASGAverageCPUUtilization"
    },
    "TargetValue": 60.0,
    "ScaleInCooldown": 120,
    "ScaleOutCooldown": 60
  }'

# ScaleInCooldown:  🇺🇦 мін. час між видаленням інстансів (секунди)
#                   🇬🇧 minimum time between removing instances (seconds)
# ScaleOutCooldown: 🇺🇦 мін. час між додаванням інстансів (секунди)
#                   🇬🇧 minimum time between adding instances (seconds)

echo "✅ Target Tracking Scaling Policy створено / created"
echo "   Target: CPU ≤ 60% | ScaleOut cooldown: 60s | ScaleIn cooldown: 120s"
```

### 8.2 Перегляд стану ASG / Check ASG state

```bash
# Перевіряємо стан ASG та інстансів
# Check ASG state and its instances

aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "academy-asg" \
  --query 'AutoScalingGroups[0].{
    Name:AutoScalingGroupName,
    Min:MinSize, Max:MaxSize, Desired:DesiredCapacity,
    Instances:length(Instances)
  }' \
  --output table

echo ""

# Переглядаємо інстанси в ASG / List ASG instances
aws autoscaling describe-auto-scaling-instances \
  --query 'AutoScalingInstances[?AutoScalingGroupName==`academy-asg`].{
    ID:InstanceId, State:LifecycleState, Health:HealthStatus, AZ:AvailabilityZone
  }' \
  --output table
```

### 8.3 Ручне масштабування / Manual scaling demo

```bash
# Демонстрація ручної зміни desired capacity
# Demonstrate manual desired capacity change

echo "Поточний стан / Current state: Desired=2"
echo "Масштабуємо до 3 / Scaling to 3..."

# aws autoscaling set-desired-capacity
#   --desired-capacity 3
#       🇺🇦 Встановлюємо нову бажану кількість. ASG запустить ще 1 інстанс
#       🇬🇧 Set new desired count. ASG will launch 1 more instance
#   --honor-cooldown
#       🇺🇦 Враховувати cooldown period (якщо active — зачекає)
#       🇬🇧 Respect cooldown period (if active — it will wait)

aws autoscaling set-desired-capacity \
  --auto-scaling-group-name "academy-asg" \
  --desired-capacity 3 \
  --honor-cooldown

echo "✅ Desired capacity → 3. ASG запускає новий інстанс / launching new instance..."
sleep 10

# Повертаємо назад / Scale back
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name "academy-asg" \
  --desired-capacity 2 \
  --honor-cooldown

echo "✅ Desired capacity → 2. ASG видалить один інстанс / will terminate one instance"
```

---

## 📉 Крок 9 — CloudWatch Dashboard / Step 9 — CloudWatch Dashboard

```bash
# Створюємо кастомний dashboard для моніторингу
# Create a custom monitoring dashboard

# aws cloudwatch put-dashboard
#   --dashboard-name → ім'я dashboard (унікальне) / dashboard name (unique)
#   --dashboard-body → JSON з описом widgets / JSON with widget definitions

aws cloudwatch put-dashboard \
  --dashboard-name "Academy-Lab4-Dashboard" \
  --dashboard-body '{
    "widgets": [
      {
        "type": "metric",
        "properties": {
          "title": "EC2 CPU Utilization (ASG)",
          "metrics": [
            ["AWS/EC2","CPUUtilization","AutoScalingGroupName","academy-asg"]
          ],
          "period": 60,
          "stat": "Average",
          "view": "timeSeries"
        }
      },
      {
        "type": "metric",
        "properties": {
          "title": "ASG Instance Count",
          "metrics": [
            ["AWS/AutoScaling","GroupInServiceInstances","AutoScalingGroupName","academy-asg"]
          ],
          "period": 60,
          "stat": "Average"
        }
      },
      {
        "type": "metric",
        "properties": {
          "title": "DynamoDB Operations",
          "metrics": [
            ["AWS/DynamoDB","ConsumedReadCapacityUnits","TableName","CadetRecords"],
            ["AWS/DynamoDB","ConsumedWriteCapacityUnits","TableName","CadetRecords"]
          ],
          "period": 60,
          "stat": "Sum"
        }
      },
      {
        "type": "alarm",
        "properties": {
          "title": "Active Alarms",
          "alarms": ["arn:aws:cloudwatch:us-east-1:'${ACCOUNT_ID}':alarm:Academy-High-CPU"]
        }
      }
    ]
  }'

echo "✅ Dashboard створено / created: Academy-Lab4-Dashboard"
echo "🌐 Відкрийте / Open: CloudWatch → Dashboards → Academy-Lab4-Dashboard"
```

---

## 📊 Крок 10 — Фінальна перевірка / Step 10 — Final Summary

```bash
echo "══════════════════════════════════════════════════════════"
echo "    ПІДСУМОК ЛАБОРАТОРНОЇ РОБОТИ / LAB SUMMARY           "
echo "══════════════════════════════════════════════════════════"

echo -e "\n📦 S3 Bucket:"
aws s3 ls "s3://${BUCKET_NAME}" --recursive | wc -l | \
  xargs -I{} echo "  Objects: {} files uploaded"

echo -e "\n💾 EBS Volume:"
aws ec2 describe-volumes --volume-ids "$EBS_ID" \
  --query 'Volumes[0].{ID:VolumeId,Type:VolumeType,Size:Size,State:State}' \
  --output table

echo -e "\n🐬 RDS MySQL:"
aws rds describe-db-instances --db-instance-identifier "academy-mysql" \
  --query 'DBInstances[0].{ID:DBInstanceIdentifier,Status:DBInstanceStatus,Engine:Engine}' \
  --output table 2>/dev/null || echo "  (still creating...)"

echo -e "\n🔑 DynamoDB:"
aws dynamodb describe-table --table-name "CadetRecords" \
  --query 'Table.{Name:TableName,Status:TableStatus,Items:ItemCount}' \
  --output table

echo -e "\n⚖️  Auto Scaling Group:"
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "academy-asg" \
  --query 'AutoScalingGroups[0].{Name:AutoScalingGroupName,Min:MinSize,Max:MaxSize,Desired:DesiredCapacity}' \
  --output table

echo -e "\n🔔 CloudWatch Alarm:"
aws cloudwatch describe-alarms --alarm-names "Academy-High-CPU" \
  --query 'MetricAlarms[0].{Name:AlarmName,State:StateValue,Threshold:Threshold}' \
  --output table
```

---

## 💾 Збережіть змінні / Save Variables

```bash
cat << EOF
=== SAVE THESE / ЗБЕРЕЖІТЬ ===
ACCOUNT_ID=$ACCOUNT_ID
AWS_REGION=$AWS_REGION
BUCKET_NAME=$BUCKET_NAME
EBS_ID=$EBS_ID
SNAPSHOT_ID=$SNAPSHOT_ID
RDS_SG_ID=$RDS_SG_ID
SNS_ARN=$SNS_ARN
LT_ID=$LT_ID
DEFAULT_VPC=$DEFAULT_VPC
EOF
```

---

## 🧹 Крок 11 — Очищення / Step 11 — Cleanup

> ⚠️ Виконайте після заняття! / Run after the lab!

```bash
# 1. Видаляємо ASG (спочатку примусово завершуємо інстанси)
aws autoscaling delete-auto-scaling-group \
  --auto-scaling-group-name "academy-asg" --force-delete
echo "✅ ASG deleted"

# 2. Видаляємо Launch Template
aws ec2 delete-launch-template --launch-template-id "$LT_ID"
echo "✅ Launch Template deleted"

# 3. Видаляємо CloudWatch Alarm та Dashboard
aws cloudwatch delete-alarms --alarm-names "Academy-High-CPU"
aws cloudwatch delete-dashboards --dashboard-names "Academy-Lab4-Dashboard"
echo "✅ CloudWatch resources deleted"

# 4. Видаляємо SNS Topic
aws sns delete-topic --topic-arn "$SNS_ARN"
echo "✅ SNS Topic deleted"

# 5. Видаляємо DynamoDB
aws dynamodb delete-table --table-name "CadetRecords"
echo "✅ DynamoDB table deleted"

# 6. Видаляємо RDS (без фінального snapshot)
aws rds delete-db-instance \
  --db-instance-identifier "academy-mysql" \
  --skip-final-snapshot
echo "✅ RDS deletion started (takes ~5 min)"

# 7. Відкріплюємо та видаляємо EBS
aws ec2 detach-volume --volume-id "$EBS_ID" 2>/dev/null
sleep 5
aws ec2 delete-volume --volume-id "$EBS_ID"
echo "✅ EBS Volume deleted"

# 8. Видаляємо demo instance
aws ec2 terminate-instances --instance-ids "$DEMO_INSTANCE" 2>/dev/null
echo "✅ Demo instance terminated"

# 9. Очищуємо та видаляємо S3 bucket (спочатку всі об'єкти та версії!)
aws s3 rm "s3://${BUCKET_NAME}" --recursive
aws s3api delete-bucket --bucket "$BUCKET_NAME"
echo "✅ S3 Bucket deleted"

echo ""
echo "🎉 Cleanup complete! Дякуємо за роботу! 🇺🇦"
```

---

## 📚 Ключові концепції / Key Concepts

| Сервіс | 🇺🇦 Тип/Опис | 🇬🇧 Type/Description | Use Case |
|---|---|---|---|
| **S3** | Об'єктне сховище | Object storage | Files, backups, static web |
| **EBS** | Блочне сховище | Block storage (disk) | OS disk, databases |
| **EFS** | Мережева ФС | Shared network filesystem | Shared config, media |
| **RDS** | Керована реляційна БД | Managed relational DB | MySQL, PostgreSQL apps |
| **DynamoDB** | Serverless NoSQL | Serverless NoSQL | Sessions, IoT, catalogs |
| **ASG** | Авто-масштабування | Auto Scaling Group | Elastic EC2 fleets |
| **Launch Template** | Шаблон інстансу | Instance blueprint | ASG configuration |
| **CloudWatch** | Моніторинг | Monitoring & alerting | Metrics, logs, alarms |
| **SNS** | Сповіщення | Notifications | Email/SMS alerts |
| **Lifecycle Policy** | Управління даними | Data lifecycle mgmt | S3 cost optimization |

---

## 🎯 Самоперевірка / Self-Assessment

```bash
curl -O https://raw.githubusercontent.com/YOUR_REPO/main/check.sh
chmod +x check.sh && ./check.sh
```

---

*Підготовлено для AWS Academy Learner Lab | Хмарні технології — 5 курс | Заняття 4*
*Prepared for AWS Academy Learner Lab | Cloud Technologies — 5th Year | Lab 4* 🇺🇦
