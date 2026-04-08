// src/api/orders.ts

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from './client';
import type { Order } from './types';

export function useOrders(userId: number | null) {
  return useQuery<Order[]>({
    queryKey: ['orders', userId],
    queryFn: () => api.get<Order[]>(`/orders?user_id=${userId}`),
    enabled: userId !== null,
  });
}

export function useOrder(id: number | null) {
  return useQuery<Order>({
    queryKey: ['order', id],
    queryFn: () => api.get<Order>(`/orders/${id}`),
    enabled: id !== null,
    refetchOnMount: 'always',
    staleTime: 0,
    retry: 2,
  });
}

export function useCreateOrder() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (params: { user_id: number; amount_cents: number }) =>
      api.post<Order>('/orders', params),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['orders'] });
      void queryClient.invalidateQueries({ queryKey: ['account'] });
    },
  });
}

interface PayResponse {
  order: Order;
  confirmation_url: string;
}

export function usePayOrder() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (orderId: number) => api.post<PayResponse>(`/orders/${orderId}/pay`),
    onSuccess: (data) => {
      void queryClient.invalidateQueries({ queryKey: ['orders'] });
      void queryClient.invalidateQueries({ queryKey: ['order'] });
      void queryClient.invalidateQueries({ queryKey: ['account'] });
      // Redirect to YooKassa payment page
      if (data.confirmation_url) {
        window.location.href = data.confirmation_url;
      }
    },
  });
}

export function useCancelOrder() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (orderId: number) => api.post<Order>(`/orders/${orderId}/cancel`),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['orders'] });
      void queryClient.invalidateQueries({ queryKey: ['order'] });
      void queryClient.invalidateQueries({ queryKey: ['account'] });
    },
  });
}
