// Canonical step parsing for the /rates time-series endpoint.
// Mirrors lst-nav-api parseStep / getDefaultStep behaviour exactly.

export const DEFAULT_STEP = '15m';

const STEP_MULTIPLIERS: Record<string, number> = {
  m: 60 * 1000,
  h: 60 * 60 * 1000,
  d: 24 * 60 * 60 * 1000,
};

/** Parse a step like "15m" / "1h" / "1d" into milliseconds, or null when invalid. */
export function parseStep(step: string): number | null {
  const match = /^(\d+)([mhd])$/.exec(step);
  if (!match) return null;
  const amount = Number(match[1]);
  const unit = match[2];
  return amount * STEP_MULTIPLIERS[unit] || null;
}

/** Resolve the default step from an env value, falling back to DEFAULT_STEP. */
export function resolveDefaultStep(navDefaultStep: string | undefined): string {
  if (!navDefaultStep) return DEFAULT_STEP;
  return parseStep(navDefaultStep) ? navDefaultStep : DEFAULT_STEP;
}
