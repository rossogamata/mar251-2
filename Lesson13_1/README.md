# 🔧 Заняття 13.1 (Групове) — Початкова робота з Jenkins

> **Змістовий модуль 1.** Методики автоматизованого розгортання ІТ-інфраструктури
> **Середовище:** Локальний хост (Docker) + AWS Academy Learner Lab (опційно, для Deploy stage)
> **Інструменти:** Jenkins, Docker, GitHub, Ansible

## 📋 Навчальні питання

| # | Тема |
|---|---|
| **1** | Основні поняття Jenkins |
| **2** | Конфігурація Jenkins |

---

## Зміст

0. [Перевірка знань — CI/CD](#0-перевірка-знань--cicd)
1. [Що таке Jenkins і навіщо він потрібен](#1-що-таке-jenkins-і-навіщо-він-потрібен)
2. [Архітектура Jenkins](#2-архітектура-jenkins)
3. [Ключові поняття Jenkins](#3-ключові-поняття-jenkins)
4. [Встановлення Jenkins](#4-встановлення-jenkins)
5. [Перший запуск та Setup Wizard](#5-перший-запуск-та-setup-wizard)
6. [Встановлення плагінів](#6-встановлення-плагінів)
7. [Global Tool Configuration](#7-global-tool-configuration)
8. [Credentials — керування секретами](#8-credentials--керування-секретами)
9. [Перший Job: Freestyle project](#9-перший-job-freestyle-project)
10. [Pipeline Job та Jenkinsfile](#10-pipeline-job-та-jenkinsfile)
11. [Webhook — автоматичний запуск з GitHub](#11-webhook--автоматичний-запуск-з-github)
12. [Перевірка результатів збірки](#12-перевірка-результатів-збірки)
13. [Зупинка та знищення середовища](#13-зупинка-та-знищення-середовища)
14. [Завдання для самопідготовки](#14-завдання-для-самопідготовки)
15. [Підсумок заняття](#15-підсумок-заняття)

---

## 0. Перевірка знань — CI/CD

Перед початком запустіть інтерактивну самоперевірку — вона повторює ключові поняття CI/CD з попереднього заняття (Continuous Integration, Continuous Delivery/Deployment, pipeline, artifact, build agent) і лише потім переходить до Jenkins.

```bash
cd Lesson13_1/self_check
chmod +x check.sh
./check.sh
```

> Частина A скрипта (CI/CD) — це саме той матеріал, який ви проходили минулого разу. Якщо є прогалини — варто освіжити його **до** переходу до розділу 1.

Коротко нагадаємо контекст, у який вписується Jenkins:

```
Розробник                CI/CD сервер                  Продакшн
──────────                ─────────────                  ────────
git push          ──▶     1. Checkout коду
                          2. Build (компіляція/збірка)
                          3. Test (юніт/інтеграційні тести)
                          4. Package (Docker image, jar, ...)
                          5. Publish (Docker Hub, artifact repo)
                          6. Deploy (Ansible/Terraform/kubectl)  ──▶  Сервер оновлено

Jenkins автоматизує кроки 1-6: досить одного "git push",
і решта відбувається без участі людини.
```

**Jenkins — один з найпоширеніших CI/CD серверів**, який виконує саме цю послідовність. Сьогодні розгортаємо його і будуємо перший pipeline.

---

## 1. Що таке Jenkins і навіщо він потрібен

### Проблема без CI/CD сервера

Уявіть команду з 5 розробників. Кожен коммітить код кілька разів на день. Без автоматизації хтось повинен вручну:
- Витягнути код з Git
- Зібрати проект / Docker image
- Прогнати тести
- Задеплоїти на сервер

Помножте це на 10-20 коммітів щодня — ручна робота стає вузьким горлом, а помилки ("забув прогнати тести", "задеплоїв не ту гілку") — регулярними.

### Jenkins — рішення

**Jenkins** — це сервер автоматизації з відкритим вихідним кодом (Java, проект Eclipse Foundation), що дозволяє будувати **CI/CD pipeline**: послідовність кроків, які виконуються автоматично при кожній зміні коду.

```
БЕЗ JENKINS:                          З JENKINS:
────────────                         ──────────
git push                             git push
  ↓                                    ↓ (webhook)
Розробник вручну:                    Jenkins автоматично:
  ssh на CI-машину                     checkout → build → test →
  git pull                             package → push → deploy
  npm run build / docker build
  npm test
  docker push
  ssh на сервер, docker pull, restart  Розробник лише дивиться
                                       результат: ✅ / ❌
15-30 хв ручної роботи на кожен push  0 хв ручної роботи
```

### Ключові переваги

| Без Jenkins | З Jenkins |
|---|---|
| Ручна збірка/деплой на кожен коміт | Автоматичний запуск при push/PR |
| Немає єдиного місця для логів збірки | Console Output кожного build зберігається |
| Складно повторити той самий процес | Pipeline = код (Jenkinsfile) у Git |
| Немає сповіщень про поламану збірку | Email/Slack сповіщення при failure |
| Один сервер для всього | Розподілені агенти (Controller + Agents) |
| Ручний процес не документований | Jenkinsfile = документація + виконуваний код |

### Jenkins серед інших CI/CD інструментів

| Інструмент | Тип | Особливість |
|---|---|---|
| **Jenkins** | Self-hosted, open-source | Максимальна гнучкість, 1800+ плагінів, потребує власного сервера |
| GitHub Actions | SaaS, вбудований у GitHub | Просто для проектів на GitHub, YAML у `.github/workflows/` |
| GitLab CI/CD | Вбудований у GitLab | `.gitlab-ci.yml`, тісна інтеграція з GitLab |
| CircleCI / Travis CI | SaaS | Швидкий старт, платний за хмарні ресурси |
| TeamCity | JetBrains, self-hosted | Зручний UI, комерційна ліцензія для команд |

> 💡 Jenkins обирають, коли потрібен повний контроль над інфраструктурою CI/CD, підтримка legacy-систем через плагіни, або on-premise розгортання (як у нашому AWS Academy / self-hosted сценарії).

---

## 2. Архітектура Jenkins

```
╔═══════════════════════════════════════════════════════════════╗
║                    JENKINS CONTROLLER                          ║
║                  (раніше називався "Master")                   ║
║                                                                 ║
║  ┌──────────────────────────────────────────────────────┐      ║
║  │  Web UI (порт 8080)                                   │      ║
║  │  Планувальник задач (scheduler)                       │      ║
║  │  Зберігає: Job-конфігурації, історію build, плагіни    │      ║
║  │  jenkins_home/  ← весь стан Jenkins                    │      ║
║  └──────────────────────────────────────────────────────┘      ║
╚═══════════════╤═════════════════════════════╤═══════════════════╝
                │  JNLP / SSH (порт 50000)     │
                ▼                              ▼
     ┌────────────────────┐         ┌────────────────────┐
     │   AGENT / NODE 1    │   ...   │   AGENT / NODE N    │
     │  (executor x2)      │         │  (executor x4)      │
     │  Linux, Docker,     │         │  Windows, .NET SDK  │
     │  Maven, Node.js     │         │                     │
     └────────────────────┘         └────────────────────┘
```

**Controller (Master)** — головний сервер: приймає запити на збірку, розподіляє їх по агентах, зберігає конфігурацію та результати.

**Agent (Node)** — окрема машина (або контейнер), що фактично **виконує** роботу build. Controller лише координує.

**Executor** — слот на агенті для паралельного виконання одного build. Якщо в агента 4 executors — одночасно можуть виконуватись 4 build.

> Для навчального заняття ми запускаємо **Controller без окремих агентів** (`agent any` виконується прямо на Controller) — це найпростіший сценарій. У production, як правило, Controller лише координує, а build виконують окремі Agent-ноди.

---

## 3. Ключові поняття Jenkins

| Поняття | Опис |
|---|---|
| **Job / Project** | Конфігурація одного процесу автоматизації (напр. "збірка devops-landing") |
| **Build** | Один запуск Job — має номер (`#1`, `#2`, ...), статус, лог |
| **Pipeline** | Job, що описаний як код (Jenkinsfile) — послідовність stages |
| **Stage** | Логічний етап pipeline (Build, Test, Deploy) — видно на графіку у UI |
| **Step** | Одна команда всередині stage (`sh 'docker build ...'`) |
| **Workspace** | Директорія на агенті, куди Jenkins клонує код і виконує build |
| **Executor** | Слот для паралельного виконання build на агенті |
| **Plugin** | Розширення функціоналу (Git, Docker, Slack, Blue Ocean, ...) |
| **Trigger** | Що запускає build: webhook, розклад (cron), ручний запуск, upstream job |
| **Artifact** | Файл-результат build (jar, zip, Docker image), що зберігається після завершення |
| **Credentials** | Захищено збережені секрети (паролі, токени, SSH-ключі) |
| **Blue Ocean** | Сучасний UI-плагін для наочного відображення pipeline |

### Freestyle vs Pipeline

| | Freestyle Job | Pipeline Job |
|---|---|---|
| Конфігурація | Через Web UI (форми) | Через код — `Jenkinsfile` (Groovy DSL) |
| Версіонування | Не зберігається у Git автоматично | `Jenkinsfile` живе поруч з кодом у Git |
| Складна логіка (if/else, паралельність) | Складно | Природно (це код) |
| Рекомендація | Для простих одноразових задач | **Стандарт для CI/CD** — саме її ми будемо будувати |

### Declarative vs Scripted Pipeline

```groovy
// Declarative — структурований, рекомендований синтаксис
pipeline {
    agent any
    stages {
        stage('Build') {
            steps { sh 'echo building' }
        }
    }
}

// Scripted — довільний Groovy-код, більше гнучкості, складніше читати
node {
    stage('Build') {
        sh 'echo building'
    }
}
```

> У Розділі 10 ми будемо використовувати **Declarative Pipeline** — саме такий синтаксис у [jenkins/Jenkinsfile](./jenkins/Jenkinsfile).

---

## 4. Встановлення Jenkins

Найпростіший та найвідтворюваніший спосіб для заняття — **Docker**. Файли вже підготовлені у [jenkins/](./jenkins/).

### Структура

```
Lesson13_1/jenkins/
├── Dockerfile          ← Jenkins LTS + Docker CLI (для docker build у pipeline)
├── docker-compose.yml  ← запуск контейнера, порти, volumes
└── Jenkinsfile         ← приклад pipeline (Розділ 10)
```

### Передумови

```bash
docker --version           # Docker має бути встановлений (Заняття 7.1)
docker compose version     # Docker Compose v2
```

### Запуск

```bash
cd Lesson13_1/jenkins

# Збірка образу (Jenkins + docker CLI) та запуск контейнера у фоні
docker compose up -d --build

# Перевірка, що контейнер запущений
docker ps --filter name=jenkins
```

**Очікуваний вивід:**
```
CONTAINER ID   IMAGE                          STATUS         PORTS
a1b2c3d4e5f6   local/jenkins-docker:lts-jdk17 Up 20 seconds  0.0.0.0:8080->8080/tcp, 0.0.0.0:50000->50000/tcp
```

### Альтернатива — нативне встановлення (без Docker)

| ОС | Спосіб |
|---|---|
| Ubuntu/Debian | https://www.jenkins.io/doc/book/installing/linux/#debianubuntu |
| macOS | `brew install jenkins-lts` |
| Windows | https://www.jenkins.io/doc/book/installing/windows/ |

> Для цього заняття рекомендуємо Docker-варіант — він однаковий для всіх ОС і легко знищується (`docker compose down -v`) після заняття.

---

## 5. Перший запуск та Setup Wizard

### Отримання пароля адміністратора

При першому старті Jenkins генерує тимчасовий пароль і виводить його в лог:

```bash
docker compose logs jenkins | grep -A 2 "Please use the following password"
```

Або напряму з контейнера:

```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

**Очікуваний вивід:**
```
a1b2c3d4e5f647890123456789abcdef
```

### Кроки Setup Wizard

1. Відкрийте у браузері **http://localhost:8080**
2. Вставте пароль з попереднього кроку у поле **Administrator password**
3. Оберіть **"Install suggested plugins"** (Git, Pipeline, Credentials Binding, тощо — автоматично)
4. Дочекайтесь встановлення (2-5 хв)
5. Створіть першого адміністратора:

```
Username:  admin
Password:  ********  (запишіть — знадобиться далі)
Full name: Admin
Email:     ваш email
```

6. **Instance Configuration** → залиште `http://localhost:8080/` як Jenkins URL → **Save and Finish**
7. **Jenkins is ready!** → **Start using Jenkins**

---

## 6. Встановлення плагінів

Для нашого pipeline (Git → Docker → Ansible) додатково потрібні:

**Manage Jenkins → Plugins → Available plugins**, знайдіть і встановіть:

| Плагін | Навіщо |
|---|---|
| **Docker Pipeline** | Крок `docker.build()`, робота з Docker з pipeline |
| **Git** | Зазвичай вже входить у suggested plugins — checkout з Git/GitHub |
| **GitHub Integration** | Webhook-тригери з GitHub, статус build у PR |
| **Blue Ocean** | Візуальний UI для перегляду pipeline (опційно, зручно для демонстрації) |
| **Credentials Binding** | Безпечна передача credentials у sh-кроки (зазвичай вже встановлений) |

```
Manage Jenkins → Plugins → Available plugins
  → пошук "Docker Pipeline" → ☑ → Install
  → пошук "Blue Ocean"      → ☑ → Install
  → Restart Jenkins when installation is complete (внизу сторінки)
```

**Перевірка встановлених плагінів:**
```
Manage Jenkins → Plugins → Installed plugins
```

---

## 7. Global Tool Configuration

`Manage Jenkins → Tools` — тут реєструються шляхи до інструментів, якими будуть користуватись усі Job.

| Інструмент | Навіщо реєструвати |
|---|---|
| **Git** | Шлях до `git` executable (зазвичай визначається автоматично) |
| **JDK** | Якщо збираєте Java/Maven-проекти |
| **Docker** | Якщо не використовуєте `sh 'docker ...'` напряму, а плагін Docker Pipeline |

Для нашого сценарію (`sh 'docker build ...'` прямо у Jenkinsfile) додаткова конфігурація Tools **не обов'язкова** — Docker CLI вже вбудований в образ ([jenkins/Dockerfile](./jenkins/Dockerfile)), і Jenkins викликає його як звичайну shell-команду.

Перевірте доступність docker всередині Jenkins:

```bash
docker exec jenkins docker version
```

**Очікуваний вивід (фрагмент):**
```
Client: Docker Engine - Community
 Version:           25.x.x
Server: (через /var/run/docker.sock хоста)
 Engine:
  Version:          25.x.x
```

> Це працює завдяки монтуванню `/var/run/docker.sock` у [docker-compose.yml](./jenkins/docker-compose.yml) — контейнер Jenkins команди `docker` виконує **на хост-машині** (Docker outside of Docker, DooD).

---

## 8. Credentials — керування секретами

Pipeline у Розділі 10 публікує image на Docker Hub — для цього потрібні збережені credentials, а не паролі у відкритому тексті в Jenkinsfile.

### Додавання Docker Hub credentials

```
Manage Jenkins → Credentials → System → Global credentials (unrestricted) → Add Credentials

Kind:        Username with password
Scope:       Global
Username:    <ваш Docker Hub логін>
Password:    <ваш Docker Hub пароль або Access Token>
ID:          dockerhub-credentials     ← саме цей ID використовується у Jenkinsfile
Description: Docker Hub push credentials
```

> 🔒 **Рекомендація:** використовуйте [Docker Hub Access Token](https://hub.docker.com/settings/security) замість основного пароля — його можна відкликати окремо, не змінюючи пароль акаунту.

### Додавання SSH-ключа для деплою (Ansible → EC2)

Якщо Deploy stage підключається до AWS Academy EC2 (Заняття 8.1):

```
Kind:        SSH Username with private key
Scope:       Global
ID:          ec2-ssh-key
Username:    ec2-user
Private Key: вставте вміст vockey.pem
```

### Як credentials виглядають у Jenkinsfile

```groovy
environment {
    DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
    // Jenkins автоматично створює змінні:
    //   DOCKERHUB_CREDENTIALS_USR  — логін
    //   DOCKERHUB_CREDENTIALS_PSW  — пароль
    // Обидві маскуються зірочками (****) у Console Output.
}
```

> Значення credentials **ніколи не з'являються у відкритому вигляді** в логах build — Jenkins автоматично замінює їх на `****`.

---

## 9. Перший Job: Freestyle project

Перш ніж перейти до Pipeline, створимо найпростіший Job через UI — щоб побачити механіку "Job → Build → Console Output".

```
Dashboard → New Item
  Item name:  hello-jenkins
  Type:       Freestyle project → OK

Build Steps → Add build step → Execute shell:
  echo "Hello from Jenkins!"
  date
  whoami

Save → Build Now
```

**Перевірка результату:**

```
Build History → #1 → Console Output
```

**Очікуваний вивід:**
```
Started by user admin
Running as SYSTEM
Building in workspace /var/jenkins_home/workspace/hello-jenkins
[hello-jenkins] $ /bin/sh -xe /tmp/jenkins123456789.sh
+ echo Hello from Jenkins!
Hello from Jenkins!
+ date
Tue Jul 15 10:23:41 UTC 2026
+ whoami
jenkins
Finished: SUCCESS
```

> `Freestyle` зручний для демонстрації механіки Jenkins, але для реального CI/CD переходимо на **Pipeline** — конфігурація як код, версіонована разом з проектом.

---

## 10. Pipeline Job та Jenkinsfile

### Підготовка репозиторію

1. Створіть публічний (або приватний з підключеними credentials) GitHub-репозиторій з вашим проектом — можна форкнути/скопіювати `Lesson7_1/app` та `Lesson8_1/ansible`.
2. Скопіюйте [jenkins/Jenkinsfile](./jenkins/Jenkinsfile) у **корінь репозиторію** під назвою `Jenkinsfile`.
3. Відредагуйте `IMAGE_NAME` під ваш Docker Hub username.

### Розбір Jenkinsfile по stages

Повний файл: [jenkins/Jenkinsfile](./jenkins/Jenkinsfile)

```groovy
pipeline {
    agent any                                    // виконувати на будь-якому доступному агенті

    environment {
        IMAGE_NAME = 'rossogamata/devops-landing'
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
    }

    stages {
        stage('Checkout') { steps { checkout scm } }       // git clone репозиторію

        stage('Build') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} -t ${IMAGE_NAME}:latest Lesson7_1/app"
            }
        }

        stage('Test') {
            steps {
                // smoke test: контейнер стартує і віддає 200 на "/"
                sh "docker run -d --name smoke-test-${BUILD_NUMBER} -p 8081:80 ${IMAGE_NAME}:${BUILD_NUMBER}"
                sh "curl -sf http://localhost:8081/ > /dev/null"
                sh "docker rm -f smoke-test-${BUILD_NUMBER}"
            }
        }

        stage('Push') {
            steps {
                sh 'echo "$DOCKERHUB_CREDENTIALS_PSW" | docker login -u "$DOCKERHUB_CREDENTIALS_USR" --password-stdin'
                sh "docker push ${IMAGE_NAME}:${BUILD_NUMBER}"
                sh "docker push ${IMAGE_NAME}:latest"
            }
        }

        stage('Deploy') {
            when { branch 'main' }                          // деплой лише з main
            steps {
                sh "ansible-playbook -i Lesson8_1/ansible/inventory/hosts.ini Lesson8_1/ansible/playbook.yml"
            }
        }
    }

    post {
        always  { sh 'docker logout || true' }
        success { echo "Build #${BUILD_NUMBER} succeeded ✅" }
        failure { echo "Build #${BUILD_NUMBER} failed ❌" }
    }
}
```

**Графічно (`BUILD_NUMBER` = номер конкретного build):**

```
Checkout → Build → Test → Push → Deploy
   git       docker    curl   docker    ansible-
   clone     build     /health push     playbook
                                         (тільки main)
```

### Створення Pipeline Job у Jenkins

```
Dashboard → New Item
  Item name: devops-landing-pipeline
  Type:      Pipeline → OK

Pipeline section:
  Definition:        Pipeline script from SCM
  SCM:                Git
  Repository URL:     https://github.com/<ваш_логін>/<репозиторій>.git
  Credentials:        (якщо приватний репо — оберіть/додайте)
  Branch Specifier:   */main
  Script Path:        Jenkinsfile     ← за замовчуванням, у корені репо

Save → Build Now
```

### Запуск і перегляд

```
Dashboard → devops-landing-pipeline → Build Now
  → з'явиться #1 у Build History
  → клік на #1 → Console Output  (текстовий лог)
  → або (з Blue Ocean) → наочний граф stages з часом виконання кожного
```

---

## 11. Webhook — автоматичний запуск з GitHub

Щоб pipeline запускався **автоматично** при кожному `git push`, а не вручну через "Build Now":

### У Jenkins

```
Job → Configure → Build Triggers
  ☑ GitHub hook trigger for GITScm polling
Save
```

### У GitHub

```
Репозиторій → Settings → Webhooks → Add webhook

Payload URL:   http://<PUBLIC_IP_або_домен_Jenkins>:8080/github-webhook/
Content type:  application/json
Events:        Just the push event
Active:        ☑
```

> ⚠️ **Локальний Jenkins (localhost) недоступний із GitHub напряму.** Для навчальної демонстрації є два варіанти:
> 1. Розгорнути Jenkins на публічній EC2 (Заняття 7.1/8.1 інфраструктура) з відкритим портом 8080.
> 2. Використати тунель (напр. `ngrok http 8080`) для тимчасового публічного URL під час заняття.

**Перевірка webhook:**
```
GitHub → Settings → Webhooks → ваш webhook → Recent Deliveries
  → останній запит має статус 200 (зелена галочка)
```

Після налаштування: `git push` → GitHub надсилає webhook → Jenkins автоматично запускає новий build.

---

## 12. Перевірка результатів збірки

```bash
# Список останніх build через Jenkins CLI (опційно) або перевірте у UI:
# Job → Build History
```

### Console Output — що шукати

```
Started by GitHub push by <username>
Checking out Revision abc1234 (refs/remotes/origin/main)
+ docker build -t rossogamata/devops-landing:5 -t rossogamata/devops-landing:latest Lesson7_1/app
Successfully built 9f8e7d6c5b4a
+ docker push rossogamata/devops-landing:5
5: digest: sha256:... size: 1234
Finished: SUCCESS
```

### Типові причини Failure та де дивитись

| Симптом у Console Output | Ймовірна причина |
|---|---|
| `permission denied ... docker.sock` | Контейнер Jenkins не має доступу до `/var/run/docker.sock` — перевірте `user: root` у docker-compose.yml |
| `unauthorized: incorrect username or password` | Невірні/відкликані Docker Hub credentials |
| `curl: (7) Failed to connect` на Test stage | Контейнер застосунку не встиг стартувати — збільшіть `sleep` |
| `Host key verification failed` на Deploy stage | Не додано SSH-credentials або не налаштовано `known_hosts` |

### Docker образи, зібрані Jenkins

```bash
docker exec jenkins docker images | grep devops-landing
```

---

## 13. Зупинка та знищення середовища

```bash
cd Lesson13_1/jenkins

# Зупинити контейнер, зберігши jenkins_home (конфігурацію, Job, історію)
docker compose down

# Повне знищення разом з jenkins_home (ОБОВ'ЯЗКОВО в кінці заняття,
# якщо не плануєте продовжувати з тим самим станом Jenkins)
docker compose down -v
```

---

## 14. Завдання для самопідготовки

> Виконується самостійно після заняття.

**Завдання:** розширити pipeline з Розділу 10 повідомленнями про статус build.

1. Додайте у `post { }` блок надсилання email або повідомлення (можна замінити на `echo` з детальнішим текстом, якщо немає доступу до SMTP/Slack):

```groovy
post {
    success {
        echo "✅ Build #${BUILD_NUMBER}: ${IMAGE_NAME}:${BUILD_NUMBER} опубліковано"
    }
    failure {
        echo "❌ Build #${BUILD_NUMBER} провалився — перевірте stage: ${env.STAGE_NAME}"
    }
}
```

2. Додайте новий stage **"Lint"** перед `Build`, що перевіряє наявність `Dockerfile`:

```groovy
stage('Lint') {
    steps {
        sh 'test -f Lesson7_1/app/Dockerfile && echo "Dockerfile OK"'
    }
}
```

3. За додаткові бали: підключіть **Blue Ocean** і зробіть скріншот наочного графа pipeline з усіма stages.

### Що здати

- Скріншот `Console Output` успішного build (`Finished: SUCCESS`)
- Скріншот Docker Hub репозиторію з опублікованим тегом `${BUILD_NUMBER}`
- Скріншот webhook delivery (GitHub → Settings → Webhooks → Recent Deliveries) або пояснення, чому webhook не тестувався
- *(за додаткові бали)* скріншот Blue Ocean pipeline view

---

## 15. Підсумок заняття

```
GitHub repo                    Jenkins Controller              Docker Hub / EC2
────────────                   ──────────────────              ────────────────
1. git push          ──────▶  2. webhook запускає build
   (Jenkinsfile у репо)          Checkout → Build → Test
                                       │
                                       ▼
                                 3. Push image     ──────────▶  Docker Hub
                                       │
                                       ▼
                                 4. Deploy (Ansible) ─────────▶  AWS EC2
```

| Крок | Дія |
|---|---|
| Встановити Jenkins | `docker compose up -d --build` |
| Отримати пароль | `docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword` |
| Встановити плагіни | Manage Jenkins → Plugins → Docker Pipeline, Blue Ocean |
| Додати секрети | Manage Jenkins → Credentials → `dockerhub-credentials` |
| Створити Pipeline Job | New Item → Pipeline → Pipeline script from SCM |
| Автозапуск | GitHub → Webhooks → `/github-webhook/` |
| Перевірити | Build History → Console Output |
| Знищити | `docker compose down -v` |

---

*Методології автоматизованого розгортання ІТ інфраструктури · 5 курс · AWS Academy*
*ВІДКРИТА ІНФОРМАЦІЯ*
