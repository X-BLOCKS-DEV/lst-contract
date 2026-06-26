PRAGMA foreign_keys = ON;

-- LSTメタ
CREATE TABLE IF NOT EXISTS lst_mints (
  mint           TEXT PRIMARY KEY,
  name           TEXT NOT NULL,
  stake_pool     TEXT NOT NULL,
  added_at       INTEGER NOT NULL,
  is_active      INTEGER NOT NULL DEFAULT 1,
  UNIQUE(name)
);

-- 委任スナップショット
CREATE TABLE IF NOT EXISTS delegated_snapshots (
  mint               TEXT NOT NULL,
  ts                 INTEGER NOT NULL,
  slot               INTEGER NOT NULL,
  delegated_lamports INTEGER NOT NULL,
  PRIMARY KEY (mint, slot),
  FOREIGN KEY (mint) REFERENCES lst_mints(mint) ON DELETE CASCADE
);

-- 供給スナップショット
CREATE TABLE IF NOT EXISTS token_supply_snapshots (
  mint                   TEXT NOT NULL,
  ts                     INTEGER NOT NULL,
  slot                   INTEGER NOT NULL,
  token_supply_lamports  INTEGER NOT NULL,
  PRIMARY KEY (mint, slot),
  FOREIGN KEY (mint) REFERENCES lst_mints(mint) ON DELETE CASCADE
);

-- 整合済みビュー（実運用）
CREATE VIEW IF NOT EXISTS v_rate_latest_aligned AS
WITH
latest_slots AS (
  SELECT
    m.mint,
    (SELECT MAX(slot) FROM delegated_snapshots WHERE mint=m.mint) AS latest_d_slot,
    (SELECT MAX(slot) FROM token_supply_snapshots WHERE mint=m.mint) AS latest_s_slot
  FROM lst_mints m
  WHERE m.is_active = 1
),
targets AS (
  SELECT
    mint,
    MIN(latest_d_slot, latest_s_slot) AS target_slot
  FROM latest_slots
)
SELECT
  t.mint,
  t.target_slot AS slot,
  d.ts AS delegated_ts,
  s.ts AS supply_ts,
  d.delegated_lamports,
  s.token_supply_lamports,
  printf('%.9f', (1.0 * d.delegated_lamports) / s.token_supply_lamports) AS rate_text
FROM targets t
JOIN delegated_snapshots d
  ON d.mint = t.mint AND d.slot = (
    SELECT MAX(slot) FROM delegated_snapshots
    WHERE mint=t.mint AND slot <= t.target_slot
  )
JOIN token_supply_snapshots s
  ON s.mint = t.mint AND s.slot = (
    SELECT MAX(slot) FROM token_supply_snapshots
    WHERE mint=t.mint AND slot <= t.target_slot
  );
