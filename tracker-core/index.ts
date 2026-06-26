// Chain-agnostic runtime shared by the Solana and Sui NAV trackers.
// Depends only on the D1 binding — no chain SDKs. Keeps the snapshot writes
// byte-identical to the current per-tracker implementations.

import type { LstMintRow } from '../contract/d1-rows';

export interface TrackerEnvBase {
  DB: D1Database;
  NAV_INTERVAL_MIN?: string;
}

export interface RunSummary {
  processed: number;
  failed: number;
  skipped?: boolean;
  reason?: string;
  lastTs?: number | null;
}

export const DEFAULT_INTERVAL_MIN = 15;
export const DEFAULT_MAX_PARALLEL = 4;

/** First parseable interval (minutes) among candidates, else DEFAULT_INTERVAL_MIN. */
export function resolveIntervalMin(...candidates: (string | undefined | null)[]): number {
  for (const c of candidates) {
    const n = Number(c);
    if (c != null && c !== '' && Number.isFinite(n) && n > 0) return n;
  }
  return DEFAULT_INTERVAL_MIN;
}

/** Latest snapshot ts for a chain (interval-guard anchor), or null. */
export async function getLastSnapshotTs(db: D1Database, chain: string): Promise<number | null> {
  const row = await db
    .prepare('SELECT ts FROM token_supply_snapshots WHERE chain = ?1 ORDER BY ts DESC LIMIT 1')
    .bind(chain)
    .first<{ ts: number }>();
  return row?.ts ?? null;
}

/** True when the min interval since lastTs has not elapsed (i.e. skip the run). */
export function isWithinInterval(
  lastTs: number | null,
  intervalMs: number,
  now: number = Date.now(),
): boolean {
  return lastTs != null && now - lastTs < intervalMs;
}

/** Active LSTs for a chain. stake_pool is NOT NULL by schema, so SELECT * is safe. */
export async function fetchActiveLsts(db: D1Database, chain: string): Promise<LstMintRow[]> {
  const { results } = await db
    .prepare('SELECT * FROM lst_mints WHERE chain = ?1 AND is_active = 1')
    .bind(chain)
    .all<LstMintRow>();
  return results ?? [];
}

export async function upsertTokenSupply(
  db: D1Database,
  chain: string,
  mint: string,
  ts: number,
  slot: number,
  amount: bigint,
): Promise<void> {
  await db
    .prepare(
      `INSERT INTO token_supply_snapshots (chain, mint, ts, slot, token_supply_lamports)
       VALUES (?1, ?2, ?3, ?4, ?5)
       ON CONFLICT(chain, mint, slot) DO UPDATE
       SET ts = excluded.ts, token_supply_lamports = excluded.token_supply_lamports`,
    )
    .bind(chain, mint, ts, slot, amount.toString())
    .run();
}

export async function upsertDelegated(
  db: D1Database,
  chain: string,
  mint: string,
  ts: number,
  slot: number,
  amount: bigint,
): Promise<void> {
  await db
    .prepare(
      `INSERT INTO delegated_snapshots (chain, mint, ts, slot, delegated_lamports)
       VALUES (?1, ?2, ?3, ?4, ?5)
       ON CONFLICT(chain, mint, slot) DO UPDATE
       SET ts = excluded.ts, delegated_lamports = excluded.delegated_lamports`,
    )
    .bind(chain, mint, ts, slot, amount.toString())
    .run();
}

/**
 * Refresh the materialized nav_latest serving table for a chain from the
 * v_rate_latest_aligned view. Call after a tracker run. Output is identical to
 * the view, so lst-nav-api can read nav_latest (with a view fallback) without
 * changing the /latest response. Additive — no-op until migration 0006 applied.
 */
export async function refreshNavLatest(db: D1Database, chain: string): Promise<void> {
  await db
    .prepare(
      `INSERT OR REPLACE INTO nav_latest
         (chain, mint, slot, delegated_ts, supply_ts, delegated_lamports, token_supply_lamports, rate_text)
       SELECT chain, mint, slot, delegated_ts, supply_ts, delegated_lamports, token_supply_lamports, rate_text
       FROM v_rate_latest_aligned
       WHERE chain = ?1`,
    )
    .bind(chain)
    .run();
}

/** Run handler over items with a bounded number of concurrent workers. */
export async function mapWithConcurrency<T>(
  items: T[],
  limit: number,
  handler: (item: T) => Promise<void>,
): Promise<void> {
  const queue = [...items];
  const workers: Promise<void>[] = [];
  for (let i = 0; i < Math.min(limit, queue.length); i += 1) {
    workers.push(
      (async function run() {
        while (queue.length) {
          const next = queue.shift();
          if (next === undefined) return;
          await handler(next);
        }
      })(),
    );
  }
  await Promise.all(workers);
}

/**
 * Shared HTTP surface for tracker workers:
 *   GET /health -> "ok"
 *   GET /run    -> runs once, returns the RunSummary as JSON (500 on throw)
 *   else        -> 404
 */
export function createTrackerFetchHandler<E extends TrackerEnvBase>(
  runOnce: (env: E) => Promise<RunSummary>,
) {
  return async (request: Request, env: E): Promise<Response> => {
    const url = new URL(request.url);
    if (url.pathname === '/health') {
      return new Response('ok');
    }
    if (url.pathname === '/run') {
      try {
        const result = await runOnce(env);
        return Response.json(result);
      } catch (err) {
        console.error('run error', err);
        return new Response('run failed', { status: 500 });
      }
    }
    return new Response('not found', { status: 404 });
  };
}
