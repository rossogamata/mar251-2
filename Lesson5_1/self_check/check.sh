#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  AWS Academy — Lab 5 Self-Assessment / Самоперевірка            ║
# ║  RDS · ALB · Auto Scaling · Load Balancing                      ║
# ║  Бази даних · Балансування · Масштабування                      ║
# ╚══════════════════════════════════════════════════════════════════╝

RED='\033[0;31m';  GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m';  MAGENTA='\033[0;35m'
BOLD='\033[1m';    DIM='\033[2m';      NC='\033[0m'

Q_OK=0; Q_TOT=0; A_OK=0; A_TOT=0

ok()   { echo -e "  ${GREEN}✅  $1${NC}"; }
fail() { echo -e "  ${RED}❌  $1${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️   $1${NC}"; }
info() { echo -e "  ${BLUE}ℹ️   $1${NC}"; }
hint() { echo -e "  ${DIM}     💡 $1${NC}"; }

banner() {
  echo ""
  echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
  printf "${BOLD}${BLUE}║${NC}  %-60s${BOLD}${BLUE}║${NC}\n" "$1"
  echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
}

section() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}  $1${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

pause() {
  echo ""
  read -rp "$(echo -e "  ${MAGENTA}▶  Press Enter / Натисніть Enter...${NC}")" _
}

mcq() {
  local q="$1" correct="$2" hint_txt="$3"; shift 3; local opts=("$@")
  echo ""; echo -e "${BOLD}${YELLOW}❓  ${q}${NC}"; echo ""
  for i in "${!opts[@]}"; do echo -e "    ${BOLD}$((i+1)))${NC}  ${opts[$i]}"; done
  echo ""
  read -rp "$(echo -e "  ${BOLD}Answer / Відповідь (1-${#opts[@]}): ${NC}")" ans
  Q_TOT=$((Q_TOT+1))
  if [[ "$ans" == "$correct" ]]; then
    ok "Correct / Правильно! 🎉"; Q_OK=$((Q_OK+1))
  else
    fail "Wrong. Correct: ${BOLD}${correct}) ${opts[$((correct-1))]}${NC}"
    hint "$hint_txt"
  fi
}

chk() {
  local label="$1" rid="$2" cmd="$3"
  A_TOT=$((A_TOT+1))
  echo -ne "  Checking ${BOLD}${label}${NC}... "
  if [[ -z "$rid" || "$rid" == "None" || "$rid" == "null" || "$rid" == "n/a" ]]; then
    echo ""; fail "${label} — ID not provided / ID не введено"; return 1
  fi
  local r; r=$(eval "$cmd" 2>/dev/null)
  if [[ -n "$r" && "$r" != "None" && "$r" != "null" ]]; then
    echo ""; ok "${label}: ${BOLD}${rid}${NC}"; A_OK=$((A_OK+1)); return 0
  else
    echo ""; fail "${label}: not found / не знайдено"; return 1
  fi
}

# ═══════════════════════════════════════════════════════════════════
clear; echo ""
echo -e "${BOLD}${MAGENTA}"
cat << 'BANNER'
  ╔════════════════════════════════════════════════════════════════╗
  ║   AWS ACADEMY — LAB 5  ·  SELF-ASSESSMENT / САМОПЕРЕВІРКА     ║
  ║   RDS · ALB · Auto Scaling · Load Balancing                   ║
  ╚════════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"
echo -e "  ${CYAN}Part 1: Theory — Lab 5 (RDS) + Lab 6 (ALB/ASG) — 15 questions${NC}"
echo -e "  ${CYAN}Part 2: Live verification of your AWS resources${NC}"
echo -e "  ${CYAN}Part 3: Practical live challenge${NC}"
echo ""
read -rp "  Full name / Ім'я та прізвище: " STUDENT
echo -e "\n  ${GREEN}Hello / Привіт, ${BOLD}${STUDENT}${NC}${GREEN}! Let's go! 🚀${NC}"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null)
pause

# ═══════════════════════════════════════════════════════════════════
#   PART 1 — THEORY QUIZ / ЧАСТИНА 1 — ТЕОРЕТИЧНИЙ КВІЗ
# ═══════════════════════════════════════════════════════════════════

banner "PART 1 / ЧАСТИНА 1 — Theory Quiz  (15 questions)"

# ── BLOCK A: RDS / Бази даних ────────────────────────────────────────
section "BLOCK A — RDS & Databases  (Q1–Q7)"

section "Q1 / З1 of 15 — RDS vs Self-managed DB"
mcq \
  "What does 'managed' in Amazon RDS mean? What does AWS handle automatically? / Що означає 'керована' (managed) БД в RDS? Що AWS робить автоматично?" \
  "3" \
  "RDS = managed: AWS handles OS patching, DB engine updates, automated backups (up to 35 days), storage scaling, and Multi-AZ failover. You only manage: schema, users, data, query optimization. / RDS: AWS керує ОС, патчами, бекапами, failover. Ви керуєте: схемою, даними, запитами." \
  "RDS manages only storage — you manage OS, backups, and DB engine / Тільки сховище — ОС і бекапи ваші" \
  "RDS manages billing only — all technical aspects are your responsibility / Тільки білінг — все інше ваше" \
  "RDS manages OS, patching, backups, failover — you manage schema and data / ОС, патчі, бекапи, failover — ваші схема та дані" \
  "RDS is fully automated — you have no access to configure anything / Повністю автоматизована — немає доступу"

pause

section "Q2 / З2 of 15 — DB Subnet Group"
mcq \
  "Why must a DB Subnet Group contain subnets in at least 2 different AZs? / Чому DB Subnet Group повинна містити підмережі щонайменше в 2 різних AZ?" \
  "2" \
  "AWS requires 2+ AZ subnets for Multi-AZ failover support. Even in Single-AZ mode, RDS uses this for maintenance flexibility. The standby replica (Multi-AZ) is always in a different AZ. / AWS вимагає 2+ AZ для підтримки Multi-AZ failover. Резерв завжди в іншій AZ." \
  "To reduce network latency between DB and applications / Зменшити затримку мережі" \
  "To support Multi-AZ placement — standby replica must be in a different AZ / Підтримка Multi-AZ — резерв в іншій AZ" \
  "To allow RDS to distribute data across multiple disks / Розподілити дані на кілька дисків" \
  "AWS requires at least 2 subnets for billing purposes / AWS вимагає 2 підмережі для білінгу"

pause

section "Q3 / З3 of 15 — Parameter Group"
mcq \
  "What is an RDS Parameter Group and when would you use a custom one? / Що таке RDS Parameter Group і коли потрібна кастомна?" \
  "1" \
  "Parameter Group = DB engine config file (like my.cnf for MySQL). Default group is read-only. Create a custom group to change: character encoding, max_connections, slow query log, buffer sizes, timeouts. / Файл конфігурації СУБД (як my.cnf). Default — тільки читання. Кастомна — для зміни encoding, slow log, max_connections." \
  "A config file for the DB engine (like my.cnf); custom needed to change DB settings / Конфіг СУБД; кастомна для зміни налаштувань" \
  "A security policy that defines which users can access the DB / Політика безпеки доступу до БД" \
  "A group of RDS instances sharing the same configuration / Група інстансів зі спільною конфігурацією" \
  "A backup schedule definition for automated snapshots / Розклад автоматичних бекапів"

pause

section "Q4 / З4 of 15 — Multi-AZ vs Read Replica"
mcq \
  "What is the key difference between Multi-AZ and a Read Replica in RDS? / Ключова різниця між Multi-AZ та Read Replica в RDS?" \
  "4" \
  "Multi-AZ = synchronous standby in another AZ for AVAILABILITY (automatic failover, not readable). Read Replica = asynchronous copy for SCALABILITY (readable, no automatic failover). / Multi-AZ: синхронний резерв для відмовостійкості (не читається). Read Replica: асинхронна копія для масштабування читання." \
  "Multi-AZ gives better performance, Read Replica gives redundancy / Multi-AZ — продуктивність, Replica — резервування" \
  "Multi-AZ stores data in multiple regions, Read Replica in one region / Multi-AZ — кілька регіонів, Replica — один" \
  "Multi-AZ requires manual failover, Read Replica is automatic / Multi-AZ — ручний failover, Replica — автоматичний" \
  "Multi-AZ = sync standby for availability/failover; Read Replica = async copy for read scaling / Multi-AZ — синхронний резерв; Replica — асинхронна копія для читання"

pause

section "Q5 / З5 of 15 — RDS Security"
mcq \
  "Why should --no-publicly-accessible be set for a production RDS instance? / Чому для RDS у продакшені слід вказати --no-publicly-accessible?" \
  "3" \
  "publicly-accessible = RDS gets a public IP reachable from internet — attack surface. no-publicly-accessible = RDS has only private IP, accessible ONLY from within the VPC via Security Group. Defense in depth principle. / Publicly-accessible = публічний IP, вразливий. No-publicly-accessible = лише приватний IP, доступ тільки з VPC через SG. Принцип ешелонованого захисту." \
  "Public RDS cannot be encrypted / Публічний RDS не можна шифрувати" \
  "Public RDS cannot be backed up automatically / Публічний RDS не може мати авто-бекапів" \
  "Public RDS gets a public IP reachable from internet — unnecessary attack surface / Публічний IP = вектор атаки з інтернету" \
  "Public RDS charges more for network traffic / Публічний RDS коштує більше"

pause

section "Q6 / З6 of 15 — RDS Storage Autoscaling"
mcq \
  "What does the --max-allocated-storage parameter control in RDS? / За що відповідає параметр --max-allocated-storage в RDS?" \
  "2" \
  "--max-allocated-storage enables storage autoscaling. When free space < 10% (or <5GB), RDS auto-expands up to this limit. Without it, you must manually scale storage. Prevents outages from disk full. / Вмикає авто-розширення сховища. При < 10% місця RDS розширюється до цього ліміту. Запобігає переповненню диску." \
  "Maximum number of database connections allowed / Максимальна кількість з'єднань" \
  "Upper limit for automatic storage expansion / Верхня межа для автоматичного розширення сховища" \
  "Maximum size of the initial DB dump / Максимальний розмір початкового дампу" \
  "Limit on backup storage retained by RDS / Ліміт сховища для резервних копій"

pause

section "Q7 / З7 of 15 — SG-to-SG Rule"
mcq \
  "In the lab we used --source-group \$EC2_SG for the RDS Security Group instead of a CIDR. Why? / В лабораторній роботі ми використали --source-group замість CIDR для RDS SG. Навіщо?" \
  "1" \
  "SG-to-SG reference allows all EC2 instances with that SG to reach RDS, regardless of their IP. IPs can change (spot, ASG scaling). No need to update rules when instances are replaced. More secure than 0.0.0.0/0. / SG-to-SG: всі EC2 з цією SG можуть досягти RDS незалежно від IP. IP можуть мінятись (ASG, spot). Безпечніше за CIDR." \
  "SG reference works faster than CIDR-based rules / SG правила швидші за CIDR" \
  "CIDR blocks are not supported in RDS security groups / CIDR не підтримуються в RDS SG" \
  "SG reference is required for cross-AZ traffic / SG посилання потрібне для cross-AZ трафіку" \
  "SG reference: EC2 instances with that SG can reach RDS regardless of their changing IPs / EC2 з тією SG можуть досягти RDS незалежно від IP, що змінюється"

pause

# ── BLOCK B: ALB & Load Balancing ────────────────────────────────────
section "BLOCK B — ALB & Load Balancing  (Q8–Q11)"

section "Q8 / З8 of 15 — ALB vs NLB"
mcq \
  "When should you choose NLB (Network Load Balancer) over ALB (Application Load Balancer)? / Коли вибрати NLB замість ALB?" \
  "4" \
  "ALB = L7 (HTTP/HTTPS), understands URLs/headers, path-based routing, good for web apps. NLB = L4 (TCP/UDP), passes raw packets, ultra-low latency (<1ms), handles millions of req/sec, preserves client IP, good for gaming/VoIP/financial trading. / ALB: L7, HTTP, маршрутизація по URL. NLB: L4, TCP/UDP, мікросекундна затримка, для ігор/VoIP/фінансів." \
  "When you need path-based routing by URL / Маршрутизація по URL шляху" \
  "When your application uses HTTP cookies for session affinity / Сесійне прив'язування через cookie" \
  "When you need to inspect HTTP request headers / Перегляд HTTP заголовків" \
  "When you need ultra-low latency TCP/UDP — gaming, VoIP, financial trading / Мікросекундна затримка TCP/UDP — ігри, VoIP, фінанси"

pause

section "Q9 / З9 of 15 — Target Group Health Checks"
mcq \
  "An instance passes the EC2 health check but fails the ELB health check. What does this mean? / Інстанс проходить EC2 перевірку, але не проходить ELB. Що це означає?" \
  "3" \
  "EC2 health check = is the VM running (system level). ELB health check = does the APPLICATION respond to HTTP requests with 200 OK. Failing ELB check means the VM is running but the web server/app is broken. ALB stops sending traffic to it. / EC2: чи запущена VM. ELB: чи відповідає ЗАСТОСУНОК на HTTP. Проходить EC2 але не ELB = VM жива, але веб-сервер не працює. ALB виключає з балансування." \
  "The instance has insufficient CPU for the application / Недостатньо CPU" \
  "The instance's Security Group is blocking the load balancer / SG блокує балансувальник" \
  "The VM is running but the web application is not responding (e.g. Apache crashed) / VM жива але веб-застосунок не відповідає (наприклад Apache впав)" \
  "The instance is in a different AZ than the load balancer / Інстанс у іншій AZ"

pause

section "Q10 / З10 of 15 — ALB Scheme"
mcq \
  "You need an ALB that is accessible ONLY from inside the corporate VPC (not from internet). Which scheme? / Потрібен ALB доступний ТІЛЬКИ зсередині корпоративної VPC. Яка схема?" \
  "2" \
  "internet-facing = public ALB with public IP/DNS, reachable from internet. internal = private ALB with private IP only, accessible only within VPC (or via VPN/Direct Connect). Use internal for microservices-to-microservices traffic. / internet-facing = публічний. internal = приватний IP, тільки з VPC. Для мікросервісів всередині VPC." \
  "internet-facing — still requires a Security Group to restrict access / Потрібна SG для обмеження" \
  "internal — gets only a private IP, accessible only within the VPC / Тільки приватний IP, доступний з VPC" \
  "private — a special scheme for corporate environments / Спеціальна схема для корпоративних середовищ" \
  "vpc-only — the AWS-recommended scheme for internal services / Рекомендована для внутрішніх сервісів"

pause

section "Q11 / З11 of 15 — ALB Listener Rules"
mcq \
  "ALB Listener can route traffic based on URL path. How would you route /api/* to one TG and /* to another? / ALB може маршрутизувати по URL. Як направити /api/* в один TG а /* в інший?" \
  "1" \
  "ALB Listener supports path-based routing rules. Add rule: IF path=/api/* THEN forward to api-tg. Default action: forward to web-tg. Rules evaluated top to bottom, first match wins. / ALB підтримує path-based routing. Правило: IF path=/api/* → api-tg. Default → web-tg. Правила від першого до останнього." \
  "Create two Listener Rules: path=/api/* → api-tg; default → web-tg / Два правила: /api/* → api-tg; default → web-tg" \
  "Create two separate ALBs — one for API and one for web / Два окремих ALB" \
  "Use two separate Target Groups with different ports / Два TG на різних портах" \
  "Use ALB access logs to filter and redirect traffic post-hoc / Логи ALB для постфактум перенаправлення"

pause

# ── BLOCK C: Auto Scaling ─────────────────────────────────────────────
section "BLOCK C — Auto Scaling  (Q12–Q15)"

section "Q12 / З12 of 15 — Health Check Type ELB vs EC2"
mcq \
  "Your ASG uses health-check-type EC2. An instance's Apache crashes — what happens? / ASG використовує health-check-type EC2. Apache впав на інстансі — що станеться?" \
  "4" \
  "EC2 health check = checks only if the VM is running (hypervisor level). Apache crash = VM still running → EC2 check passes. ASG will NOT replace the instance. ALB stops sending traffic (ELB check fails) but ASG keeps the broken instance. Solution: use --health-check-type ELB so ASG replaces unhealthy app instances. / EC2 check: тільки чи жива VM. Apache впав — VM жива, EC2 check пройде. ASG НЕ замінить. Рішення: ELB health check type." \
  "ASG immediately replaces the instance / ASG одразу замінить інстанс" \
  "ALB stops routing traffic AND ASG replaces the instance / ALB та ASG разом реагують" \
  "The instance gets rebooted automatically / Інстанс перезавантажується автоматично" \
  "ALB stops routing traffic but ASG keeps the broken instance (use --health-check-type ELB to fix) / ALB зупиняє трафік, ASG залишає зламаний (треба ELB health check type)"

pause

section "Q13 / З13 of 15 — Cooldown Period"
mcq \
  "Why is ScaleInCooldown set longer than ScaleOutCooldown in our lab? / Чому ScaleInCooldown довший за ScaleOutCooldown в нашій лабораторній?" \
  "3" \
  "ScaleOut cooldown: short (60s) — need to react fast when load spikes. ScaleIn cooldown: long (180s) — avoid removing instances too quickly after load drops. Load spikes can be momentary (burst), so removing instances during a short dip causes thrashing. / ScaleOut: короткий (60с) — реагуємо швидко на навантаження. ScaleIn: довгий (180с) — не видаляємо передчасно, навантаження може повернутись." \
  "ScaleIn requires more time to terminate instances safely / Завершення інстансів потребує більше часу" \
  "AWS charges extra for rapid scale-in operations / AWS стягує більше за швидке масштабування вниз" \
  "Scale-in pauses longer to avoid removing instances during brief load dips (thrashing prevention) / Пауза щоб не видалити інстанси під час короткого спаду навантаження" \
  "ScaleIn cooldown must always equal ScaleOut cooldown / Вони завжди повинні бути рівними"

pause

section "Q14 / З14 of 15 — ASG + ALB Integration"
mcq \
  "What happens automatically when ASG launches a new instance because of high CPU load? / Що відбувається автоматично коли ASG запускає новий інстанс через велике CPU навантаження?" \
  "2" \
  "ASG-to-TG integration: when ASG launches an instance, it auto-registers it to the Target Group. ALB starts health-checking it. After health-check-grace-period + 2 consecutive healthy checks, ALB includes it in load balancing. All automatic — no manual steps. / Автоматична реєстрація в Target Group → ALB перевіряє health → після grace period включає в балансування. Нічого вручну." \
  "You must manually register the new instance with the Target Group / Треба вручну зареєструвати в Target Group" \
  "The instance is auto-registered to the Target Group and ALB starts routing to it after health checks pass / Авто-реєстрація в TG, ALB включає після проходження health check" \
  "The instance gets a new Elastic IP assigned automatically / Отримує новий Elastic IP автоматично" \
  "You must update the ALB Listener rules to include the new instance / Треба оновити правила Listener"

pause

section "Q15 / З15 of 15 — Launch Template Versioning"
mcq \
  "Your ASG uses Version=\$Latest in the Launch Template. You publish v2 with a new AMI. What happens? / ASG використовує Version=\$Latest. Ви публікуєте v2 з новим AMI. Що відбудеться?" \
  "3" \
  "\$Latest always points to the newest template version. Existing running instances are NOT replaced (ASG never restarts healthy instances). Only NEW instances launched after v2 publication use v2. To refresh all instances: use Instance Refresh feature or manually cycle desired capacity. / \$Latest = завжди найновіша. Існуючі інстанси НЕ замінюються. Нові після публікації v2 — запускаються з v2. Для оновлення всіх: Instance Refresh." \
  "All existing instances are immediately replaced with v2 / Всі існуючі одразу замінюються" \
  "The ASG is paused until all instances are updated to v2 / ASG призупиняється для оновлення" \
  "Only NEW instances use v2; existing instances keep running with v1 until replaced / Лише нові інстанси використовують v2; існуючі продовжують з v1" \
  "ASG refuses to launch new instances until you manually confirm v2 / ASG не запускає поки не підтверджено v2"

pause

# ── Quiz summary ─────────────────────────────────────────────────────
section "Quiz Results / Результати квізу"
Q_PCT=$((Q_OK * 100 / Q_TOT))
echo ""
echo -e "  Correct / Правильно: ${BOLD}${Q_OK} / ${Q_TOT}${NC}  (${Q_PCT}%)"
echo -ne "  Grade / Оцінка: "
if   [[ $Q_PCT -ge 87 ]]; then echo -e "${BOLD}${GREEN}Excellent / Відмінно 🏆${NC}"
elif [[ $Q_PCT -ge 70 ]]; then echo -e "${BOLD}${CYAN}Good / Добре 👍${NC}"
elif [[ $Q_PCT -ge 53 ]]; then echo -e "${BOLD}${YELLOW}Satisfactory / Задовільно 😐${NC}"
else                           echo -e "${BOLD}${RED}Review material / Повторіть матеріал 📖${NC}"; fi
pause

# ═══════════════════════════════════════════════════════════════════
#   PART 2 — AWS RESOURCE VERIFICATION / ПЕРЕВІРКА РЕСУРСІВ
# ═══════════════════════════════════════════════════════════════════

banner "PART 2 / ЧАСТИНА 2 — AWS Resource Verification"
echo ""
echo -e "  ${CYAN}Enter resource IDs/names created during Labs 5 & 6.${NC}"
echo -e "  ${CYAN}Введіть ID/імена ресурсів створених під час занять 5 і 6.${NC}"
echo ""

read -rp "  VPC ID                 (e.g. vpc-0abc1234):            " I_VPC
read -rp "  RDS Instance ID        (e.g. lab5-mysql):              " I_RDS
read -rp "  RDS Parameter Group    (e.g. lab5-mysql-params):       " I_PG
read -rp "  DB Subnet Group        (e.g. lab5-db-subnet-group):    " I_DBSG
read -rp "  EC2 Security Group ID  (e.g. sg-0abc1234):             " I_EC2_SG
read -rp "  RDS Security Group ID  (e.g. sg-0def5678):             " I_RDS_SG
read -rp "  ALB ARN or name        (e.g. lab5-alb):                " I_ALB
read -rp "  Target Group ARN       (e.g. arn:aws:elasticloadbala):  " I_TG
read -rp "  ASG name               (e.g. lab5-asg):                " I_ASG
read -rp "  Launch Template ID     (e.g. lt-0abc1234):             " I_LT

section "Running checks / Виконую перевірки..."
echo ""

# ── VPC ──────────────────────────────────────────────────────────────
chk "VPC exists / існує" "$I_VPC" \
  "aws ec2 describe-vpcs --vpc-ids '${I_VPC}' --query 'Vpcs[0].VpcId' --output text"

if [[ -n "$I_VPC" ]]; then
  # Check 4 subnets
  SUB_COUNT=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=${I_VPC}" \
    --query 'length(Subnets)' --output text 2>/dev/null)
  A_TOT=$((A_TOT+1))
  if [[ "$SUB_COUNT" -ge 4 ]]; then
    ok "VPC: ${BOLD}${SUB_COUNT}${NC} subnets (public + private) ✨"; A_OK=$((A_OK+1))
  elif [[ "$SUB_COUNT" -ge 2 ]]; then
    warn "VPC: ${BOLD}${SUB_COUNT}${NC} subnets — expected 4 (2 public + 2 private)"
  else
    fail "VPC: Only ${BOLD}${SUB_COUNT:-0}${NC} subnet(s) found — expected 4"
    hint "Create: pub-a, pub-b, priv-a, priv-b subnets in 2 different AZs"
  fi

  # Check public vs private subnets
  PUB_COUNT=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=${I_VPC}" "Name=map-public-ip-on-launch,Values=true" \
    --query 'length(Subnets)' --output text 2>/dev/null)
  A_TOT=$((A_TOT+1))
  if [[ "$PUB_COUNT" -eq 2 ]]; then
    ok "VPC: Exactly 2 public subnets (auto-assign IP) ✨"; A_OK=$((A_OK+1))
  else
    fail "VPC: ${BOLD}${PUB_COUNT:-0}${NC} public subnets — expected 2 (private subnets must NOT have public IP)"
    hint "Only pub-a and pub-b should have --map-public-ip-on-launch"
  fi
fi

echo ""

# ── RDS ──────────────────────────────────────────────────────────────
chk "RDS instance / інстанс" "$I_RDS" \
  "aws rds describe-db-instances --db-instance-identifier '${I_RDS}' --query 'DBInstances[0].DBInstanceIdentifier' --output text"

if [[ -n "$I_RDS" ]]; then
  RDS_STATUS=$(aws rds describe-db-instances \
    --db-instance-identifier "$I_RDS" \
    --query 'DBInstances[0].DBInstanceStatus' --output text 2>/dev/null)
  RDS_PUBLIC=$(aws rds describe-db-instances \
    --db-instance-identifier "$I_RDS" \
    --query 'DBInstances[0].PubliclyAccessible' --output text 2>/dev/null)
  RDS_BACKUP=$(aws rds describe-db-instances \
    --db-instance-identifier "$I_RDS" \
    --query 'DBInstances[0].BackupRetentionPeriod' --output text 2>/dev/null)
  RDS_STORAGE=$(aws rds describe-db-instances \
    --db-instance-identifier "$I_RDS" \
    --query 'DBInstances[0].StorageType' --output text 2>/dev/null)
  RDS_AUTOSCALE=$(aws rds describe-db-instances \
    --db-instance-identifier "$I_RDS" \
    --query 'DBInstances[0].MaxAllocatedStorage' --output text 2>/dev/null)
  RDS_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier "$I_RDS" \
    --query 'DBInstances[0].Endpoint.Address' --output text 2>/dev/null)

  # Status
  A_TOT=$((A_TOT+1))
  if [[ "$RDS_STATUS" == "available" ]]; then
    ok "RDS: Status ${BOLD}available${NC} ✨  Endpoint: ${BOLD}${RDS_ENDPOINT}${NC}"; A_OK=$((A_OK+1))
  elif [[ "$RDS_STATUS" == "creating" || "$RDS_STATUS" == "backing-up" ]]; then
    warn "RDS: Status ${BOLD}${RDS_STATUS}${NC} — still starting, re-check in a few minutes"
    A_TOT=$((A_TOT-1)) # don't penalize for timing
  else
    fail "RDS: Status ${BOLD}${RDS_STATUS:-unknown}${NC} — expected available"
  fi

  # Not publicly accessible
  A_TOT=$((A_TOT+1))
  if [[ "$RDS_PUBLIC" == "False" || "$RDS_PUBLIC" == "false" ]]; then
    ok "RDS: Not publicly accessible — private only ✨  (best practice!)"; A_OK=$((A_OK+1))
  else
    fail "RDS: ${BOLD}Publicly accessible!${NC} — should be --no-publicly-accessible for security"
    hint "Modify: aws rds modify-db-instance --db-instance-identifier $I_RDS --no-publicly-accessible"
  fi

  # Backup retention
  A_TOT=$((A_TOT+1))
  if [[ "$RDS_BACKUP" -ge 1 ]]; then
    ok "RDS: Backup retention = ${BOLD}${RDS_BACKUP}${NC} days ✨"; A_OK=$((A_OK+1))
  else
    fail "RDS: Backup retention = ${BOLD}${RDS_BACKUP:-0}${NC} days — expected ≥ 1"
    hint "Add: --backup-retention-period 7"
  fi

  # Storage autoscaling
  A_TOT=$((A_TOT+1))
  if [[ -n "$RDS_AUTOSCALE" && "$RDS_AUTOSCALE" != "None" && "$RDS_AUTOSCALE" -gt 20 ]]; then
    ok "RDS: Storage autoscaling enabled / увімкнено → max ${BOLD}${RDS_AUTOSCALE}${NC} GB ✨"; A_OK=$((A_OK+1))
  else
    fail "RDS: Storage autoscaling not configured (MaxAllocatedStorage: ${RDS_AUTOSCALE:-none})"
    hint "Add: --max-allocated-storage 100"
  fi
fi

echo ""

# ── RDS Parameter Group ───────────────────────────────────────────────
chk "RDS Parameter Group" "$I_PG" \
  "aws rds describe-db-parameter-groups --db-parameter-group-name '${I_PG}' --query 'DBParameterGroups[0].DBParameterGroupName' --output text"

if [[ -n "$I_PG" ]]; then
  # Check if custom (not default)
  PG_FAMILY=$(aws rds describe-db-parameter-groups \
    --db-parameter-group-name "$I_PG" \
    --query 'DBParameterGroups[0].DBParameterGroupFamily' --output text 2>/dev/null)
  A_TOT=$((A_TOT+1))
  if [[ "$PG_FAMILY" == "mysql8.0" || "$PG_FAMILY" == "mysql"* ]]; then
    ok "Parameter Group: family ${BOLD}${PG_FAMILY}${NC} ✨"; A_OK=$((A_OK+1))
  else
    fail "Parameter Group: family ${BOLD}${PG_FAMILY:-?}${NC} — expected mysql8.0"
  fi

  # Check slow_query_log param
  SL_VAL=$(aws rds describe-db-parameters \
    --db-parameter-group-name "$I_PG" \
    --query "Parameters[?ParameterName=='slow_query_log'].ParameterValue" \
    --output text 2>/dev/null)
  A_TOT=$((A_TOT+1))
  if [[ "$SL_VAL" == "1" ]]; then
    ok "Parameter Group: slow_query_log = ${BOLD}1${NC} (enabled) ✨"; A_OK=$((A_OK+1))
  else
    fail "Parameter Group: slow_query_log = ${BOLD}${SL_VAL:-not set}${NC} — expected 1"
    hint "Modify parameter group: slow_query_log=1, long_query_time=2"
  fi
fi

echo ""

# ── DB Subnet Group ───────────────────────────────────────────────────
chk "DB Subnet Group" "$I_DBSG" \
  "aws rds describe-db-subnet-groups --db-subnet-group-name '${I_DBSG}' --query 'DBSubnetGroups[0].DBSubnetGroupName' --output text"

if [[ -n "$I_DBSG" ]]; then
  DBSG_STATUS=$(aws rds describe-db-subnet-groups \
    --db-subnet-group-name "$I_DBSG" \
    --query 'DBSubnetGroups[0].SubnetGroupStatus' --output text 2>/dev/null)
  DBSG_COUNT=$(aws rds describe-db-subnet-groups \
    --db-subnet-group-name "$I_DBSG" \
    --query 'length(DBSubnetGroups[0].Subnets)' --output text 2>/dev/null)
  DBSG_AZS=$(aws rds describe-db-subnet-groups \
    --db-subnet-group-name "$I_DBSG" \
    --query 'DBSubnetGroups[0].Subnets[*].SubnetAvailabilityZone.Name' \
    --output text 2>/dev/null | tr '\t' ' ')

  A_TOT=$((A_TOT+1))
  if [[ "$DBSG_STATUS" == "Complete" && "$DBSG_COUNT" -ge 2 ]]; then
    ok "DB Subnet Group: ${BOLD}${DBSG_COUNT}${NC} subnets, AZs: ${BOLD}${DBSG_AZS}${NC} ✨"; A_OK=$((A_OK+1))
  else
    fail "DB Subnet Group: ${BOLD}${DBSG_COUNT:-0}${NC} subnets (status: ${DBSG_STATUS}) — expected ≥2"
  fi
fi

echo ""

# ── Security Groups ───────────────────────────────────────────────────
chk "EC2 Security Group" "$I_EC2_SG" \
  "aws ec2 describe-security-groups --group-ids '${I_EC2_SG}' --query 'SecurityGroups[0].GroupId' --output text"

chk "RDS Security Group" "$I_RDS_SG" \
  "aws ec2 describe-security-groups --group-ids '${I_RDS_SG}' --query 'SecurityGroups[0].GroupId' --output text"

if [[ -n "$I_RDS_SG" ]]; then
  # Check that RDS SG allows port 3306 from EC2 SG (not 0.0.0.0/0)
  RDS_SG_SOURCE=$(aws ec2 describe-security-groups \
    --group-ids "$I_RDS_SG" \
    --query "SecurityGroups[0].IpPermissions[?FromPort==\`3306\`].UserIdGroupPairs[0].GroupId" \
    --output text 2>/dev/null)
  RDS_SG_CIDR=$(aws ec2 describe-security-groups \
    --group-ids "$I_RDS_SG" \
    --query "SecurityGroups[0].IpPermissions[?FromPort==\`3306\`].IpRanges[0].CidrIp" \
    --output text 2>/dev/null)

  A_TOT=$((A_TOT+1))
  if [[ -n "$RDS_SG_SOURCE" && "$RDS_SG_SOURCE" != "None" ]]; then
    ok "RDS SG: port 3306 allowed from SG ${BOLD}${RDS_SG_SOURCE}${NC} (SG-to-SG rule ✨ best practice!)"
    A_OK=$((A_OK+1))
  elif [[ "$RDS_SG_CIDR" == "0.0.0.0/0" ]]; then
    fail "RDS SG: port 3306 open to ${BOLD}0.0.0.0/0${NC} — should use SG-to-SG reference, not CIDR!"
    hint "Use --source-group \$EC2_SG instead of --cidr 0.0.0.0/0"
  else
    fail "RDS SG: no rule for port 3306 found"
    hint "Authorize port 3306 from EC2 Security Group"
  fi
fi

echo ""

# ── ALB ───────────────────────────────────────────────────────────────
# Resolve ARN by name if needed
if [[ -n "$I_ALB" && ! "$I_ALB" == arn:* ]]; then
  I_ALB_ARN=$(aws elbv2 describe-load-balancers \
    --names "$I_ALB" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null)
else
  I_ALB_ARN="$I_ALB"
fi

chk "ALB exists / існує" "${I_ALB}" \
  "aws elbv2 describe-load-balancers --load-balancer-arns '${I_ALB_ARN}' --query 'LoadBalancers[0].LoadBalancerName' --output text"

if [[ -n "$I_ALB_ARN" ]]; then
  ALB_SCHEME=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns "$I_ALB_ARN" \
    --query 'LoadBalancers[0].Scheme' --output text 2>/dev/null)
  ALB_STATE=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns "$I_ALB_ARN" \
    --query 'LoadBalancers[0].State.Code' --output text 2>/dev/null)
  ALB_DNS=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns "$I_ALB_ARN" \
    --query 'LoadBalancers[0].DNSName' --output text 2>/dev/null)
  ALB_AZ_COUNT=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns "$I_ALB_ARN" \
    --query 'length(LoadBalancers[0].AvailabilityZones)' --output text 2>/dev/null)

  A_TOT=$((A_TOT+1))
  if [[ "$ALB_STATE" == "active" ]]; then
    ok "ALB: State ${BOLD}active${NC} | Scheme: ${BOLD}${ALB_SCHEME}${NC} | AZs: ${BOLD}${ALB_AZ_COUNT}${NC} ✨"; A_OK=$((A_OK+1))
    info "ALB DNS: $ALB_DNS"
  elif [[ "$ALB_STATE" == "provisioning" ]]; then
    warn "ALB: Still ${BOLD}provisioning${NC} — wait a few minutes"
  else
    fail "ALB: State ${BOLD}${ALB_STATE:-unknown}${NC} — expected active"
  fi

  A_TOT=$((A_TOT+1))
  if [[ "$ALB_AZ_COUNT" -ge 2 ]]; then
    ok "ALB: Deployed in ${BOLD}${ALB_AZ_COUNT}${NC} AZs (HA requirement) ✨"; A_OK=$((A_OK+1))
  else
    fail "ALB: Only ${BOLD}${ALB_AZ_COUNT:-1}${NC} AZ — must span at least 2 AZs!"
    hint "ALB needs subnets in 2+ different AZs"
  fi

  # Check Listener
  LISTENER_COUNT=$(aws elbv2 describe-listeners \
    --load-balancer-arn "$I_ALB_ARN" \
    --query 'length(Listeners)' --output text 2>/dev/null)
  A_TOT=$((A_TOT+1))
  if [[ "$LISTENER_COUNT" -ge 1 ]]; then
    LISTENER_PORT=$(aws elbv2 describe-listeners \
      --load-balancer-arn "$I_ALB_ARN" \
      --query 'Listeners[0].Port' --output text 2>/dev/null)
    ok "ALB: ${BOLD}${LISTENER_COUNT}${NC} Listener(s) configured, port ${BOLD}${LISTENER_PORT}${NC} ✨"; A_OK=$((A_OK+1))
  else
    fail "ALB: No Listeners configured — traffic won't be routed"
    hint "Create listener: aws elbv2 create-listener --port 80 --protocol HTTP ..."
  fi
