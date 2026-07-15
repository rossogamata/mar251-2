#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  AWS Academy — Заняття 13.1 / Lesson 13.1 — Self-Assessment      ║
# ║  CI/CD Recap · Jenkins Concepts · Jenkins Configuration          ║
# ╚══════════════════════════════════════════════════════════════════╝

RED='\033[0;31m';  GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m';  MAGENTA='\033[0;35m'
WHITE='\033[1;37m'; BOLD='\033[1m';    DIM='\033[2m'; NC='\033[0m'

Q_OK=0; Q_TOT=0
declare -a WRONG_TOPICS

ok()   { echo -e "  ${GREEN}✅  $1${NC}"; }
fail() { echo -e "  ${RED}❌  $1${NC}"; }
hint() { echo -e "  ${DIM}     💡 $1${NC}"; }

banner() {
  local w=64
  echo ""
  echo -e "${BOLD}${BLUE}╔$(printf '═%.0s' $(seq 1 $w))╗${NC}"
  printf "${BOLD}${BLUE}║${NC}  %-${w}s${BOLD}${BLUE}║${NC}\n" "$1"
  echo -e "${BOLD}${BLUE}╚$(printf '═%.0s' $(seq 1 $w))╝${NC}"
}

section() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}  $1${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

pause() {
  echo ""
  read -rp "$(echo -e "  ${MAGENTA}▶  Press Enter / Натисніть Enter...${NC}")" _
}

# ── Multiple choice ──────────────────────────────────────────────────
mcq() {
  local q="$1" correct="$2" hint_txt="$3" topic="$4"; shift 4
  local opts=("$@")

  echo ""; echo -e "${BOLD}${YELLOW}❓  ${q}${NC}"; echo ""
  for i in "${!opts[@]}"; do
    echo -e "    ${BOLD}$((i+1)))${NC}  ${opts[$i]}"
  done
  echo ""
  read -rp "$(echo -e "  ${BOLD}Answer / Відповідь (1-${#opts[@]}): ${NC}")" ans

  Q_TOT=$((Q_TOT+1))
  if [[ "$ans" == "$correct" ]]; then
    ok "Correct / Правильно! 🎉"
    Q_OK=$((Q_OK+1))
    return 0
  else
    fail "Wrong. Correct: ${BOLD}${correct}) ${opts[$((correct-1))]}${NC}"
    hint "$hint_txt"
    WRONG_TOPICS+=("$topic")
    return 1
  fi
}

# ── True/False ───────────────────────────────────────────────────────
tf_question() {
  local statement="$1" correct="$2" hint_txt="$3" topic="$4"

  echo ""; echo -e "${BOLD}${YELLOW}❓  Правда чи хибно? / True or False?${NC}"
  echo ""
  echo -e "    ${BOLD}\"${statement}\"${NC}"
  echo ""
  echo -e "    ${BOLD}1)${NC}  ✅ Правда / True"
  echo -e "    ${BOLD}2)${NC}  ❌ Хибно / False"
  echo ""
  read -rp "$(echo -e "  ${BOLD}Answer / Відповідь (1/2): ${NC}")" ans

  Q_TOT=$((Q_TOT+1))
  if [[ "$ans" == "$correct" ]]; then
    ok "Correct / Правильно! 🎉"
    Q_OK=$((Q_OK+1))
  else
    local expected_str
    [[ "$correct" == "1" ]] && expected_str="Правда / True" || expected_str="Хибно / False"
    fail "Wrong. Correct: ${BOLD}${expected_str}${NC}"
    hint "$hint_txt"
    WRONG_TOPICS+=("$topic")
  fi
}

# ── Fill in the blank ────────────────────────────────────────────────
fill_blank() {
  local q="$1" correct="$2" hint_txt="$3" topic="$4"
  local accept_list=("${@:5}")

  echo ""; echo -e "${BOLD}${YELLOW}❓  Заповніть пропуск / Fill in the blank:${NC}"
  echo ""
  echo -e "    ${BOLD}${q}${NC}"
  echo ""
  read -rp "$(echo -e "  ${BOLD}Answer / Відповідь: ${NC}")" ans

  local ans_lower; ans_lower=$(echo "$ans" | tr '[:upper:]' '[:lower:]' | xargs)
  Q_TOT=$((Q_TOT+1))

  local matched=false
  for accepted in "$correct" "${accept_list[@]}"; do
    local acc_lower; acc_lower=$(echo "$accepted" | tr '[:upper:]' '[:lower:]' | xargs)
    if [[ "$ans_lower" == "$acc_lower" ]]; then matched=true; break; fi
  done

  if $matched; then
    ok "Correct / Правильно! 🎉"
    Q_OK=$((Q_OK+1))
  else
    fail "Wrong. Correct: ${BOLD}${correct}${NC}"
    hint "$hint_txt"
    WRONG_TOPICS+=("$topic")
  fi
}

# ══════════════════════════════════════════════════════════════════════
clear; echo ""
echo -e "${BOLD}${MAGENTA}"
cat << 'BANNER'
  ╔══════════════════════════════════════════════════════════════════╗
  ║   AWS ACADEMY  ·  ЗАНЯТТЯ 13.1 / LESSON 13.1                    ║
  ║   САМОПЕРЕВІРКА / SELF-ASSESSMENT                                ║
  ║   CI/CD Recap  ·  Jenkins Concepts  ·  Jenkins Configuration    ║
  ╚══════════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"
echo -e "  ${CYAN}Структура / Structure:${NC}"
echo -e "  ${DIM}  Частина A: Повторення CI/CD    (6 питань / questions)${NC}"
echo -e "  ${DIM}  Частина B: Поняття Jenkins      (8 питань / questions)${NC}"
echo -e "  ${DIM}  Частина C: Конфігурація Jenkins (8 питань / questions)${NC}"
echo -e "  ${DIM}  Разом / Total: 22 питання / questions${NC}"
echo ""
read -rp "  Full name / Ім'я та прізвище: " STUDENT
echo -e "\n  ${GREEN}Привіт / Hello, ${BOLD}${STUDENT}${NC}${GREEN}! Починаємо / Let's start! 🚀${NC}"
pause

# ══════════════════════════════════════════════════════════════════════
#   ЧАСТИНА A — ПОВТОРЕННЯ CI/CD / PART A — CI/CD RECAP  (Q1–Q6)
# ══════════════════════════════════════════════════════════════════════

banner "ЧАСТИНА A / PART A — CI/CD Recap  (Q1–Q6)"

section "Q1 / З1 of 22 — Continuous Integration"
mcq \
  "Що таке Continuous Integration (CI)? / What is Continuous Integration (CI)?" \
  "3" \
  "CI: developers merge code changes into a shared branch frequently (multiple times a day); each merge automatically triggers a build and test run to catch integration issues early. / CI: розробники часто зливають зміни у спільну гілку; кожне злиття автоматично запускає build і тести для раннього виявлення проблем." \
  "CI/CD" \
  "Ручне тестування коду раз на тиждень / Manual code testing once a week" \
  "Розгортання коду напряму у продакшн без перевірок / Deploying code straight to production without checks" \
  "Часте автоматичне зливання коду з автоматичною збіркою та тестами / Frequent automatic merging with automated build and tests" \
  "Зберігання коду у кількох репозиторіях одночасно / Storing code in multiple repositories simultaneously"

pause

section "Q2 / З2 of 22 — Continuous Delivery vs Deployment"
mcq \
  "Чим Continuous Delivery відрізняється від Continuous Deployment? / How does Continuous Delivery differ from Continuous Deployment?" \
  "2" \
  "Continuous Delivery: every change is automatically built, tested, and made ready for release, but a human decides WHEN to actually release to production (manual approval gate). Continuous Deployment: releases to production automatically, no manual gate at all. / Continuous Delivery: зміна автоматично готова до релізу, але людина вирішує КОЛИ реально випускати. Continuous Deployment: реліз у продакшн повністю автоматичний, без ручного затвердження." \
  "CI/CD" \
  "Це синоніми, різниці немає / They are synonyms, no difference" \
  "Delivery потребує ручного затвердження релізу; Deployment випускає у продакшн повністю автоматично / Delivery needs manual release approval; Deployment goes to production fully automatically" \
  "Delivery — тільки для мобільних застосунків, Deployment — тільки для вебу / Delivery is mobile-only, Deployment is web-only" \
  "Deployment працює лише з Docker, Delivery — лише з VM / Deployment only works with Docker, Delivery only with VMs"

pause

section "Q3 / З3 of 22 — Навіщо автоматичні тести у pipeline"
mcq \
  "Навіщо у CI/CD pipeline розміщують автоматичні тести ще ДО деплою? / Why place automated tests in the pipeline BEFORE deployment?" \
  "1" \
  "'Fail fast' principle: catching a broken build at the Test stage (minutes) is far cheaper than discovering it in production (hours of downtime, angry users, rollback). Automated tests are the gatekeeper before Deploy. / Принцип 'fail fast': виявити поламану збірку на етапі Test (хвилини) значно дешевше, ніж у продакшн (простій, невдоволені користувачі, rollback)." \
  "CI/CD" \
  "Щоб виявити помилки якомога раніше і не пропустити їх у продакшн (fail fast) / To catch errors as early as possible and keep them out of production (fail fast)" \
  "Тести потрібні лише для звітності керівництву / Tests exist only for management reporting" \
  "Тести пришвидшують сам процес збірки / Tests speed up the build process itself" \
  "Тести замінюють потребу у code review / Tests replace the need for code review"

pause

section "Q4 / З4 of 22 — Artifact"
mcq \
  "Що таке 'artifact' у контексті CI/CD pipeline? / What is an 'artifact' in a CI/CD pipeline?" \
  "4" \
  "An artifact is a build OUTPUT — a packaged, deployable result: a compiled binary, a .jar/.zip, or (in our course) a Docker image. Artifacts are typically stored in a registry (Docker Hub, Nexus, Artifactory) and are what actually gets deployed, not the source code itself. / Artifact — це РЕЗУЛЬТАТ збірки: скомпільований бінарник, jar/zip, або (у нашому курсі) Docker image. Зберігається у реєстрі (Docker Hub, Nexus) і саме він розгортається, а не вихідний код." \
  "CI/CD" \
  "Гілка у Git з нестабільним кодом / A Git branch with unstable code" \
  "Лог помилок після невдалого build / An error log after a failed build" \
  "Файл конфігурації Jenkins / A Jenkins configuration file" \
  "Результат збірки (напр. Docker image), що зберігається у реєстрі та розгортається / A build output (e.g. Docker image) stored in a registry and deployed"

pause

section "Q5 / З5 of 22 — Принцип CI"
tf_question \
  "Continuous Integration означає, що розробники зливають зміни у спільну гілку рідко — раз на кілька тижнів, щоб уникнути конфліктів. / Continuous Integration means developers merge changes into the shared branch rarely — once every few weeks — to avoid conflicts." \
  "2" \
  "FALSE. CI is the opposite: FREQUENT integration (multiple times per day) is the whole point — it keeps merge conflicts small and catches integration bugs immediately, rather than accumulating large risky merges. / ХИБНО. CI — це навпаки: ЧАСТА інтеграція (кілька разів на день) — саме в цьому суть: конфлікти маленькі, а помилки інтеграції виявляються одразу, а не накопичуються у великих ризикованих злиттях." \
  "CI/CD"

pause

section "Q6 / З6 of 22 — Build Agent / Runner"
mcq \
  "Яку роль виконує 'build agent' (runner) у CI/CD системі? / What role does a 'build agent' (runner) play in a CI/CD system?" \
  "3" \
  "A build agent is the machine (physical, VM, or container) that ACTUALLY executes the pipeline steps: checkout, compile, test, package. The CI/CD server (e.g. Jenkins Controller) schedules and coordinates work but delegates the real execution to agents — this is what lets pipelines scale across many parallel jobs. / Build agent — це машина (фізична, VM або контейнер), яка ФАКТИЧНО виконує кроки pipeline: checkout, компіляція, тести, пакування. CI/CD сервер лише планує й координує роботу, а виконання делегує агентам — це дає масштабованість." \
  "CI/CD" \
  "Зберігає історію коммітів у Git / Stores commit history in Git" \
  "Генерує документацію проекту / Generates project documentation" \
  "Виконує фактичні кроки pipeline (checkout, build, test) за дорученням CI/CD сервера / Executes the actual pipeline steps on behalf of the CI/CD server" \
  "Замінює потребу у Docker registry / Replaces the need for a Docker registry"

pause

# ══════════════════════════════════════════════════════════════════════
#   ЧАСТИНА B — ПОНЯТТЯ JENKINS / PART B — JENKINS CONCEPTS  (Q7–Q14)
# ══════════════════════════════════════════════════════════════════════

banner "ЧАСТИНА B / PART B — Jenkins Concepts  (Q7–Q14)"

section "Q7 / З7 of 22 — Що таке Jenkins"
mcq \
  "Що таке Jenkins? / What is Jenkins?" \
  "2" \
  "Jenkins is an open-source, self-hosted automation server used to build CI/CD pipelines: it can checkout code, build, test, package, and deploy automatically on every code change, coordinated via a web UI and 1800+ plugins. / Jenkins — це відкритий, self-hosted сервер автоматизації для побудови CI/CD pipeline: checkout, build, test, package, deploy автоматично при кожній зміні коду, з веб-інтерфейсом і 1800+ плагінами." \
  "Jenkins" \
  "Хмарний реєстр Docker-образів / A cloud Docker image registry" \
  "Відкритий self-hosted сервер автоматизації для CI/CD pipeline / An open-source self-hosted automation server for CI/CD pipelines" \
  "Мова програмування для написання pipeline / A programming language for writing pipelines" \
  "Плагін для GitHub, що замінює Git / A GitHub plugin that replaces Git"

pause

section "Q8 / З8 of 22 — Controller vs Agent"
mcq \
  "Яка різниця між Jenkins Controller (Master) та Agent (Node)? / What is the difference between Jenkins Controller (Master) and Agent (Node)?" \
  "1" \
  "Controller: coordinates everything — Web UI, scheduling, storing job configs and build history. Agent: a separate machine/container that actually EXECUTES the build steps. Small setups can run everything on the Controller alone (agent any without dedicated nodes), but production setups distribute work across many agents. / Controller: координує все — UI, планування, зберігання конфігурацій та історії. Agent: окрема машина/контейнер, яка ВИКОНУЄ кроки build. У невеликих конфігураціях все виконується на Controller, у продакшн — розподілено по агентах." \
  "Jenkins" \
  "Controller координує та зберігає стан; Agent фактично виконує build / Controller coordinates and stores state; Agent actually executes builds" \
  "Controller і Agent — це синоніми одного компонента / Controller and Agent are synonyms for the same component" \
  "Agent зберігає jenkins_home, Controller лише виконує build / Agent stores jenkins_home, Controller only executes builds" \
  "Controller працює тільки на Windows, Agent — тільки на Linux / Controller only runs on Windows, Agent only on Linux"

pause

section "Q9 / З9 of 22 — Executor"
mcq \
  "Що таке 'executor' в Jenkins? / What is an 'executor' in Jenkins?" \
  "3" \
  "An executor is a slot on an agent (or the controller) capable of running ONE build at a time. If an agent has 4 executors, it can run 4 builds concurrently. This is the mechanism behind Jenkins' parallel build capacity. / Executor — це слот на агенті (або controller), здатний виконувати ОДИН build одночасно. Якщо в агента 4 executors — можуть виконуватись 4 build паралельно." \
  "Jenkins" \
  "Плагін для виконання shell-скриптів / A plugin for running shell scripts" \
  "Файл конфігурації credentials / A credentials configuration file" \
  "Слот для паралельного виконання одного build на агенті / A slot for running one build concurrently on an agent" \
  "Утиліта для видалення старих build з історії / A utility for deleting old builds from history"

pause

section "Q10 / З10 of 22 — Job vs Build"
mcq \
  "Яка різниця між 'Job' та 'Build' в Jenkins? / What is the difference between a 'Job' and a 'Build' in Jenkins?" \
  "4" \
  "A Job (Project) is the reusable CONFIGURATION — what to checkout, what steps to run. A Build is one specific EXECUTION of that job, with its own number (#1, #2, ...), status, console log, and duration. One Job produces many Builds over time. / Job (Project) — це багаторазова КОНФІГУРАЦІЯ. Build — це один конкретний ЗАПУСК цієї конфігурації, зі своїм номером, статусом та логом. Один Job породжує багато Build з часом." \
  "Jenkins" \
  "Job — це плагін, Build — це агент / Job is a plugin, Build is an agent" \
  "Job виконується автоматично, Build — тільки вручну / Job runs automatically, Build only runs manually" \
  "Це синоніми в Jenkins / They are synonyms in Jenkins" \
  "Job — конфігурація процесу; Build — один конкретний запуск цієї конфігурації / Job is the process configuration; Build is one specific run of it"

pause

section "Q11 / З11 of 22 — Freestyle vs Pipeline"
mcq \
  "Чому Pipeline Job зазвичай кращий вибір за Freestyle project для реального CI/CD? / Why is a Pipeline Job usually preferred over a Freestyle project for real CI/CD?" \
  "2" \
  "Freestyle jobs are configured through the Web UI form-by-form — not version-controlled, hard to review, hard to replicate. Pipeline jobs are defined as CODE (Jenkinsfile) that lives in the Git repo alongside the source — reviewable via PR, versioned, reproducible, supports complex logic (conditionals, parallelism). / Freestyle налаштовується через форми UI — не версіонується, важко рев'ювити. Pipeline описаний як КОД (Jenkinsfile) у Git разом із проектом — рев'юється через PR, версіонується, підтримує складну логіку." \
  "Jenkins" \
  "Freestyle застарів і більше не підтримується Jenkins / Freestyle is deprecated and no longer supported by Jenkins" \
  "Pipeline описаний як код (Jenkinsfile) у Git — версіонується та підтримує складну логіку / Pipeline is described as code (Jenkinsfile) in Git — versioned and supports complex logic" \
  "Freestyle не може запускати shell-команди / Freestyle cannot run shell commands" \
  "Pipeline не потребує встановлення плагінів / Pipeline requires no plugin installation"

pause

section "Q12 / З12 of 22 — Declarative vs Scripted Pipeline"
mcq \
  "Чим Declarative Pipeline відрізняється від Scripted Pipeline? / How does a Declarative Pipeline differ from a Scripted Pipeline?" \
  "1" \
  "Declarative: a structured, opinionated syntax (pipeline { agent {} stages {} }) — easier to read, recommended for most cases, has built-in validation. Scripted: raw Groovy code (node { stage(){} }) — more flexible but harder to read and maintain. Most teams, including ours, use Declarative. / Declarative: структурований синтаксис (pipeline { agent {} stages {} }) — легше читати, рекомендований, має вбудовану валідацію. Scripted: довільний Groovy-код — більше гнучкості, складніше підтримувати." \
  "Jenkins" \
  "Declarative має структурований синтаксис (pipeline{stages{}}) і рекомендований; Scripted — довільний Groovy-код / Declarative has structured syntax and is recommended; Scripted is free-form Groovy code" \
  "Scripted працює лише з Docker, Declarative — лише з Kubernetes / Scripted only works with Docker, Declarative only with Kubernetes" \
  "Це те саме, різні лише назви файлів / They are the same, only file names differ" \
  "Declarative підтримує лише один stage, Scripted — необмежену кількість / Declarative supports only one stage, Scripted unlimited"

pause

section "Q13 / З13 of 22 — Stage vs Step"
mcq \
  "Яка різниця між 'stage' та 'step' у Jenkins Pipeline? / What is the difference between a 'stage' and a 'step' in a Jenkins Pipeline?" \
  "3" \
  "A stage is a logical phase of the pipeline (Build, Test, Deploy) — it is what's visualized as a distinct block in the pipeline graph/Blue Ocean view. A step is one single command/action INSIDE a stage (e.g. sh 'docker build ...'). A stage contains one or more steps. / Stage — логічний етап pipeline (Build, Test, Deploy) — саме він відображається як блок у графі/Blue Ocean. Step — одна конкретна команда ВСЕРЕДИНІ stage. Stage містить один або декілька steps." \
  "Jenkins" \
  "Це синоніми / They are synonyms" \
  "Step — це весь pipeline, stage — лише один build / Step is the whole pipeline, stage is a single build" \
  "Stage — логічний етап (видно у графі), step — одна команда всередині stage / Stage is a logical phase (shown in the graph), step is a single command inside a stage" \
  "Stage використовується лише у Scripted Pipeline / Stage is only used in Scripted Pipeline"

pause

section "Q14 / З14 of 22 — Plugin"
mcq \
  "Яку роль відіграють плагіни (plugins) в Jenkins? / What role do plugins play in Jenkins?" \
  "4" \
  "Jenkins core is intentionally minimal; almost all real functionality (Git integration, Docker steps, GitHub webhooks, Slack notifications, Blue Ocean UI) comes from plugins. This is why Jenkins is so flexible — with 1800+ plugins it can integrate with nearly any tool in a DevOps stack. / Ядро Jenkins навмисно мінімальне; майже весь функціонал (Git, Docker, GitHub webhooks, Slack, Blue Ocean) додається через плагіни. Саме тому Jenkins такий гнучкий — 1800+ плагінів дозволяють інтегруватись майже з будь-яким інструментом." \
  "Jenkins" \
  "Плагіни потрібні лише для оформлення теми Web UI / Plugins are only for Web UI theming" \
  "Плагіни замінюють потребу у Jenkinsfile / Plugins replace the need for a Jenkinsfile" \
  "Плагін можна встановити лише під час першого запуску / A plugin can only be installed during the first setup" \
  "Плагіни розширюють функціонал Jenkins (Git, Docker, webhooks, UI) — ядро само по собі мінімальне / Plugins extend Jenkins functionality (Git, Docker, webhooks, UI) — the core itself is minimal"

pause

# ══════════════════════════════════════════════════════════════════════
#   ЧАСТИНА C — КОНФІГУРАЦІЯ JENKINS / PART C — CONFIGURATION  (Q15–Q22)
# ══════════════════════════════════════════════════════════════════════

banner "ЧАСТИНА C / PART C — Jenkins Configuration  (Q15–Q22)"

section "Q15 / З15 of 22 — initialAdminPassword"
mcq \
  "Де знаходиться тимчасовий пароль адміністратора після першого запуску Jenkins? / Where is the temporary admin password found after Jenkins' first start?" \
  "3" \
  "On first start, Jenkins generates a random password and writes it to a file inside jenkins_home: /var/jenkins_home/secrets/initialAdminPassword. It's also printed to the container/service logs. This is a one-time password used only to get through the Setup Wizard. / При першому старті Jenkins генерує випадковий пароль у файл /var/jenkins_home/secrets/initialAdminPassword (також виводиться у логи). Це одноразовий пароль лише для проходження Setup Wizard." \
  "Configuration" \
  "У змінній середовища JENKINS_PASSWORD / In the JENKINS_PASSWORD environment variable" \
  "У файлі docker-compose.yml / In the docker-compose.yml file" \
  "У /var/jenkins_home/secrets/initialAdminPassword (і в логах контейнера) / In /var/jenkins_home/secrets/initialAdminPassword (and container logs)" \
  "У Credentials Manager під ID 'admin' / In Credentials Manager under ID 'admin'"

pause

section "Q16 / З16 of 22 — Suggested Plugins"
tf_question \
  "'Install suggested plugins' у Setup Wizard автоматично встановлює базовий набір плагінів (Git, Pipeline, Credentials Binding), і додаткові плагіни (напр. Docker Pipeline) все одно можна встановити пізніше через Manage Jenkins → Plugins. / 'Install suggested plugins' in the Setup Wizard auto-installs a base set (Git, Pipeline, Credentials Binding), and additional plugins (e.g. Docker Pipeline) can still be installed later via Manage Jenkins → Plugins." \
  "1" \
  "TRUE. Suggested plugins cover the common baseline. Anything project-specific (Docker Pipeline, Blue Ocean, Slack Notification, etc.) is added afterward from Manage Jenkins → Plugins → Available plugins, exactly as we did in Section 6. / ПРАВДА. Suggested plugins покривають базовий набір. Усе специфічне для проекту (Docker Pipeline, Blue Ocean тощо) додається пізніше через Manage Jenkins → Plugins → Available plugins." \
  "Configuration"

pause

section "Q17 / З17 of 22 — credentials() binding"
mcq \
  "Що робить вираз 'credentials(\"dockerhub-credentials\")' у блоці environment Jenkinsfile? / What does 'credentials(\"dockerhub-credentials\")' do in a Jenkinsfile environment block?" \
  "2" \
  "It looks up the stored credential by its ID ('dockerhub-credentials') in Jenkins Credentials Manager and injects it into the pipeline as environment variables — for a username/password credential, it creates both DOCKERHUB_CREDENTIALS_USR and DOCKERHUB_CREDENTIALS_PSW, both automatically masked as **** in Console Output. / Виражння шукає збережений credential за ID у Credentials Manager і підставляє його у змінні DOCKERHUB_CREDENTIALS_USR / _PSW, які автоматично маскуються як **** у Console Output." \
  "Configuration" \
  "Створює новий Docker Hub акаунт автоматично / Automatically creates a new Docker Hub account" \
  "Підставляє збережений секрет у змінні USR/PSW, замасковані у логах / Injects the stored secret into USR/PSW variables, masked in logs" \
  "Видаляє credential з Jenkins після використання / Deletes the credential from Jenkins after use" \
  "Шифрує весь Jenkinsfile перед виконанням / Encrypts the entire Jenkinsfile before execution"

pause

section "Q18 / З18 of 22 — Docker socket mount (DooD)"
mcq \
  "Навіщо у docker-compose.yml для Jenkins монтується /var/run/docker.sock у контейнер? / Why is /var/run/docker.sock mounted into the Jenkins container in docker-compose.yml?" \
  "4" \
  "This 'Docker outside of Docker' (DooD) pattern lets the Jenkins container's docker CLI talk to the HOST's Docker daemon through the socket, so pipeline steps like 'docker build'/'docker push' actually create real images on the host — without needing a nested Docker daemon inside the Jenkins container itself. / Патерн 'Docker outside of Docker' (DooD): docker CLI всередині контейнера Jenkins звертається до Docker daemon ХОСТА через сокет, тому 'docker build'/'docker push' реально створюють образи на хості, без вкладеного daemon всередині контейнера." \
  "Configuration" \
  "Це потрібно лише для перегляду логів контейнера / It's only needed to view container logs" \
  "Це прискорює запуск Web UI Jenkins / It speeds up the Jenkins Web UI startup" \
  "Це необхідно для роботи Blue Ocean плагіна / It's required for the Blue Ocean plugin to work" \
  "Дозволяє docker-командам у pipeline звертатись до Docker daemon хоста (DooD) / Lets docker commands in the pipeline reach the host's Docker daemon (DooD)"

pause

section "Q19 / З19 of 22 — GitHub Webhook"
mcq \
  "Яку проблему вирішує GitHub webhook, налаштований на '/github-webhook/'? / What problem does a GitHub webhook configured on '/github-webhook/' solve?" \
  "3" \
  "Without a webhook, someone has to manually click 'Build Now' after every push, or Jenkins has to poll the repo on a schedule (wasteful, delayed). A webhook makes GitHub notify Jenkins the INSTANT a push happens, triggering an automatic build with near-zero delay. / Без webhook хтось має вручну натискати 'Build Now', або Jenkins опитує репозиторій за розкладом (марно, із затримкою). Webhook змушує GitHub повідомляти Jenkins ОДРАЗУ при push, запускаючи build майже без затримки." \
  "Configuration" \
  "Він шифрує трафік між GitHub та Jenkins / It encrypts traffic between GitHub and Jenkins" \
  "Він створює резервну копію репозиторію в Jenkins / It creates a backup of the repo inside Jenkins" \
  "Він автоматично запускає build одразу після push, без ручного 'Build Now' або опитування / It automatically triggers a build right after push, without manual 'Build Now' or polling" \
  "Він потрібен лише для приватних репозиторіїв / It's only needed for private repositories"

pause

section "Q20 / З20 of 22 — Global Tool Configuration"
mcq \
  "Для чого призначений розділ 'Manage Jenkins → Tools' (Global Tool Configuration)? / What is 'Manage Jenkins → Tools' (Global Tool Configuration) for?" \
  "1" \
  "It registers the location/version of build tools (JDK, Maven, Git, NodeJS, Docker) that ALL jobs can reference by name, instead of each Jenkinsfile hardcoding a filesystem path. If a pipeline just calls raw shell commands (like our 'sh docker build ...') that tool is already on PATH, explicit Tool Configuration for it isn't required. / Реєструє шляхи/версії інструментів (JDK, Maven, Git, Docker), доступні всім Job за назвою, без хардкоду шляху у кожному Jenkinsfile. Якщо pipeline просто викликає shell-команду, яка вже в PATH — окрема реєстрація не обов'язкова." \
  "Configuration" \
  "Реєструє шляхи/версії build-інструментів, спільні для всіх Job / Registers paths/versions of build tools, shared by all jobs" \
  "Керує обліковими записами користувачів Jenkins / Manages Jenkins user accounts" \
  "Налаштовує SMTP-сервер для email-сповіщень / Configures the SMTP server for email notifications" \
  "Створює резервні копії jenkins_home за розкладом / Schedules backups of jenkins_home"

pause

section "Q21 / З21 of 22 — Script Path"
fill_blank \
  "У налаштуваннях Pipeline Job з джерелом 'Pipeline script from SCM' поле '________ ________' вказує шлях до Jenkinsfile у репозиторії (за замовчуванням просто 'Jenkinsfile' у корені). / In a Pipeline Job configured with 'Pipeline script from SCM', the '________ ________' field specifies the path to the Jenkinsfile in the repo (default: just 'Jenkinsfile' at the root)." \
  "Script Path" \
  "The 'Script Path' field tells Jenkins where to find the Jenkinsfile once it has checked out the repository — useful when the Jenkinsfile isn't at the repo root (e.g. 'ci/Jenkinsfile'). / Поле 'Script Path' вказує Jenkins де шукати Jenkinsfile після checkout репозиторію — корисно, якщо Jenkinsfile не в корені (напр. 'ci/Jenkinsfile')." \
  "Configuration" \
  "ScriptPath" "script path"

pause

section "Q22 / З22 of 22 — Troubleshooting: permission denied on docker.sock"
mcq \
  "У Console Output з'явилась помилка 'permission denied while trying to connect to the Docker daemon socket'. Найімовірніша причина? / Console Output shows 'permission denied while trying to connect to the Docker daemon socket'. Most likely cause?" \
  "2" \
  "The jenkins user inside the container doesn't have permission to access the mounted /var/run/docker.sock (owned by root/docker group on the host). Fix: run the container as root (as in our docker-compose.yml 'user: root'), or add the jenkins user to a matching docker GID. / Користувач jenkins всередині контейнера не має прав на змонтований /var/run/docker.sock (належить root/docker group на хості). Рішення: запускати контейнер як root ('user: root' у docker-compose.yml) або додати jenkins у групу docker з відповідним GID." \
  "Configuration" \
  "GitHub webhook налаштовано неправильно / GitHub webhook is misconfigured" \
  "Контейнер Jenkins не має прав доступу до /var/run/docker.sock — потрібен root або відповідна група docker / The Jenkins container lacks permission on /var/run/docker.sock — needs root or the matching docker group" \
  "Docker Hub credentials невірні / Docker Hub credentials are incorrect" \
  "Плагін Docker Pipeline не встановлений / The Docker Pipeline plugin isn't installed"

pause

# ══════════════════════════════════════════════════════════════════════
#   ФІНАЛЬНИЙ РЕЗУЛЬТАТ / FINAL RESULTS
# ══════════════════════════════════════════════════════════════════════

clear
banner "🏁  FINAL RESULTS / ФІНАЛЬНІ РЕЗУЛЬТАТИ"
echo ""

PCT=$((Q_OK * 100 / Q_TOT))

echo -e "  ${BOLD}Student / Курсант:${NC}  ${STUDENT}"
echo -e "  ${BOLD}Date / Дата:${NC}        $(date '+%d.%m.%Y %H:%M')"
echo ""

# Score bar
BAR_FILLED=$((Q_OK * 30 / Q_TOT))
BAR_EMPTY=$((30 - BAR_FILLED))
BAR="${GREEN}$(printf '█%.0s' $(seq 1 $BAR_FILLED))${NC}${DIM}$(printf '░%.0s' $(seq 1 $BAR_EMPTY))${NC}"

echo -e "  ┌──────────────────────────────────────────────────────────┐"
echo -e "  │  Правильно / Correct:  ${BOLD}${Q_OK} / ${Q_TOT}${NC}  (${PCT}%)                    │"
echo -e "  │  [${BAR}]  │"
echo -e "  └──────────────────────────────────────────────────────────┘"
echo ""

if   [[ $PCT -ge 88 ]]; then GRADE="Відмінно / Excellent 🏆";         COL=$GREEN
elif [[ $PCT -ge 72 ]]; then GRADE="Добре / Good 🥈";                  COL=$CYAN
elif [[ $PCT -ge 56 ]]; then GRADE="Задовільно / Satisfactory 🥉";     COL=$YELLOW
else                          GRADE="Потребує доопрацювання / Needs work 📖"; COL=$RED; fi

echo -e "  ${BOLD}${COL}${GRADE}${NC}  (${PCT}%)"
echo ""

# Topic recommendations
if [[ ${#WRONG_TOPICS[@]} -gt 0 ]]; then
  echo -e "  ${BOLD}${YELLOW}📌 Теми для повторення / Topics to review:${NC}"

  declare -A TOPIC_COUNTS
  for t in "${WRONG_TOPICS[@]}"; do
    TOPIC_COUNTS["$t"]=$((${TOPIC_COUNTS["$t"]:-0}+1))
  done

  for topic in "${!TOPIC_COUNTS[@]}"; do
    count=${TOPIC_COUNTS[$topic]}
    echo -e "  ${DIM}   • ${topic}: ${count} помилок / mistake(s)${NC}"
  done
  echo ""
fi

# Knowledge map
echo -e "  ${BOLD}${CYAN}── Карта знань / Knowledge Map ──────────────────────────────────${NC}"
echo ""
echo -e "  ${DIM}CI/CD:${NC}"
echo -e "  ${DIM}  Continuous Integration · Delivery vs Deployment · Fail Fast · Artifact · Build Agent${NC}"
echo ""
echo -e "  ${DIM}Jenkins Concepts:${NC}"
echo -e "  ${DIM}  Controller/Agent · Executor · Job vs Build · Freestyle vs Pipeline${NC}"
echo -e "  ${DIM}  Declarative vs Scripted · Stage vs Step · Plugin${NC}"
echo ""
echo -e "  ${DIM}Jenkins Configuration:${NC}"
echo -e "  ${DIM}  initialAdminPassword · Suggested Plugins · Credentials Binding${NC}"
echo -e "  ${DIM}  Docker Socket (DooD) · Webhook · Global Tool Config · Script Path${NC}"
echo ""
echo -e "  ${BOLD}${CYAN}── Документація / Documentation ──────────────────────────────────${NC}"
echo -e "  ${DIM}📘 Jenkins:      https://www.jenkins.io/doc/${NC}"
echo -e "  ${DIM}📘 Pipeline:     https://www.jenkins.io/doc/book/pipeline/syntax/${NC}"
echo -e "  ${DIM}📘 Docker image: https://hub.docker.com/r/jenkins/jenkins${NC}"
echo ""

# Save result
RESULT_FILE="lesson13_1_result_$(echo "$STUDENT" | tr ' ' '_')_$(date +%Y%m%d_%H%M).txt"
cat << EOF > "$RESULT_FILE"
AWS Academy — Lesson 13.1 Result / Результат
=============================================
Student / Курсант : $STUDENT
Date / Дата       : $(date '+%d.%m.%Y %H:%M')
Score / Бал       : $Q_OK / $Q_TOT  (${PCT}%)
Grade / Оцінка    : $GRADE

Covered topics / Теми:
  A) CI/CD Recap        (Q1-Q6):   CI, Delivery vs Deployment, Fail Fast, Artifact, Build Agent
  B) Jenkins Concepts    (Q7-Q14):  Controller/Agent, Executor, Job/Build, Freestyle/Pipeline, Declarative/Scripted, Stage/Step, Plugin
  C) Jenkins Config      (Q15-Q22): initialAdminPassword, Plugins, Credentials, Docker Socket, Webhook, Tools, Script Path, Troubleshooting
EOF

ok "Result saved / Результат збережено: ${BOLD}${RESULT_FILE}${NC}"
echo ""
echo -e "${BOLD}${MAGENTA}  Дякуємо! / Thank you!  Слава Україні! 🇺🇦${NC}"
echo ""
