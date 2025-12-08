# LedgerOne

## 1. Product Summary

**Working name:** LedgerOne
**Platform:** Flutter (mobile first).
**Core idea:**
One offline-first app that:

* Tracks all assets you own (crypto + fiat).
* Knows where they live (exchanges, wallets, banks, cash).
* Lets you manually log what happens (trades, transfers, expenses, income).
* Can optionally compute a USD portfolio value using a **manual “Update prices”** action and flexible per-asset price configs.

No live charts. No trading tools. No automations. Just clarity.

---

## 2. Design Principles (things the dev must not mess up)

1. **Offline-first**

   * App must work fully offline for:

     * viewing balances
     * adding/editing transactions
     * managing assets/accounts/categories
   * Internet is used only when the user explicitly taps “Update prices”.

2. **Single source of truth**

   * Balances are always derived from transactions.
   * No hidden balance fields that can get out of sync.

3. **One unified model**

   * Money and crypto share the same underlying data model.
   * “Crypto tab” and “Money tab” are just different views/filters.

4. **No positions, no guardrails in v1**

   * No “open positions”, “targets”, “warnings”, or risk rules.
   * Keep it lean; these are future extensions.

5. **User owns everything**

   * Local storage only.
   * Simple export/backup.
   * No external account connections (no exchange API keys in v1).

---

## 3. Core Concepts (Domain Model)

Describe these clearly to the builder; they map to DB tables and domain classes.

### 3.1 Asset

Represents any unit of value you track.

Attributes:

* Identifier (internal id)
* Symbol (for display, e.g. BTC, ETH, USDT, EUR)
* Name (Bitcoin, Ether, Euro, etc.)
* Type: crypto, fiat, or other
* Number of decimals (precision)
* Optional “price source configuration” (stored as text; this will be the JSON-like config the user pastes)

Notes:

* USDT is just another asset.
* EUR is just another asset.
* The app does not hardcode any asset list; user can create assets but you can ship some defaults.

---

### 3.2 Account

Represents a container where assets live (exchange, wallet, bank…).

Attributes:

* Identifier
* Name (e.g. Binance Spot, Metamask, ING Main)
* Type: exchange, bank, wallet, cash, other
* Notes

---

### 3.3 Category

Used primarily for fiat income/expense classification.

Attributes:

* Identifier
* Name (Rent, Groceries, Investment, Salary, etc.)
* Kind: expense, income, transfer, or mixed
* Optional parent category (for grouping)

---

### 3.4 Transaction

A real-world event at a specific time:

Examples: trade, transfer, income, expense, correction.

Attributes:

* Identifier
* Date and time (ISO 8601 format)
* Kind: trade, transfer, income, expense, adjustment
* Description (free text)

Important: a transaction is just a logical “envelope” that contains one or more “legs”.

---

### 3.5 Transaction Leg

Each leg represents the change to one account in one asset.

Attributes:

* Identifier
* Reference to a transaction
* Reference to an account
* Reference to an asset
* Amount:

  * Positive means balance increases.
  * Negative means balance decreases.
* Role: main, fee, gas, tax, or other
* Optional category (mainly used for fiat expenses/income legs)

Example mental mapping:

* “You send 500 EUR from Bank A to Binance” = one transfer transaction with two legs:

  * Bank A / EUR: -500 (main)
  * Binance / EUR: +500 (main)

All balances come from summing these legs.

---

### 3.6 Price Snapshot

Stored price of an asset in some currency (in this version: always USD) at a given time.

Attributes:

* Identifier
* Reference to asset
* Currency code (e.g. USD)
* Price (1 unit of the asset in that currency)
* Timestamp of when it was taken
* Optional source name (e.g. “coingecko”, “binance”)

These are created only when the user runs a manual price update.

---

### 3.7 Price Source Configuration

This is not a separate stored entity; it’s part of the asset as a text field.

Concept:

* A structured configuration describing how to fetch the asset’s price from any HTTP API.

Fields (conceptual, the builder will map this to JSON structure internally):