fi

echo ""

# ── Target Group ─────────────────────────────────────────────────────
chk "Target Group" "$I_TG" \
  "aws elbv2 describe-target-groups --target-group-arns '${I_TG}' --query 'TargetGroups[0].TargetGroupName' --output text"

if [[ -n "$I_TG" ]]; then
  TG_HCK_PATH=$(aws elbv2 describe-target-groups \
    --target-group-arns "$I_TG" \
    --query 'TargetGroups[0].HealthCheckPath' --output text 2>/dev/null)
  TG_HEALTHY=$(aws elbv2 describe-target-health \
    --target-group-arn "$I_TG" \
    --query 'length(TargetHealthDescriptions[?TargetHealth.State==`healthy`])' \
    --output text 2>/dev/null)
  TG_TOTAL=$(aws elbv2 describe-target-health \
    --target-group-arn "$I_TG" \
    --query 'length(TargetHealthDescriptions)' \
    --output text 2>/dev/null)

  A_TOT=$((A_TOT+1))
  if [[ "$TG_HEALTHY" -ge 1 ]]; then
    ok "Target Group: ${BOLD}${TG_HEALTHY} healthy${NC} / ${TG_TOTAL} total targets ✨ (path: ${TG_HCK_PATH})"
    A_OK=$((A_OK+1))
  else
    warn "Target Group: ${BOLD}${TG_HEALTHY:-0} healthy${NC} / ${TG_TOTAL} total — instances may still be starting"
    hint "Wait 60-120 seconds for instances to pass health checks, then re-run"
  fi
