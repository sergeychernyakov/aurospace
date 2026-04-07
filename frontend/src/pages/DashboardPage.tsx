// src/pages/DashboardPage.tsx

import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useUser } from '../context/UserContext';
import { useOrders } from '../api/orders';
import { useAccount } from '../api/accounts';
import StatusBadge from '../shared/components/StatusBadge';
import MoneyFormat from '../shared/components/MoneyFormat';
import LoadingSpinner from '../shared/components/LoadingSpinner';
import ErrorDisplay from '../shared/components/ErrorDisplay';
import CreateOrderForm from './CreateOrderForm';

export default function DashboardPage() {
  const { user } = useUser();
  const {
    data: orders,
    isLoading: ordersLoading,
    error: ordersError,
  } = useOrders(user?.id ?? null);
  const {
    data: account,
    isLoading: accountLoading,
    error: accountError,
  } = useAccount(user?.id ?? null);
  const [showForm, setShowForm] = useState(false);

  if (!user) {
    return <ErrorDisplay message="No user selected" />;
  }
  if (ordersLoading || accountLoading) {
    return <LoadingSpinner />;
  }
  if (ordersError) {
    return <ErrorDisplay message={ordersError.message} />;
  }
  if (accountError) {
    return <ErrorDisplay message={accountError.message} />;
  }

  const statusCounts = {
    total: orders?.length ?? 0,
    successful: orders?.filter((o) => o.status === 'successful').length ?? 0,
    payment_pending: orders?.filter((o) => o.status === 'payment_pending').length ?? 0,
    cancelled: orders?.filter((o) => o.status === 'cancelled').length ?? 0,
  };

  const recentOrders = orders?.slice(0, 5) ?? [];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">Dashboard</h1>
        <button
          onClick={() => setShowForm(true)}
          className="cursor-pointer rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-blue-700"
        >
          Create Order
        </button>
      </div>

      {/* Balance Card */}
      <div className="rounded-xl bg-gradient-to-r from-blue-600 to-blue-800 p-6 text-white shadow-lg">
        <p className="text-sm font-medium opacity-80">Current Balance</p>
        <p className="mt-1 text-4xl font-bold">
          <MoneyFormat cents={account?.balance_cents ?? 0} currency={account?.currency} />
        </p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        {[
          { label: 'Total Orders', value: statusCounts.total, color: 'text-gray-900 dark:text-gray-100' },
          { label: 'Successful', value: statusCounts.successful, color: 'text-green-400' },
          { label: 'Pending', value: statusCounts.payment_pending, color: 'text-yellow-400' },
          { label: 'Cancelled', value: statusCounts.cancelled, color: 'text-red-400' },
        ].map((card) => (
          <div key={card.label} className="rounded-lg border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-800 p-4 shadow-sm">
            <p className="text-sm text-gray-500 dark:text-gray-400">{card.label}</p>
            <p className={`mt-1 text-2xl font-bold ${card.color}`}>{card.value}</p>
          </div>
        ))}
      </div>

      {/* Recent Orders */}
      <div className="rounded-lg border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-800 shadow-sm">
        <div className="border-b border-gray-200 dark:border-gray-700 px-4 py-3">
          <h2 className="font-semibold text-gray-900 dark:text-gray-100">Recent Orders</h2>
        </div>
        {recentOrders.length === 0 ? (
          <p className="p-4 text-sm text-gray-500 dark:text-gray-400">No orders yet</p>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-100 dark:bg-gray-900 text-left text-xs font-medium uppercase text-gray-500 dark:text-gray-400">
              <tr>
                <th className="px-4 py-2">#</th>
                <th className="px-4 py-2">Amount</th>
                <th className="px-4 py-2">Status</th>
                <th className="px-4 py-2">Date</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
              {recentOrders.map((order) => (
                <tr key={order.id} className="cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700">
                  <td className="px-4 py-3">
                    <Link
                      to={`/orders/${order.id}`}
                      className="cursor-pointer text-blue-400 hover:underline"
                    >
                      {order.id}
                    </Link>
                  </td>
                  <td className="px-4 py-3 text-gray-900 dark:text-gray-100">
                    <MoneyFormat cents={order.amount_cents} currency={order.currency} />
                  </td>
                  <td className="px-4 py-3">
                    <StatusBadge status={order.status} />
                  </td>
                  <td className="px-4 py-3 text-sm text-gray-500 dark:text-gray-400">
                    {new Date(order.created_at).toLocaleDateString()}
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
