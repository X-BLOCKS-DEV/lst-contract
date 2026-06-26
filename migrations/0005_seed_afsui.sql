-- Seed AfSUI (Aftermath, Sui mainnet) for cross-chain tracking.
INSERT OR REPLACE INTO lst_mints (
  chain, mint, name, stake_pool, added_at, is_active, decimals, backing_method, backing_locator
) VALUES (
  'sui',
  '0xf325ce1300e8dac124071d3152c5c5ee6174914f8bc2161e88329cf579246efc::afsui::AFSUI',
  'AfSUI',
  '0x55486449e41d89cfbdb20e005c1c5c1007858ad5b4d5d7c047d2b3b592fe8791',
  strftime('%s','now')*1000,
  1,
  9,
  'object_field',
  '{"objectId":"0x55486449e41d89cfbdb20e005c1c5c1007858ad5b4d5d7c047d2b3b592fe8791","path":["content","fields","total_sui_amount"]}'
);
