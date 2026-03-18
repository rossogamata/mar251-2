#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  AWS Academy — Lab 4 Self-Assessment / Самоперевірка            ║
# ║  Storage · Databases · Auto Scaling · Monitoring                ║
# ║  Зберігання · Бази даних · Масштабування · Моніторинг           ║
# ╚══════════════════════════════════════════════════════════════════╝

# ── Colors / Кольори ────────────────────────────────────────────────
RED='\033[0;31m';  GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m';  MAGENTA='\033[0;35m'
BOLD='\033[1m';    DIM='\033[2m';      NC='\033[0m'

# ── Score counters ───────────────────────────────────────────────────
Q_OK=0; Q_TOT=0; A_OK=0; A_TOT=0

# ── Helpers ─────────────────────────────────────────────────────────
ok()   { echo -e "  ${GREEN}✅  $1${NC}"; }
fail() { echo -e "  ${RED}❌  $1${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️   $1${NC}"; }
info() { echo -e "  ${BLUE}ℹ️   $1${NC}"; }
hint() { echo -e "  ${DIM}     💡 $1${NC}"; }

banner() {
  echo ""
  echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
  printf "${BOLD}${BLUE}║${NC}  %-56s${BOLD}${BLUE}║${NC}\n" "$1"
  echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
}

section() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}  $1${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

pause() {
  echo ""
  read -rp "$(echo -e "  ${MAGENTA}▶  Press Enter / Натисніть Enter...${NC}")" _
}

# ── Multiple choice / Множинний вибір ───────────────────────────────
mcq() {
  local q="$1" correct="$2" hint_txt="$3"; shift 3; local opts=("$@")
  echo ""; echo -e "${BOLD}${YELLOW}❓  ${q}${NC}"; echo ""
  for i in "${!opts[@]}"; do
    echo -e "    ${BOLD}$((i+1)))${NC}  ${opts[$i]}"
  done
  echo ""
  read -rp "$(echo -e "  ${BOLD}Answer / Відповідь (1-${#opts[@]}): ${NC}")" ans
  Q_TOT=$((Q_TOT+1))
  if [[ "$ans" == "$correct" ]]; then
    ok "Correct / Правильно! 🎉"; Q_OK=$((Q_OK+1))
  else
    fail "Wrong. Answer: ${BOLD}${correct}) ${opts[$((correct-1))]}${NC}"
    hint "$hint_txt"
  fi
}

# ── AWS check / Перевірка AWS ресурсу ────────────────────────────────
chk() {
  local label="$1" rid="$2" cmd="$3"
  A_TOT=$((A_TOT+1))
  echo -ne "  Checking ${BOLD}${label}${NC}... "
  if [[ -z "$rid" || "$rid" == "None" || "$rid" == "null" || "$rid" == "n/a" ]]; then
    echo ""; fail "${label} — ID not provided"; return 1
  fi
  local r; r=$(eval "$cmd" 2>/dev/null)
  if [[ -n "$r" && "$r" != "None" && "$r" != "null" ]]; then
    echo ""; ok "${label}: ${BOLD}${rid}${NC}"; A_OK=$((A_OK+1)); return 0
  else
    echo ""; fail "${label}: not found or error"; return 1
  fi
}

# ═══════════════════════════════════════════════════════════════════
#                           START
# ═══════════════════════════════════════════════════════════════════
clear; echo ""
echo -e "${BOLD}${MAGENTA}"
cat << 'BANNER'
  ╔══════════════════════════════════════════════════════════════╗
  ║   AWS ACADEMY — LAB 4  ·  SELF-ASSESSMENT / САМОПЕРЕВІРКА   ║
  ║   Storage · Databases · Auto Scaling · Monitoring            ║
  ╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"
echo -e "  ${CYAN}Part 1: Theory quiz (15 questions).${NC}"
echo -e "  ${CYAN}Part 2: Live verification of your AWS resources.${NC}"
echo -e "  ${CYAN}Part 3: Practical challenge.${NC}"
echo ""
read -rp "  Full name / Ім'я та прізвище: " STUDENT
echo -e "\n  ${GREEN}Hello / Привіт, ${BOLD}${STUDENT}${NC}${GREEN}! Let's go! 🚀${NC}"

pause

# ═══════════════════════════════════════════════════════════════════
#   PART 1 — THEORY QUIZ / ЧАСТИНА 1 — ТЕОРЕТИЧНИЙ КВІЗ  (15 Qs)
# ═══════════════════════════════════════════════════════════════════

banner "PART 1 / ЧАСТИНА 1 — Theory Quiz  (15 questions)"

# ─── BLOCK A: STORAGE / ЗБЕРІГАННЯ ──────────────────────────────────
section "BLOCK A — Storage / Зберігання  (Q1–Q5)"

section "Q1 / З1 of 15 — S3 Storage Class"
mcq \
  "What is the correct order of S3 storage classes from most to least expensive (retrieval speed)? / Правильний порядок класів S3 від найдорожчого до найдешевшого?" \
  "2" \
  "STANDARD (instant) → STANDARD_IA (instant, infrequent) → GLACIER (minutes). Price drops with access speed. / STANDARD → STANDARD_IA → GLACIER. Ціна падає зі швидкістю доступу." \
  "GLACIER → STANDARD_IA → STANDARD" \
  "STANDARD → STANDARD_IA → GLACIER" \
  "STANDARD_IA → STANDARD → GLACIER" \
  "STANDARD → GLACIER → STANDARD_IA"

pause

section "Q2 / З2 of 15 — S3 Versioning"
mcq \
  "What happens to the old file when you overwrite an object in an S3 bucket with versioning ENABLED? / Що відбувається зі старим файлом при перезаписі об'єкта в бакеті з увімкненим версіонуванням?" \
  "3" \
  "Both old and new versions are preserved. Each gets a unique VersionId. You can restore any version. / Обидві версії зберігаються, кожна з унікальним VersionId. Можна відновити будь-яку." \
  "The old file is permanently deleted / Старий файл видаляється назавжди" \
  "The new file gets a different name / Новий файл отримує інше ім'я" \
  "Both versions are preserved with a unique VersionId / Обидві версії зберігаються з унікальним VersionId" \
  "The operation fails — overwriting is not allowed / Операція відхиляється — перезапис заборонено"

pause

section "Q3 / З3 of 15 — EBS vs S3"
mcq \
  "Which storage service would you choose to store the operating system disk of an EC2 instance? / Яке сховище вибрати для диску ОС EC2-інстансу?" \
  "1" \
  "EBS is block storage — works like a disk. S3 is object storage accessed via API/HTTP — cannot be used as a bootable OS disk. / EBS = блочне сховище як диск. S3 = об'єктне, не може бути завантажувальним диском." \
  "EBS — block storage, works like a physical disk / EBS — блочне, як фізичний диск" \
  "S3 — unlimited capacity, any data / S3 — безмежна ємність, будь-які дані" \
  "EFS — network file system / EFS — мережева файлова система" \
  "DynamoDB — fast key-value storage / DynamoDB — швидке сховище ключ-значення"

pause

section "Q4 / З4 of 15 — EBS Availability Zone Constraint"
mcq \
  "You created an EBS volume in us-east-1a. To which instance can you attach it? / Ви створили EBS в us-east-1a. До якого інстансу можна прикріпити?" \
  "2" \
  "EBS volumes are AZ-specific. They can only be attached to instances in the SAME AZ. To move across AZs — create a snapshot, then restore in the target AZ. / EBS прив'язаний до AZ. Для переміщення — snapshot → відновлення в іншій AZ." \
  "Any instance in the same region (us-east-1) / Будь-який в тому ж регіоні" \
  "Only an instance in us-east-1a / Тільки інстанс у us-east-1a" \
  "Any instance in the same VPC / Будь-який в тій же VPC" \
  "Any instance globally / Будь-який глобально"

pause

section "Q5 / З5 of 15 — S3 Lifecycle"
mcq \
  "What is the purpose of an S3 Lifecycle Policy? / Для чого призначена S3 Lifecycle Policy?" \
  "3" \
  "Lifecycle policy automatically transitions objects to cheaper storage classes or deletes them after N days — reducing costs without manual work. / Lifecycle автоматично переміщує об'єкти до дешевших класів або видаляє через N днів." \
  "To replicate objects to another region automatically / Реплікувати в інший регіон" \
  "To encrypt all objects at rest / Шифрувати всі об'єкти" \
  "To automatically move or expire objects to reduce costs / Автоматично переміщувати або видаляти для зниження витрат" \
  "To restrict access by IP address / Обмежити доступ по IP"

pause

# ─── BLOCK B: DATABASES / БАЗИ ДАНИХ ────────────────────────────────
section "BLOCK B — Databases / Бази даних  (Q6–Q10)"

section "Q6 / З6 of 15 — RDS vs DynamoDB"
mcq \
  "When would you choose DynamoDB over RDS? / Коли DynamoDB кращий за RDS?" \
  "4" \
  "DynamoDB = serverless NoSQL, horizontal scale, millisecond latency, flexible schema. Best for: high-throughput key-value, IoT, sessions. RDS = relational, SQL, ACID, complex queries. / DynamoDB: serverless NoSQL, гнучка схема. RDS: реляційна БД, SQL, складні запити." \
  "When you need complex SQL JOINs across many tables / Складні SQL JOIN між таблицями" \
  "When you need ACID transactions across multiple records / ACID транзакції між записами" \
  "When data has a rigid, well-defined schema / Жорстка, добре визначена схема" \
  "When you need millisecond latency and horizontal scaling at any load / Мілісекундна затримка і горизонтальне масштабування"

pause

section "Q7 / З7 of 15 — DynamoDB Key Types"
mcq \
  "In DynamoDB, what is the difference between a Partition Key (HASH) and Sort Key (RANGE)? / Різниця між Partition Key та Sort Key у DynamoDB?" \
  "2" \
  "Partition Key (HASH) distributes data across partitions — must be unique per item (alone) or per HASH value (with RANGE). Sort Key (RANGE) allows range queries within the same partition. / Partition Key розподіляє дані. Sort Key дозволяє діапазонні запити в межах розділу." \
  "Both keys together form the primary key; HASH alone must be unique / Обидва разом формують первинний ключ; HASH сам по собі унікальний" \
  "HASH determines storage node, RANGE enables range queries within that node / HASH визначає вузол, RANGE — запити діапазону в ньому" \
  "HASH is for numbers only, RANGE is for strings only / HASH тільки для чисел, RANGE тільки для рядків" \
  "They are interchangeable — both serve the same purpose / Вони взаємозамінні"

pause

section "Q8 / З8 of 15 — DynamoDB Scan vs Query"
mcq \
  "Why is DynamoDB 'scan' expensive for large tables? / Чому DynamoDB 'scan' дорогий для великих таблиць?" \
  "1" \
  "Scan reads EVERY item in the table regardless of the filter. For 1M items — 1M read capacity units consumed. Query uses the index and reads only matching partition. / Scan читає ВСЮ таблицю. Query використовує індекс і читає лише потрібний розділ." \
  "Scan reads every item in the table — consumes full read capacity / Читає всю таблицю — споживає всю потужність читання" \
  "Scan requires a special IAM permission that costs extra / Потребує спеціального IAM дозволу" \
  "Scan locks the table for other operations / Блокує таблицю для інших операцій" \
  "Scan is only available in PROVISIONED billing mode / Доступний тільки в PROVISIONED режимі"

pause

section "Q9 / З9 of 15 — RDS Multi-AZ"
mcq \
  "What does enabling Multi-AZ on RDS provide? / Що дає увімкнення Multi-AZ для RDS?" \
  "3" \
  "Multi-AZ keeps a synchronous standby replica in a different AZ. If the primary fails, RDS automatically fails over to the standby — typically < 2 minutes. No data loss. / Multi-AZ тримає синхронну репліку в іншій AZ. При збої — автоматичний failover < 2 хв." \
  "Better read performance through read replicas / Краща продуктивність читання через репліки" \
  "Distributing data across multiple database tables / Розподіл даних між таблицями" \
  "Automatic failover to a standby in another AZ / Автоматичний перехід на резерв в іншій AZ" \
  "Lower cost through distributed billing / Нижча вартість через розподілений білінг"

pause

section "Q10 / З10 of 15 — RDS vs Aurora"
mcq \
  "Which is a key advantage of Amazon Aurora over standard RDS MySQL? / Головна перевага Amazon Aurora над стандартним RDS MySQL?" \
  "2" \
  "Aurora uses a cloud-native storage layer shared across 6 copies in 3 AZs. Up to 5× faster than MySQL, auto-grows storage, and has native serverless option. / Aurora: хмарне сховище, 6 копій у 3 AZ, до 5× швидше MySQL, auto-grow." \
  "Aurora is always free of charge / Aurora завжди безкоштовна" \
  "Aurora is up to 5× faster and uses replicated cloud-native storage / До 5× швидше, реплікований хмарний рушій зберігання" \
  "Aurora supports only PostgreSQL, not MySQL / Підтримує тільки PostgreSQL" \
  "Aurora has no storage limits at all / Не має жодних обмежень сховища"

pause

# ─── BLOCK C: SCALING & MONITORING ─────────────────────────────────
section "BLOCK C — Auto Scaling & Monitoring  (Q11–Q15)"

section "Q11 / З11 of 15 — ASG min/max/desired"
mcq \
  "ASG is configured: min=1, max=5, desired=2. What happens when load spikes and needs 7 instances? / ASG: min=1, max=5, desired=2. Що станеться коли навантаження потребує 7 інстансів?" \
  "3" \
  "ASG enforces the max. It will scale to 5 (the max) — never beyond. To allow 7 instances, you must increase max first. / ASG дотримується max. Масштабується до 5 (max) — ніколи понад. Потрібно збільшити max." \
  "ASG launches all 7 needed instances / Запускає всі 7 потрібних інстансів" \
  "ASG stays at 2 and ignores the load / Залишається на 2 і ігнорує навантаження" \
  "ASG scales to maximum of 5 instances / Масштабується до максимуму 5 інстансів" \
  "ASG throws an error and stops scaling / Видає помилку і зупиняє масштабування"

pause

section "Q12 / З12 of 15 — Target Tracking vs Simple Scaling"
mcq \
  "Why is TargetTrackingScaling recommended over SimpleScaling for ASG? / Чому TargetTrackingScaling кращий за SimpleScaling для ASG?" \
  "1" \
  "TargetTracking automatically calculates how many instances to add/remove to reach the target metric value. SimpleScaling adds/removes a fixed number per alarm trigger — can overshoot or undershoot. / TargetTracking сам розраховує кількість. SimpleScaling = фіксований крок, може не влучити." \
  "Target Tracking automatically calculates scale steps to reach the target metric / Автоматично розраховує кроки для досягнення цільової метрики" \
  "Target Tracking is cheaper because it triggers fewer alarms / Дешевший, бо рідше спрацьовує" \
  "Target Tracking works with all AWS services, Simple only with EC2 / Працює з усіма сервісами" \
  "Target Tracking is the only type supported by Launch Templates / Єдиний тип що підтримується"

pause

section "Q13 / З13 of 15 — CloudWatch Namespace"
mcq \
  "What is a CloudWatch namespace and give an example? / Що таке CloudWatch namespace і наведіть приклад?" \
  "2" \
  "A namespace is a container that groups related metrics from one AWS service. AWS/EC2 contains EC2 metrics, AWS/RDS contains RDS metrics etc. Prevents metric name collisions between services. / Namespace групує метрики одного сервісу. AWS/EC2, AWS/RDS — запобігає конфліктам імен." \
  "A region-specific identifier for CloudWatch data / Регіональний ідентифікатор" \
  "A container grouping metrics from one service (e.g. AWS/EC2, AWS/RDS) / Контейнер метрик сервісу (AWS/EC2, AWS/RDS)" \
  "A time range for metric retention / Часовий діапазон зберігання метрик" \
  "An IAM permission set for CloudWatch access / Набір IAM дозволів"

pause

section "Q14 / З14 of 15 — CloudWatch Alarm States"
mcq \
  "A CloudWatch alarm is in INSUFFICIENT_DATA state. What does this mean? / Alarm у стані INSUFFICIENT_DATA. Що це означає?" \
  "3" \
  "INSUFFICIENT_DATA means not enough data points have been collected yet (e.g. resource just created, or metric reporting gap). OK = metric within threshold. ALARM = threshold breached. / INSUFFICIENT_DATA = ще не зібрано достатньо даних (ресурс тільки створено або пропуск метрики)." \
  "The alarm has fired and the threshold is breached / Алерт спрацював, поріг перевищено" \
  "The metric value is exactly at the threshold / Метрика рівно на порозі" \
  "Not enough data points collected yet / Ще не зібрано достатньо точок даних" \
  "The alarm configuration is invalid / Конфігурація алерту некоректна"

pause

section "Q15 / З15 of 15 — SNS + CloudWatch Integration"
mcq \
  "How does SNS integrate with CloudWatch alarms? / Як SNS інтегрується з CloudWatch alarm?" \
  "4" \
  "CloudWatch alarm action points to an SNS Topic ARN. When alarm transitions (OK→ALARM or ALARM→OK), it publishes a message to the topic. SNS then delivers to all subscribers (email, SMS, Lambda). / Alarm дія → SNS Topic ARN. При спрацюванні публікується повідомлення → доставляється підписникам." \
  "SNS polls CloudWatch every minute to check alarm state / SNS опитує CloudWatch кожну хвилину" \
  "You must manually trigger SNS after each alarm / Треба вручну запустити SNS після alarm" \
  "SNS stores CloudWatch logs and sends reports weekly / SNS зберігає логи і звітує щотижня" \
  "CloudWatch sends to SNS Topic ARN on alarm state change; SNS delivers to subscribers / CloudWatch надсилає в SNS Topic; SNS доставляє підписникам"

pause

# ── Quiz summary ─────────────────────────────────────────────────────
section "Quiz Results / Результати квізу"
echo ""
Q_PCT=$((Q_OK * 100 / Q_TOT))
echo -e "  Correct / Правильно: ${BOLD}${Q_OK} / ${Q_TOT}${NC}  (${Q_PCT}%)"
echo -ne "  Grade / Оцінка: "
if   [[ $Q_PCT -ge 87 ]]; then echo -e "${BOLD}${GREEN}Excellent / Відмінно 🏆${NC}"
elif [[ $Q_PCT -ge 70 ]]; then echo -e "${BOLD}${CYAN}Good / Добре 👍${NC}"
elif [[ $Q_PCT -ge 53 ]]; then echo -e "${BOLD}${YELLOW}Satisfactory / Задовільно 😐${NC}"
else                           echo -e "${BOLD}${RED}Review material / Повторіть матеріал 📖${NC}"; fi

pause

# ═══════════════════════════════════════════════════════════════════
#   PART 2 — AWS INFRASTRUCTURE VERIFICATION / ПЕРЕВІРКА РЕСУРСІВ
# ═══════════════════════════════════════════════════════════════════

banner "PART 2 / ЧАСТИНА 2 — AWS Resource Verification"
echo ""
echo -e "  ${CYAN}Enter the resource IDs/names you created during Lab 4.${NC}"
echo -e "  ${CYAN}Введіть ID/імена ресурсів створених під час заняття 4.${NC}"
echo ""

ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null)
echo -e "  ${DIM}Detected Account ID: ${ACCOUNT_ID}${NC}"
echo ""

read -rp "  S3 Bucket name / Ім'я бакету       (e.g. academy-lab4-123456): " I_BUCKET
read -rp "  EBS Volume ID                        (e.g. vol-0abc1234):        " I_EBS
read -rp "  DynamoDB Table name / Таблиця        (e.g. CadetRecords):        " I_DDB
read -rp "  RDS DB Instance ID                   (e.g. academy-mysql):       " I_RDS
read -rp "  SNS Topic ARN                        (e.g. arn:aws:sns:...):     " I_SNS
read -rp "  ASG name / Ім'я групи               (e.g. academy-asg):         " I_ASG
read -rp "  CloudWatch Alarm name                (e.g. Academy-High-CPU):    " I_ALARM
read -rp "  Launch Template ID                   (e.g. lt-0abc1234):         " I_LT

section "Running checks / Виконую перевірки..."
echo ""

# ── S3 ───────────────────────────────────────────────────────────────
chk "S3 Bucket exists / існує" "$I_BUCKET" \
  "aws s3api head-bucket --bucket '${I_BUCKET}' && echo ok"

if [[ -n "$I_BUCKET" ]]; then
  # Check versioning
  VERS=$(aws s3api get-bucket-versioning --bucket "$I_BUCKET" \
    --query 'Status' --output text 2>/dev/null)
  A_TOT=$((A_TOT+1))
  if [[ "$VERS" == "Enabled" ]]; then
    ok "S3: Versioning is Enabled / увімкнено ✨"; A_OK=$((A_OK+1))
  else
    fail "S3: Versioning is ${BOLD}${VERS:-Disabled}${NC} — expected Enabled"
    hint "Run: aws s3api put-bucket-versioning --bucket $I_BUCKET --versioning-configuration Status=Enabled"
  fi

  # Check lifecycle
  LC=$(aws s3api get-bucket-lifecycle-configuration --bucket "$I_BUCKET" \
    --query 'Rules[0].ID' --output text 2>/dev/null)
  A_TOT=$((A_TOT+1))
  if [[ -n "$LC" && "$LC" != "None" ]]; then
    ok "S3: Lifecycle policy configured / налаштована: ${BOLD}${LC}${NC} ✨"; A_OK=$((A_OK+1))
  else
    fail "S3: Lifecycle policy NOT configured / не налаштована"
    hint "Check step 1.5 in README for lifecycle.json"
  fi

  # Count objects
  OBJ_COUNT=$(aws s3 ls "s3://${I_BUCKET}" --recursive 2>/dev/null | wc -l)
  A_TOT=$((A_TOT+1))
  if [[ "$OBJ_COUNT" -ge 3 ]]; then
    ok "S3: ${BOLD}${OBJ_COUNT}${NC} objects uploaded / файлів завантажено ✨"; A_OK=$((A_OK+1))
  else
    fail "S3: Only ${BOLD}${OBJ_COUNT}${NC} object(s) found — expected at least 3"
    hint "Check steps 1.3 in README — upload 3 files"
  fi
fi

echo ""

# ── EBS ──────────────────────────────────────────────────────────────
chk "EBS Volume exists / існує" "$I_EBS" \
  "aws ec2 describe-volumes --volume-ids '${I_EBS}' --query 'Volumes[0].VolumeId' --output text"

if [[ -n "$I_EBS" ]]; then
  EBS_TYPE=$(aws ec2 describe-volumes --volume-ids "$I_EBS" \
    --query 'Volumes[0].VolumeType' --output text 2>/dev/null)
  EBS_SIZE=$(aws ec2 describe-volumes --volume-ids "$I_EBS" \
    --query 'Volumes[0].Size' --output text 2>/dev/null)
  EBS_STATE=$(aws ec2 describe-volumes --volume-ids "$I_EBS" \
    --query 'Volumes[0].State' --output text 2>/dev/null)

  A_TOT=$((A_TOT+1))
  if [[ "$EBS_TYPE" == "gp3" ]]; then
    ok "EBS: Type is gp3 ✨ (Size: ${EBS_SIZE}GB, State: ${EBS_STATE})"; A_OK=$((A_OK+1))
  else
    fail "EBS: Type is ${BOLD}${EBS_TYPE:-unknown}${NC} — expected gp3"
  fi

  SNAP=$(aws ec2 describe-snapshots \
    --filters "Name=volume-id,Values=${I_EBS}" "Name=owner-id,Values=${ACCOUNT_ID}" \
    --query 'Snapshots[0].SnapshotId' --output text 2>/dev/null)
  A_TOT=$((A_TOT+1))
  if [[ -n "$SNAP" && "$SNAP" != "None" ]]; then
    ok "EBS: Snapshot exists / знімок існує: ${BOLD}${SNAP}${NC} ✨"; A_OK=$((A_OK+1))
  else
    fail "EBS: No snapshot found / Знімок не знайдено"
    hint "Run: aws ec2 create-snapshot --volume-id $I_EBS --description 'lab4'"
  fi
fi

echo ""

# ── DynamoDB ─────────────────────────────────────────────────────────
chk "DynamoDB table / таблиця" "$I_DDB" \
  "aws dynamodb describe-table --table-name '${I_DDB}' --query 'Table.TableName' --output text"

if [[ -n "$I_DDB" ]]; then
  DDB_STATUS=$(aws dynamodb describe-table --table-name "$I_DDB" \
    --query 'Table.TableStatus' --output text 2>/dev/null)
  DDB_BILLING=$(aws dynamodb describe-table --table-name "$I_DDB" \
    --query 'Table.BillingModeSummary.BillingMode' --output text 2>/dev/null)

  A_TOT=$((A_TOT+1))
  if [[ "$DDB_STATUS" == "ACTIVE" ]]; then
    ok "DynamoDB: Status ACTIVE ✨  (Billing: ${DDB_BILLING})"; A_OK=$((A_OK+1))
  else
    fail "DynamoDB: Status is ${BOLD}${DDB_STATUS:-unknown}${NC} — expected ACTIVE"
  fi

  # Check items count
  ITEM_COUNT=$(aws dynamodb scan --table-name "$I_DDB" \
    --select COUNT --query 'Count' --output text 2>/dev/null)
  A_TOT=$((A_TOT+1))
  if [[ "$ITEM_COUNT" -ge 3 ]]; then
    ok "DynamoDB: ${BOLD}${ITEM_COUNT}${NC} items in table / записів ✨"; A_OK=$((A_OK+1))
  else
    fail "DynamoDB: Only ${BOLD}${ITEM_COUNT:-0}${NC} item(s) — expected at least 3"
    hint "Check step 4.2 in README — add 3 items with put-item"
  fi

  # Check partition key
  DDB_HASH=$(aws dynamodb describe-table --table-name "$I_DDB" \
    --query "Table.KeySchema[?KeyType=='HASH'].AttributeName" \
    --output text 2>/dev/null)
  A_TOT=$((A_TOT+1))
  if [[ "$DDB_HASH" == "CadetId" ]]; then
    ok "DynamoDB: Partition key is CadetId ✨"; A_OK=$((A_OK+1))
  else
    fail "DynamoDB: Partition key is '${BOLD}${DDB_HASH:-?}${NC}' — expected 'CadetId'"
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
  RDS_ENGINE=$(aws rds describe-db-instances \
    --db-instance-identifier "$I_RDS" \
    --query 'DBInstances[0].Engine' --output text 2>/dev/null)
  RDS_AZ=$(aws rds describe-db-instances \
    --db-instance-identifier "$I_RDS" \
    --query 'DBInstances[0].MultiAZ' --output text 2>/dev/null)

  A_TOT=$((A_TOT+1))
  if [[ "$RDS_STATUS" == "available" ]]; then
    ok "RDS: Status available ✨  (Engine: ${RDS_ENGINE}, Multi-AZ: ${RDS_AZ})"; A_OK=$((A_OK+1))
  elif [[ "$RDS_STATUS" == "creating" || "$RDS_STATUS" == "modifying" ]]; then
    warn "RDS: Still ${BOLD}${RDS_STATUS}${NC} — wait a few minutes and re-run"
  else
    fail "RDS: Status is ${BOLD}${RDS_STATUS:-unknown}${NC} — expected available"
  fi

  A_TOT=$((A_TOT+1))
  if [[ "$RDS_ENGINE" == "mysql" ]]; then
    ok "RDS: Engine is MySQL ✨"; A_OK=$((A_OK+1))
  else
    fail "RDS: Engine is ${BOLD}${RDS_ENGINE:-?}${NC} — expected mysql"
  fi
fi

echo ""

# ── SNS ──────────────────────────────────────────────────────────────
chk "SNS Topic" "$I_SNS" \
  "aws sns get-topic-attributes --topic-arn '${I_SNS}' --query 'Attributes.TopicArn' --output text"

if [[ -n "$I_SNS" ]]; then
  SNS_SUBS=$(aws sns list-subscriptions-by-topic --topic-arn "$I_SNS" \
    --query 'length(Subscriptions)' --output text 2>/dev/null)
  A_TOT=$((A_TOT+1))
  if [[ "$SNS_SUBS" -ge 1 ]]; then
    ok "SNS: ${BOLD}${SNS_SUBS}${NC} subscription(s) found / підписок знайдено ✨"; A_OK=$((A_OK+1))
  else
    fail "SNS: No subscriptions / Підписки відсутні"
    hint "Run aws sns subscribe to add an email subscription"
  fi
fi

echo ""

# ── Launch Template ───────────────────────────────────────────────────
chk "Launch Template" "$I_LT" \
  "aws ec2 describe-launch-templates --launch-template-ids '${I_LT}' --query 'LaunchTemplates[0].LaunchTemplateId' --output text"

echo ""

# ── Auto Scaling Group ────────────────────────────────────────────────
chk "Auto Scaling Group / Група" "$I_ASG" \
  "aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names '${I_ASG}' --query 'AutoScalingGroups[0].AutoScalingGroupName' --output text"

if [[ -n "$I_ASG" ]]; then
  ASG_MIN=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$I_ASG" \
    --query 'AutoScalingGroups[0].MinSize' --output text 2>/dev/null)
  ASG_MAX=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$I_ASG" \
    --query 'AutoScalingGroups[0].MaxSize' --output text 2>/dev/null)
  ASG_DES=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$I_ASG" \
    --query 'AutoScalingGroups[0].DesiredCapacity' --output text 2>/dev/null)
  ASG_INST=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$I_ASG" \
    --query 'AutoScalingGroups[0].Instances | length(@)' --output text 2>/dev/null)

  A_TOT=$((A_TOT+1))
  if [[ "$ASG_MIN" -ge 1 && "$ASG_MAX" -ge 2 ]]; then
    ok "ASG: min=${BOLD}${ASG_MIN}${NC} max=${BOLD}${ASG_MAX}${NC} desired=${BOLD}${ASG_DES}${NC} running=${BOLD}${ASG_INST}${NC} ✨"
    A_OK=$((A_OK+1))
  else
    fail "ASG: min/max not as expected (min=${ASG_MIN}, max=${ASG_MAX})"
  fi

  # Check for scaling policy
  POLICY=$(aws autoscaling describe-policies \
    --auto-scaling-group-name "$I_ASG" \
    --query 'ScalingPolicies[0].PolicyName' --output text 2>/dev/null)
  A_TOT=$((A_TOT+1))
  if [[ -n "$POLICY" && "$POLICY" != "None" ]]; then
    ok "ASG: Scaling policy exists / правило масштабування: ${BOLD}${POLICY}${NC} ✨"; A_OK=$((A_OK+1))
  else
    fail "ASG: No scaling policy found / Правило не знайдено"
    hint "Check step 8.1 in README — create a TargetTrackingScaling policy"
  fi
fi

echo ""

# ── CloudWatch Alarm ──────────────────────────────────────────────────
chk "CloudWatch Alarm" "$I_ALARM" \
  "aws cloudwatch describe-alarms --alarm-names '${I_ALARM}' --query 'MetricAlarms[0].AlarmName' --output text"

if [[ -n "$I_ALARM" ]]; then
  ALM_STATE=$(aws cloudwatch describe-alarms --alarm-names "$I_ALARM" \
    --query 'MetricAlarms[0].StateValue' --output text 2>/dev/null)
  ALM_THRESH=$(aws cloudwatch describe-alarms --alarm-names "$I_ALARM" \
    --query 'MetricAlarms[0].Threshold' --output text 2>/dev/null)
  ALM_METRIC=$(aws cloudwatch describe-alarms --alarm-names "$I_ALARM" \
    --query 'MetricAlarms[0].MetricName' --output text 2>/dev/null)
  ALM_ACTIONS=$(aws cloudwatch describe-alarms --alarm-names "$I_ALARM" \
    --query 'length(MetricAlarms[0].AlarmActions)' --output text 2>/dev/null)

  A_TOT=$((A_TOT+1))
  if [[ "$ALM_METRIC" == "CPUUtilization" || -n "$ALM_METRIC" ]]; then
    ok "CloudWatch: Metric=${BOLD}${ALM_METRIC}${NC} Threshold=${BOLD}${ALM_THRESH}${NC} State=${BOLD}${ALM_STATE}${NC} ✨"
    A_OK=$((A_OK+1))
  else
    fail "CloudWatch: Alarm metric not configured correctly"
  fi

  A_TOT=$((A_TOT+1))
  if [[ "$ALM_ACTIONS" -ge 1 ]]; then
    ok "CloudWatch: Alarm has ${BOLD}${ALM_ACTIONS}${NC} action(s) / дій (SNS notification) ✨"; A_OK=$((A_OK+1))
  else
    fail "CloudWatch: No alarm actions / Дії не налаштовані — SNS not linked"
    hint "Add --alarm-actions with your SNS_ARN"
  fi
fi

pause

# ═══════════════════════════════════════════════════════════════════
#   PART 3 — PRACTICAL CHALLENGE / ЧАСТИНА 3 — ПРАКТИЧНЕ ЗАВДАННЯ
# ═══════════════════════════════════════════════════════════════════

banner "PART 3 / ЧАСТИНА 3 — Practical Challenge"
echo ""
echo -e "  ${CYAN}Complete one of the following tasks and we verify live:${NC}"
echo -e "  ${CYAN}Виконайте одне із завдань і ми перевіримо в реальному часі:${NC}"
echo ""
echo -e "  ${BOLD}A)${NC} Manually scale ASG desired capacity to 3, then back to 2"
echo -e "     ${DIM}Змініть desired до 3, потім назад до 2${NC}"
echo ""
echo -e "  ${BOLD}B)${NC} Upload a new version of any file to S3 and verify version count ≥ 2"
echo -e "     ${DIM}Завантажте нову версію файлу в S3 і перевірте що версій ≥ 2${NC}"
echo ""
echo -e "  ${BOLD}C)${NC} Add one DynamoDB item and verify total item count increases"
echo -e "     ${DIM}Додайте запис у DynamoDB і перевірте що кількість записів зросла${NC}"
echo ""
read -rp "  Choose task / Виберіть завдання (A/B/C): " TASK_CHOICE

case "${TASK_CHOICE^^}" in
  A)
    echo -e "\n  ${YELLOW}⚡  Scale ASG to 3, then to 2. Press Enter when done.${NC}"
    pause
    if [[ -n "$I_ASG" ]]; then
      NEW_DES=$(aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-names "$I_ASG" \
        --query 'AutoScalingGroups[0].DesiredCapacity' --output text 2>/dev/null)
      A_TOT=$((A_TOT+1))
      ok "ASG DesiredCapacity is now: ${BOLD}${NEW_DES}${NC}"
      A_OK=$((A_OK+1))
    fi
    ;;
  B)
    echo -e "\n  ${YELLOW}⚡  Upload a new file version to S3. Press Enter when done.${NC}"
    pause
    if [[ -n "$I_BUCKET" ]]; then
      VER_COUNT=$(aws s3api list-object-versions --bucket "$I_BUCKET" \
        --query 'length(Versions)' --output text 2>/dev/null)
      A_TOT=$((A_TOT+1))
      if [[ "$VER_COUNT" -ge 2 ]]; then
        ok "S3: ${BOLD}${VER_COUNT}${NC} versions found — versioning working! ✨"; A_OK=$((A_OK+1))
      else
        fail "S3: Only ${VER_COUNT:-0} version(s) — upload and overwrite a file"
      fi
    fi
    ;;
  C)
    echo -e "\n  ${YELLOW}⚡  Add a DynamoDB item. Press Enter when done.${NC}"
    pause
    if [[ -n "$I_DDB" ]]; then
      NEW_COUNT=$(aws dynamodb scan --table-name "$I_DDB" \
        --select COUNT --query 'Count' --output text 2>/dev/null)
      A_TOT=$((A_TOT+1))
      if [[ "$NEW_COUNT" -gt "$ITEM_COUNT" ]] || [[ "$NEW_COUNT" -ge 4 ]]; then
        ok "DynamoDB: ${BOLD}${NEW_COUNT}${NC} items — new item added! ✨"; A_OK=$((A_OK+1))
      else
        fail "DynamoDB: Item count unchanged (${NEW_COUNT}). Try again."
      fi
    fi
    ;;
  *)
    warn "No valid task selected / Завдання не вибрано. Skipping."
    ;;
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
echo -e "  ┌──────────────────────────────────────────────────┐"
echo -e "  │  Theory quiz / Теоретичний квіз:                 │"
echo -e "  │    ${BOLD}${Q_OK} / ${Q_TOT}${NC} correct / правильно                   │"
echo -e "  │                                                  │"
echo -e "  │  AWS infrastructure / Перевірка ресурсів:        │"
echo -e "  │    ${BOLD}${A_OK} / ${A_TOT}${NC} checks passed / перевірок пройдено   │"
echo -e "  │  ──────────────────────────────────────────────  │"
echo -e "  │  ${BOLD}TOTAL / РАЗОМ:  ${TOTAL} / ${MAX}  (${PCT}%)${NC}                │"
echo -e "  └──────────────────────────────────────────────────┘"
echo ""

