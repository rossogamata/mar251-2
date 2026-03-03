# 🛡️ Заняття: Основи AWS — VPC, EC2, Network ACL, Elastic IP

> **Курс:** Хмарні технології | **Курс навчання:** 5-й курс  
> **Середовище:** AWS Academy Learner Lab (CloudShell)  
> **Тривалість:** ~120 хвилин  

---

## 📋 Цілі заняття

Після завершення заняття курсант буде вміти:

- [ ] Користуватись **AWS CLI** через браузер (CloudShell)
- [ ] Створювати та налаштовувати **VPC** з підмережами
- [ ] Запускати **EC2-інстанси** в різних підмережах
- [ ] Налаштовувати **Network ACL** для контролю трафіку
- [ ] Створювати **Elastic IP** та прив'язувати/відв'язувати його до інстансів

---

## 🗺️ Архітектура, яку ми побудуємо

```
┌─────────────────────────────────────────────────────────┐
│  VPC: 10.0.0.0/16  (academy-vpc)                        │
│                                                         │
│  ┌──────────────────────┐  ┌──────────────────────────┐ │
│  │  Subnet-A            │  │  Subnet-B                │ │
│  │  10.0.1.0/24         │  │  10.0.2.0/24             │ │
│  │  us-east-1a          │  │  us-east-1b              │ │
│  │                      │  │                          │ │
│  │  ┌────────────────┐  │  │  ┌────────────────────┐  │ │
│  │  │  EC2: WebServer│  │  │  │  EC2: AppServer    │  │ │
│  │  │  (Elastic IP ←─┼──┼──┼──┼──→ переміщуємо)   │  │ │
│  │  └────────────────┘  │  │  └────────────────────┘  │ │
│  └──────────────────────┘  └──────────────────────────┘ │
│                                                         │
│  [Internet Gateway]  [Route Table]  [Network ACL]       │
└─────────────────────────────────────────────────────────┘
```

---

## 🚀 Крок 0 — Запуск AWS CloudShell

