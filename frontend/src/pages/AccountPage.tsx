// src/pages/AccountPage.tsx

import { useUser } from '../context/UserContext';
import { useAccount } from '../api/accounts';
import MoneyFormat from '../shared/components/MoneyFormat';
import StatusBadge from '../shared/components/StatusBadge';
import LoadingSpinner from '../shared/components/LoadingSpinner';
import ErrorDisplay from '../shared/components/ErrorDisplay';

export default function AccountPage() {
  const { user } = useUser();
  const { data: account, isLoading, error } = useAccount(user?.id ?? null);

  if (!user) {
    return <ErrorDisplay message="No user selected" />;
  }
  if (isLoading) {
    return <LoadingSpinner />;
  }
  if (error) {
    return <ErrorDisplay message={error.message} />;
  }
  if (!account) {
    return <ErrorDisplay message="Account not found" />;
  }

  const entries = account.ledger_entries?.slice(0, 20) ?? [];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Account</h1>

      {/* Balance Card */}
      <div className="rounded-xl bg-gradient-to-r from-blue-600 to-blue-800 p-6 text-white shadow-lg">
        <p className="text-sm font-medium opacity-80">Balance</p>
        <p className="mt-1 text-4xl font-bold">
          <MoneyFormat cents={account.balance_cents} currency={account.currency} />
        </p>
        <p className="mt-2 text-sm opacity-60">{user.email}</p>
      </div>

      {/* Recent Ledger Entries */}
      <div className="rounded-lg border bg-white shadow-sm">
        <div className="border-b px-4 py-3">
          <h2 className="font-semibold text-gray-900">Recent Ledger Entries</h2>
        </div>
        {entries.length === 0 ? (
          <p className="p-4 text-sm text-gray-500">No entries yet</p>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-50 text-left text-xs font-medium uppercase text-gray-500">
              <tr>
                <th className="px-4 py-2">Type</th>
                <th className="px-4 py-2">Amount</th>
                <th className="px-4 py-2">Order</th>
                <th className="px-4 py-2">Reference</th>
                <th className="px-4 py-2">Date</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {entries.map((entry) => (
                <tr key={entry.id}>
                  <td className="px-4 py-3">
                    <StatusBadge status={entry.entry_type} />
                  </td>
                  <td className="px-4 py-3">
                    <MoneyFormat cents={entry.amount_cents} currency={entry.currency} />
                  </td>
                  <td className="px-4 py-3 text-sm text-gray-500">#{entry.order_id}</td>
                  <td className="px-4 py-3 text-sm text-gray-500">{entry.reference ?? '-'}</td>
                  <td className="px-4 py-3 text-sm text-gray-500">
                    {new Date(entry.created_at).toLocaleString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <p className="text-sm text-gray-500">
        For full audit trail, visit the{' '}
        <a
          href="/admin"
          target="_blank"
          rel="noopener noreferrer"
          className="cursor-pointer text-blue-600 hover:underline"
        >
          Admin Panel
        </a>
        .
      </p>
    </div>
  );
}