if   [[ $PCT -ge 90 ]]; then GRADE="Excellent / Відмінно 🏆";           COL=$GREEN
elif [[ $PCT -ge 75 ]]; then GRADE="Good / Добре 🥈";                   COL=$CYAN
elif [[ $PCT -ge 60 ]]; then GRADE="Satisfactory / Задовільно 🥉";      COL=$YELLOW
else                          GRADE="Review needed / Повторіть матеріал 📖"; COL=$RED; fi

echo -e "  ${BOLD}${COL}${GRADE}${NC}"
echo ""

if [[ $PCT -lt 75 ]]; then
  echo -e "  ${DIM}Areas to review / Що повторити:${NC}"
  [[ $Q_OK -lt 10 ]] && info "README theory sections (Кроки 1–9)"
  [[ $A_OK -lt $((A_TOT * 3 / 4)) ]] && info "Lab practical steps — re-run the commands"
fi

echo ""
echo -e "  ${BOLD}${CYAN}── Further learning / Для поглибленого вивчення ────────────${NC}"
echo -e "  ${DIM}📘 S3 User Guide:    https://docs.aws.amazon.com/s3/${NC}"
echo -e "  ${DIM}📘 RDS User Guide:   https://docs.aws.amazon.com/rds/${NC}"
echo -e "  ${DIM}📘 DynamoDB Guide:   https://docs.aws.amazon.com/dynamodb/${NC}"
echo -e "  ${DIM}📘 Auto Scaling:     https://docs.aws.amazon.com/autoscaling/${NC}"
echo -e "  ${DIM}📘 CloudWatch:       https://docs.aws.amazon.com/cloudwatch/${NC}"
echo ""

# Save result
RESULT_FILE="lab4_result_$(echo "$STUDENT" | tr ' ' '_')_$(date +%Y%m%d_%H%M).txt"
cat << EOF > "$RESULT_FILE"
AWS Academy — Lab 4 Result / Результат
========================================
Student / Курсант : $STUDENT
Date / Дата       : $(date '+%d.%m.%Y %H:%M')
Quiz              : $Q_OK / $Q_TOT
AWS checks        : $A_OK / $A_TOT
Total / Разом     : $TOTAL / $MAX  (${PCT}%)
Grade / Оцінка    : $GRADE

Resources entered / Ресурси введені:
  S3 Bucket    : $I_BUCKET
  EBS Volume   : $I_EBS
  DynamoDB     : $I_DDB
  RDS          : $I_RDS
  SNS Topic    : $I_SNS
  ASG          : $I_ASG
  CW Alarm     : $I_ALARM
  Launch Tmpl  : $I_LT
EOF

ok "Result saved / Результат збережено: ${BOLD}${RESULT_FILE}${NC}"
echo ""
echo -e "${BOLD}${MAGENTA}  Дякуємо! / Thank you!  Слава Україні! 🇺🇦${NC}"
echo ""
