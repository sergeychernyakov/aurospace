// src/pages/OrdersListPage.tsx

import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { clsx } from 'clsx';
import { useUser } from '../context/UserContext';
import { useOrders } from '../api/orders';
import StatusBadge from '../shared/components/StatusBadge';
import MoneyFormat from '../shared/components/MoneyFormat';
import LoadingSpinner from '../shared/components/LoadingSpinner';
import ErrorDisplay from '../shared/components/ErrorDisplay';
import CreateOrderForm from './CreateOrderForm';

const STATUS_TABS = [
  { key: 'all', label: 'All' },
  { key: 'created', label: 'Created' },
  { key: 'payment_pending', label: 'Payment Pending' },
  { key: 'successful', label: 'Successful' },
  { key: 'cancelled', label: 'Cancelled' },
];

export default function OrdersListPage() {
  const { user } = useUser();
  const { data: orders, isLoading, error } = useOrders(user?.id ?? null);
  const [statusFilter, setStatusFilter] = useState('all');
  const [showForm, setShowForm] = useState(false);
  const navigate = useNavigate();

  if (!user) {
    return <ErrorDisplay message="No user selected" />;
  }
  if (isLoading) {
    return <LoadingSpinner />;
  }
  if (error) {
    return <ErrorDisplay message={error.message} />;
  }

  const filtered =
    statusFilter === 'all'
      ? (orders ?? [])
      : (orders ?? []).filter((o) => o.status === statusFilter);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Orders</h1>
        <button
          onClick={() => setShowForm(true)}
          className="cursor-pointer rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-blue-700"
        >
          Create Order
        </button>
      </div>

      {/* Status Filter Tabs */}
      <div className="flex gap-1 rounded-lg bg-gray-100 p-1">
        {STATUS_TABS.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setStatusFilter(tab.key)}
            className={clsx(
              'cursor-pointer rounded-md px-3 py-1.5 text-sm font-medium transition-colors',
              statusFilter === tab.key
                ? 'bg-white text-gray-900 shadow-sm'
                : 'text-gray-600 hover:text-gray-900',
            )}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Orders Table */}
      <div className="overflow-hidden rounded-lg border bg-white shadow-sm">
        {filtered.length === 0 ? (
          <p className="p-4 text-sm text-gray-500">No orders found</p>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-50 text-left text-xs font-medium uppercase text-gray-500">
              <tr>
                <th className="px-4 py-3">#</th>
                <th className="px-4 py-3">Amount</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3">Date</th>
                <th className="px-4 py-3">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {filtered.map((order) => (
                <tr
                  key={order.id}
                  onClick={() => navigate(`/orders/${order.id}`)}
                  className="cursor-pointer hover:bg-gray-50"
                >
                  <td className="px-4 py-3 font-medium text-blue-600">{order.id}</td>
                  <td className="px-4 py-3">
                    <MoneyFormat cents={order.amount_cents} currency={order.currency} />
                  </td>
                  <td className="px-4 py-3">
                    <StatusBadge status={order.status} />
                  </td>
                  <td className="px-4 py-3 text-sm text-gray-500">
                    {new Date(order.created_at).toLocaleDateString()}
                  </td>
                  <td className="px-4 py-3">
                    <Link
                      to={`/orders/${order.id}`}
                      onClick={(e) => e.stopPropagation()}
                      className="cursor-pointer text-sm text-blue-600 hover:underline"
                    >
                      View
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {showForm && <CreateOrderForm onClose={() => setShowForm(false)} />}
    </div>
  );
}
