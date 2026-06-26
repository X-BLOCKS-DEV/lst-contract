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
`nav_latest` (serving), view `v_rate_latest_aligned`.

## Schema & migrations — single owner
- The **canonical schema lives here** (`lst-contract/migrations`).
- Migrations are **applied by exactly one pipeline**: `solana-lst-nav-tracker`
  (its deploy workflow runs `d1 migrations apply`). The Sui tracker, the API,
  and folio **never** apply migrations — they deploy only. This prevents
  migration races on the shared D1.
- Adding a migration: add the file to `lst-contract/migrations` **and** to
  `solana-lst-nav-tracker/migrations` (the applied copy), then deploy via the
  Solana pipeline. Prefer additive changes.

## Backups
- The Solana and API production/staging deploy workflows export D1 to R2
  (`lst-nav-backup`) before deploying. Take a manual backup before any
  non-additive schema change.

## Deploy model
- Deploys trigger **only on push to `staging` / `production`** branches.
- Feature branches and PRs to `main` **do not deploy**. Promote `main → staging
  → production` to roll out.
- The deploy bundles consume `lst-contract` as a submodule, so every CI checkout
  must use `actions/checkout@v4` with `submodules: recursive`. Clone locally with
  `git submodule update --init --recursive`.

## Serving boundary (nav_latest)
- Trackers refresh `nav_latest` from `v_rate_latest_aligned` after each run
  (`refreshNavLatest`). The API serves `/latest` from `nav_latest` with a view
  fallback, so output is identical and rollout order is irrelevant.
- `/rates` continues to read the raw snapshot history.

## Cron-trigger limit (account)
- The Cloudflare account is at the **5 cron-trigger cap**. Adding cron Workers or
  re-registering a stopped cron can exceed it. The Solana **staging** deploy is
  currently expected to fail at the schedule step (its staging cron is stopped);
  this is unrelated to code. Free a cron or raise the plan to turn it green.

## Lockfiles / toolchain
- Each deployable repo should commit a lockfile and use `--frozen-lockfile` in
  CI. The local Nix devshell pnpm may differ from CI pnpm; verify with
  `wrangler deploy --dry-run` (bundles) and the repo's typecheck/tests.