* HTTP method (usually GET)
* URL of the endpoint
* Query parameters (key–value pairs)
* Headers (key–value pairs)
* Path inside the JSON response where the numeric price is found, using a simple dot notation
* Multiplier to transform the returned value if needed (for example, if the API returns cents instead of units)

The app must:

* Parse this configuration from text.
* Validate it.
* Use it to run HTTP requests during price updates.
* Extract the numeric price from the API response.

---

## 4. Core Behaviors and Calculations

These rules are important; they define how the app “thinks”.

### 4.1 Balances

Balance of an asset in a specific account:

* Sum of all amounts from transaction legs where account and asset match.

Total balance of an asset across all accounts:

* Sum of all amounts from legs with that asset, regardless of account.

There is no separate “balance table”. All balances must be derived from transaction legs.

---

### 4.2 USD Valuation

For each asset with a non-zero total balance:

1. Look up the most recent price snapshot in USD for that asset.
2. Multiply asset balance by that price → asset value in USD.
3. Sum all asset USD values to get portfolio USD value.

If an asset has no price snapshot:

* Its USD value is treated as unknown.
* The UI should still show its quantity, but no USD valuation.

---

### 4.3 Price Update Flow

Triggered by a manual user action, such as a button “Update prices”.

Behavior:

1. Find all assets that have a price source configuration defined.
2. For each of these assets:

   * Parse the config.
   * Perform the HTTP request described in the config.
   * Parse the response.
   * Extract the price using the configured response path.
   * Apply the multiplier.
   * Create a new price snapshot record for that asset in USD, with the current timestamp.

Rules:

* Failures for one asset must not cancel updates for others.
* The app should surface basic errors (e.g. invalid config, HTTP error, parse error).
* No automatic background price updates. Only manual.

---

### 4.4 Transaction Types and Patterns

The builder should implement **predefined transaction flows** that generate transaction + legs correctly.

You want these patterns:

1. Trade (crypto or fiat-for-crypto)

   * One account.
   * At least one leg where an asset decreases (what you pay).
   * At least one leg where another asset increases (what you receive).
   * Optional fee leg(s) in a third asset or the same asset.

2. Transfer

   * Same asset.
   * Two accounts.
   * One negative leg (source account), one positive leg (destination account).

3. Income

   * Typically fiat.
   * One positive leg on a fiat account.
   * Optional category (e.g. Salary).

4. Expense

   * Typically fiat.
   * One negative leg on a fiat account.
   * Category required (Rent, Groceries, etc.).

5. Adjustment

   * For corrections, manual fixing, imported balances.
   * App should allow arbitrary legs, but clearly mark these as adjustments.

---

## 5. Application Structure (High-Level Modules)

The builder can choose patterns, but you want roughly this structure:

1. **Presentation / UI**

   * Screens:

     * Dashboard
     * Crypto
     * Money
     * Transaction editor
     * Asset editor
     * Account editor
     * Category manager
     * Settings / Backup / Price update
   * State management appropriate for Flutter.

2. **Domain / Application Layer**

   * Services or use-cases responsible for:

     * Creating/editing/deleting assets, accounts, categories.
     * Creating transactions via the predefined flows (trade, transfer, income, expense, adjustment).
     * Computing balances per account and per asset.
     * Computing portfolio-level data (e.g. crypto vs fiat in USD).
     * Parsing and executing price source configurations.
     * Generating backups and exports.

3. **Data Layer**

   * Local persistence (SQLite or similar).
   * HTTP client for price updates.
   * Mappers between storage models and domain entities.

---

## 6. Screens and UX (What the User Actually Sees)

Describe it so the builder doesn’t guess.

### 6.1 Main Navigation

Main navigation uses bottom tabs:

* Dashboard
* Crypto
* Money
* Settings

Tabs should be independent views over the same data.

---

### 6.2 Dashboard

Purpose:

* Quick overview of entire financial picture.

Should show:

* Total portfolio value in USD (if any price snapshots exist).
* Total crypto value in USD.
* Total fiat value in USD.
* Option to refresh prices (manual button).
* A simple list of top few assets by USD value (show symbol, quantity, USD value if available).

