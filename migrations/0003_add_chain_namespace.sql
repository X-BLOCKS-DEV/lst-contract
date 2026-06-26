-- Explicitly manage FKs while reshaping tables to keep existing data
PRAGMA foreign_keys = OFF;

-- 既存ビューを更新するために削除
DROP VIEW IF EXISTS v_rate_latest_aligned;

-- 既存データをバックアップ（念のため。再実行時に備えて先に削除）
DROP TABLE IF EXISTS delegated_snapshots_backup;
DROP TABLE IF EXISTS token_supply_snapshots_backup;
CREATE TABLE delegated_snapshots_backup AS SELECT * FROM delegated_snapshots;
CREATE TABLE token_supply_snapshots_backup AS SELECT * FROM token_supply_snapshots;

-- lst_mints を chain 付きスキーマに移行（データ保持）
CREATE TABLE lst_mints_new (
  chain      TEXT NOT NULL,        -- "sol" or "sui"
  mint       TEXT NOT NULL,
  name       TEXT NOT NULL,
  stake_pool TEXT NOT NULL,
  added_at   INTEGER NOT NULL,
  is_active  INTEGER NOT NULL DEFAULT 1,
  PRIMARY KEY (chain, mint)
);

INSERT INTO lst_mints_new (chain, mint, name, stake_pool, added_at, is_active)
SELECT
  'sol' AS chain,
  mint,
  name,
  stake_pool,
  added_at,
  is_active
FROM lst_mints;

DROP TABLE lst_mints;
ALTER TABLE lst_mints_new RENAME TO lst_mints;

-- delegated_snapshots を chain 付きスキーマに移行（データ保持）
DROP TABLE IF EXISTS delegated_snapshots_new;
CREATE TABLE delegated_snapshots_new (
  chain              TEXT NOT NULL,
  mint               TEXT NOT NULL,
  ts                 INTEGER NOT NULL,
  slot               INTEGER NOT NULL,
  delegated_lamports INTEGER NOT NULL,
  PRIMARY KEY (chain, mint, slot),
  FOREIGN KEY (chain, mint) REFERENCES lst_mints(chain, mint) ON DELETE CASCADE
);

INSERT INTO delegated_snapshots_new (chain, mint, ts, slot, delegated_lamports)
SELECT
  'sol' AS chain,
  mint,
  ts,
  slot,
  delegated_lamports
FROM delegated_snapshots;

DROP TABLE delegated_snapshots;
ALTER TABLE delegated_snapshots_new RENAME TO delegated_snapshots;

-- token_supply_snapshots を chain 付きスキーマに移行（データ保持）
DROP TABLE IF EXISTS token_supply_snapshots_new;
CREATE TABLE token_supply_snapshots_new (
  chain                  TEXT NOT NULL,
  mint                   TEXT NOT NULL,
  ts                     INTEGER NOT NULL,
  slot                   INTEGER NOT NULL,
  token_supply_lamports  INTEGER NOT NULL,
  PRIMARY KEY (chain, mint, slot),
  FOREIGN KEY (chain, mint) REFERENCES lst_mints(chain, mint) ON DELETE CASCADE
);

INSERT INTO token_supply_snapshots_new (chain, mint, ts, slot, token_supply_lamports)
SELECT
  'sol' AS chain,
  mint,
  ts,
  slot,
  token_supply_lamports
FROM token_supply_snapshots;

DROP TABLE token_supply_snapshots;
ALTER TABLE token_supply_snapshots_new RENAME TO token_supply_snapshots;

-- バックアップから chain 付きテーブルへ再投入（D1 の挙動によるデータ消失を防止）
INSERT OR IGNORE INTO delegated_snapshots (chain, mint, ts, slot, delegated_lamports)
SELECT 'sol' AS chain, mint, ts, slot, delegated_lamports
FROM delegated_snapshots_backup;

INSERT OR IGNORE INTO token_supply_snapshots (chain, mint, ts, slot, token_supply_lamports)
SELECT 'sol' AS chain, mint, ts, slot, token_supply_lamports
FROM token_supply_snapshots_backup;

DROP TABLE delegated_snapshots_backup;
DROP TABLE token_supply_snapshots_backup;

-- 整合済みビュー（chain 対応版）
CREATE VIEW v_rate_latest_aligned AS
WITH
latest_slots AS (
  SELECT
    m.chain,
    m.mint,
    (SELECT MAX(slot) FROM delegated_snapshots WHERE chain=m.chain AND mint=m.mint) AS latest_d_slot,
    (SELECT MAX(slot) FROM token_supply_snapshots WHERE chain=m.chain AND mint=m.mint) AS latest_s_slot
  FROM lst_mints m
  WHERE m.is_active = 1
),
targets AS (
  SELECT
    chain,
    mint,
    MIN(latest_d_slot, latest_s_slot) AS target_slot
  FROM latest_slots
)
SELECT
  t.chain,
  t.mint,
  t.target_slot AS slot,
  d.ts AS delegated_ts,
  s.ts AS supply_ts,
  d.delegated_lamports,
  s.token_supply_lamports,
  printf('%.9f', (1.0 * d.delegated_lamports) / s.token_supply_lamports) AS rate_text
FROM targets t
JOIN delegated_snapshots d
  ON d.chain = t.chain AND d.mint = t.mint AND d.slot = (
    SELECT MAX(slot) FROM delegated_snapshots
    WHERE chain=t.chain AND mint=t.mint AND slot <= t.target_slot
  )
JOIN token_supply_snapshots s
  ON s.chain = t.chain AND s.mint = t.mint AND s.slot = (
    SELECT MAX(slot) FROM token_supply_snapshots
    WHERE chain=t.chain AND mint=t.mint AND slot <= t.target_slot
  )
WHERE t.target_slot IS NOT NULL;

PRAGMA foreign_keys = ON;
