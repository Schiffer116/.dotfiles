#!/bin/bash
# Computes remaining liquid assets (grouped by digital balances vs physical
# cash) and the daily amount left until the next payday, reading the
# beancount ledger in personal_finance. Payday is the 24th, moved to the
# nearest weekday if it falls on a weekend (Sat -> 23rd, Sun -> 25th).
set -euo pipefail

# Prints the actual payday date (YYYY-MM-DD) for the given YYYY-MM.
adjusted_payday() {
  local raw="$1-24"
  case "$(date -d "$raw" +%u)" in
    6) date -d "$raw -1 day" +%Y-%m-%d ;; # Saturday -> Friday
    7) date -d "$raw +1 day" +%Y-%m-%d ;; # Sunday -> Monday
    *) date -d "$raw" +%Y-%m-%d ;;
  esac
}

# Known Tet (Lunar New Year) dates; extend this table as new years are published.
LUNAR_NEW_YEAR_DATES=(
  2024-02-10 2025-01-29 2026-02-17 2027-02-06 2028-01-26 2029-02-13
  2030-02-03 2031-01-23 2032-02-11 2033-01-31 2034-02-19 2035-02-08
)

LEDGER_DIR="${PERSONAL_FINANCE_LEDGER:?PERSONAL_FINANCE_LEDGER is not set (see .zshenv)}"
BEAN_QUERY="$LEDGER_DIR/.venv/bin/bean-query"
MAIN="$LEDGER_DIR/ledger/main.beancount"

balances_csv=$("$BEAN_QUERY" -f csv "$MAIN" \
  "SELECT account, sum(position) FROM OPEN ON 2026-10-01 WHERE account ~ '^Assets:(Bank|Cash|EWallet):' GROUP BY account" \
  2>/dev/null | tr -d '\r')

digital_raw=0
cash_raw=0

while IFS=',' read -r account amount_field; do
  [ "$account" = "account" ] && continue
  [ -z "$account" ] && continue
  amount=$(printf '%s' "$amount_field" | awk '{print $1}')
  amount=${amount:-0}
  case "$account" in
    Assets:Bank:*|Assets:EWallet:*) digital_raw=$(( digital_raw + amount )) ;;
    Assets:Cash:*)                  cash_raw=$(( cash_raw + amount )) ;;
  esac
done <<< "$balances_csv"

total_raw=$(( digital_raw + cash_raw ))

accounts_json=$(jq -nc \
  --arg digital "$(numfmt --grouping -- "$digital_raw")" \
  --arg cash "$(numfmt --grouping -- "$cash_raw")" \
  '[{name: "Digital", balance: $digital}, {name: "Cash", balance: $cash}]')

today_epoch=$(date -d "today 00:00" +%s)

this_payday_epoch=$(date -d "$(adjusted_payday "$(date +%Y-%m)")" +%s)
if [ "$today_epoch" -le "$this_payday_epoch" ]; then
  payday_epoch=$this_payday_epoch
else
  payday_epoch=$(date -d "$(adjusted_payday "$(date -d "+1 month" +%Y-%m)")" +%s)
fi

days_remaining=$(( (payday_epoch - today_epoch) / 86400 ))
[ "$days_remaining" -lt 1 ] && days_remaining=1

daily_raw=$(( total_raw / days_remaining ))

total_fmt=$(numfmt --grouping -- "$total_raw")
daily_fmt=$(numfmt --grouping -- "$daily_raw")

this_year=$(date +%Y)
new_year_this_epoch=$(date -d "$this_year-01-01" +%s)
if [ "$today_epoch" -le "$new_year_this_epoch" ]; then
  new_year_epoch=$new_year_this_epoch
else
  new_year_epoch=$(date -d "$((this_year + 1))-01-01" +%s)
fi
days_until_new_year=$(( (new_year_epoch - today_epoch) / 86400 ))

days_until_lunar_new_year=-1
for d in "${LUNAR_NEW_YEAR_DATES[@]}"; do
  lunar_epoch=$(date -d "$d" +%s)
  if [ "$lunar_epoch" -ge "$today_epoch" ]; then
    days_until_lunar_new_year=$(( (lunar_epoch - today_epoch) / 86400 ))
    break
  fi
done

jq -nc --arg total "$total_fmt" --arg daily "$daily_fmt" --argjson days "$days_remaining" --argjson accounts "$accounts_json" \
  --argjson days_until_new_year "$days_until_new_year" --argjson days_until_lunar_new_year "$days_until_lunar_new_year" \
  '{total: $total, daily: $daily, days_remaining: $days, accounts: $accounts,
    days_until_new_year: $days_until_new_year, days_until_lunar_new_year: $days_until_lunar_new_year}'