fi

echo ""

# ── Launch Template ───────────────────────────────────────────────────
chk "Launch Template" "$I_LT" \
  "aws ec2 describe-launch-templates --launch-template-ids '${I_LT}' --query 'LaunchTemplates[0].LaunchTemplateId' --output text"

if [[ -n "$I_LT" ]]; then
  LT_VER=$(aws ec2 describe-launch-templates \
    --launch-template-ids "$I_LT" \
    --query 'LaunchTemplates[0].LatestVersionNumber' --output text 2>/dev/null)
  A_TOT=$((A_TOT+1))
  if [[ -n "$LT_VER" ]]; then
    ok "Launch Template: latest version ${BOLD}${LT_VER}${NC} ✨"; A_OK=$((A_OK+1))
  else
    fail "Launch Template: could not determine version"
  fi
fi

echo ""

# ── Auto Scaling Group ────────────────────────────────────────────────
chk "Auto Scaling Group" "$I_ASG" \
  "aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names '${I_ASG}' --query 'AutoScalingGroups[0].AutoScalingGroupName' --output text"

if [[ -n "$I_ASG" ]]; then
  ASG_MIN=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$I_ASG" \
    --query 'AutoScalingGroups[0].MinSize' --output text 2>/dev/null)
  ASG_MAX=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$I_ASG" \
    --query 'AutoScalingGroups[0].MaxSize' --output text 2>/dev/null)
  ASG_HC=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$I_ASG" \
    --query 'AutoScalingGroups[0].HealthCheckType' --output text 2>/dev/null)
  ASG_TGS=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$I_ASG" \
    --query 'length(AutoScalingGroups[0].TargetGroupARNs)' --output text 2>/dev/null)
  ASG_IN_SERVICE=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$I_ASG" \
    --query 'length(AutoScalingGroups[0].Instances[?LifecycleState==`InService`])' \
    --output text 2>/dev/null)

  # Min >= 2
  A_TOT=$((A_TOT+1))
  if [[ "$ASG_MIN" -ge 2 ]]; then
    ok "ASG: min=${BOLD}${ASG_MIN}${NC} max=${BOLD}${ASG_MAX}${NC} InService=${BOLD}${ASG_IN_SERVICE}${NC} ✨"; A_OK=$((A_OK+1))
  else
    fail "ASG: min=${BOLD}${ASG_MIN:-?}${NC} — expected ≥2 for High Availability"
    hint "min-size=2 ensures HA: one instance per AZ minimum"
  fi

  # Health check type ELB
  A_TOT=$((A_TOT+1))
  if [[ "$ASG_HC" == "ELB" ]]; then
    ok "ASG: HealthCheckType = ${BOLD}ELB${NC} ✨ (monitors app, not just VM)"; A_OK=$((A_OK+1))
  else
    fail "ASG: HealthCheckType = ${BOLD}${ASG_HC}${NC} — expected ELB (not EC2)"
    hint "Use --health-check-type ELB so ASG replaces instances when app fails"
  fi

  # Target Group attached
  A_TOT=$((A_TOT+1))
  if [[ "$ASG_TGS" -ge 1 ]]; then
    ok "ASG: ${BOLD}${ASG_TGS}${NC} Target Group(s) attached — ALB integration ✨"; A_OK=$((A_OK+1))
  else
    fail "ASG: No Target Groups attached — ALB won't route traffic to ASG instances"
    hint "Add --target-group-arns when creating ASG"
  fi

  # Scaling Policy
  POLICY_COUNT=$(aws autoscaling describe-policies \
    --auto-scaling-group-name "$I_ASG" \
    --query 'length(ScalingPolicies)' --output text 2>/dev/null)
  A_TOT=$((A_TOT+1))
  if [[ "$POLICY_COUNT" -ge 1 ]]; then
    POLICY_NAME=$(aws autoscaling describe-policies \
      --auto-scaling-group-name "$I_ASG" \
      --query 'ScalingPolicies[0].PolicyName' --output text 2>/dev/null)
    ok "ASG: ${BOLD}${POLICY_COUNT}${NC} scaling policy(ies) — first: ${BOLD}${POLICY_NAME}${NC} ✨"; A_OK=$((A_OK+1))
  else
    fail "ASG: No scaling policies configured — ASG won't auto-scale"
    hint "Create a TargetTrackingScaling policy (step 13 in README)"
  fi
