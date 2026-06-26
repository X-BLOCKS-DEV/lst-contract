-- Serving table: materialized latest aligned NAV per LST.
-- Mirrors the v_rate_latest_aligned view exactly. Refreshed by the trackers
-- after each run (refreshNavLatest); read by lst-nav-api /latest with a view
-- fallback, so this is purely additive and safe to apply at any time.
CREATE TABLE IF NOT EXISTS nav_latest (
  chain                 TEXT    NOT NULL,
  mint                  TEXT    NOT NULL,
  slot                  INTEGER NOT NULL,
  delegated_ts          INTEGER NOT NULL,
  supply_ts             INTEGER NOT NULL,
  delegated_lamports    INTEGER NOT NULL,
  token_supply_lamports INTEGER NOT NULL,
  rate_text             TEXT    NOT NULL,
  PRIMARY KEY (chain, mint)
);
