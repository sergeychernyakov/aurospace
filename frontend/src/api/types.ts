// src/api/types.ts

import { z } from 'zod';

export const UserSchema = z.object({
  id: z.number(),
  email: z.string(),
  name: z.string(),
  created_at: z.string(),
});

export const AccountSchema = z.object({
  id: z.number(),
  user_id: z.number(),
  balance_cents: z.number(),
  currency: z.string(),
  ledger_entries: z
    .array(
      z.object({
        id: z.number(),
        entry_type: z.string(),
        amount_cents: z.number(),
        currency: z.string(),
        reference: z.string().nullable(),
        order_id: z.number(),
        created_at: z.string(),
      }),
    )
    .optional(),
});

export const LedgerEntrySchema = z.object({
  id: z.number(),
  entry_type: z.string(),
  amount_cents: z.number(),
  currency: z.string(),
  reference: z.string().nullable(),
  order_id: z.number(),
  created_at: z.string(),
});

export const OrderSchema = z.object({
  id: z.number(),
  user_id: z.number(),
  amount_cents: z.number(),
  currency: z.string(),
  status: z.string(),
  payment_provider: z.string().nullable(),
  external_payment_id: z.string().nullable(),
  paid_at: z.string().nullable(),
  cancelled_at: z.string().nullable(),
  created_at: z.string(),
  updated_at: z.string(),
  ledger_entries: z.array(LedgerEntrySchema).optional(),
});

export type User = z.infer<typeof UserSchema>;
export type Account = z.infer<typeof AccountSchema>;
export type LedgerEntry = z.infer<typeof LedgerEntrySchema>;
export type Order = z.infer<typeof OrderSchema>;
