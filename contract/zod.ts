// Runtime (zod) schemas for the NAV API contract. Consumed by lst-folio for
// response validation. Mirrors lst-folio/src/lib/types.ts (navRateSchema /
// navHistoryPointSchema / chainSchema) so the UI keeps validating identically.
// Isolated from the plain-TS contract so the Worker API need not depend on zod.

import { z } from 'zod';

export const chainSchema = z.enum(['sol', 'sui']);
export type Chain = z.infer<typeof chainSchema>;

export const navRateSchema = z.object({
  mint: z.string(),
  chain: z.string(),
  slot: z.number().optional(),
  delegated_ts: z.number().optional(),
  supply_ts: z.number().optional(),
  delegated_amount: z.coerce.number().optional(),
  token_supply_amount: z.coerce.number().optional(),
  amount_unit: z.string().optional(),
  rate: z.coerce.number(),
  symbol: z.string().optional(),
});
export type NavRate = z.infer<typeof navRateSchema> & { updatedAt?: string };

export const navHistoryPointSchema = z.object({
  chain: z.string().optional(),
  mint: z.string().optional(),
  ts: z.coerce.number(),
  slot: z.number().optional(),
  delegated_amount: z.coerce.number().optional(),
  token_supply_amount: z.coerce.number().optional(),
  amount_unit: z.string().optional(),
  rate: z.coerce.number(),
});
export type NavHistoryPoint = z.infer<typeof navHistoryPointSchema>;
