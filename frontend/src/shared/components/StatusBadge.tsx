// src/shared/components/StatusBadge.tsx

import { clsx } from 'clsx';

const STATUS_STYLES: Record<string, string> = {
  created: 'bg-blue-100 text-blue-800 dark:bg-blue-900/50 dark:text-blue-300',
  payment_pending: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/50 dark:text-yellow-300',
  successful: 'bg-green-100 text-green-800 dark:bg-green-900/50 dark:text-green-300',
  cancelled: 'bg-red-100 text-red-800 dark:bg-red-900/50 dark:text-red-300',
  credit: 'bg-green-100 text-green-800 dark:bg-green-900/50 dark:text-green-300',
  debit: 'bg-blue-100 text-blue-800 dark:bg-blue-900/50 dark:text-blue-300',
  reversal: 'bg-orange-100 text-orange-800 dark:bg-orange-900/50 dark:text-orange-300',
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
        'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold',
        STATUS_STYLES[status] ?? 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300',
      )}
    >
      {STATUS_LABELS[status] ?? status}
    </span>
  );
}
