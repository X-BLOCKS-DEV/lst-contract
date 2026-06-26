# lst-contract

Canonical, single-source-of-truth contract for the bclab LST NAV stack
(`lst-nav-api`, `solana-lst-nav-tracker`, `sui-lst-nav-tracker`, `lst-folio`).

Consumed **as source** via git submodule — no build/publish step. Workers
(esbuild/wrangler) and Next.js bundle the TS directly.

## Layout
- `migrations/` — **canonical** D1 schema for the shared `lst_nav` database
  (0001–0005). This is the source of truth; trackers/api consume it. Migration
  application stays on a single pipeline (see ownership note below).
- `contract/` — plain-TS contract (no zod): `chain.ts` (`Chain`, `parseChain`,
  `getAmountUnit`, `ErrorBody`), `step.ts` (`parseStep`), `d1-rows.ts`,
  `api-types.ts`. Import via `./contract`.
- `contract/zod.ts` — zod schemas for runtime validation (lst-folio). Import via
  `./contract/zod` only where zod is wanted (keeps the Worker API zod-free).
- `tracker-core/` — chain-agnostic runtime shared by the trackers: interval
  guard, `fetchActiveLsts`, snapshot upserts, `mapWithConcurrency`, and the
  `/health` + `/run` fetch handler. Depends only on the D1 binding.

## Usage (consumer repo)
```bash
git submodule add git@github.com:X-BLOCKS-DEV/lst-contract.git lst-contract
```
```ts
import { parseChain, getAmountUnit } from "./lst-contract/contract";
import { upsertTokenSupply } from "./lst-contract/tracker-core";
```
CI must check out submodules (`actions/checkout` with `submodules: recursive`).

## Schema ownership
The shared `lst_nav` D1 (one per env) is written by both trackers and read by
the API. To avoid migration races, **migrations live here** and are applied by a
single pipeline (currently `solana-lst-nav-tracker`); other repos deploy only.
