// src/pages/CreateOrderForm.tsx

import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useUser } from '../context/UserContext';
import { useCreateOrder } from '../api/orders';

interface CreateOrderFormProps {
  onClose: () => void;
}

export default function CreateOrderForm({ onClose }: CreateOrderFormProps) {
  const { user } = useUser();
  const [amountRub, setAmountRub] = useState('');
  const [formError, setFormError] = useState('');
  const createOrder = useCreateOrder();
  const navigate = useNavigate();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setFormError('');

    const parsed = parseFloat(amountRub);
    if (isNaN(parsed) || parsed <= 0) {
      setFormError('Amount must be a positive number');
      return;
    }

    if (!user) {
      setFormError('No user selected');
      return;
    }

    const amountCents = Math.round(parsed * 100);

    createOrder.mutate(
      { user_id: user.id, amount_cents: amountCents },
      {
        onSuccess: (order) => {
          onClose();
          navigate(`/orders/${order.id}`);
        },
        onError: (err) => {
          setFormError(err.message);
        },
      },
    );
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
      <div className="mx-4 w-full max-w-md rounded-lg border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-800 p-6 shadow-xl">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold text-gray-100">Create Order</h2>
          <button onClick={onClose} className="cursor-pointer text-gray-400 hover:text-gray-200">
            X
          </button>
        </div>

        <form onSubmit={handleSubmit} className="mt-4 space-y-4">
          <div>
            <label htmlFor="amount" className="block text-sm font-medium text-gray-300">
              Amount (RUB)
            </label>
            <input
              id="amount"
              type="number"
              step="0.01"
              min="0.01"
              value={amountRub}
              onChange={(e) => setAmountRub(e.target.value)}
              placeholder="100.00"
              className="mt-1 block w-full rounded-md border border-gray-300 bg-gray-50 px-3 py-2 text-gray-900 dark:border-gray-600 dark:bg-gray-700 dark:text-white shadow-sm placeholder:text-gray-500 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              required
            />
          </div>

          {formError && <p className="text-sm text-red-400">{formError}</p>}

          <div className="flex justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              className="cursor-pointer rounded-md border border-gray-600 px-4 py-2 text-sm font-medium text-gray-300 hover:bg-gray-700"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={createOrder.isPending}
              className="cursor-pointer rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-blue-700 disabled:opacity-50"
            >
              {createOrder.isPending ? 'Creating...' : 'Create'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
