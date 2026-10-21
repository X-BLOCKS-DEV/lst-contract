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

/** GET /prices/latest item — newest JPY quote per symbol. */
export interface PriceLatestItem {
  symbol: string;
  ts: number;
  price_jpy: number;
  pct_1h: number | null;
  pct_24h: number | null;
  pct_7d: number | null;
  pct_30d: number | null;
  source: string;
}

/** GET /prices/history item — the newest quote at or before each step tick. */
export interface PriceHistoryItem {
  symbol: string;
  ts: number;
  price_jpy: number;
}

/** GET /legacy/prices/:coin_id/latest — shape of the 2023 price API (NOVA dashboard). */
export interface LegacyPriceQuote {
  quote_id: number;
  coin_id: number;
  price_jpy: number;
  updated_at: string;
  percent_change_1h: number | null;
  percent_change_24h: number | null;
  percent_change_7d: number | null;
  percent_change_30d: number | null;
  symbol: string;
  slug: string;
  image_url: string;
}

/** GET /legacy/coins item — shape of the 2023 price API (NOVA dashboard). */
export interface LegacyCoin {
  coin_id: number;
  cmc_id: number;
  symbol: string;
  slug: string;
  image_url: string;
}