1. Увійдіть до [AWS Academy](https://awsacademy.instructure.com) → відкрийте **Learner Lab**
2. Натисніть **Start Lab** та дочекайтесь зеленого індикатора ●
3. Натисніть **AWS** (або **Open Console**) для переходу до консолі
4. У верхній панелі консолі знайдіть іконку **CloudShell** `>_` та клікніть на неї
5. Зачекайте поки CloudShell ініціалізується (≈30 сек)

### ✅ Перевірте доступ до AWS CLI:
```bash
aws --version
aws sts get-caller-identity
```

**Очікуваний результат:**
```json
{
    "UserId": "AROA...",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/..."
}
```

> 💡 **Що таке CloudShell?** — це браузерний термінал прямо в консолі AWS. Він вже має налаштований AWS CLI з вашими правами — не потрібно вводити ключі вручну.

---

## 🏗️ Крок 1 — Створення VPC

**VPC (Virtual Private Cloud)** — ізольована мережа у хмарі. Це ваш власний сегмент мережі в AWS.

```bash
# Створюємо VPC з CIDR-блоком 10.0.0.0/16
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=academy-vpc}]' \
  --query 'Vpc.VpcId' \
  --output text)

echo "✅ VPC створено: $VPC_ID"
```

```bash
# Вмикаємо DNS-імена для інстансів всередині VPC
aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --enable-dns-hostnames '{"Value":true}'

echo "✅ DNS hostnames увімкнено"
```

> 💡 **CIDR 10.0.0.0/16** означає: адреси від 10.0.0.0 до 10.0.255.255 — це 65 536 адрес для вашої мережі.

---

## 🌐 Крок 2 — Створення Internet Gateway

**Internet Gateway** — "ворота" між вашою VPC та інтернетом.

```bash
# Створюємо Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=academy-igw}]' \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)

echo "✅ Internet Gateway створено: $IGW_ID"
```

```bash
# Прикріплюємо IGW до нашої VPC
aws ec2 attach-internet-gateway \
  --internet-gateway-id $IGW_ID \
  --vpc-id $VPC_ID

echo "✅ IGW прикріплено до VPC"
```

---

## 📦 Крок 3 — Створення підмереж (Subnets)

**Subnet** — підмережа всередині VPC. Кожна підмережа розташована в окремій **зоні доступності (AZ)**.

```bash
# Підмережа A — зона us-east-1a
SUBNET_A_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=academy-subnet-a}]' \
  --query 'Subnet.SubnetId' \
  --output text)

echo "✅ Subnet-A створено: $SUBNET_A_ID"
```

```bash
# Підмережа B — зона us-east-1b
SUBNET_B_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 \
  --availability-zone us-east-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=academy-subnet-b}]' \
  --query 'Subnet.SubnetId' \
  --output text)

echo "✅ Subnet-B створено: $SUBNET_B_ID"
```

```bash
# Вмикаємо автоматичне призначення публічних IP в обох підмережах
aws ec2 modify-subnet-attribute --subnet-id $SUBNET_A_ID --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id $SUBNET_B_ID --map-public-ip-on-launch

echo "✅ Автопризначення Public IP увімкнено"
```

---

## 🛣️ Крок 4 — Налаштування таблиці маршрутизації

**Route Table** — таблиця, що визначає куди направляти мережевий трафік.

```bash
# Створюємо таблицю маршрутизації
RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=academy-rt-public}]' \
  --query 'RouteTable.RouteTableId' \
  --output text)

echo "✅ Route Table створено: $RT_ID"
```

```bash
# Додаємо маршрут: весь трафік (0.0.0.0/0) — через Internet Gateway
aws ec2 create-route \
  --route-table-id $RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID

echo "✅ Маршрут до інтернету додано"
```

```bash
# Прив'язуємо таблицю маршрутів до обох підмереж
aws ec2 associate-route-table --route-table-id $RT_ID --subnet-id $SUBNET_A_ID
aws ec2 associate-route-table --route-table-id $RT_ID --subnet-id $SUBNET_B_ID

echo "✅ Route Table прив'язано до підмереж"
```

---

## 🔒 Крок 5 — Налаштування Network ACL

**Network ACL (NACL)** — перший рівень захисту на рівні підмережі. Працює з правилами **дозволити/заборонити** для вхідного та вихідного трафіку.

> 💡 **Різниця між NACL та Security Group:**
> | | Network ACL | Security Group |
> |---|---|---|
> | Рівень | Підмережа | Інстанс |
> | Тип | Stateless | Stateful |
> | Правила | Дозволити + Заборонити | Тільки дозволити |
> | Порядок | Номер правила (↑ = пріоритет) | Всі перевіряються |

```bash
# Отримуємо ID стандартного NACL для нашої VPC
NACL_ID=$(aws ec2 describe-network-acls \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'NetworkAcls[0].NetworkAclId' \
  --output text)

echo "✅ NACL ID: $NACL_ID"
```

```bash
# Дозволяємо вхідний SSH (порт 22) — правило 100
aws ec2 create-network-acl-entry \
  --network-acl-id $NACL_ID \
  --ingress \
  --rule-number 100 \
  --protocol tcp \
  --port-range From=22,To=22 \
  --cidr-block 0.0.0.0/0 \
  --rule-action allow

echo "✅ NACL: SSH вхідний — дозволено"
```

```bash
# Дозволяємо вхідний HTTP (порт 80) — правило 110
aws ec2 create-network-acl-entry \
  --network-acl-id $NACL_ID \
  --ingress \
  --rule-number 110 \
  --protocol tcp \
  --port-range From=80,To=80 \
  --cidr-block 0.0.0.0/0 \
  --rule-action allow

echo "✅ NACL: HTTP вхідний — дозволено"
```

```bash
# Дозволяємо вхідний ICMP (ping) — правило 120
aws ec2 create-network-acl-entry \
  --network-acl-id $NACL_ID \
  --ingress \
  --rule-number 120 \
  --protocol icmp \
  --icmp-type-code Code=-1,Type=-1 \
  --cidr-block 0.0.0.0/0 \
  --rule-action allow

echo "✅ NACL: ICMP (ping) вхідний — дозволено"
```

```bash
# Дозволяємо вхідні ephemeral-порти (відповіді від серверів) — правило 130
aws ec2 create-network-acl-entry \
  --network-acl-id $NACL_ID \
  --ingress \
  --rule-number 130 \
  --protocol tcp \
  --port-range From=1024,To=65535 \
  --cidr-block 0.0.0.0/0 \
  --rule-action allow

echo "✅ NACL: Ephemeral ports вхідні — дозволено"
```

```bash
# Дозволяємо весь вихідний трафік — правило 100
aws ec2 create-network-acl-entry \
  --network-acl-id $NACL_ID \
  --egress \
  --rule-number 100 \
  --protocol -1 \
  --cidr-block 0.0.0.0/0 \
  --rule-action allow

echo "✅ NACL: Весь вихідний трафік — дозволено"
```

---

## 🛡️ Крок 6 — Створення Security Group

**Security Group** — другий рівень захисту на рівні інстансу. Stateful — якщо дозволили вхідний трафік, відповідь автоматично дозволена.

```bash
# Створюємо Security Group
SG_ID=$(aws ec2 create-security-group \
  --group-name academy-sg \
  --description "Security Group for Academy Lab" \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=academy-sg}]' \
  --query 'GroupId' \
  --output text)

echo "✅ Security Group створено: $SG_ID"
```

```bash
# Дозволяємо SSH з будь-якої адреси
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# Дозволяємо HTTP
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

# Дозволяємо ICMP (ping)
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol icmp \
  --port -1 \
  --cidr 0.0.0.0/0

echo "✅ Security Group правила додано"
```

---

## 💻 Крок 7 — Запуск EC2-інстансів

**EC2 (Elastic Compute Cloud)** — віртуальні машини в AWS.

```bash
# Отримуємо останній AMI Amazon Linux 2023
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters \
    "Name=name,Values=al2023-ami-2023*-x86_64" \
    "Name=state,Values=available" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --output text)

echo "✅ AMI знайдено: $AMI_ID"
```

```bash
# Запускаємо WebServer в Subnet-A
INSTANCE_A_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t2.micro \
  --subnet-id $SUBNET_A_ID \
  --security-group-ids $SG_ID \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=WebServer}]' \
  --user-data '#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>WebServer — Subnet A ($(hostname -I))</h1>" > /var/www/html/index.html' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "✅ WebServer (Subnet-A) запущено: $INSTANCE_A_ID"
```

```bash
# Запускаємо AppServer в Subnet-B
INSTANCE_B_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t2.micro \
  --subnet-id $SUBNET_B_ID \
  --security-group-ids $SG_ID \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=AppServer}]' \
  --user-data '#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>AppServer — Subnet B ($(hostname -I))</h1>" > /var/www/html/index.html' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "✅ AppServer (Subnet-B) запущено: $INSTANCE_B_ID"
```

```bash
# Чекаємо поки обидва інстанси стануть "running"
echo "⏳ Очікуємо запуску інстансів..."
aws ec2 wait instance-running \
  --instance-ids $INSTANCE_A_ID $INSTANCE_B_ID

echo "✅ Обидва інстанси запущені!"
```

---

## 🌍 Крок 8 — Elastic IP: створення та прив'язка

**Elastic IP (EIP)** — статична публічна IP-адреса, яку можна переміщувати між інстансами.

> 💡 **Навіщо Elastic IP?** Звичайний публічний IP змінюється при перезапуску інстансу. Elastic IP — незмінний і залишається вашим, поки ви його не відпустите.

```bash
# Отримуємо ENI (мережевий інтерфейс) для першого інстансу
ENI_A=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_A_ID \
  --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
  --output text)

# Отримуємо ENI для другого інстансу  
ENI_B=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_B_ID \
  --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
  --output text)

echo "✅ ENI WebServer: $ENI_A"
echo "✅ ENI AppServer: $ENI_B"
```

```bash
# Виділяємо Elastic IP (з пулу Amazon)
EIP_ALLOC_ID=$(aws ec2 allocate-address \
  --domain vpc \
  --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=academy-eip}]' \
  --query 'AllocationId' \
  --output text)

EIP_ADDRESS=$(aws ec2 describe-addresses \
  --allocation-ids $EIP_ALLOC_ID \
  --query 'Addresses[0].PublicIp' \
  --output text)

echo "✅ Elastic IP виділено: $EIP_ADDRESS (ID: $EIP_ALLOC_ID)"
```

### 8.1 Прив'язка EIP до WebServer (Subnet-A)

```bash
aws ec2 associate-address \
  --allocation-id $EIP_ALLOC_ID \
  --network-interface-id $ENI_A

echo "✅ Elastic IP $EIP_ADDRESS → WebServer (Subnet-A)"
echo "🌐 Перевірте в браузері: http://$EIP_ADDRESS"
```

> ⏳ Зачекайте ~2-3 хвилини поки запуститься httpd, потім відкрийте `http://$EIP_ADDRESS` у браузері.

### 8.2 Перевірка — хто зараз тримає EIP?

```bash
aws ec2 describe-addresses \
  --allocation-ids $EIP_ALLOC_ID \
  --query 'Addresses[0].{IP:PublicIp,Instance:InstanceId,ENI:NetworkInterfaceId}' \
  --output table
```

---

## 🔄 Крок 9 — Переміщення Elastic IP на AppServer

Це і є ключовий момент заняття — ми **відв'язуємо** EIP від одного інстансу і **прив'язуємо** до іншого без зміни IP-адреси.

```bash
# Отримуємо Association ID поточної прив'язки
ASSOC_ID=$(aws ec2 describe-addresses \
  --allocation-ids $EIP_ALLOC_ID \
  --query 'Addresses[0].AssociationId' \
  --output text)

echo "Поточна прив'язка: $ASSOC_ID"
```

```bash
# Відв'язуємо EIP від WebServer
aws ec2 disassociate-address \
  --association-id $ASSOC_ID

echo "✅ EIP відв'язано від WebServer"
```

```bash
# Прив'язуємо EIP до AppServer
aws ec2 associate-address \
  --allocation-id $EIP_ALLOC_ID \
  --network-interface-id $ENI_B

echo "✅ Elastic IP $EIP_ADDRESS → AppServer (Subnet-B)"
echo "🌐 Перевірте в браузері: http://$EIP_ADDRESS"
```

> ⚡ **Зверніть увагу:** IP-адреса ($EIP_ADDRESS) залишилась тією ж, але тепер вона веде на інший сервер! Саме в цьому цінність Elastic IP — можна переключати трафік без зміни DNS.

---

## 📊 Крок 10 — Перевірка всієї інфраструктури

```bash
echo "════════════════════════════════════════"
echo "       ПІДСУМОК ІНФРАСТРУКТУРИ          "
echo "════════════════════════════════════════"

echo ""
echo "🏢 VPC:"
aws ec2 describe-vpcs --vpc-ids $VPC_ID \
  --query 'Vpcs[0].{ID:VpcId,CIDR:CidrBlock,Name:Tags[?Key==`Name`]|[0].Value}' \
  --output table

echo ""
echo "📦 Підмережі:"
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[*].{ID:SubnetId,CIDR:CidrBlock,AZ:AvailabilityZone,Name:Tags[?Key==`Name`]|[0].Value}' \
  --output table

echo ""
echo "💻 Інстанси:"
aws ec2 describe-instances \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,PrivateIP:PrivateIpAddress,Subnet:SubnetId,Name:Tags[?Key==`Name`]|[0].Value}' \
  --output table

echo ""
echo "🌍 Elastic IP:"
aws ec2 describe-addresses \
  --allocation-ids $EIP_ALLOC_ID \
  --query 'Addresses[0].{IP:PublicIp,Instance:InstanceId,State:Domain}' \
  --output table
```

---

## 💾 Збереження змінних (важливо!)

Якщо CloudShell session переривається — зберіть ваші ID:

```bash
# Виконайте це і збережіть результат
cat << EOF
=== ЗБЕРЕЖІТЬ ЦІ ЗНАЧЕННЯ ===
VPC_ID=$VPC_ID
SUBNET_A_ID=$SUBNET_A_ID
SUBNET_B_ID=$SUBNET_B_ID
IGW_ID=$IGW_ID
RT_ID=$RT_ID
SG_ID=$SG_ID
NACL_ID=$NACL_ID
INSTANCE_A_ID=$INSTANCE_A_ID
INSTANCE_B_ID=$INSTANCE_B_ID
EIP_ALLOC_ID=$EIP_ALLOC_ID
EIP_ADDRESS=$EIP_ADDRESS
ENI_A=$ENI_A
ENI_B=$ENI_B
EOF
```

---

## 🧹 Крок 11 — Очищення ресурсів (після заняття)

> ⚠️ **ОБОВ'ЯЗКОВО** виконайте після заняття — AWS Academy має ліміти ресурсів!

```bash
# 1. Відв'язуємо та звільняємо Elastic IP
ASSOC_ID=$(aws ec2 describe-addresses --allocation-ids $EIP_ALLOC_ID \
  --query 'Addresses[0].AssociationId' --output text)
aws ec2 disassociate-address --association-id $ASSOC_ID
aws ec2 release-address --allocation-id $EIP_ALLOC_ID

# 2. Зупиняємо та видаляємо інстанси
aws ec2 terminate-instances --instance-ids $INSTANCE_A_ID $INSTANCE_B_ID
aws ec2 wait instance-terminated --instance-ids $INSTANCE_A_ID $INSTANCE_B_ID

# 3. Видаляємо Security Group
aws ec2 delete-security-group --group-id $SG_ID

# 4. Від'єднуємо та видаляємо Internet Gateway
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID

# 5. Видаляємо підмережі
aws ec2 delete-subnet --subnet-id $SUBNET_A_ID
aws ec2 delete-subnet --subnet-id $SUBNET_B_ID

# 6. Видаляємо Route Table
aws ec2 delete-route-table --route-table-id $RT_ID

# 7. Видаляємо VPC
aws ec2 delete-vpc --vpc-id $VPC_ID

echo "✅ Всі ресурси очищено!"
```

---

## 📚 Ключові концепції для запам'ятовування

| Поняття | Опис | Аналогія |
|---|---|---|
| **VPC** | Ізольована мережа в AWS | Приватна кімната в хмарі |
| **Subnet** | Підмережа всередині VPC | Кімнати всередині приміщення |
| **Internet Gateway** | Шлюз до інтернету | Двері назовні |
| **Route Table** | Таблиця маршрутів | Вказівники на дорозі |
| **Security Group** | Firewall на рівні інстансу | Охоронець біля дверей |
| **Network ACL** | Firewall на рівні підмережі | Охоронець на вході у поверх |
| **Elastic IP** | Статична публічна IP | Постійна адреса, яку можна передати |
| **EC2** | Віртуальна машина | Сервер у хмарі |

---

## 🎯 Завдання для самоперевірки

Після виконання всіх кроків запустіть скрипт самоперевірки:

```bash
# Завантажте та запустіть скрипт
curl -O https://raw.githubusercontent.com/YOUR_REPO/main/check.sh
chmod +x check.sh
./check.sh
```

Або скопіюйте вміст `check.sh` з репозиторію та запустіть в CloudShell.

---

*Підготовлено для AWS Academy Learner Lab | Хмарні технології — 5 курс*