fi

pause

# ═══════════════════════════════════════════════════════════════════
#   PART 3 — PRACTICAL CHALLENGE / ПРАКТИЧНЕ ЗАВДАННЯ
# ═══════════════════════════════════════════════════════════════════

banner "PART 3 / ЧАСТИНА 3 — Live Practical Challenge"
echo ""
echo -e "  ${CYAN}Choose a task to demonstrate live / Виберіть завдання для демонстрації:${NC}"
echo ""
echo -e "  ${BOLD}A)${NC} Scale OUT to 4 instances, verify all healthy in Target Group, scale back to 2"
echo -e "     ${DIM}Масштабуйте до 4, перевірте що всі healthy в Target Group, поверніть до 2${NC}"
echo ""
echo -e "  ${BOLD}B)${NC} Query ALB DNS and show 2+ different Instance IDs in responses (balancing demo)"
echo -e "     ${DIM}Запросіть ALB DNS і покажіть 2+ різних Instance ID у відповідях${NC}"
echo ""
echo -e "  ${BOLD}C)${NC} Connect to RDS and run: SHOW DATABASES; SHOW TABLES; SELECT * FROM cadets;"
echo -e "     ${DIM}Підключіться до RDS і виконайте: SHOW DATABASES; SHOW TABLES; SELECT...${NC}"
echo ""
read -rp "  Choose / Виберіть (A/B/C): " CHOICE

