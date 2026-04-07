// src/shared/components/StatusBadge.tsx

import { clsx } from 'clsx';

const STATUS_STYLES: Record<string, string> = {
  created: 'bg-blue-900/50 text-blue-300',
  payment_pending: 'bg-yellow-900/50 text-yellow-300',
  successful: 'bg-green-900/50 text-green-300',
  cancelled: 'bg-red-900/50 text-red-300',
  credit: 'bg-green-900/50 text-green-300',
  reversal: 'bg-orange-900/50 text-orange-300',
};

const STATUS_LABELS: Record<string, string> = {
  created: 'Created',
  payment_pending: 'Payment Pending',
  successful: 'Successful',
  cancelled: 'Cancelled',
};

interface StatusBadgeProps {
  status: string;
}

export default function StatusBadge({ status }: StatusBadgeProps) {
  return (
    <span
      className={clsx(
        'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium',
        STATUS_STYLES[status] ?? 'bg-gray-700 text-gray-300',
      )}
    >
      {STATUS_LABELS[status] ?? status}
    </span>
  );
}
