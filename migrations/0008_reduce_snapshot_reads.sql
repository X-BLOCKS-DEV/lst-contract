-- /rates: cover the slot projection as well as the timestamp search.
-- Keep 0007 immutable; replace its narrower indexes to avoid duplicate writes.
CREATE INDEX IF NOT EXISTS idx_delegated_chain_mint_ts_slot
  ON delegated_snapshots(chain, mint, ts, slot);
CREATE INDEX IF NOT EXISTS idx_supply_chain_mint_ts_slot
  ON token_supply_snapshots(chain, mint, ts, slot);
DROP INDEX IF EXISTS idx_delegated_chain_mint_ts;
DROP INDEX IF EXISTS idx_supply_chain_mint_ts;

-- Both trackers check the newest timestamp for a CHAIN every run.
-- (chain,mint,ts) cannot satisfy ORDER BY ts without scanning all mints.
CREATE INDEX IF NOT EXISTS idx_supply_chain_ts
  ON token_supply_snapshots(chain, ts DESC);