case "${CHOICE^^}" in
  A)
    echo -e "\n  ${YELLOW}⚡  Scale to 4, then back to 2. Press Enter when done.${NC}"
    pause
    if [[ -n "$I_ASG" && -n "$I_TG" ]]; then
      CUR_DES=$(aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-names "$I_ASG" \
        --query 'AutoScalingGroups[0].DesiredCapacity' --output text 2>/dev/null)
      HEALTHY=$(aws elbv2 describe-target-health \
        --target-group-arn "$I_TG" \
        --query 'length(TargetHealthDescriptions[?TargetHealth.State==`healthy`])' \
        --output text 2>/dev/null)
      A_TOT=$((A_TOT+1))
      echo -e "  Current desired: ${BOLD}${CUR_DES}${NC}  |  Healthy targets: ${BOLD}${HEALTHY}${NC}"
      if [[ "$HEALTHY" -ge 2 ]]; then
        ok "Challenge A complete: ${BOLD}${HEALTHY}${NC} healthy targets in Target Group ✨"; A_OK=$((A_OK+1))
      else
        fail "Challenge A: only ${BOLD}${HEALTHY:-0}${NC} healthy targets — scale and wait for health checks"
      fi
    fi ;;
  B)
    echo -e "\n  ${YELLOW}⚡  We'll send 6 curl requests to the ALB and check instance distribution.${NC}"
    if [[ -n "$I_ALB_ARN" ]]; then
      ALB_DNS_LIVE=$(aws elbv2 describe-load-balancers \
        --load-balancer-arns "$I_ALB_ARN" \
        --query 'LoadBalancers[0].DNSName' --output text 2>/dev/null)
      echo ""
      echo -e "  Sending 6 requests to: ${BOLD}http://${ALB_DNS_LIVE}${NC}"
      echo ""
      declare -A INST_HITS
      for i in $(seq 1 6); do
        IPAGE=$(curl -s --connect-timeout 5 "http://${ALB_DNS_LIVE}" 2>/dev/null)
        IID=$(echo "$IPAGE" | grep -oP '(?<=Instance ID</span> )i-[a-z0-9]+' | head -1)
        [[ -z "$IID" ]] && IID="(no response / no response)"
        INST_HITS["$IID"]=$((${INST_HITS["$IID"]:-0}+1))
        echo -e "  Request $i → ${BOLD}${IID}${NC}"
        sleep 1
      done
      UNIQUE_COUNT=${#INST_HITS[@]}
      A_TOT=$((A_TOT+1))
      echo ""
      if [[ "$UNIQUE_COUNT" -ge 2 ]]; then
        ok "Challenge B: ${BOLD}${UNIQUE_COUNT}${NC} different instances served requests — ALB is balancing! ✨"
        A_OK=$((A_OK+1))
      else
        warn "Challenge B: only 1 instance responded — check if 2+ instances are healthy in TG"
      fi
    else
      warn "ALB ARN not provided — cannot run live test"
    fi ;;
  C)
    echo -e "\n  ${YELLOW}⚡  Connect to RDS and run the SQL commands. Press Enter when done.${NC}"
    if [[ -n "$I_RDS" ]]; then
      EP=$(aws rds describe-db-instances \
        --db-instance-identifier "$I_RDS" \
        --query 'DBInstances[0].Endpoint.Address' --output text 2>/dev/null)
      echo ""
      echo -e "  Command / Команда:"
      echo -e "  ${CYAN}mysql -h ${EP} -P 3306 -u admin -p labdb${NC}"
      echo ""
      echo -e "  Then run / Виконайте:"
      echo -e "  ${CYAN}SHOW TABLES; SELECT * FROM cadets; EXIT;${NC}"
      pause
      read -rp "  Did you successfully connect and run queries? / Підключились і виконали запити? (yes/так): " CONN_OK
      A_TOT=$((A_TOT+1))
      if [[ "$CONN_OK" =~ ^(yes|так|y|t)$ ]]; then
        ok "Challenge C: RDS connection and SQL queries completed ✨"; A_OK=$((A_OK+1))
      else
        fail "Challenge C: Connection not confirmed"
        hint "Ensure mysql client is installed and RDS SG allows port 3306 from your EC2/CloudShell"
      fi
    fi ;;
  *)
    warn "No valid choice — skipping challenge / Немає вибору"
