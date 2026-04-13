# Заняття 8.1 — Ansible: автоматизоване розгортання та управління ІТ-інфраструктурою

> **Змістовий модуль 1.** Методики автоматизованого розгортання ІТ-інфраструктури  
> **Середовище:** Локальний хост + AWS Academy Learner Lab  
> **Інструменти:** Terraform, Ansible, AWS EC2, Docker

---

## Зміст

1. [Встановлення Terraform та Ansible](#1-встановлення-terraform-та-ansible)
2. [Що таке Ansible і навіщо він потрібен](#2-що-таке-ansible-і-навіщо-він-потрібен)
3. [Як Ansible працює: архітектура](#3-як-ansible-працює-архітектура)
4. [Ключові поняття Ansible](#4-ключові-поняття-ansible)
5. [Terraform — розгортання чистої VM](#5-terraform--розгортання-чистої-vm)
6. [Структура Ansible проекту](#6-структура-ansible-проекту)
7. [ansible.cfg — конфігурація](#7-ansiblecfg--конфігурація)
8. [Inventory — список хостів](#8-inventory--список-хостів)
9. [group_vars — змінні](#9-group_vars--змінні)
10. [Playbook — повний розбір](#10-playbook--повний-розбір)
11. [Ad-hoc команди](#11-ad-hoc-команди)
12. [Запуск playbook](#12-запуск-playbook)
13. [Перевірка результатів](#13-перевірка-результатів)
14. [Знищення інфраструктури](#14-знищення-інфраструктури)
15. [Завдання для самопідготовки](#15-завдання-для-самопідготовки)

---

## 1. Встановлення Terraform та Ansible

### Terraform

| ОС | Посилання |
|---|---|
| Windows | https://developer.hashicorp.com/terraform/install#windows |
| macOS | https://developer.hashicorp.com/terraform/install#darwin |
| Ubuntu/Debian | https://developer.hashicorp.com/terraform/install#linux |

```bash
# Перевірка встановлення
terraform --version
# Очікуваний вивід: Terraform v1.x.x
```

### Ansible

| ОС | Посилання |
|---|---|
| macOS | https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html#installing-ansible-on-macos |
| Ubuntu/Debian | https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html#installing-ansible-on-ubuntu |
| Windows (WSL) | https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html#installing-ansible-on-ubuntu |

> **Примітка для Windows:** Ansible не запускається нативно на Windows. Використовуйте WSL (Windows Subsystem for Linux) з Ubuntu, або macOS/Linux хост.

```bash
# macOS
brew install ansible

# Ubuntu / WSL (Ubuntu)
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

# Перевірка встановлення
ansible --version
# Очікуваний вивід: ansible [core 2.x.x]
```

---

## 2. Що таке Ansible і навіщо він потрібен

### Проблема без Ansible

Уявіть: у вас 50 серверів і на кожен потрібно:
- Створити 10 користувачів
- Встановити 5 пакетів
- Запустити сервіси

Без автоматизації це означає 50 SSH-підключень і сотні однакових команд вручну. Помилитися дуже легко, відтворити точно — неможливо.

### Ansible — рішення

**Ansible** — інструмент автоматизації конфігурації та розгортання. Ви описуєте *бажаний стан* сервера у YAML-файлі (playbook), і Ansible приводить кожен сервер до цього стану.

```
БЕЗ ANSIBLE:                    З ANSIBLE:
───────────                     ──────────
ssh server01                    ansible-playbook playbook.yml
  useradd deploy                   ↓
  useradd developer             Ansible підключається до всіх
  dnf install git               серверів паралельно і виконує
  dnf install docker            всі задачі автоматично.
  systemctl start docker
ssh server02                    50 серверів = та сама команда.
  useradd deploy                Ручна праця → 0 хвилин.
  ...
50 серверів × 30 хв = 25 год!
```

### Ключові переваги

| Без Ansible | З Ansible |
|---|---|
| Ручне підключення до кожного сервера | Один запуск → всі сервери |
| Складно відтворити | Playbook = документація + інструкція |
| Легко помилитися | Ідемпотентність: можна запускати багато разів |
| Немає версіонування конфігурації | Playbook зберігається у Git |
| Потрібен агент на кожному сервері | Agentless: тільки SSH |

---

## 3. Як Ansible працює: архітектура

```
╔══════════════════════════════════════════════════════════════╗
║                     CONTROL NODE                             ║
║              (ваш локальний комп'ютер / CI сервер)           ║
║                                                              ║
║  ┌─────────────────────────────────────────────────────┐     ║
║  │  ansible-playbook playbook.yml                      │     ║
║  └──────────────┬──────────────────────────────────────┘     ║
║                 │                                            ║
║  Ansible читає: │                                            ║
║  ├── ansible.cfg       (конфігурація)                        ║
║  ├── inventory/hosts.ini  (список серверів)                  ║
║  ├── group_vars/all.yml   (змінні)                           ║
║  └── playbook.yml         (задачі)                           ║
╚═════════════════╪════════════════════════════════════════════╝
                  │
                  │  SSH (порт 22)
                  │  Передає Python-модулі, виконує, видаляє
                  │
     ┌────────────┴─────────────┐
     ▼                          ▼
╔══════════════╗         ╔══════════════╗
║ MANAGED NODE ║   ...   ║ MANAGED NODE ║
║  server-01   ║         ║  server-50   ║
║ (EC2, Linux) ║         ║ (EC2, Linux) ║
║              ║         ║              ║
║  SSH daemon  ║         ║  SSH daemon  ║
║  Python 3    ║         ║  Python 3    ║
╚══════════════╝         ╚══════════════╝
```

**Важливо:** на Managed Node потрібен лише SSH та Python 3. Жодних агентів встановлювати не потрібно.

**Як Ansible виконує задачу:**
1. Зчитує playbook та визначає яку задачу виконати
2. Генерує невеликий Python-скрипт (модуль)
3. Копіює скрипт на сервер через SSH (`scp`)
4. Виконує скрипт на сервері (`ssh ... python3 module.py`)
5. Отримує JSON-результат та видаляє скрипт
6. Відображає результат: `ok`, `changed`, `failed`

---

## 4. Ключові поняття Ansible

| Поняття | Опис |
|---|---|
| **Control Node** | Машина, з якої запускається Ansible (ваш комп'ютер) |
| **Managed Node** | Сервер, яким керує Ansible (EC2 інстанс) |
| **Inventory** | Список Managed Node з параметрами підключення |
| **Playbook** | YAML-файл із описом бажаного стану сервера |
| **Play** | Частина playbook: "на цих хостах виконати ці задачі" |
| **Task** | Одна атомарна дія (встановити пакет, створити файл, тощо) |
| **Module** | Вбудована функція Ansible (`user`, `dnf`, `systemd`, ...) |
| **Role** | Набір tasks, змінних і шаблонів для перевикористання |
| **Group Vars** | Змінні, що застосовуються до групи хостів |
| **Idempotency** | Властивість: повторний запуск дає той самий результат |

### Ідемпотентність — ключова властивість

```bash
# Перший запуск: Docker не встановлений
ansible-playbook playbook.yml
# TASK [Встановити системні пакети] → changed ← встановив

# Другий запуск: Docker вже встановлений
ansible-playbook playbook.yml
# TASK [Встановити системні пакети] → ok     ← нічого не змінював

# Можна запускати скільки завгодно — результат завжди однаковий.
```

---

## 5. Terraform — розгортання чистої VM

### Що змінилось порівняно з Lesson 7.1

У Lesson 7.1 Terraform встановлював Docker через `user_data` (скрипт при першому старті VM). Тепер Terraform відповідає **лише за інфраструктуру**, а Ansible — за конфігурацію.

```
LESSON 7.1:                        LESSON 8.1:
───────────                        ──────────
Terraform:                         Terraform:         Ansible:
├── VPC                            ├── VPC            ├── Користувачі
├── Subnet                         ├── Subnet         ├── Git
├── EC2                            ├── EC2 (чистий)   ├── Docker
└── user_data:                     └── outputs.tf     ├── net-tools
    ├── dnf install docker         (IP для inventory) └── systemctl docker
    └── docker run ...
                                   Чітке розмежування відповідальності:
                                   Terraform = інфраструктура
                                   Ansible   = конфігурація
```

### Структура Terraform проекту

```
terraform/
├── provider.tf    ← AWS провайдер та версія
├── variables.tf   ← змінні (регіон, CIDR, тип інстансу, ключ)
├── main.tf        ← ресурси: VPC, Subnet, IGW, Route, SG, EC2
└── outputs.tf     ← вивід: IP, SSH команда, рядок для inventory
```

### Розгортання

```bash
# Перейдіть у директорію Terraform
cd Lesson8_1/terraform

# Ініціалізація — завантаження AWS провайдера
terraform init

# Перегляд плану (нічого не створює)
terraform plan

# Розгортання (введіть 'yes')
terraform apply
```

**Очікуваний вивід після `terraform apply`:**
```
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:

ansible_inventory_entry = "3.85.142.201 ansible_user=ec2-user ansible_ssh_private_key_file=../vockey.pem"
instance_public_ip      = "3.85.142.201"
ssh_command             = "ssh -i vockey.pem ec2-user@3.85.142.201"
```

> Скопіюйте значення `ansible_inventory_entry` — воно знадобиться у наступному кроці.

---

## 6. Структура Ansible проекту

```
ansible/
├── ansible.cfg              ← конфігурація Ansible (де ключ, який юзер, тощо)
├── playbook.yml             ← головний playbook із задачами
├── inventory/
│   └── hosts.ini            ← список хостів (заповнюється після terraform apply)
└── group_vars/
    └── all.yml              ← змінні: список пакетів і користувачів
```

**Розміщення ключа:**
```
Lesson8_1/
├── vockey.pem           ← скопіюйте сюди із AWS Academy
├── terraform/
└── ansible/
    ├── ansible.cfg      ← private_key_file = ../vockey.pem
    └── ...
```

---

## 7. ansible.cfg — конфігурація

Повний файл: [ansible/ansible.cfg](./ansible/ansible.cfg)

```ini
[defaults]
inventory        = inventory/hosts.ini  # де шукати хости
remote_user      = ec2-user             # SSH користувач (Amazon Linux 2023)
private_key_file = ../vockey.pem        # SSH ключ відносно ansible.cfg
host_key_checking = False               # не питати підтвердження при першому підключенні
forks            = 5                    # скільки хостів обробляти паралельно
stdout_callback  = yaml                 # формат виводу (yaml читається зручніше)

[privilege_escalation]
become        = True   # використовувати sudo автоматично
become_method = sudo
become_user   = root
```

**Навіщо `host_key_checking = False`?**

При першому SSH-підключенні до нового хоста термінал запитує підтвердження:
```
The authenticity of host '3.85.142.201' can't be established.
Are you sure you want to continue connecting (yes/no)?
```
Ansible не може відповісти інтерактивно, тому вимикаємо перевірку для тимчасових EC2 інстансів.

---

## 8. Inventory — список хостів

Повний файл: [ansible/inventory/hosts.ini](./ansible/inventory/hosts.ini)

Inventory — це карта вашої інфраструктури. Ansible читає звідси список серверів та параметри підключення.

### Формат INI

```ini
[webservers]               ← ім'я групи (використовується у playbook: hosts: webservers)
3.85.142.201 ansible_user=ec2-user ansible_ssh_private_key_file=../vockey.pem
```

### Заповнення після terraform apply

```bash
# 1. Отримайте IP із виводу terraform
terraform output ansible_inventory_entry

# 2. Відредагуйте hosts.ini — замініть <EC2_PUBLIC_IP> на реальний IP
# Наприклад:
# 3.85.142.201 ansible_user=ec2-user ansible_ssh_private_key_file=../vockey.pem

# 3. Перевірте доступність
cd ../ansible
ansible webservers -m ping
```

### Структура груп

```ini
# Кілька хостів в одній групі
[webservers]
10.0.1.10 ansible_user=ec2-user ...
10.0.1.11 ansible_user=ec2-user ...

# Окрема група
[databases]
10.0.2.10 ansible_user=ec2-user ...

# Мета-група (об'єднує інші групи)
[all_servers:children]
webservers
databases
```

---

## 9. group_vars — змінні

Повний файл: [ansible/group_vars/all.yml](./ansible/group_vars/all.yml)

Ansible автоматично завантажує `group_vars/all.yml` для всіх хостів. Змінюйте тут — playbook.yml не потребує правок.

### Список пакетів

```yaml
packages:
  - git        # система контролю версій
  - docker     # платформа контейнеризації
  - net-tools  # мережеві утиліти: ifconfig, netstat, route
```

Щоб додати пакет — додайте рядок. Щоб видалити з сервера — змініть `state: present` → `state: absent` у playbook.

### Список користувачів (10 акаунтів)

```yaml
users:
  - { name: "deploy",     shell: "/bin/bash",    groups: ["docker"]          }  # сервісний акаунт деплою
  - { name: "developer",  shell: "/bin/bash",    groups: ["docker"]          }  # розробник
  - { name: "devops",     shell: "/bin/bash",    groups: ["docker", "wheel"] }  # DevOps інженер (sudo)
  - { name: "monitoring", shell: "/sbin/nologin", groups: []                 }  # моніторинг (вхід заборонено)
  - { name: "backup",     shell: "/sbin/nologin", groups: []                 }  # резервне копіювання
  - { name: "jenkins",    shell: "/bin/bash",    groups: ["docker"]          }  # CI/CD
  - { name: "gitlab",     shell: "/bin/bash",    groups: ["docker"]          }  # GitLab Runner
  - { name: "ansible",    shell: "/bin/bash",    groups: ["wheel"]           }  # автоматизація (sudo)
  - { name: "ops",        shell: "/bin/bash",    groups: ["docker", "wheel"] }  # operations (sudo)
  - { name: "sysadmin",   shell: "/bin/bash",    groups: ["wheel"]           }  # системний адміністратор
```

### Ієрархія змінних (від найнижчого до найвищого пріоритету)

```
group_vars/all.yml          ← базові значення для всіх
    ↓ перекривається
group_vars/webservers.yml   ← значення для групи webservers
    ↓ перекривається
host_vars/3.85.142.201.yml  ← значення для конкретного хоста
    ↓ перекривається
ansible-playbook -e "key=value"  ← передані через CLI (найвищий пріоритет)
```

---

## 10. Playbook — повний розбір

Повний файл із коментарями: [ansible/playbook.yml](./ansible/playbook.yml)

### Загальна структура

```yaml
---
- name: Назва Play          # опис для людей
  hosts: webservers         # на яких хостах виконувати
  become: true              # використовувати sudo

  tasks:
    - name: Назва задачі    # опис для людей
      ansible.builtin.модуль:
        параметр: значення
      loop: "{{ змінна }}"
      when: умова
```

### Задача 1 — Створення користувачів

```yaml
- name: "Створити системного користувача {{ item.name }}"
  ansible.builtin.user:
    name:        "{{ item.name }}"
    comment:     "{{ item.comment }}"
    shell:       "{{ item.shell }}"
    groups:      "{{ item.groups | join(',') }}"  # ["docker","wheel"] → "docker,wheel"
    append:      true        # додати до груп, не перезаписати
    create_home: true        # створити /home/<name>
    state:       present     # акаунт має існувати
  loop: "{{ users }}"        # виконати для кожного із 10 користувачів
  loop_control:
    label: "{{ item.name }}" # виводити тільки ім'я у логах
```

**Результат у системі:**
```bash
# /etc/passwd — нові рядки:
deploy:x:1001:1001:Deployment service account:/home/deploy:/bin/bash
developer:x:1002:1002:Developer account:/home/developer:/bin/bash
monitoring:x:1003:1003:Monitoring service account:/home/monitoring:/sbin/nologin
...

# /etc/group — нові записи:
docker:x:999:deploy,developer,devops,jenkins,gitlab,ops
wheel:x:10:devops,ansible,ops,sysadmin
```

### Задача 2 — Встановлення пакетів

```yaml
- name: "Встановити системні пакети"
  ansible.builtin.dnf:
    name:         "{{ packages }}"   # весь список за один виклик
    state:        present
    update_cache: true               # dnf makecache перед встановленням
```

**Еквівалент:**
```bash
dnf makecache && dnf install -y git docker net-tools
```

### Задача 3 — Запуск Docker

```yaml
- name: "Запустити та увімкнути сервіс Docker"
  ansible.builtin.systemd:
    name:    docker
    state:   started  # systemctl start docker
    enabled: true     # systemctl enable docker
```

**Еквівалент:**
```bash
systemctl start docker && systemctl enable docker
```

### Задача 4 — Групи Docker

```yaml
- name: "Додати {{ item.name }} до групи docker"
  ansible.builtin.user:
    name:   "{{ item.name }}"
    groups: docker
    append: true
  loop: "{{ users }}"
  loop_control:
    label: "{{ item.name }}"
  when: "'docker' in item.groups"   # тільки якщо docker є у списку груп
```

**Умова `when` по кожному користувачу:**

```
deploy     → groups: ["docker"]          → виконати ✓
devops     → groups: ["docker", "wheel"] → виконати ✓
monitoring → groups: []                  → пропустити (skipping)
sysadmin   → groups: ["wheel"]           → пропустити (skipping)
```

---

## 11. Ad-hoc команди

Ad-hoc — разові команди без playbook. Корисні для швидкої перевірки або однієї дії.

```
ansible <група_хостів> -m <модуль> -a "<аргументи>"
```

### Перевірка з'єднання

```bash
# Пінг — перевірити SSH доступ до всіх хостів
ansible webservers -m ping

# Очікуваний вивід:
# 3.85.142.201 | SUCCESS => {
#     "ansible_facts": { "discovered_interpreter_python": "/usr/bin/python3" },
#     "changed": false,
#     "ping": "pong"
# }
```

### Отримання інформації

```bash
# Виконати shell-команду
ansible webservers -m command -a "whoami"
ansible webservers -m command -a "cat /etc/os-release"

# Перевірити наявність користувача
ansible webservers -m command -a "id deploy"

# Перевірити встановлені пакети
ansible webservers -m command -a "rpm -q git docker net-tools"

# Перевірити мережеві інтерфейси (після встановлення net-tools)
ansible webservers -m command -a "ifconfig"
ansible webservers -m command -a "netstat -tuln"

# Зібрати всі факти про хост (IP, ОС, CPU, RAM, диски...)
ansible webservers -m setup
ansible webservers -m setup -a "filter=ansible_distribution*"
```

### Управління сервісами

```bash
# Перевірити статус Docker
ansible webservers -m command -a "systemctl status docker" --become

# Перезапустити Docker
ansible webservers -m systemd -a "name=docker state=restarted" --become
```

### Управління файлами

```bash
# Створити директорію
ansible webservers -m file -a "path=/opt/app state=directory mode=0755" --become

# Скопіювати файл на сервер
ansible webservers -m copy -a "src=./config.txt dest=/etc/myapp/config.txt" --become
```

> **`--become`** у ad-hoc командах — те саме що `become: true` у playbook (виконати від root).

---

## 12. Запуск playbook

### Підготовка

```bash
# Перейдіть у директорію Ansible
cd Lesson8_1/ansible

# Скопіюйте ключ поруч із директорією Lesson8_1/
cp /шлях/до/vockey.pem ../

# Встановіть правильні права на ключ
chmod 400 ../vockey.pem

# Заповніть inventory (замініть <EC2_PUBLIC_IP> на реальний IP)
# Значення беремо з: terraform output ansible_inventory_entry
nano inventory/hosts.ini
```

### Перевірка перед запуском

```bash
# 1. Перевірка синтаксису playbook
ansible-playbook playbook.yml --syntax-check

# 2. Dry run — показує що зміниться, нічого не виконує
ansible-playbook playbook.yml --check --diff

# 3. Перевірка підключення до хостів
ansible webservers -m ping
```

### Запуск

```bash
# Повний запуск
ansible-playbook playbook.yml
```

**Очікуваний вивід:**

```
PLAY [Налаштування сервера — користувачі, пакети, Docker] ****

TASK [Gathering Facts] ************************************************
ok: [3.85.142.201]

TASK [Створити системного користувача deploy] *************************
changed: [3.85.142.201]

TASK [Створити системного користувача developer] **********************
changed: [3.85.142.201]

... (ще 8 користувачів)

TASK [Встановити системні пакети] *************************************
changed: [3.85.142.201]

TASK [Запустити та увімкнути сервіс Docker] ***************************
changed: [3.85.142.201]

TASK [Додати deploy до групи docker] **********************************
changed: [3.85.142.201]

... (ще 5 користувачів з docker)

TASK [Додати monitoring до групи docker] ******************************
skipping: [3.85.142.201]   ← when: умова не виконалась

PLAY RECAP ************************************************************
3.85.142.201 : ok=18  changed=17  unreachable=0  failed=0  skipped=4
```

### Повторний запуск (ідемпотентність)

```bash
ansible-playbook playbook.yml
# PLAY RECAP: ok=18  changed=0  unreachable=0  failed=0
#                    ^^^^^^^^^
#             changed=0 — нічого не змінювалось, сервер вже у потрібному стані
```

### Корисні прапорці

```bash
# Детальний вивід (verbose)
ansible-playbook playbook.yml -v     # рівень 1: результати задач
ansible-playbook playbook.yml -vv    # рівень 2: + параметри підключення
ansible-playbook playbook.yml -vvv   # рівень 3: + SSH дебаг

# Виконати тільки для одного хоста
ansible-playbook playbook.yml --limit 3.85.142.201

# Запитувати підтвердження перед кожною задачею (корисно при навчанні)
ansible-playbook playbook.yml --step
```

---

## 13. Перевірка результатів

Підключіться до сервера та перевірте результати:

```bash
# Підключення
ssh -i ../vockey.pem ec2-user@<PUBLIC_IP>
```

### Перевірка користувачів

```bash
# Переглянути всіх створених користувачів
cut -d: -f1 /etc/passwd | tail -10

# Перевірити конкретного користувача
id deploy
# uid=1001(deploy) gid=1001(deploy) groups=1001(deploy),999(docker)

id devops
# uid=1002(devops) gid=1002(devops) groups=1002(devops),999(docker),10(wheel)

id monitoring
# uid=1003(monitoring) gid=1003(monitoring) groups=1003(monitoring)
# (без docker і wheel — як і задано)

# Перевірити shell для сервісного акаунту
grep monitoring /etc/passwd
# monitoring:x:1003:1003:Monitoring service account:/home/monitoring:/sbin/nologin

# Перевірити домашні директорії
ls /home/
# ansible  backup  deploy  developer  devops  gitlab  jenkins  monitoring  ops  sysadmin
```

### Перевірка пакетів

```bash
# Перевірити встановлені пакети
rpm -q git docker net-tools

# Версії
git --version
docker --version
ifconfig --version
```

### Перевірка Docker

```bash
# Статус сервісу
systemctl status docker
# ● docker.service - Docker Application Container Engine
#    Active: active (running)  ← має бути active

# Автозапуск
systemctl is-enabled docker
# enabled  ← має бути enabled

# Запустити docker без sudo (від імені deploy)
sudo -u deploy docker ps
# CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES
# (порожній список — Docker працює, контейнерів ще немає)
```

### Мережева діагностика з net-tools

```bash
# Мережеві інтерфейси
ifconfig

# Прослуховувані порти
netstat -tuln

# Таблиця маршрутизації
route -n
```

---

## 14. Знищення інфраструктури

```bash
cd Lesson8_1/terraform

# ОБОВ'ЯЗКОВО виконати наприкінці заняття, щоб не витрачати кредити AWS Academy
terraform destroy
```

---

## 15. Завдання для самопідготовки

> Виконується самостійно після заняття.

**Завдання:** повністю відтворити pipeline: Terraform → Ansible → Docker контейнер.

### Кроки

**1. Розгорнути інстанс Terraform**
```bash
cd Lesson8_1/terraform
terraform init && terraform apply
```

**2. Налаштувати сервер Ansible**

Заповніть `inventory/hosts.ini` і запустіть playbook:
```bash
cd Lesson8_1/ansible
ansible-playbook playbook.yml
```

**3. Запустити Docker контейнер через Ansible**

Додайте до `playbook.yml` нову задачу після блоку Docker:

```yaml
- name: "Запустити Docker контейнер"
  community.docker.docker_container:
    name:    devops-landing
    image:   rossogamata/devops-landing:latest
    # (за додаткові бали: використайте власний Docker image із Lesson 7.1)
    state:   started
    restart_policy: always
    ports:
      - "80:80"
```

> **За додаткові бали:** замість `rossogamata/devops-landing:latest` використайте власний Docker image, зібраний та опублікований у Lesson 7.1. Вкажіть посилання на свій Docker Hub репозиторій у коментарі до завдання.

**4. Перевірка**

```bash
# Перевірте що контейнер запущений
ansible webservers -m command -a "docker ps"

# Відкрийте у браузері
# http://<PUBLIC_IP>
```

**5. Знищення після перевірки**
```bash
cd Lesson8_1/terraform && terraform destroy
```

### Що здати

- Скріншот виводу `ansible-playbook playbook.yml` (PLAY RECAP)
- Скріншот `docker ps` на сервері
- Скріншот відкритого застосунку у браузері (`http://<PUBLIC_IP>`)
- *(за додаткові бали)* посилання на власний Docker Hub image

---

## Підсумок заняття

```
Локальний хост                        AWS EC2
──────────────                        ───────
1. terraform apply      ──────────►  Чистий EC2 інстанс
   (інфраструктура)                  (немає жодного ПЗ)
                                          │
2. ansible-playbook     ──── SSH ────►   ├── 10 користувачів
   playbook.yml                          ├── git, docker, net-tools
   (конфігурація)                        └── docker.service (running)
```

| Крок | Команда |
|---|---|
| Розгорнути VM | `terraform apply` |
| Заповнити inventory | вставити IP у `inventory/hosts.ini` |
| Перевірити доступ | `ansible webservers -m ping` |
| Dry run | `ansible-playbook playbook.yml --check` |
| Запустити | `ansible-playbook playbook.yml` |
| Знищити | `terraform destroy` |

---

*Методології автоматизованого розгортання ІТ інфраструктури · 5 курс · AWS Academy*  
*ВІДКРИТА ІНФОРМАЦІЯ*
