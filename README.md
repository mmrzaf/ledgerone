# LedgerOne

**LedgerOne** is an offline-first personal finance and crypto tracking app.
It manages assets (crypto + fiat), accounts, categories, and transactions, then computes balances and optional USD values using **manual price updates**.

No automation. No live syncing. Just clarity and ownership.

---

## Why this exists (and what makes it different)

* Works **fully offline** — balances are **derived from transactions**, not hidden fields.
* **One unified data model** for crypto and fiat.
* The user is in full control:

  * Local storage only
  * Manual price configurations
  * Optional backups/exports

The app is intentionally **not**:

* A trading terminal
* A live portfolio tracker
* An exchange API client (v1)

---

## Core behaviors (summary)

* Balances are always computed from **transaction legs**.
* Total portfolio value is derived by combining balances + latest known USD prices.
* Prices are fetched only when the user taps **Update prices**.
* A single manual flow can update prices for multiple assets — failures don’t block others.



---

## Domain Model (tl;dr version)

Entities:

* **Asset:** crypto, fiat, or other. Optional price config.
* **Account:** where assets live (exchange, bank, wallet, cash).
* **Category:** for fiat income/expense classification.
* **Transaction:** logical “event.”
* **Transaction Leg:** balance delta for a single asset in an account.
* **Price Snapshot:** stored USD price at a specific time.

All balances come **only** from summing the legs.



---

## Planned Screens (v1)

* **Dashboard** — overview + manual price refresh
* **Crypto tab** — assets & accounts
* **Money tab** — fiat, categories, month summaries
* **Transaction Editor** — trade, transfer, income, expense, adjustment
* **Asset Editor** — includes testable price source configs
* **Account Editor**
* **Settings / Backup**



---

## V1 Limits (intentional)

* No automatic background sync
* No exchange API imports
* No portfolio charts (unless trivial)
* No risk/guardrail rules
* No hidden balances

These may come later, but the **data model already supports them**.



---

## Architecture expectations (high level)

* **Presentation layer:** tabs, screens, forms
* **Domain layer:** balance calculations, flows (trade, transfer, etc.)
* **Data layer:** SQLite + HTTP for price updates
* **Backup/restore service**



---

## Design principles (non-negotiable)

1. Offline-first
2. Single source of truth
3. Unified model for crypto + fiat
4. No guardrails in v1
5. User owns everything



---

## Development Checklist (before writing real code)

> This is based on your current starter template.

### 1) Rename & repoint

* Update `pubspec.yaml` name/description
* Change Android/iOS bundle identifiers
* Replace README, CHANGELOG, LICENSE appropriately

### 2) Environment setup

* Define dev/stage/prod configurations (even if stage=prod initially)

### 3) Dependency Injection decisions

* Decide whether to include:

  * Analytics (stub is fine)
  * Crash logging (stub is fine)

### 4) Routing cleanup

* Decide initial screens
* Delete template boilerplate that doesn’t serve LedgerOne

### 5) Remove template “Home”

* Replace with LedgerOne Dashboard

### 6) Replace template fake data

* Remove mock repos
* Introduce LedgerOne domain entities

### 7) Error policy decisions

* Define what errors show inline vs silent

### 8) Theme & localization

* Set primary colors and baseline typography
* Only ship languages you realistically use

### 9) Tests

* Keep template structure
* Replace content as domain evolves

---

## Backup & security

* Full dataset backup to file
* Full restore from file (with explicit confirmation)
* Optional app-level lock (PIN/biometric)



---

## Future scope (don’t block v1)

* Positions & baskets
* Risk allocation
* Automated exchange imports
* Background price polling
* Charts & dashboards

The current model naturally supports these later without schema rewrites.



---

## Status

This README reflects the **project foundation**, not implementation status.
Before “real app work,” the repo should be cleaned according to the checklist above.