esac

pause

# ═══════════════════════════════════════════════════════════════════
#   FINAL RESULTS / ФІНАЛЬНІ РЕЗУЛЬТАТИ
# ═══════════════════════════════════════════════════════════════════

clear
banner "🏁  FINAL RESULTS / ФІНАЛЬНІ РЕЗУЛЬТАТИ"
echo ""

TOTAL=$((Q_OK + A_OK))
MAX=$((Q_TOT + A_TOT))
[[ $MAX -eq 0 ]] && MAX=1
PCT=$((TOTAL * 100 / MAX))

echo -e "  ${BOLD}Student / Курсант:${NC}  ${STUDENT}"
echo -e "  ${BOLD}Date / Дата:${NC}        $(date '+%d.%m.%Y %H:%M')"
echo ""
echo -e "  ┌──────────────────────────────────────────────────────┐"
echo -e "  │  Theory quiz / Теоретичний квіз:                     │"
echo -e "  │    ${BOLD}${Q_OK} / ${Q_TOT}${NC} correct / правильно (Lab5: 7q, Lab6: 8q)  │"
echo -e "  │                                                      │"
echo -e "  │  AWS resource checks / Перевірка ресурсів:           │"
echo -e "  │    ${BOLD}${A_OK} / ${A_TOT}${NC} checks passed / перевірок пройдено     │"
echo -e "  │  ──────────────────────────────────────────────────  │"
echo -e "  │  ${BOLD}TOTAL / РАЗОМ:  ${TOTAL} / ${MAX}  (${PCT}%)${NC}                  │"
echo -e "  └──────────────────────────────────────────────────────┘"
echo ""

