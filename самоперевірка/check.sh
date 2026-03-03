#!/bin/bash
# ╔══════════════════════════════════════════════════════════╗
# ║     AWS Academy — Скрипт самоперевірки та закріплення    ║
# ║     Хмарні технології | 5-й курс                         ║
# ╚══════════════════════════════════════════════════════════╝

# ── Кольори для виводу ──────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── Лічильники балів ────────────────────────────────────────
TOTAL_SCORE=0
MAX_SCORE=0
QUIZ_SCORE=0
QUIZ_MAX=0
INFRA_SCORE=0
INFRA_MAX=0

# ── Допоміжні функції ───────────────────────────────────────
print_header() {
  echo ""
  echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${BLUE}║${NC}  ${BOLD}$1${NC}"
  echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
}

print_section() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}  $1${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

ok()   { echo -e "  ${GREEN}✅ $1${NC}"; }
fail() { echo -e "  ${RED}❌ $1${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $1${NC}"; }
info() { echo -e "  ${BLUE}ℹ️  $1${NC}"; }
ask()  { echo -e "\n${BOLD}${YELLOW}❓ $1${NC}"; }

pause() {
  echo ""
  read -p "  $(echo -e "${MAGENTA}[Натисніть Enter для продовження...]${NC}")" _
}

add_score() {
  local points=$1
  local category=$2
  if [ "$category" = "quiz" ]; then
    QUIZ_SCORE=$((QUIZ_SCORE + points))
    QUIZ_MAX=$((QUIZ_MAX + 1))
  elif [ "$category" = "infra" ]; then
    INFRA_SCORE=$((INFRA_SCORE + points))
    INFRA_MAX=$((INFRA_MAX + 1))
  fi
  TOTAL_SCORE=$((TOTAL_SCORE + points))
}

add_max() {
  local category=$1
  MAX_SCORE=$((MAX_SCORE + 1))
}

# ── Функція запитання з варіантами ──────────────────────────
ask_multiple_choice() {
  local question="$1"
  local correct="$2"
  shift 2
  local options=("$@")
  local hint="${options[-1]}"
  unset 'options[-1]'

  ask "$question"
  echo ""
  for i in "${!options[@]}"; do
    echo -e "    ${BOLD}$((i+1)))${NC} ${options[$i]}"
  done
  echo ""
  read -p "  Ваша відповідь (1-${#options[@]}): " answer

  add_max "quiz"
  if [ "$answer" = "$correct" ]; then
    ok "Правильно! 🎉"
    add_score 1 "quiz"
    return 0
  else
    fail "Неправильно. Правильна відповідь: ${BOLD}${correct}) ${options[$((correct-1))]}${NC}"
    info "💡 Підказка: $hint"
    return 1
  fi
}

# ── Функція перевірки AWS ресурсу ───────────────────────────
check_aws_resource() {
  local description="$1"
  local resource_id="$2"
  local aws_command="$3"
  local expected="$4"

  echo -ne "  Перевіряю ${description}... "
  add_max "infra"

  if [ -z "$resource_id" ] || [ "$resource_id" = "None" ] || [ "$resource_id" = "null" ]; then
    fail "${description} — ID не вказано або порожнє"
    return 1
  fi

  local result
  result=$(eval "$aws_command" 2>/dev/null)
  local exit_code=$?

  if [ $exit_code -eq 0 ] && [ -n "$result" ]; then
    ok "${description}: ${BOLD}${resource_id}${NC}"
    add_score 1 "infra"
    return 0
  else
    fail "${description}: не знайдено або помилка"
    return 1
  fi
}

# ═══════════════════════════════════════════════════════════
#                    ПОЧАТОК СКРИПТУ
# ═══════════════════════════════════════════════════════════

clear
echo ""
echo -e "${BOLD}${MAGENTA}"
cat << 'BANNER'
  ╔═══════════════════════════════════════════════════════╗
  ║                                                       ║
  ║    AWS ACADEMY — САМОПЕРЕВІРКА                        ║
  ║    VPC | EC2 | Network ACL | Elastic IP               ║
  ║                                                       ║
  ╚═══════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "  ${CYAN}Вітаємо на інтерактивній перевірці знань!${NC}"
echo -e "  Скрипт перевірить ${BOLD}теоретичні знання${NC} та ${BOLD}реальні AWS ресурси${NC}."
echo ""
read -p "  Введіть ваше ім'я та прізвище: " STUDENT_NAME
echo ""
echo -e "  ${GREEN}Привіт, ${BOLD}${STUDENT_NAME}${NC}${GREEN}! Починаємо...${NC}"

pause

# ═══════════════════════════════════════════════════════════
#   ЧАСТИНА 1 — ТЕОРЕТИЧНИЙ КВІЗ
# ═══════════════════════════════════════════════════════════

print_header "ЧАСТИНА 1 — ТЕОРЕТИЧНИЙ КВІЗ (10 запитань)"
echo -e "  За кожну правильну відповідь — 1 бал."

# Запитання 1
print_section "Запитання 1 / 10 — VPC"
ask_multiple_choice \
  "Що таке VPC в AWS?" \
  "3" \
  "Virtual Public Cloud — хмарне сховище файлів" \
  "Virtual Private Connection — захищений VPN-тунель" \
  "Virtual Private Cloud — ізольована мережа в хмарі" \
  "Virtual Processing Core — обчислювальний ресурс" \
  "VPC розшифровується як Virtual Private Cloud — це ваш власний ізольований сегмент мережі в AWS"

pause

# Запитання 2
print_section "Запитання 2 / 10 — CIDR"
ask_multiple_choice \
  "Скільки IP-адрес містить блок 10.0.0.0/16?" \
  "3" \
  "256 адрес" \
  "4 096 адрес" \
  "65 536 адрес" \
  "1 048 576 адрес" \
  "/16 означає 16 фіксованих бітів. Решта 32-16=16 бітів вільні: 2^16 = 65 536 адрес"

pause

# Запитання 3
print_section "Запитання 3 / 10 — Internet Gateway"
ask_multiple_choice \
  "Яка роль Internet Gateway у VPC?" \
  "2" \
  "Фільтрує трафік між підмережами" \
  "Забезпечує зв'язок між VPC та інтернетом" \
  "Розподіляє IP-адреси між інстансами" \
  "Шифрує трафік між зонами доступності" \
  "Internet Gateway — це 'ворота' між вашою VPC та публічним інтернетом"

pause

# Запитання 4
print_section "Запитання 4 / 10 — Network ACL vs Security Group"
ask_multiple_choice \
  "Яка ключова відмінність між Network ACL та Security Group?" \
  "1" \
  "NACL є stateless (не відстежує стан), SG є stateful (відстежує стан)" \
  "NACL захищає інстанс, SG захищає підмережу" \
  "NACL підтримує тільки IPv6, SG — тільки IPv4" \
  "NACL — платна послуга, SG — безкоштовна" \
  "NACL stateless: кожен пакет перевіряється незалежно. SG stateful: якщо дозволили вхідний, відповідь автоматично дозволена"

pause

# Запитання 5
print_section "Запитання 5 / 10 — Elastic IP"
ask_multiple_choice \
  "Яка головна перевага Elastic IP порівняно зі звичайним публічним IP?" \
  "2" \
  "Elastic IP завжди швидший завдяки спеціальній маршрутизації" \
  "Elastic IP залишається незмінним та може переміщуватись між інстансами" \
  "Elastic IP автоматично захищений від DDoS-атак" \
  "Elastic IP не тарифікується ніколи" \
  "Звичайний публічний IP змінюється при перезапуску. Elastic IP — статичний і залишається вашим"

pause

# Запитання 6
print_section "Запитання 6 / 10 — Route Table"
ask_multiple_choice \
  "Що відбудеться, якщо підмережа не матиме маршруту 0.0.0.0/0 через Internet Gateway?" \
  "3" \
  "Інстанси в цій підмережі будуть видалені" \
  "Інстанси автоматично знайдуть альтернативний маршрут" \
  "Інстанси в цій підмережі не матимуть доступу до інтернету" \
  "Internet Gateway автоматично додасть маршрут" \
  "0.0.0.0/0 означає 'весь трафік'. Без цього маршруту підмережа є приватною — без доступу до інтернету"

pause

# Запитання 7
print_section "Запитання 7 / 10 — Availability Zone"
ask_multiple_choice \
  "Навіщо ми розміщуємо підмережі в різних Availability Zones?" \
  "4" \
  "Щоб отримати нижчу вартість за трафік між ними" \
  "Щоб мати різні CIDR-блоки" \
  "Щоб AWS CLI міг їх легше знайти" \
  "Для відмовостійкості — якщо одна зона відмовить, інша працюватиме" \
  "AZ — це фізично ізольовані дата-центри. Розподіл між AZ забезпечує high availability"

pause

# Запитання 8
print_section "Запитання 8 / 10 — Порядок правил NACL"
ask_multiple_choice \
  "Як Network ACL обробляє правила?" \
  "1" \
  "У порядку зростання номерів правил, перше співпадіння — застосовується" \
  "Всі правила перевіряються, найбільш специфічне застосовується" \
  "У порядку спадання номерів правил" \
  "Правила застосовуються в алфавітному порядку типу протоколу" \
  "NACL перевіряє правила від найменшого номера. Перше правило що збіглось — застосовується, решта ігноруються"

pause

# Запитання 9
print_section "Запитання 9 / 10 — ENI"
ask_multiple_choice \
  "Що таке ENI (Elastic Network Interface)?" \
  "2" \
  "Тип зберігання даних для EC2-інстансів" \
  "Віртуальна мережева карта, яку можна прикріпити до інстансу" \
  "Служба моніторингу мережевого трафіку" \
  "Протокол шифрування між підмережами" \
  "ENI — це віртуальний мережевий інтерфейс. Elastic IP прив'язується саме до ENI, а не безпосередньо до інстансу"

pause

# Запитання 10
print_section "Запитання 10 / 10 — AWS CLI"
ask_multiple_choice \
  "Яка команда AWS CLI показує інформацію про ваш поточний обліковий запис?" \
  "3" \
  "aws ec2 describe-account" \
  "aws iam get-account" \
  "aws sts get-caller-identity" \
  "aws config show-identity" \
  "aws sts get-caller-identity повертає UserId, Account та ARN поточних облікових даних"

pause

# Підсумок квізу
print_section "Результати теоретичного квізу"
echo ""
QUIZ_PERCENT=$((QUIZ_SCORE * 100 / QUIZ_MAX))
echo -e "  Правильних відповідей: ${BOLD}${QUIZ_SCORE} / ${QUIZ_MAX}${NC}"
echo -ne "  Оцінка: "

if [ $QUIZ_PERCENT -ge 90 ]; then
  echo -e "${BOLD}${GREEN}Відмінно! 🏆 (${QUIZ_PERCENT}%)${NC}"
elif [ $QUIZ_PERCENT -ge 70 ]; then
  echo -e "${BOLD}${YELLOW}Добре! 👍 (${QUIZ_PERCENT}%)${NC}"
elif [ $QUIZ_PERCENT -ge 50 ]; then
  echo -e "${BOLD}${YELLOW}Задовільно 😐 (${QUIZ_PERCENT}%)${NC}"
else
  echo -e "${BOLD}${RED}Потрібно повторити матеріал 📖 (${QUIZ_PERCENT}%)${NC}"
fi

pause

# ═══════════════════════════════════════════════════════════
#   ЧАСТИНА 2 — ПЕРЕВІРКА AWS ІНФРАСТРУКТУРИ
# ═══════════════════════════════════════════════════════════

print_header "ЧАСТИНА 2 — ПЕРЕВІРКА РЕАЛЬНИХ AWS РЕСУРСІВ"
echo -e "  ${CYAN}Введіть ID ресурсів, які ви створили під час заняття.${NC}"
echo -e "  ${YELLOW}Підказка: якщо змінні ще є в сесії — запустіть команди в дужках${NC}"
echo ""

# Збір ID від курсанта
echo -e "${BOLD}Введіть ID ресурсів:${NC}"
echo ""

read -p "  VPC ID (напр. vpc-0abc1234): " INPUT_VPC_ID
read -p "  Subnet-A ID (напр. subnet-0abc): " INPUT_SUBNET_A
read -p "  Subnet-B ID (напр. subnet-0def): " INPUT_SUBNET_B
read -p "  EC2 WebServer ID (напр. i-0abc1234): " INPUT_INST_A
read -p "  EC2 AppServer ID (напр. i-0def5678): " INPUT_INST_B
read -p "  Elastic IP Allocation ID (напр. eipalloc-0abc): " INPUT_EIP
read -p "  Security Group ID (напр. sg-0abc1234): " INPUT_SG
read -p "  Internet Gateway ID (напр. igw-0abc): " INPUT_IGW

print_section "Перевірка ресурсів..."
echo ""

# Перевірка VPC
check_aws_resource \
  "VPC" \
  "$INPUT_VPC_ID" \
  "aws ec2 describe-vpcs --vpc-ids $INPUT_VPC_ID --query 'Vpcs[0].VpcId' --output text 2>/dev/null"

# Перевірка CIDR VPC
if [ -n "$INPUT_VPC_ID" ]; then
  VPC_CIDR=$(aws ec2 describe-vpcs --vpc-ids "$INPUT_VPC_ID" \
    --query 'Vpcs[0].CidrBlock' --output text 2>/dev/null)
  if [ "$VPC_CIDR" = "10.0.0.0/16" ]; then
    ok "VPC CIDR правильний: ${BOLD}10.0.0.0/16${NC}"
    add_score 1 "infra"
    add_max "infra"
  else
    fail "VPC CIDR: очікувалось 10.0.0.0/16, знайдено ${BOLD}${VPC_CIDR}${NC}"
    add_max "infra"
  fi
fi

echo ""

# Перевірка Subnet-A
check_aws_resource \
  "Subnet-A" \
  "$INPUT_SUBNET_A" \
  "aws ec2 describe-subnets --subnet-ids $INPUT_SUBNET_A --query 'Subnets[0].SubnetId' --output text 2>/dev/null"

# Перевірка CIDR Subnet-A
if [ -n "$INPUT_SUBNET_A" ]; then
  SUBNET_A_CIDR=$(aws ec2 describe-subnets --subnet-ids "$INPUT_SUBNET_A" \
    --query 'Subnets[0].CidrBlock' --output text 2>/dev/null)
  if [ "$SUBNET_A_CIDR" = "10.0.1.0/24" ]; then
    ok "Subnet-A CIDR правильний: ${BOLD}10.0.1.0/24${NC}"
    add_score 1 "infra"
    add_max "infra"
  else
    fail "Subnet-A CIDR: очікувалось 10.0.1.0/24, знайдено ${BOLD}${SUBNET_A_CIDR}${NC}"
    add_max "infra"
  fi
fi

# Перевірка Subnet-B
check_aws_resource \
  "Subnet-B" \
  "$INPUT_SUBNET_B" \
  "aws ec2 describe-subnets --subnet-ids $INPUT_SUBNET_B --query 'Subnets[0].SubnetId' --output text 2>/dev/null"

# Перевірка що підмережі в різних AZ
if [ -n "$INPUT_SUBNET_A" ] && [ -n "$INPUT_SUBNET_B" ]; then
  AZ_A=$(aws ec2 describe-subnets --subnet-ids "$INPUT_SUBNET_A" \
    --query 'Subnets[0].AvailabilityZone' --output text 2>/dev/null)
  AZ_B=$(aws ec2 describe-subnets --subnet-ids "$INPUT_SUBNET_B" \
    --query 'Subnets[0].AvailabilityZone' --output text 2>/dev/null)
  add_max "infra"
  if [ "$AZ_A" != "$AZ_B" ] && [ -n "$AZ_A" ] && [ -n "$AZ_B" ]; then
    ok "Підмережі в різних AZ: ${BOLD}${AZ_A}${NC} та ${BOLD}${AZ_B}${NC} ✨"
    add_score 1 "infra"
  else
    fail "Підмережі повинні бути в різних Availability Zones!"
  fi
fi

echo ""

# Перевірка Internet Gateway
check_aws_resource \
  "Internet Gateway" \
  "$INPUT_IGW" \
  "aws ec2 describe-internet-gateways --internet-gateway-ids $INPUT_IGW --query 'InternetGateways[0].InternetGatewayId' --output text 2>/dev/null"

# Перевірка що IGW прикріплений до VPC
if [ -n "$INPUT_IGW" ] && [ -n "$INPUT_VPC_ID" ]; then
  IGW_ATTACHED=$(aws ec2 describe-internet-gateways \
    --internet-gateway-ids "$INPUT_IGW" \
    --query "InternetGateways[0].Attachments[?VpcId=='$INPUT_VPC_ID'].State" \
    --output text 2>/dev/null)
  add_max "infra"
  if [ "$IGW_ATTACHED" = "available" ]; then
    ok "Internet Gateway прикріплений до VPC ✨"
    add_score 1 "infra"
  else
    fail "Internet Gateway не прикріплений до вашої VPC!"
  fi
fi

echo ""

# Перевірка Security Group
check_aws_resource \
  "Security Group" \
  "$INPUT_SG" \
  "aws ec2 describe-security-groups --group-ids $INPUT_SG --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null"

# Перевірка правил SG (SSH)
if [ -n "$INPUT_SG" ]; then
  SSH_RULE=$(aws ec2 describe-security-groups --group-ids "$INPUT_SG" \
    --query "SecurityGroups[0].IpPermissions[?FromPort==\`22\`].FromPort" \
    --output text 2>/dev/null)
  add_max "infra"
  if [ "$SSH_RULE" = "22" ]; then
    ok "Security Group: SSH (порт 22) дозволено ✨"
    add_score 1 "infra"
  else
    fail "Security Group: правило SSH (порт 22) не знайдено!"
  fi
fi

echo ""

# Перевірка EC2 WebServer
check_aws_resource \
  "EC2 WebServer (Subnet-A)" \
  "$INPUT_INST_A" \
  "aws ec2 describe-instances --instance-ids $INPUT_INST_A --query 'Reservations[0].Instances[0].InstanceId' --output text 2>/dev/null"

# Перевірка стану WebServer
if [ -n "$INPUT_INST_A" ]; then
  INST_A_STATE=$(aws ec2 describe-instances --instance-ids "$INPUT_INST_A" \
    --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null)
  add_max "infra"
  if [ "$INST_A_STATE" = "running" ]; then
    ok "WebServer запущений (state: running) ✨"
    add_score 1 "infra"
  else
    warn "WebServer стан: ${BOLD}${INST_A_STATE}${NC} (очікується: running)"
  fi
fi

# Перевірка EC2 AppServer
check_aws_resource \
  "EC2 AppServer (Subnet-B)" \
  "$INPUT_INST_B" \
  "aws ec2 describe-instances --instance-ids $INPUT_INST_B --query 'Reservations[0].Instances[0].InstanceId' --output text 2>/dev/null"

# Перевірка стану AppServer
if [ -n "$INPUT_INST_B" ]; then
  INST_B_STATE=$(aws ec2 describe-instances --instance-ids "$INPUT_INST_B" \
    --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null)
  add_max "infra"
  if [ "$INST_B_STATE" = "running" ]; then
    ok "AppServer запущений (state: running) ✨"
    add_score 1 "infra"
  else
    warn "AppServer стан: ${BOLD}${INST_B_STATE}${NC} (очікується: running)"
  fi
fi

echo ""

# Перевірка Elastic IP
check_aws_resource \
  "Elastic IP" \
  "$INPUT_EIP" \
  "aws ec2 describe-addresses --allocation-ids $INPUT_EIP --query 'Addresses[0].AllocationId' --output text 2>/dev/null"

# Перевірка поточної прив'язки EIP
if [ -n "$INPUT_EIP" ]; then
  EIP_INSTANCE=$(aws ec2 describe-addresses --allocation-ids "$INPUT_EIP" \
    --query 'Addresses[0].InstanceId' --output text 2>/dev/null)
  EIP_PUBLIC=$(aws ec2 describe-addresses --allocation-ids "$INPUT_EIP" \
    --query 'Addresses[0].PublicIp' --output text 2>/dev/null)

  add_max "infra"
  if [ -n "$EIP_INSTANCE" ] && [ "$EIP_INSTANCE" != "None" ] && [ "$EIP_INSTANCE" != "null" ]; then
    ok "Elastic IP ${BOLD}${EIP_PUBLIC}${NC} прив'язаний до: ${BOLD}${EIP_INSTANCE}${NC}"
    add_score 1 "infra"

    # Додатково перевіряємо чи прив'язаний до AppServer
    add_max "infra"
    if [ "$EIP_INSTANCE" = "$INPUT_INST_B" ]; then
      ok "Elastic IP прив'язаний до ${BOLD}AppServer${NC} — завдання з переміщення виконано! 🎉"
      add_score 1 "infra"
    elif [ "$EIP_INSTANCE" = "$INPUT_INST_A" ]; then
      warn "Elastic IP ще на WebServer — спробуйте перемістити на AppServer"
    else
      warn "EIP прив'язаний до невідомого інстансу"
    fi
  else
    fail "Elastic IP не прив'язаний до жодного інстансу!"
  fi
fi

pause

# ═══════════════════════════════════════════════════════════
#   ЧАСТИНА 3 — ПРАКТИЧНЕ ЗАВДАННЯ (БОНУС)
# ═══════════════════════════════════════════════════════════

print_header "ЧАСТИНА 3 — БОНУСНЕ ПРАКТИЧНЕ ЗАВДАННЯ"
echo ""
echo -e "  ${CYAN}Продемонструйте перенесення Elastic IP на AppServer${NC}"
echo -e "  ${CYAN}прямо зараз і ми перевіримо результат.${NC}"
echo ""
echo -e "  Підказка: вам знадобляться команди:"
echo -e "  ${YELLOW}aws ec2 disassociate-address${NC} та ${YELLOW}aws ec2 associate-address${NC}"
echo ""

read -p "  Ви готові до перевірки? (так/ні): " BONUS_READY

if [[ "$BONUS_READY" == "так" ]] || [[ "$BONUS_READY" == "yes" ]] || [[ "$BONUS_READY" == "y" ]]; then
  echo ""
  echo -e "  ${YELLOW}Виконайте переміщення зараз, потім натисніть Enter...${NC}"
  pause

  if [ -n "$INPUT_EIP" ] && [ -n "$INPUT_INST_B" ]; then
    BONUS_INSTANCE=$(aws ec2 describe-addresses --allocation-ids "$INPUT_EIP" \
      --query 'Addresses[0].InstanceId' --output text 2>/dev/null)

    add_max "infra"
    if [ "$BONUS_INSTANCE" = "$INPUT_INST_B" ]; then
      ok "${BOLD}БОНУС:${NC} Elastic IP успішно переміщено на AppServer! +1 бал 🏆"
      add_score 1 "infra"
    else
      fail "Elastic IP ще не на AppServer. Поточний інстанс: ${BOLD}${BONUS_INSTANCE}${NC}"
    fi
  fi
fi

pause

# ═══════════════════════════════════════════════════════════
#   ЧАСТИНА 4 — ФІНАЛЬНИЙ ПІДСУМОК
# ═══════════════════════════════════════════════════════════

clear
print_header "🏁 ФІНАЛЬНИЙ ПІДСУМОК"
echo ""

MAX_SCORE=$((QUIZ_MAX + INFRA_MAX))
TOTAL_SCORE=$((QUIZ_SCORE + INFRA_SCORE))

echo -e "  ${BOLD}Студент:${NC} ${STUDENT_NAME}"
echo -e "  ${BOLD}Дата:${NC}    $(date '+%d.%m.%Y %H:%M')"
echo ""
echo -e "  ┌─────────────────────────────────────────┐"
echo -e "  │  Теоретичний квіз:   ${BOLD}${QUIZ_SCORE} / ${QUIZ_MAX}${NC} балів"
echo -e "  │  Перевірка AWS:      ${BOLD}${INFRA_SCORE} / ${INFRA_MAX}${NC} балів"
echo -e "  │  ─────────────────────────────────────  │"
echo -e "  │  ${BOLD}РАЗОМ:             ${TOTAL_SCORE} / ${MAX_SCORE} балів${NC}"
echo -e "  └─────────────────────────────────────────┘"
echo ""

FINAL_PERCENT=$((TOTAL_SCORE * 100 / MAX_SCORE))

if [ $FINAL_PERCENT -ge 90 ]; then
  echo -e "  ${BOLD}${GREEN}🏆 ВІДМІННО! (${FINAL_PERCENT}%)${NC}"
  echo -e "  ${GREEN}Чудова робота! Ви відмінно засвоїли матеріал заняття.${NC}"
  GRADE="Відмінно"
elif [ $FINAL_PERCENT -ge 75 ]; then
  echo -e "  ${BOLD}${CYAN}🥈 ДОБРЕ! (${FINAL_PERCENT}%)${NC}"
  echo -e "  ${CYAN}Добрий результат! Є кілька моментів для поглиблення.${NC}"
  GRADE="Добре"
elif [ $FINAL_PERCENT -ge 60 ]; then
  echo -e "  ${BOLD}${YELLOW}🥉 ЗАДОВІЛЬНО (${FINAL_PERCENT}%)${NC}"
  echo -e "  ${YELLOW}Рекомендуємо повторити розділи: Network ACL та Elastic IP.${NC}"
  GRADE="Задовільно"
else
  echo -e "  ${BOLD}${RED}📖 ПОТРЕБУЄ ДООПРАЦЮВАННЯ (${FINAL_PERCENT}%)${NC}"
  echo -e "  ${RED}Рекомендуємо перечитати README та повторити практичні кроки.${NC}"
  GRADE="Незадовільно"
fi

echo ""
echo -e "  ${BOLD}${CYAN}── Корисні посилання для самостійного вивчення ──${NC}"
echo -e "  📘 AWS VPC Documentation: https://docs.aws.amazon.com/vpc/"
echo -e "  📘 AWS CLI Reference:     https://docs.aws.amazon.com/cli/latest/reference/"
echo -e "  📘 AWS Well-Architected:  https://aws.amazon.com/architecture/well-architected/"
echo ""

# Збереження результатів
RESULT_FILE="aws_check_result_$(echo $STUDENT_NAME | tr ' ' '_')_$(date +%Y%m%d_%H%M).txt"
cat << EOF > "$RESULT_FILE"
AWS Academy — Результат самоперевірки
======================================
Студент:     $STUDENT_NAME
Дата:        $(date '+%d.%m.%Y %H:%M')
Квіз:        $QUIZ_SCORE / $QUIZ_MAX
AWS ресурси: $INFRA_SCORE / $INFRA_MAX
Разом:       $TOTAL_SCORE / $MAX_SCORE ($FINAL_PERCENT%)
Оцінка:      $GRADE

Ресурси:
  VPC:       $INPUT_VPC_ID
  Subnet-A:  $INPUT_SUBNET_A
  Subnet-B:  $INPUT_SUBNET_B
  WebServer: $INPUT_INST_A
  AppServer: $INPUT_INST_B
  EIP:       $INPUT_EIP
EOF

echo -e "  ${GREEN}✅ Результат збережено: ${BOLD}${RESULT_FILE}${NC}"
echo ""
echo -e "${BOLD}${MAGENTA}  Дякуємо за роботу на занятті! Слава Україні! 🇺🇦${NC}"
echo ""
