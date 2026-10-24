-- Seed wstETH (Lido wrapped stETH, Ethereum mainnet) for cross-chain tracking.
--
-- Storage unit: decimals=9 means snapshots are stored in GWEI (10^9), the same
-- way sol uses lamports and sui uses mist. This is NOT wstETH's ERC-20 on-chain
-- decimals (18): its wei-denominated supply (~3.7e24) overflows SQLite's 64-bit
-- INTEGER, so the eth tracker scales wei down by 10^9. rate = delegated/supply
-- is unit-free, so the view's rate_text stays exact (= stEthPerToken/1e18 ≈ 1.25).
--
-- backing_method 'evm_exchange_rate': the eth tracker reads backing_locator for
-- the eth_call selectors (contract defaults to mint when "contract" is absent):
--   rateSelector   stEthPerToken() = 0x035faf82  (stETH per 1 wstETH, 1e18)
--   supplySelector totalSupply()   = 0x18160ddd  (wstETH total, wei)
-- Both verified on mainnet (block 26256174: rate 1.24700, supply 3,693,366).
INSERT OR REPLACE INTO lst_mints (
  chain, mint, name, stake_pool, added_at, is_active, decimals, backing_method, backing_locator
) VALUES (
  'eth',
  '0x7f39c581f595b53c5cb19bd0b3f8da6c935e2ca0',
  'wstETH',
  '0x7f39c581f595b53c5cb19bd0b3f8da6c935e2ca0',
  strftime('%s','now')*1000,
  1,
  9,
  'evm_exchange_rate',
  '{"rateSelector":"0x035faf82","supplySelector":"0x18160ddd"}'
);
