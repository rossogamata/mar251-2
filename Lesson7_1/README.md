# 🐳 Заняття 7.1 — Використання Docker для автоматизації розгортання ІТ-інфраструктури

> **Змістовий модуль 1.** Методики автоматизованого розгортання ІТ-інфраструктури  
> **Середовище:** Локальний хост + AWS Academy Learner Lab  
> **Інструменти:** Docker, Docker Hub, Terraform, AWS EC2

---

## Зміст

1. [Встановлення Docker](#1-встановлення-docker)
2. [Що таке Docker і навіщо він потрібен](#2-що-таке-docker-і-навіщо-він-потрібен)
3. [JavaScript проект — огляд](#3-javascript-проект--огляд)
4. [Dockerfile — розбір по шарах](#4-dockerfile--розбір-по-шарах)
5. [Збірка Docker image](#5-збірка-docker-image)
6. [Локальний запуск контейнера](#6-локальний-запуск-контейнера)
7. [Публікація image на Docker Hub](#7-публікація-image-на-docker-hub)
8. [Налаштування доступу до AWS Academy](#8-налаштування-доступу-до-aws-academy)
9. [Провіженінг інфраструктури Terraform](#9-провіженінг-інфраструктури-terraform)
10. [Запуск контейнера на AWS EC2](#10-запуск-контейнера-на-aws-ec2)

---

## 1. Встановлення Docker

Оберіть свою операційну систему та перейдіть за посиланням на офіційну інструкцію:

| ОС | Посилання |
|---|---|
| Windows | https://docs.docker.com/desktop/setup/install/windows-install/ |
| macOS | https://docs.docker.com/desktop/setup/install/mac-install/ |
| Ubuntu | https://docs.docker.com/engine/install/ubuntu/ |

> **Перевірка встановлення** — після інсталяції відкрийте термінал і виконайте:
> ```bash
> docker --version
> docker run hello-world
> ```

---

## 2. Що таке Docker і навіщо він потрібен

### Проблема без Docker

Уявіть ситуацію: розробник пише застосунок на своєму MacBook, тестувальник перевіряє його на Windows, а сервер працює на Linux. Кожне середовище має різні версії Node.js, різні системні бібліотеки, різні налаштування. Результат — класичне *"у мене на машині працює"*.

### Docker — рішення

**Docker** — платформа контейнеризації, яка дозволяє упакувати застосунок разом із усіма залежностями у стандартизований ізольований модуль — **контейнер**.

```
┌─────────────────────────────────────────────┐
│              Ваш застосунок                  │
├─────────────────────────────────────────────┤
│    Залежності (Node.js, npm пакети, ...)     │
├─────────────────────────────────────────────┤
│         Docker контейнер (ізоляція)          │
├─────────────────────────────────────────────┤
│    Linux Kernel (будь-який хост: Win/Mac)    │
└─────────────────────────────────────────────┘
```

### Ключові переваги для DevOps

| Без Docker | З Docker |
|---|---|
| "У мене на машині працює" | Однаково працює скрізь |
| Ручне встановлення залежностей | `docker run` — і все готово |
| Конфлікти між версіями | Повна ізоляція між контейнерами |
| Складне масштабування | Запусти ще 10 копій однією командою |
| Важке відтворення середовища | `docker build` — повна відтворюваність |

### Ключові поняття

- **Image** (образ) — шаблон, знімок файлової системи з вашим застосунком. Аналогія: ISO-образ диска.
- **Container** (контейнер) — запущений екземпляр image. Аналогія: запущена програма.
- **Dockerfile** — інструкція для збірки image: що встановити, що скопіювати, як запустити.
- **Registry** — сховище image. Docker Hub — публічний реєстр (аналог GitHub, але для image).
- **Layer** (шар) — кожна інструкція у Dockerfile створює окремий шар. Шари кешуються.

### Docker vs Віртуальна машина

```
VM:                              Docker:
┌──────────────────┐             ┌──────────────────┐
│    Застосунок    │             │    Застосунок    │
├──────────────────┤             ├──────────────────┤
│  Guest OS (2 ГБ) │             │  Docker Engine   │
├──────────────────┤             ├──────────────────┤
│   Hypervisor     │             │    Host OS       │
├──────────────────┤             ├──────────────────┤
│    Host OS       │             │    Hardware      │
└──────────────────┘             └──────────────────┘
Старт: хвилини                  Старт: секунди
Розмір: гігабайти               Розмір: мегабайти
```

---

## 3. JavaScript проект — огляд

Проект знаходиться у директорії [app/](./app/).

```
app/
├── Dockerfile          ← інструкція збірки Docker image
├── .dockerignore       ← що НЕ копіювати в image (аналог .gitignore)
├── package.json        ← залежності та npm скрипти
├── index.html          ← єдина HTML сторінка
└── src/
    ├── main.js         ← JavaScript логіка
    └── style.css       ← стилі
```

**Що робить застосунок:** одностронінкове демо про дисципліну "Методології автоматизованого розгортання ІТ інфраструктури" — з описом інструментів, DevOps пайплайну та стеку технологій.

**Білдер:** [Vite](https://vitejs.dev/) — сучасний бандлер для JavaScript. Команда `npm run build` компілює та мінімізує код у директорію `dist/`.

---

## 4. Dockerfile — розбір по шарах

Повний [Dockerfile](./app/Dockerfile) з детальними коментарями знаходиться у `app/Dockerfile`.

### Схема multi-stage збірки

```
┌─────────────────────────────────────────────────────────┐
│  STAGE 1: builder (node:20-alpine)                      │
│                                                          │
│  FROM node:20-alpine  ← базовий образ ~50 МБ            │
│      │                                                   │
│  WORKDIR /app         ← робоча директорія               │
│      │                                                   │
│  COPY package.json    ← окремий шар для кешування       │
│      │                                                   │
│  RUN npm install      ← встановлення залежностей        │
│      │                                                   │
│  COPY . .             ← вихідний код                    │
│      │                                                   │
│  RUN npm run build    ← збірка → /app/dist/             │
└──────────────────────────┬──────────────────────────────┘
                           │ лише /app/dist/
                           ▼
┌─────────────────────────────────────────────────────────┐
│  STAGE 2: production (nginx:alpine)                     │
│                                                          │
│  FROM nginx:alpine    ← базовий образ ~8 МБ             │
│      │                                                   │
│  COPY --from=builder /app/dist → /usr/share/nginx/html  │
│      │                                                   │
│  EXPOSE 80            ← документуємо порт               │
│      │                                                   │
│  CMD ["nginx", "-g", "daemon off;"]  ← запуск           │
└─────────────────────────────────────────────────────────┘

Фінальний image: ~10 МБ (без Node.js, без node_modules)
```

### Чому шари важливі: кешування

```bash
# Перша збірка — всі шари будуються:
Step 1/8: FROM node:20-alpine       → завантаження
Step 2/8: WORKDIR /app              → створення
Step 3/8: COPY package.json ./      → копіювання
Step 4/8: RUN npm install           → 30 секунд ⏳
Step 5/8: COPY . .                  → копіювання
Step 6/8: RUN npm run build         → збірка

# Друга збірка (змінили лише main.js):
Step 1/8: FROM node:20-alpine       → CACHED ✅
Step 2/8: WORKDIR /app              → CACHED ✅
Step 3/8: COPY package.json ./      → CACHED ✅
Step 4/8: RUN npm install           → CACHED ✅ (економія 30 сек!)
Step 5/8: COPY . .                  → rebuild
Step 6/8: RUN npm run build         → rebuild
```

---

## 5. Збірка Docker image

```bash
# Перейдіть у директорію з Dockerfile
cd Lesson7_1/app

# Збірка image
# -t    — тег (ім'я та версія image)
# .     — контекст збірки (поточна директорія)
docker build -t rossogamata/devops-landing:latest .

# Перевірте, що image створений
docker images | grep devops-landing
```

> **Очікуваний вивід:**
> ```
> REPOSITORY                      TAG       IMAGE ID       SIZE
> rossogamata/devops-landing      latest    abc123def456   12.3MB
> ```

---

## 6. Локальний запуск контейнера

```bash
# Запуск контейнера
# -d        — фоновий режим (detached)
# --name    — зручне ім'я для управління контейнером
# -p 8080:80 — пробрасовуємо локальний порт 8080 → порт 80 контейнера
docker run -d --name devops-landing -p 8080:80 rossogamata/devops-landing:latest

# Відкрийте у браузері: http://localhost:8080
```

### Корисні команди для роботи з контейнером

```bash
# Список запущених контейнерів
docker ps

# Список ВСІХ контейнерів (включно зі зупиненими)
docker ps -a

# Логи контейнера (корисно для дебагу)
docker logs devops-landing

# Зупинка контейнера
docker stop devops-landing

# Видалення контейнера (спочатку треба зупинити)
docker rm devops-landing

# Зупинити та видалити одразу
docker rm -f devops-landing

# Зайти всередину запущеного контейнера (як SSH)
docker exec -it devops-landing sh

# Список усіх локальних image
docker images

# Видалення image
docker rmi rossogamata/devops-landing:latest
```

---

## 7. Публікація image на Docker Hub

### Авторизація

```bash
# Введіть ваш Docker Hub логін і пароль
docker login
```

### Push image

```bash
# Переконайтесь, що image тегований з вашим username
# Формат: username/repository:tag
docker tag rossogamata/devops-landing:latest rossogamata/devops-landing:v1.0

# Публікація на Docker Hub
docker push rossogamata/devops-landing:latest
docker push rossogamata/devops-landing:v1.0
```

> Image буде доступний за адресою: https://hub.docker.com/repositories/rossogamata

### Завантаження image (на будь-якому хості)

```bash
# Завантажити та запустити image без попередньої збірки
docker pull rossogamata/devops-landing:latest
docker run -d -p 80:80 rossogamata/devops-landing:latest
```

---

## 8. Налаштування доступу до AWS Academy

### Крок 1 — Запуск лабораторії

1. Увійдіть на [awsacademy.instructure.com](https://awsacademy.instructure.com) → **Learner Lab**
2. Натисніть **Start Lab** → дочекайтесь ● зеленого індикатора
3. Натисніть **AWS Details** → **Download PEM** (збережіть `vockey.pem`)

### Крок 2 — Налаштування AWS credentials

```bash
# Натисніть "AWS Details" → "AWS CLI" → скопіюйте credentials
# Відкрийте файл ~/.aws/credentials та вставте скопійовані дані:
[default]
aws_access_key_id=ASIA...
aws_secret_access_key=...
aws_session_token=...

# Перевірка доступу
aws sts get-caller-identity
```

> **Важливо:** credentials в AWS Academy діють лише поки лабораторія активна. При кожному новому сеансі потрібно оновлювати.

### Крок 3 — Встановлення Terraform

```bash
# macOS
brew install terraform

# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform

# Перевірка
terraform --version
```

---

## 9. Провіженінг інфраструктури Terraform

Terraform проект знаходиться у директорії [terraform/](./terraform/).

### Структура проекту

```
terraform/
├── provider.tf    ← налаштування AWS провайдера
├── variables.tf   ← змінні (регіон, CIDR, тип інстансу...)
├── main.tf        ← усі ресурси AWS (VPC, Subnet, IGW, EC2...)
└── outputs.tf     ← вивід результатів (IP, SSH команда, URL)
```

### Ресурси, які створює Terraform

```
AWS Academy
└── VPC (10.0.0.0/16)
    ├── Публічна Subnet (10.0.1.0/24)
    │   └── EC2 Instance (t2.micro)
    │       └── Security Group (SSH:22, HTTP:80)
    ├── Internet Gateway
    └── Route Table → Route (0.0.0.0/0 → IGW)
```

### Кроки розгортання

```bash
# Перейдіть у директорію Terraform
cd Lesson7_1/terraform

# Ініціалізація — завантаження провайдера AWS
terraform init

# Перегляд плану — що буде створено
terraform plan

# Застосування (введіть 'yes' для підтвердження)
terraform apply

# Після успішного apply Terraform виведе:
# instance_public_ip = "3.xx.xx.xx"
# ssh_command        = "ssh -i vockey.pem ec2-user@3.xx.xx.xx"
# app_url            = "http://3.xx.xx.xx"
```

> **Увага:** EC2 інстанс автоматично встановлює Docker та запускає контейнер через `user_data`. Це займає ~2 хвилини після створення.

### Знищення інфраструктури після заняття

```bash
# ОБОВ'ЯЗКОВО виконати наприкінці заняття, щоб не витрачати кредити
terraform destroy
```

---

## 10. Запуск контейнера на AWS EC2

### Підключення до інстансу по SSH

```bash
# Дайте права на ключ
chmod 400 vockey.pem

# Підключіться (IP дізнайтесь з виводу terraform apply або aws console)
ssh -i vockey.pem ec2-user@<PUBLIC_IP>
```

### Перевірка стану контейнера

```bash
# Перевірте, що Docker встановлений
docker --version

# Перевірте статус контейнера (має бути Up)
docker ps

# Перегляньте логи контейнера
docker logs devops-landing
```

### Доступ до застосунку

Відкрийте у браузері:
```
http://<PUBLIC_IP>
```

### Якщо контейнер не запустився автоматично

```bash
# Запустіть вручну
docker run -d \
  --name devops-landing \
  --restart always \
  -p 80:80 \
  rossogamata/devops-landing:latest
```

### Оновлення застосунку на сервері

```bash
# Зупинити та видалити старий контейнер
docker rm -f devops-landing

# Завантажити нову версію image
docker pull rossogamata/devops-landing:latest

# Запустити оновлений контейнер
docker run -d \
  --name devops-landing \
  --restart always \
  -p 80:80 \
  rossogamata/devops-landing:latest
```

---

## Підсумок заняття

```
Локальний хост                Docker Hub            AWS EC2
─────────────                 ──────────            ───────
1. git clone / код            3. docker push →      4. terraform apply
2. docker build ──────────────────────────────────► 5. docker pull (auto)
   docker run (тест)          rossogamata/           6. docker run (auto)
                              devops-landing          7. http://<IP> ✅
```

| Крок | Команда |
|---|---|
| Збірка | `docker build -t rossogamata/devops-landing:latest .` |
| Тест локально | `docker run -d -p 8080:80 rossogamata/devops-landing:latest` |
| Публікація | `docker push rossogamata/devops-landing:latest` |
| Інфраструктура | `terraform apply` |
| Перевірка | `http://<PUBLIC_IP>` |
| Прибирання | `terraform destroy` |

---

*Методології автоматизованого розгортання ІТ інфраструктури · 5 курс · AWS Academy*  
*ВІДКРИТА ІНФОРМАЦІЯ*
