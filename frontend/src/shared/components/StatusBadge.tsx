// src/shared/components/StatusBadge.tsx

import { clsx } from 'clsx';

const STATUS_STYLES: Record<string, string> = {
  created: 'bg-blue-100 text-blue-800',
  payment_pending: 'bg-yellow-100 text-yellow-800',
  successful: 'bg-green-100 text-green-800',
  cancelled: 'bg-red-100 text-red-800',
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
        STATUS_STYLES[status] ?? 'bg-gray-100 text-gray-800',
      )}
    >
      {STATUS_LABELS[status] ?? status}
    </span>
  );
}
