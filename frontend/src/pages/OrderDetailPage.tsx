// src/pages/OrderDetailPage.tsx

import { useParams, Link } from 'react-router-dom';
import { useOrder, usePayOrder, useCancelOrder } from '../api/orders';
import StatusBadge from '../shared/components/StatusBadge';
import MoneyFormat from '../shared/components/MoneyFormat';
import LoadingSpinner from '../shared/components/LoadingSpinner';
import ErrorDisplay from '../shared/components/ErrorDisplay';

export default function OrderDetailPage() {
  const { id } = useParams<{ id: string }>();
  const orderId = id ? Number(id) : null;
  const { data: order, isLoading, error } = useOrder(orderId);
  const payMutation = usePayOrder();
  const cancelMutation = useCancelOrder();

  if (isLoading) {
    return <LoadingSpinner />;
  }
  if (error) {
    return <ErrorDisplay message={error.message} />;
  }
  if (!order) {
    return <ErrorDisplay message="Order not found" />;
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Link to="/orders" className="cursor-pointer text-blue-600 hover:underline">
          &larr; Back to Orders
        </Link>
      </div>

      {/* Order Info Card */}
      <div className="rounded-lg border bg-white p-6 shadow-sm">
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Order #{order.id}</h1>
            <div className="mt-2">
              <StatusBadge status={order.status} />
            </div>
          </div>
          <div className="text-right">
            <p className="text-2xl font-bold">
              <MoneyFormat cents={order.amount_cents} currency={order.currency} />
            </p>
          </div>
        </div>

        <dl className="mt-6 grid grid-cols-2 gap-4 sm:grid-cols-4">
          <div>
            <dt className="text-sm text-gray-500">Created</dt>
            <dd className="mt-1 text-sm font-medium">
              {new Date(order.created_at).toLocaleString()}
            </dd>
          </div>
          {order.paid_at && (
            <div>
              <dt className="text-sm text-gray-500">Paid</dt>
              <dd className="mt-1 text-sm font-medium">
                {new Date(order.paid_at).toLocaleString()}
              </dd>
            </div>
          )}
          {order.cancelled_at && (
            <div>
              <dt className="text-sm text-gray-500">Cancelled</dt>
              <dd className="mt-1 text-sm font-medium">
                {new Date(order.cancelled_at).toLocaleString()}
              </dd>
            </div>
          )}
          {order.payment_provider && (
            <div>
              <dt className="text-sm text-gray-500">Provider</dt>
              <dd className="mt-1 text-sm font-medium">{order.payment_provider}</dd>
            </div>
          )}
          {order.external_payment_id && (
            <div>
              <dt className="text-sm text-gray-500">Payment ID</dt>
              <dd className="mt-1 text-sm font-mono text-xs">{order.external_payment_id}</dd>
            </div>
          )}
        </dl>

        {/* Action Buttons */}
        <div className="mt-6 flex gap-3">
          {order.status === 'created' && (
            <button
              onClick={() => payMutation.mutate(order.id)}
              disabled={payMutation.isPending}
              className="cursor-pointer rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-green-700 disabled:opacity-50"
            >
              {payMutation.isPending ? 'Processing...' : 'Pay'}
            </button>
          )}
          {order.status === 'payment_pending' && (
            <span className="inline-flex items-center rounded-lg bg-yellow-100 px-4 py-2 text-sm font-medium text-yellow-800">
              Waiting for payment...
            </span>
          )}
          {order.status === 'successful' && (
            <button
              onClick={() => {
                if (window.confirm('Are you sure you want to cancel this order?')) {
                  cancelMutation.mutate(order.id);
                }
              }}
              disabled={cancelMutation.isPending}
              className="cursor-pointer rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-red-700 disabled:opacity-50"
            >
              {cancelMutation.isPending ? 'Cancelling...' : 'Cancel Order'}
            </button>
          )}
        </div>

        {payMutation.isError && (
          <p className="mt-2 text-sm text-red-600">Payment failed: {payMutation.error.message}</p>
        )}
        {cancelMutation.isError && (
          <p className="mt-2 text-sm text-red-600">
            Cancellation failed: {cancelMutation.error.message}
          </p>
        )}
      </div>

      {/* Ledger Entries */}
      {order.ledger_entries && order.ledger_entries.length > 0 && (
        <div className="rounded-lg border bg-white shadow-sm">
          <div className="border-b px-4 py-3">
            <h2 className="font-semibold text-gray-900">Ledger Entries</h2>
          </div>
          <table className="w-full">
            <thead className="bg-gray-50 text-left text-xs font-medium uppercase text-gray-500">
              <tr>
                <th className="px-4 py-2">#</th>
                <th className="px-4 py-2">Type</th>
                <th className="px-4 py-2">Amount</th>
                <th className="px-4 py-2">Reference</th>
                <th className="px-4 py-2">Date</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {order.ledger_entries.map((entry) => (
                <tr key={entry.id}>
                  <td className="px-4 py-3 text-sm">{entry.id}</td>
                  <td className="px-4 py-3">
                    <StatusBadge status={entry.entry_type} />
                  </td>
                  <td className="px-4 py-3">
                    <MoneyFormat cents={entry.amount_cents} currency={entry.currency} />
                  </td>
                  <td className="px-4 py-3 text-sm text-gray-500">{entry.reference ?? '-'}</td>
                  <td className="px-4 py-3 text-sm text-gray-500">
                    {new Date(entry.created_at).toLocaleString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
