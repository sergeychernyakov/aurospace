// src/api/accounts.ts

import { useQuery } from '@tanstack/react-query';
import { api } from './client';
import type { Account } from './types';

export function useAccount(userId: number | null) {
  return useQuery<Account>({
    queryKey: ['account', userId],
    queryFn: () => api.get<Account>(`/accounts/${userId}?user_id=${userId}`),
    enabled: userId !== null,
  });
}
