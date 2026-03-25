#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  AWS Academy — Заняття 6 / Lecture 6 — Self-Assessment          ║
# ║  IaC · Terraform · Ansible                                      ║
# ║  Інфраструктура як Код · Terraform · Ansible                    ║
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

subsection() {
  echo ""
  echo -e "  ${BOLD}${WHITE}▶  $1${NC}"
  echo -e "  ${DIM}$(printf '─%.0s' $(seq 1 58))${NC}"
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
  ║   AWS ACADEMY  ·  ЗАНЯТТЯ 6 / LECTURE 6                         ║
  ║   САМОПЕРЕВІРКА / SELF-ASSESSMENT                                ║
  ║   IaC  ·  Terraform  ·  Ansible                                 ║
  ╚══════════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"
echo -e "  ${CYAN}Структура / Structure:${NC}"
echo -e "  ${DIM}  Частина A: IaC концепції     (6 питань / questions)${NC}"
echo -e "  ${DIM}  Частина B: Terraform          (8 питань / questions)${NC}"
echo -e "  ${DIM}  Частина C: Ansible            (7 питань / questions)${NC}"
echo -e "  ${DIM}  Частина D: Порівняння / Match  (4 питання / questions)${NC}"
echo -e "  ${DIM}  Разом / Total: 25 питань / questions${NC}"
echo ""
read -rp "  Full name / Ім'я та прізвище: " STUDENT
echo -e "\n  ${GREEN}Привіт / Hello, ${BOLD}${STUDENT}${NC}${GREEN}! Починаємо / Let's start! 🚀${NC}"
pause

# ══════════════════════════════════════════════════════════════════════
#   ЧАСТИНА A — IaC КОНЦЕПЦІЇ / PART A — IaC CONCEPTS  (Q1–Q6)
# ══════════════════════════════════════════════════════════════════════

banner "ЧАСТИНА A / PART A — IaC Concepts  (Q1–Q6)"

section "Q1 / З1 of 25 — Визначення IaC / IaC Definition"
mcq \
  "Яке найточніше визначення Infrastructure as Code? / Which best defines IaC?" \
  "3" \
  "IaC = managing infrastructure through machine-readable config files stored in version control, not through manual clicks or commands. Benefits: reproducibility, speed, audit trail, disaster recovery from code. / IaC = управління інфраструктурою через файли конфігурації у системі контролю версій. Переваги: відтворюваність, швидкість, аудит, відновлення з коду." \
  "IaC" \
  "Розгортання застосунків через Docker-контейнери / Deploying apps via Docker containers" \
  "Автоматизоване тестування програмного коду / Automated testing of software code" \
  "Управління інфраструктурою через машиночитані файли конфігурації у VCS / Managing infra via machine-readable config files in VCS" \
  "Ручне налаштування серверів з детальною документацією / Manual server config with detailed documentation"

pause

section "Q2 / З2 of 25 — Idempotency / Ідемпотентність"
mcq \
  "Що означає 'ідемпотентність' (idempotency) в контексті IaC? / What does 'idempotency' mean in IaC context?" \
  "2" \
  "Idempotency: applying the same config N times = same result as applying once. If the resource already matches the desired state, nothing changes. Key for safe repeated runs (CI/CD, cron, re-runs after failure). / Ідемпотентність: застосування конфігурації N разів = той самий результат. Якщо стан вже відповідає — нічого не змінюється." \
  "IaC" \
  "Застосування однієї конфігурації N разів завжди дає однаковий результат / Applying same config N times always gives the same result" \
  "Розгортання займає однаковий час незалежно від розміру інфраструктури / Deployment takes equal time regardless of infra size" \
  "Можливість запускати одну конфігурацію паралельно на кількох системах / Ability to run one config in parallel on many systems" \
  "Автоматичне масштабування при збільшенні навантаження / Automatic scaling on load increase"

pause

section "Q3 / З3 of 25 — Декларативний підхід / Declarative Approach"
mcq \
  "Чим декларативний підхід відрізняється від імперативного? / How does declarative differ from imperative?" \
  "1" \
  "Declarative: you describe WHAT state you want (e.g. '2 EC2 running'). Tool calculates HOW to get there. Imperative: you write every step HOW to do it (create if not exists, update if different...). / Декларативний: описуєш ЩО хочеш. Інструмент вирішує ЯК. Імперативний: описуєш ЯК крок за кроком." \
  "IaC" \
  "Декларативний: описуєш ЩО хочеш, інструмент вирішує ЯК / Declarative: describe WHAT you want, tool decides HOW" \
  "Декларативний: описуєш ЯК виконати кожен крок / Declarative: describe HOW to perform each step" \
  "Декларативний: конфігурація написана декількома мовами одночасно / Declarative: config written in multiple languages" \
  "Декларативний: використовує тільки YAML, imperativ — тільки JSON / Declarative: YAML only, imperative: JSON only"

pause

section "Q4 / З4 of 25 — Переваги IaC / IaC Benefits"
tf_question \
  "Однією з ключових переваг IaC є можливість відновити ALL інфраструктуру з нуля лише з коду репозиторію після катастрофічного збою. / One key IaC benefit is the ability to fully rebuild all infrastructure from the code repository alone after a catastrophic failure." \
  "1" \
  "Yes — this is Disaster Recovery from code. With IaC, if an entire data center fails, you re-apply your Terraform/Ansible code and recreate the full environment. No manual reconstruction needed. / Так — це Disaster Recovery з коду. При збої ДЦ просто застосовуєш код і відтворюєш середовище повністю." \
  "IaC"

pause

section "Q5 / З5 of 25 — Snowflake Servers"
mcq \
  "Що таке 'Snowflake Server' і як IaC вирішує цю проблему? / What is a 'Snowflake Server' and how does IaC solve it?" \
  "4" \
  "Snowflake Server = a unique, manually configured server that nobody dares touch because nobody fully knows its state. IaC eliminates snowflakes: every server is built from the same code = identical, replaceable, documented. / Snowflake Server = унікальний, вручну налаштований сервер якого бояться чіпати. IaC усуває це: всі сервери з одного коду = ідентичні, замінні, задокументовані." \
  "IaC" \
  "Сервер що автоматично масштабується у хмарі / Server that auto-scales in the cloud" \
  "Сервер з вбудованим шифруванням даних / Server with built-in data encryption" \
  "Сервер розгорнутий у холодному регіоні / Server deployed in a cold region" \
  "Унікальний ручно налаштований сервер, IaC усуває унікальність через код / Unique manually configured server, IaC eliminates uniqueness via code"

pause

section "Q6 / З6 of 25 — Типи IaC-інструментів / IaC Tool Types"
mcq \
  "Яку з наведених задач найкраще вирішує Provisioning-інструмент (наприклад Terraform), а не Configuration Management (Ansible)? / Which task is best handled by a Provisioning tool (Terraform) rather than Config Management (Ansible)?" \
  "2" \
  "Terraform: creates cloud RESOURCES (VPC, EC2, S3, IAM, RDS). Ansible: configures what's INSIDE those resources (installs packages, writes config files, manages services). Terraform cannot install nginx on EC2; Ansible cannot create an EC2 instance. / Terraform: створює хмарні РЕСУРСИ. Ansible: налаштовує ЩО ВСЕРЕДИНІ ресурсів." \
  "IaC" \
  "Встановлення nginx та конфігурація /etc/nginx/nginx.conf / Installing nginx and configuring nginx.conf" \
  "Створення VPC, підмереж, Internet Gateway та EC2 інстансу / Creating VPC, subnets, IGW and EC2 instance" \
  "Розгортання застосунку на вже запущеному сервері / Deploying an app to an already running server" \
  "Встановлення системних патчів на 50 серверах / Installing OS patches on 50 servers"

pause

# ══════════════════════════════════════════════════════════════════════
#   ЧАСТИНА B — TERRAFORM  (Q7–Q14)
# ══════════════════════════════════════════════════════════════════════

banner "ЧАСТИНА B / PART B — Terraform  (Q7–Q14)"

section "Q7 / З7 of 25 — HCL та синтаксис / HCL Syntax"
mcq \
  "Як у Terraform-коді посилатись на атрибут id ресурсу типу aws_vpc з локальною назвою 'main'? / How do you reference the id attribute of an aws_vpc resource named 'main' in Terraform?" \
  "3" \
  "Terraform reference syntax: type.local_name.attribute → aws_vpc.main.id. This is how resources reference each other. Terraform builds a dependency graph from these references and determines the creation order. / Синтаксис посилання: тип.назва.атрибут → aws_vpc.main.id. З цих посилань Terraform будує граф залежностей і порядок створення." \
  "Terraform" \
  "var.aws_vpc.main.id" \
  "resource.aws_vpc.main.id" \
  "aws_vpc.main.id" \
  "data.aws_vpc.main.id"

pause

section "Q8 / З8 of 25 — Terraform State"
mcq \
  "Навіщо Terraform потрібен State (tfstate)? Що відбудеться без нього? / Why does Terraform need State (tfstate)? What happens without it?" \
  "1" \
  "State = Terraform's memory of what it deployed. Terraform compares: code ↔ state ↔ real infra to calculate changes. Without state, Terraform cannot know if resources already exist → would try to create everything again → errors (resource already exists). / State = пам'ять Terraform про розгорнуте. Без нього Terraform не знає що вже існує → спробує створити знову → помилки." \
  "Terraform" \
  "State відслідковує розгорнуті ресурси; без нього Terraform не знає що існує і намагатиметься перестворити все / State tracks deployed resources; without it Terraform doesn't know what exists and tries to recreate everything" \
  "State зберігає паролі та секрети в зашифрованому вигляді / State stores passwords and secrets encrypted" \
  "State — лише кеш для прискорення роботи, без нього все однаково / State is just a cache for speed, works fine without it" \
  "State зберігає попередні версії конфігурації для rollback / State stores previous config versions for rollback"

pause

section "Q9 / З9 of 25 — terraform plan"
mcq \
  "Що робить команда 'terraform plan' і чому вона важлива? / What does 'terraform plan' do and why is it important?" \
  "4" \
  "terraform plan = dry run: shows exactly what WILL change (+ create, ~ update, - destroy) without making any changes. Critical for review before apply — catch mistakes before they hit production. Save with -out=tfplan to apply the exact reviewed plan. / terraform plan = сухий запуск: показує що БУДЕ змінено (+ створити, ~ оновити, - видалити) без застосування. Критично для review перед apply." \
  "Terraform" \
  "Застосовує конфігурацію до реальної інфраструктури / Applies configuration to real infrastructure" \
  "Перевіряє синтаксис HCL без звернення до API / Validates HCL syntax without API calls" \
  "Форматує код відповідно до стандарту HashiCorp / Formats code to HashiCorp standard" \
  "Показує що буде змінено без реального виконання (dry run) / Shows what will change without executing (dry run)"

pause

section "Q10 / З10 of 25 — Remote State"
mcq \
  "Чому НЕ слід зберігати terraform.tfstate у Git-репозиторії? / Why should you NOT store terraform.tfstate in a Git repository?" \
  "2" \
  "State often contains SENSITIVE data (passwords, private IPs, secrets) in plain text. Also: concurrent team access causes conflicts and race conditions (two people apply simultaneously → state corruption). Solution: remote backend (S3 + DynamoDB for locking). / State містить чутливі дані в plain text. Паралельний доступ команди → конфлікти та race conditions. Рішення: S3 + DynamoDB для блокування." \
  "Terraform" \
  "Git не підтримує файли розміром більше 1 МБ / Git doesn't support files larger than 1MB" \
  "State містить чутливі дані і при командній роботі виникають race conditions / State contains sensitive data and team concurrent use causes race conditions" \
  "Terraform не може читати State з Git-репозиторію / Terraform cannot read State from a Git repo" \
  "State-файли не є текстовими, Git не може їх версіонувати / State files are not text, Git cannot version them"

pause

section "Q11 / З11 of 25 — Data Source"
mcq \
  "Чим Terraform Data Source відрізняється від Resource? / How does a Terraform Data Source differ from a Resource?" \
  "3" \
  "Resource: Terraform CREATES and manages it (lifecycle: create, update, destroy). Data Source: Terraform only READS existing data — never creates or modifies. Use data sources to reference resources created outside Terraform (existing VPCs, latest AMI IDs, account IDs). / Resource: Terraform СТВОРЮЄ і управляє. Data Source: тільки ЧИТАЄ існуючі дані — нічого не створює. Використовується для ресурсів поза Terraform." \
  "Terraform" \
  "Data Source знаходиться у окремому providers-файлі / Data Source lives in a separate providers file" \
  "Data Source може тільки читати ресурси у тому ж акаунті / Data Source can only read resources in the same account" \
  "Resource створює/управляє ресурсами; Data Source лише читає існуючі без змін / Resource creates/manages; Data Source only reads existing without changes" \
  "Різниця лише синтаксична: data {} замість resource {} / Only syntactic difference: data {} instead of resource {}"

pause

section "Q12 / З12 of 25 — Modules / Модулі"
mcq \
  "Яка головна перевага використання Terraform Modules? / What is the main benefit of Terraform Modules?" \
  "4" \
  "Modules = reusable, parameterized infrastructure blocks. Like functions in programming. Instead of copy-pasting 50 lines for each VPC — write a VPC module once, call it with different params for dev/staging/prod. Enables DRY (Don't Repeat Yourself) principle. / Модулі = повторно використовувані блоки. Як функції. Замість copy-paste — написати модуль один раз і викликати з різними параметрами для dev/staging/prod. Принцип DRY." \
  "Terraform" \
  "Модулі шифрують State-файл / Modules encrypt the State file" \
  "Модулі дозволяють запускати Terraform без AWS-ключів / Modules allow running without AWS keys" \
  "Модулі кешують provider-плагіни для прискорення / Modules cache provider plugins for speed" \
  "Модулі дозволяють повторно використовувати конфігурацію і уникнути дублювання коду (DRY) / Modules enable reuse and avoid code duplication (DRY)"

pause

section "Q13 / З13 of 25 — Sensitive Variables"
tf_question \
  "Якщо змінна Terraform оголошена з 'sensitive = true', Terraform не записує її значення у State-файл і воно повністю захищене. / If a Terraform variable is declared with 'sensitive = true', Terraform never writes its value to the State file and it is fully protected." \
  "2" \
  "FALSE. sensitive=true only hides the value in CLI output/logs — it prevents accidental display. BUT the value IS still written to tfstate in plain text! Always restrict access to tfstate (private S3 + encryption) when using sensitive variables. / ХИБНО. sensitive=true лише приховує значення в CLI виводі. Але значення ВСЕ ОДНО записується в tfstate у plain text! Завжди обмежуйте доступ до tfstate." \
  "Terraform"

pause

section "Q14 / З14 of 25 — terraform import"
mcq \
  "Для чого використовується команда 'terraform import'? / What is 'terraform import' used for?" \
  "2" \
  "terraform import: brings an existing manually-created resource under Terraform management by adding it to State. Use case: you have production resources created via Console/CLI and want to start managing them with Terraform. Note: import adds to State but does NOT write the HCL code — you must write it manually. / terraform import: бере вже існуючий ресурс під управління Terraform через додавання в State. Код HCL при цьому треба написати вручну." \
  "Terraform" \
  "Завантажити Terraform provider з реєстру HashiCorp / Download Terraform provider from HashiCorp registry" \
  "Взяти існуючий ресурс (створений вручну) під управління Terraform / Bring an existing manually-created resource under Terraform management" \
  "Перенести State-файл між бекендами / Migrate State file between backends" \
  "Імпортувати змінні з .env файлу / Import variables from a .env file"

pause

# ══════════════════════════════════════════════════════════════════════
#   ЧАСТИНА C — ANSIBLE  (Q15–Q21)
# ══════════════════════════════════════════════════════════════════════

banner "ЧАСТИНА C / PART C — Ansible  (Q15–Q21)"

section "Q15 / З15 of 25 — Agentless Architecture"
mcq \
  "Що означає 'agentless' в Ansible і яка перевага цього підходу? / What does 'agentless' mean in Ansible and what is the benefit?" \
  "1" \
  "Agentless: no software needs to be pre-installed on managed servers. Ansible connects via standard SSH (Linux) or WinRM (Windows) using existing OS infrastructure. Benefits: no agent maintenance, no port opening, works with any fresh server immediately. / Agentless: не потрібно встановлювати агент на сервери. Ansible підключається через стандартний SSH. Переваги: немає обслуговування агентів, працює з будь-яким сервером відразу." \
  "Ansible" \
  "Ansible не потребує агента на серверах — підключається через SSH без додаткового ПЗ / Ansible needs no agent on servers — connects via SSH without extra software" \
  "Ansible встановлює агент тільки на серверах у хмарі, не на локальних / Ansible installs agent only on cloud servers, not local" \
  "Ansible-агент встановлюється автоматично при першому підключенні / Agent auto-installs on first connection" \
  "Agentless означає що Ansible не потребує мережевого підключення / Agentless means Ansible needs no network connection"

pause

section "Q16 / З16 of 25 — Inventory"
mcq \
  "Яка різниця між статичним та динамічним Ansible Inventory? Коли використовувати динамічний? / What's the difference between static and dynamic Ansible Inventory?" \
  "3" \
  "Static inventory: fixed hosts.ini/yml file — good for stable, small environments. Dynamic inventory: script/plugin that queries AWS/GCP/Azure API at runtime to get current list of running instances. Essential for cloud/ASG environments where IPs change constantly. / Статичний: фіксований файл. Динамічний: скрипт/плагін що запитує AWS API під час запуску. Необхідний для хмарних середовищ де IP постійно змінюються." \
  "Ansible" \
  "Статичний інвентар може містити тільки IPv4, динамічний — IPv6 / Static: IPv4 only, dynamic: IPv6" \
  "Статичний зашифрований, динамічний у відкритому тексті / Static is encrypted, dynamic is plaintext" \
  "Статичний: фіксований файл; динамічний: запитує API і повертає поточні хости (для AWS/ASG) / Static: fixed file; dynamic: queries API for current hosts (for AWS/ASG)" \
  "Динамічний інвентар — тільки для Docker Swarm кластерів / Dynamic inventory only for Docker Swarm"

pause

section "Q17 / З17 of 25 — Playbook структура / Playbook Structure"
mcq \
  "В Ansible Playbook що таке 'handler' і коли він виконується? / In an Ansible Playbook what is a 'handler' and when does it run?" \
  "4" \
  "Handler = a task triggered by 'notify:' in another task. Runs ONLY if the notifying task made a change (changed=true), and runs ONCE at the end of the play — regardless of how many tasks notified it. Classic use: restart nginx only if config changed. / Handler = завдання що запускається через 'notify:'. Виконується ТІЛЬКИ якщо задача зробила зміну (changed=true), і лише РАЗ в кінці play. Класика: перезапустити nginx тільки якщо конфіг змінився." \
  "Ansible" \
  "Завдання що виконується перед усіма іншими у play / Task that runs before all others in a play" \
  "Змінна що передається між plays у playbook / Variable passed between plays in a playbook" \
  "Завдання що виконується паралельно на всіх хостах одночасно / Task that runs in parallel on all hosts simultaneously" \
  "Завдання-відповідь що виконується тільки при зміні та лише раз в кінці play / Response task that runs only on change and only once at play end"

pause

section "Q18 / З18 of 25 — become: true"
fill_blank \
  "В Ansible, атрибут '________: true' дозволяє виконувати завдання з підвищеними правами (sudo) на керованому хості. / In Ansible, the '________: true' attribute allows running tasks with elevated privileges (sudo) on the managed host." \
  "become" \
  "become: true = run tasks as sudo/root. Without it, tasks run as the SSH user. Use become_user to specify a different privileged user. / become: true = виконувати від sudo/root. Без нього завдання виконуються від SSH-користувача." \
  "Ansible"

pause

section "Q19 / З19 of 25 — Ansible Roles"
mcq \
  "Яка структурна перевага Ansible Roles порівняно з простим плейбуком? / What structural advantage do Ansible Roles have over a plain playbook?" \
  "2" \
  "Roles enforce a standardized directory structure (tasks/, handlers/, templates/, files/, vars/, defaults/, meta/) that enables: reuse across projects, sharing via Ansible Galaxy, clear separation of concerns. A role is a self-contained automation unit. / Ролі дають стандартну структуру директорій (tasks/, handlers/, templates/...) що дозволяє: повторне використання, шерінг через Galaxy, чіткий розподіл відповідальностей." \
  "Ansible" \
  "Ролі виконуються швидше ніж tasks у playbook / Roles execute faster than tasks in a playbook" \
  "Ролі забезпечують стандартну структуру та повторне використання через Galaxy / Roles provide standard structure and reusability via Galaxy" \
  "Ролі можуть підключатись до хостів без SSH / Roles can connect to hosts without SSH" \
  "Ролі підтримують тільки YAML, а playbook — YAML та JSON / Roles support YAML only, playbooks support YAML and JSON"

pause

section "Q20 / З20 of 25 — Ansible Vault"
mcq \
  "Що забезпечує Ansible Vault і яке обмеження у нього є? / What does Ansible Vault provide and what limitation does it have?" \
  "1" \
  "Vault encrypts files/strings with AES-256, safe to commit to Git. Limitation: Vault protects data AT REST (in files) but decrypts at runtime — the decrypted value is visible in memory and may appear in verbose logs. Also: the vault password itself must be protected externally. / Vault шифрує файли AES-256, безпечно у Git. Обмеження: розшифровує під час виконання — значення видиме у пам'яті та verbose логах. Пароль від vault треба захистити окремо." \
  "Ansible" \
  "Vault шифрує секрети для безпечного зберігання у Git; але розшифровує під час виконання (видиме у verbose) / Vault encrypts secrets for safe Git storage; but decrypts at runtime (visible in verbose mode)" \
  "Vault забезпечує повну анонімність — ніколи не розшифровує дані / Vault provides full anonymity — never decrypts data" \
  "Vault замінює SSH-ключі для автентифікації / Vault replaces SSH keys for authentication" \
  "Vault зберігає зашифровані дані тільки в оперативній пам'яті / Vault stores encrypted data only in RAM"

pause

section "Q21 / З21 of 25 — loop vs include_tasks"
mcq \
  "Яка різниця між 'loop' та 'include_tasks' в Ansible Playbook? / What is the difference between 'loop' and 'include_tasks' in Ansible?" \
  "3" \
  "loop: iterates the SAME task over a list of items (install pkg1, pkg2, pkg3 with one task block). include_tasks: includes an ENTIRE separate task file — good for organizing complex logic into sub-files loaded conditionally. / loop: ітерує ОДНЕ завдання по списку елементів. include_tasks: підключає окремий ФАЙЛ завдань — для організації складної логіки в підфайли." \
  "Ansible" \
  "loop — для підключення файлів, include_tasks — для ітерації / loop for including files, include_tasks for iteration" \
  "loop і include_tasks — синоніми, взаємозамінні / loop and include_tasks are synonyms, interchangeable" \
  "loop ітерує одне завдання по списку; include_tasks підключає окремий файл завдань / loop iterates one task over a list; include_tasks includes a separate tasks file" \
  "loop — для hosts, include_tasks — для roles / loop for hosts, include_tasks for roles"

pause

# ══════════════════════════════════════════════════════════════════════
#   ЧАСТИНА D — ПОРІВНЯННЯ / PART D — COMPARISON & INTEGRATION (Q22–Q25)
# ══════════════════════════════════════════════════════════════════════

banner "ЧАСТИНА D / PART D — Comparison & Integration  (Q22–Q25)"

section "Q22 / З22 of 25 — Terraform vs Ansible — Правильне використання"
mcq \
  "Ваша команда хоче: 1) розгорнути VPC + EC2 + RDS в AWS, 2) встановити nginx + Python app, 3) налаштувати cron. Який інструмент для яких задач? / Your team wants to: 1) deploy VPC+EC2+RDS, 2) install nginx+Python app, 3) configure cron. Which tool for which?" \
  "4" \
  "Classic split: Terraform for cloud RESOURCES (VPC, EC2, RDS — infrastructure that AWS manages). Ansible for OS-level CONFIGURATION (nginx install, app deploy, cron setup — things done inside the OS). Neither tool can fully replace the other. / Класичний розподіл: Terraform для РЕСУРСІВ AWS (VPC, EC2, RDS). Ansible для КОНФІГУРАЦІЇ ОС (nginx, app deploy, cron — те що відбувається всередині ОС)." \
  "Both" \
  "Тільки Terraform для всіх трьох задач / Only Terraform for all three tasks" \
  "Тільки Ansible для всіх трьох задач / Only Ansible for all three tasks" \
  "Terraform для VPC+EC2+RDS; Ansible для решти — але вони незалежні / Terraform for VPC+EC2+RDS; Ansible for the rest — but independent" \
  "Terraform для VPC+EC2+RDS (cloud resources); Ansible для nginx+app+cron (OS config) / Terraform: cloud resources; Ansible: OS config"

pause

section "Q23 / З23 of 25 — State vs Stateless"
mcq \
  "Terraform зберігає State, Ansible — ні. Яке практичне значення цієї різниці? / Terraform stores State, Ansible doesn't. What is the practical significance?" \
  "2" \
  "Terraform with State: knows exact current state of all resources → can calculate precise diff → knows what to create/update/destroy. Without state: would have to query every resource from scratch every run. Ansible stateless: checks current state on each run by querying OS directly (idempotent modules handle this). / Terraform зі State: знає точний стан → розраховує diff → знає що створити/оновити/знищити. Ansible stateless: кожен модуль перевіряє поточний стан безпосередньо на хості при кожному запуску." \
  "Both" \
  "Terraform зі State знає точний стан ресурсів і може розрахувати diff; Ansible перевіряє стан на хості під час кожного запуску / Terraform with State knows exact resource state and calculates diff; Ansible checks state on host during each run" \
  "Ansible без State не може бути ідемпотентним / Ansible without State cannot be idempotent" \
  "Terraform без State не може підключитись до AWS / Terraform without State cannot connect to AWS" \
  "Різниця лише технічна, практично вони однакові / Only technical difference, practically the same"

pause

section "Q24 / З24 of 25 — Інтеграція / Integration Pattern"
mcq \
  "Як найкраще передати output Terraform (IP нових EC2) до Ansible Inventory? / How best to pass Terraform output (new EC2 IPs) to Ansible Inventory?" \
  "3" \
  "Best patterns: 1) Use dynamic inventory plugin (amazon.aws.aws_ec2) — Ansible directly queries AWS API, no Terraform needed. 2) terraform output -json | script to generate inventory file. 3) Use Terraform local_file resource to generate inventory. Never hardcode IPs — they change with every apply. / Кращі шаблони: 1) Динамічний інвентар aws_ec2 — Ansible сам запитує AWS API. 2) terraform output -json → скрипт генерує inventory. 3) Ніколи не хардкодити IP — вони змінюються." \
  "Both" \
  "Вручну скопіювати IP з terraform output у hosts.ini / Manually copy IPs from terraform output to hosts.ini" \
  "Передати IP через змінну середовища ANSIBLE_HOST / Pass via ANSIBLE_HOST environment variable" \
  "Використати динамічний інвентар або terraform output -json для автогенерації inventory / Use dynamic inventory or terraform output -json to auto-generate inventory" \
  "Terraform і Ansible не можуть використовуватись разом / Terraform and Ansible cannot be used together"

pause

section "Q25 / З25 of 25 — IaC в CI/CD"
mcq \
  "Яка правильна послідовність кроків у CI/CD pipeline для IaC? / What is the correct CI/CD pipeline step sequence for IaC?" \
  "2" \
  "Correct IaC CI/CD order: 1) validate/fmt (syntax) → 2) plan (review what will change, add to PR) → 3) human review/approve → 4) apply (on merge to main). This ensures no untested changes reach production. Destroy only done manually or in separate pipeline with extra approval. / Правильна послідовність: validate/fmt → plan (додати до PR) → review/approve → apply (після merge). Destroy — тільки вручну або окремий pipeline з подвійним підтвердженням." \
  "IaC" \
  "apply → plan → validate → destroy / apply → plan → validate → destroy" \
  "validate → fmt → plan → (review) → apply / validate → fmt → plan → (review) → apply" \
  "plan → apply → validate → fmt / plan → apply → validate → fmt" \
  "init → apply → plan → validate / init → apply → plan → validate"

pause

# ══════════════════════════════════════════════════════════════════════
#   ФІНАЛЬНИЙ РЕЗУЛЬТАТ / FINAL RESULTS
# ══════════════════════════════════════════════════════════════════════

clear
banner "🏁  FINAL RESULTS / ФІНАЛЬНІ РЕЗУЛЬТАТИ"
echo ""

PCT=$((Q_OK * 100 / Q_TOT))
GRADE_A=$((Q_TOT * 87 / 100))   # ~90% for A
GRADE_B=$((Q_TOT * 70 / 100))
GRADE_C=$((Q_TOT * 53 / 100))

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
echo -e "  │                                                          │"

# Breakdown by section
Q_A=$((Q_OK < 6 ? Q_OK : 6))
echo -e "  │  A — IaC:        ??? / 6   B — Terraform: ??? / 8       │"
echo -e "  │  C — Ansible:    ??? / 7   D — Comparison: ??? / 4      │"
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
echo -e "  ${DIM}IaC:${NC}"
echo -e "  ${DIM}  Idempotency · Declarative · Version Control · Reproducibility${NC}"
echo ""
echo -e "  ${DIM}Terraform:${NC}"
echo -e "  ${DIM}  HCL · Provider · Resource · Data Source · Variable · Output${NC}"
echo -e "  ${DIM}  State · Plan → Apply → Destroy · Modules · import · sensitive${NC}"
echo ""
echo -e "  ${DIM}Ansible:${NC}"
echo -e "  ${DIM}  Agentless (SSH) · Inventory · Playbook · Task · Module${NC}"
echo -e "  ${DIM}  Handler · Role · Vault · Galaxy · become · loop${NC}"
echo ""
echo -e "  ${BOLD}${CYAN}── Документація / Documentation ──────────────────────────────────${NC}"
echo -e "  ${DIM}📘 Terraform: https://developer.hashicorp.com/terraform/docs${NC}"
echo -e "  ${DIM}📘 Ansible:   https://docs.ansible.com${NC}"
echo -e "  ${DIM}📘 TF AWS:    https://registry.terraform.io/providers/hashicorp/aws${NC}"
echo -e "  ${DIM}📘 Galaxy:    https://galaxy.ansible.com${NC}"
echo ""

# Save result
RESULT_FILE="lecture6_result_$(echo "$STUDENT" | tr ' ' '_')_$(date +%Y%m%d_%H%M).txt"
cat << EOF > "$RESULT_FILE"
AWS Academy — Lecture 6 Result / Результат
===========================================
Student / Курсант : $STUDENT
Date / Дата       : $(date '+%d.%m.%Y %H:%M')
Score / Бал       : $Q_OK / $Q_TOT  (${PCT}%)
Grade / Оцінка    : $GRADE

Covered topics / Теми:
  A) IaC Concepts (Q1-Q6):    Definition, Idempotency, Declarative, Benefits, Snowflake, Tool Types
  B) Terraform   (Q7-Q14):    HCL Syntax, State, Plan, Remote State, Data Source, Modules, Sensitive, Import
  C) Ansible     (Q15-Q21):   Agentless, Inventory, Handlers, become, Roles, Vault, loop
  D) Comparison  (Q22-Q25):   Tool selection, State vs Stateless, Integration, CI/CD Pipeline
EOF

ok "Result saved / Результат збережено: ${BOLD}${RESULT_FILE}${NC}"
echo ""
echo -e "${BOLD}${MAGENTA}  Дякуємо! / Thank you!  Слава Україні! 🇺🇦${NC}"
echo ""
