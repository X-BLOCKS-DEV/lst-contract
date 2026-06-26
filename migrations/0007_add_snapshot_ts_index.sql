-- Speed up the /rates time-series query.
-- /rates does correlated lookups per tick:
--   SELECT slot FROM <snapshot> WHERE chain=? AND mint=? AND ts<=? ORDER BY ts DESC LIMIT 1
-- The PK is (chain,mint,slot), so there is no index on ts — each lookup full-scans
-- the (chain,mint) partition. Over ~22k snapshots × 730 daily ticks this measured
-- ~9s on production (exceeds Worker/D1 limits → /rates hangs). These covering
-- indexes make each lookup O(log n) (~5ms total). Additive + idempotent.
CREATE INDEX IF NOT EXISTS idx_delegated_chain_mint_ts ON delegated_snapshots(chain, mint, ts);
CREATE INDEX IF NOT EXISTS idx_supply_chain_mint_ts   ON token_supply_snapshots(chain, mint, ts);
