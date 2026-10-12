# Finance Widget

Reads the Beancount ledger in `~/Documents/personal_finance` and shows what's left to spend before payday, on the eww background layer.

## Language

**Liquid assets**:
The sum of balances across accounts matching `^Assets:(Bank|Cash|EWallet):` — bank accounts, physical cash, and e-wallets. Excludes everything under `Liabilities:*` (debts) and any non-liquid `Assets:*` added later (e.g. investments), unless the regex is deliberately widened. Displayed grouped into two categories, not broken out per individual account:
- **Digital**: `Assets:Bank:*` + `Assets:EWallet:*` combined.
- **Cash**: `Assets:Cash:*` (physical cash in hand).
_Avoid_: Net worth, balance, total assets, fake/real money

**Payday**:
The 24th of the month, recurring, moved to the nearest weekday if it falls on a weekend: Saturday the 24th -> Friday the 23rd, Sunday the 24th -> Monday the 25th. If today is past this cycle's (possibly-adjusted) payday, payday is the next month's.
_Avoid_: Allowance date, cycle end, "the 24th" (not always literally the 24th)

**Daily remaining**:
Liquid assets ÷ days until payday (today inclusive, floored to a minimum of 1 day). This is a derived spending guide, not a tracked budget — there is no stored allowance figure anywhere.
_Avoid_: Allowance, budget, daily limit