No charts required in v1; if at all, very simple.

---

### 6.3 Crypto Tab

Two main sections:

1. View by Asset:

   * List of all crypto assets with:

     * Symbol and name.
     * Total quantity across all accounts.
     * Latest known USD valuation if available.
   * Selecting an asset opens a detail view:

     * Per-account breakdown (how much BTC on each exchange/wallet).
     * Transaction history related to that asset.

2. View by Account:

   * List of accounts where type is exchange or wallet.
   * Each entry shows:

     * Account name.
     * Number of different assets.
   * Selecting an account opens:

     * List of assets held in that account.
     * Balance per asset.
     * Transaction history for that account.

Actions in Crypto tab:

* Add trade.
* Add transfer between accounts.
* Add deposit from external.
* Add withdrawal to external.

All these actions open the Transaction editor with appropriate type and pre-configured structure.

---

### 6.4 Money Tab

Focuses on fiat and categories.

Sections:

1. Accounts:

   * List of fiat-related accounts (type: bank, cash, maybe fintech).
   * Show current balance per account in its native asset (e.g. EUR).

2. Transactions:

   * Filterable list of income and expense transactions.
   * Default filter: current month.
   * Basic summary:

     * Total income this period.
     * Total expenses this period.
     * Net result.

3. Categories:

   * Group expenses by category for the current period (e.g. Rent, Groceries, etc.).
   * Simple list with totals.

Actions:

* Add income.
* Add expense.
* Add transfer between fiat accounts.

---

### 6.5 Transaction Editor

Unified screen that adapts based on transaction kind.

User flow:

1. Select transaction type:

   * Trade
   * Transfer
   * Income
   * Expense
   * Adjustment

2. Form fields adjust:

For trades:

* Choose account.
* Choose “from” asset and amount.
* Choose “to” asset and amount.
* Optional fee asset and amount.
* Date/time.
* Description.

For transfers:

* From account, to account.
* Asset and amount.
* Date/time.
* Description.

For income:

* Account.
* Asset (usually fiat).
* Amount.
* Category (income type).
* Date/time.
* Description.

For expense:

* Account.
* Asset (usually fiat).
* Amount.
* Category (expense type).
* Date/time.
* Description.

Internally, this screen must translate user input into a Transaction plus the correct set of Transaction Legs.

---

### 6.6 Asset Editor

Purpose:

* Create or edit an asset and optionally attach a price source configuration.

Fields:

* Symbol.
* Name.
* Type (crypto / fiat / other).
* Decimals.
* Optional price source config text area for advanced users.

Additional behavior:

* Button to “Test price source”:

  * Parses config.
  * Calls the API.
  * Tries to extract a numeric price.
  * Shows result or error clearly (without saving if it fails).

---

### 6.7 Account Editor

Fields:

* Name.
* Type.
* Notes.

---

### 6.8 Settings / Tools

Contains:

* Manual price update button (same function as on Dashboard).
* Data export:

  * Export whole database or full dataset as a single file (backup).
  * Optionally, export CSV summaries (not mandatory in v1 but nice).
* Data import / restore from backup file.
* Maybe app lock settings (PIN/biometric) if implemented.

---

## 7. Security and Backup Expectations

The blueprint should tell the builder:

* All financial data is stored locally on the device.

* Support an easy backup mechanism:

  * Single backup file containing either the DB file or a serialized version of all entities.
  * Restore should overwrite local data after a clear confirmation.

* If feasible, support app-level lock (PIN or biometric) to open the app, especially if platform support is straightforward.

---

## 8. Future-Proofing (Optional but Important for Architecture)

Even though v1 will not implement these, the design should allow them later without breaking the schema:

* Positions (grouping certain transaction legs into “investment positions”).
* Guardrails / allocation rules:

  * For example: rules that compare crypto vs fiat proportions, or warn on certain thresholds.
* Exchange API integrations:

  * Ability to add a separate module that imports transactions from real APIs into the same data model.

The chosen model (assets, accounts, transactions, legs, price snapshots) already supports these naturally; the builder just needs to avoid hardcoding assumptions that block extensions.
