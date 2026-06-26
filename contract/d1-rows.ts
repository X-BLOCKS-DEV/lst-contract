// Canonical D1 row shapes for the shared lst_nav database.
// Source of truth: lst-contract/migrations (0001-0005). Column names keep the
// historical "lamports" suffix for both chains; the unit is conveyed via
// getAmountUnit(chain) at the API/UI boundary.

export interface LstMintRow {
  chain: string;
  mint: string;
  name: string;
  stake_pool: string;
  added_at: number;
  is_active: number;
  decimals: number;
  backing_method: string;
  backing_locator: string;
}

export interface DelegatedSnapshotRow {
  chain: string;
  mint: string;
  ts: number;
  slot: number;
  delegated_lamports: number | string;
}

export interface TokenSupplySnapshotRow {
  chain: string;
  mint: string;
  ts: number;
  slot: number;
  token_supply_lamports: number | string;
}

/** Row shape of the v_rate_latest_aligned view (per-LST latest aligned NAV). */
export interface RateLatestRow {
  chain: string;
  mint: string;
  slot: number;
  delegated_ts: number;
  supply_ts: number;
  delegated_lamports: number | string;
  token_supply_lamports: number | string;
  rate_text: string;
}
