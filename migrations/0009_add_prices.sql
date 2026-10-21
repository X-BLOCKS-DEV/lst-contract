-- JPY prices for the coins BCLAB shows (LST NAV valuation, NOVA dashboard).
-- Written by lst-nav-api: every 15 min from CoinMarketCap (source 'cmc'), plus
-- one-off backfills from the 2023 price-feeder-db ('legacy-cmc', 15-min since
-- 2023-12) and CoinGecko ('coingecko', hourly, used where CMC history is paid).
-- Purely additive; safe to apply at any time.
-- (0008 is reserved for the pending snapshot-read index change.)
CREATE TABLE IF NOT EXISTS price_coins (
  symbol         TEXT    PRIMARY KEY,
  legacy_coin_id INTEGER UNIQUE,   -- coin_id of the 2023 price API (NOVA compat routes)
  cmc_id         INTEGER NOT NULL,
  coingecko_id   TEXT    NOT NULL,
  slug           TEXT    NOT NULL,
  image_url      TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS price_quotes (
  symbol    TEXT    NOT NULL,
  ts        INTEGER NOT NULL,      -- epoch ms
  price_jpy REAL    NOT NULL,
  pct_1h    REAL,                  -- percent changes; NULL for CoinGecko backfill rows
  pct_24h   REAL,
  pct_7d    REAL,
  pct_30d   REAL,
  source    TEXT    NOT NULL,      -- cmc | legacy-cmc | coingecko
  PRIMARY KEY (symbol, ts)
) WITHOUT ROWID;

INSERT OR IGNORE INTO price_coins (symbol, legacy_coin_id, cmc_id, coingecko_id, slug, image_url) VALUES
  ('BTC', 1, 1,     'bitcoin',     'bitcoin',  'https://cryptologos.cc/logos/bitcoin-btc-logo.svg'),
  ('ETH', 2, 1027,  'ethereum',    'ethereum', 'https://cryptologos.cc/logos/ethereum-eth-logo.svg'),
  ('DOT', 3, 6636,  'polkadot',    'polkadot', 'https://cryptologos.cc/logos/polkadot-new-dot-logo.svg'),
  ('SOL', 4, 5426,  'solana',      'solana',   'https://cryptologos.cc/logos/solana-sol-logo.svg'),
  ('BNB', 5, 1839,  'binancecoin', 'bnb',      'https://cryptologos.cc/logos/bnb-bnb-logo.svg'),
  ('SUI', 6, 20947, 'sui',         'sui',      'https://cryptologos.cc/logos/sui-sui-logo.svg');
