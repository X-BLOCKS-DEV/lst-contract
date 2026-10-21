# bclab LST stack — governance

Rules that keep the shared infrastructure safe. The API contract and UI output
are held byte-identical; changes are staged and reversible.

## Shared D1 (one database per environment)
Three Workers share **one D1 per env**: the trackers write snapshots, the API
reads.

| env | db name | database_id |
|---|---|---|
| staging | `lst_nav_stg` | `da381ef4-ff8f-4910-a763-59620b58e095` |
| production | `lst_nav` | `39f43eb7-38ef-43d9-b7d4-4b2c68b56508` |

Tables: `lst_mints`, `delegated_snapshots`, `token_supply_snapshots`,
`nav_latest` (serving), view `v_rate_latest_aligned`, and the price tables
`price_coins` / `price_quotes` (0009; written by lst-nav-api, see below).

## Schema & migrations — single owner
- The **canonical schema lives here** (`lst-contract/migrations`).
- Migrations are **applied by exactly one pipeline**: `solana-lst-nav-tracker`
  (its deploy workflow runs `d1 migrations apply`). The Sui tracker, the API,
  and folio **never** apply migrations — they deploy only. This prevents
  migration races on the shared D1.
- Adding a migration: add the file to `lst-contract/migrations` only. The Solana
  tracker reads them through the submodule (`migrations_dir =
  "lst-contract/migrations"`), so bump its submodule pointer; its staging deploy
  (on merge) applies the migration to staging, and Run workflow applies it to
  production. Prefer additive changes.
- 0008 is reserved for the pending snapshot-read index change.

## Backups
- The Solana and API production/staging deploy workflows export D1 to R2
  (`lst-nav-backup`) before deploying. Take a manual backup before any
  non-additive schema change.

## Deploy model
- **Merge to `main` = staging deploy** (typecheck/tests gate it).
- **Production = Actions → Deploy production → Run workflow on `main`**; the job
  refuses any other ref. There are no `staging` / `production` branches.
- The top-level wrangler config of each Worker is dev-only (`*-dev` names), so a
  plain `wrangler deploy` from a laptop cannot overwrite a production Worker.
- The deploy bundles consume `lst-contract` as a submodule, so every CI checkout
  must use `actions/checkout@v4` with `submodules: recursive`. Clone locally with
  `git submodule update --init --recursive`.

## Serving boundary (nav_latest)
- Trackers refresh `nav_latest` from `v_rate_latest_aligned` after each run
  (`refreshNavLatest`). The API serves `/latest` from `nav_latest` with a view
  fallback, so output is identical and rollout order is irrelevant.
- `/rates` continues to read the raw snapshot history.

## Cron-trigger limit (account)
- The Cloudflare account has a **5 cron-trigger cap**. Staging Workers run no
  cron (set `crons = []` explicitly: wrangler leaves existing schedules alone
  when a config has no triggers). Production crons: Solana tracker, Sui tracker,
  lst-nav-api price collector, plus the 2023 price-feeder Workers until they are
  retired.

## Prices
- `lst-nav-api` owns price data end to end: its production cron collects JPY
  quotes from CoinMarketCap every 15 min (`CMC_API_KEY` Worker secret), it
  serves `/prices/latest` and `/prices/history`, and `/legacy/*` keeps the 2023
  price API shape for the old NOVA dashboard. Backfills run from its
  `price-backfill` workflow (dry run by default).

## Lockfiles / toolchain
- Each deployable repo should commit a lockfile and use `--frozen-lockfile` in
  CI. The local Nix devshell pnpm may differ from CI pnpm; verify with
  `wrangler deploy --dry-run` (bundles) and the repo's typecheck/tests.
