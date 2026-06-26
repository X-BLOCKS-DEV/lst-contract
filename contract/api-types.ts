// Canonical lst-nav-api response shapes. These are the UI-facing contract:
// lst-folio validates against equivalent zod schemas (see ./zod.ts).
// Keep in lockstep with lst-nav-api/src/worker.ts response mappings.

import type { AmountUnit } from './chain';

/** GET /mints item — raw lst_mints row passthrough. */
export interface MintItem {
  chain: string;
  mint: string;
  name: string;
  stake_pool: string;
  added_at: number;
  decimals: number;
  backing_method: string;
  backing_locator: string;
  is_active: number;
}

/** GET /latest item — latest aligned NAV per LST. */
export interface LatestItem {
  chain: string;
  mint: string;
  slot: number;
  delegated_ts: number;
  supply_ts: number;
  delegated_amount: number | string;
  token_supply_amount: number | string;
  amount_unit: AmountUnit;
  rate: string;
}

/** GET /rates item — NAV time-series point. */
export interface RateItem {
  chain: string;
  mint: string;
  ts: number;
  slot: number;
  delegated_amount: number | string;
  token_supply_amount: number | string;
  amount_unit: AmountUnit;
  rate: string;
}