if   [[ $PCT -ge 90 ]]; then GRADE="Excellent / Відмінно 🏆";            COL=$GREEN
elif [[ $PCT -ge 75 ]]; then GRADE="Good / Добре 🥈";                    COL=$CYAN
elif [[ $PCT -ge 60 ]]; then GRADE="Satisfactory / Задовільно 🥉";       COL=$YELLOW
else                          GRADE="Review needed / Повторіть матеріал 📖"; COL=$RED; fi

echo -e "  ${BOLD}${COL}${GRADE}${NC}"
echo ""

if [[ $PCT -lt 75 ]]; then
  echo -e "  ${DIM}Areas to review / Що повторити:${NC}"
  [[ $Q_OK -lt 10 ]] && info "README theory sections — RDS components (steps 1–8), ALB+ASG (steps 9–15)"
  [[ $A_OK -lt $((A_TOT * 3 / 4)) ]] && info "Verify resource creation steps in README and re-run failed checks"
fi

echo ""
echo -e "  ${BOLD}${CYAN}── Further reading / Для поглибленого вивчення ───────────────${NC}"
echo -e "  ${DIM}📘 RDS User Guide:        https://docs.aws.amazon.com/rds/${NC}"
echo -e "  ${DIM}📘 RDS Parameter Groups:  https://docs.aws.amazon.com/rds/latest/userguide/USER_WorkingWithParamGroups.html${NC}"
echo -e "  ${DIM}📘 ALB User Guide:        https://docs.aws.amazon.com/elasticloadbalancing/${NC}"
echo -e "  ${DIM}📘 Auto Scaling Guide:    https://docs.aws.amazon.com/autoscaling/${NC}"
echo ""

RESULT="lab5_result_$(echo "$STUDENT" | tr ' ' '_')_$(date +%Y%m%d_%H%M).txt"
cat << EOF > "$RESULT"
AWS Academy — Lab 5 Result / Результат
=========================================
Student / Курсант : $STUDENT
Date / Дата       : $(date '+%d.%m.%Y %H:%M')
Quiz              : $Q_OK / $Q_TOT
AWS checks        : $A_OK / $A_TOT
Total / Разом     : $TOTAL / $MAX  (${PCT}%)
Grade / Оцінка    : $GRADE

Resources / Ресурси:
  VPC         : $I_VPC
  RDS         : $I_RDS
  Param Group : $I_PG
  DB SubnetGr : $I_DBSG
  EC2 SG      : $I_EC2_SG
  RDS SG      : $I_RDS_SG
  ALB         : $I_ALB
  Target Group: $I_TG
  ASG         : $I_ASG
  LT          : $I_LT
EOF

ok "Result saved / Результат збережено: ${BOLD}${RESULT}${NC}"
echo ""
echo -e "${BOLD}${MAGENTA}  Дякуємо! / Thank you!  Слава Україні! 🇺🇦${NC}"
echo ""
