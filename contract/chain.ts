// Canonical chain + amount-unit contract shared across NAV trackers, API, and UI.
// Mirrors the existing behaviour in lst-nav-api (parseChain / getAmountUnit)
// and lst-folio (chainSchema). Plain TS only — no zod here so the Worker API
// can import it without pulling a runtime dependency.

export type Chain = 'sol' | 'sui';

export const SUPPORTED_CHAINS: readonly Chain[] = ['sol', 'sui'] as const;

export type AmountUnit = 'lamports' | 'mist';

export type ErrorCode = 'INVALID_PARAM' | 'NOT_FOUND' | 'INTERNAL_ERROR';

export interface ErrorBody {
  error: string;
  code: ErrorCode;
}

/** Returns the normalized chain, or null when invalid. Defaults to 'sol'. */
export function parseChain(value: string | null | undefined): Chain | null {
  const chain = (value ?? 'sol').toLowerCase();
  return chain === 'sol' || chain === 'sui' ? chain : null;
}

/** Base unit per chain: Solana lamports (10^9), Sui mist (10^9). */
export function getAmountUnit(chain: string): AmountUnit {
  return chain === 'sui' ? 'mist' : 'lamports';
}
