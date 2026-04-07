// src/shared/components/UserSelector.tsx

import { useUser } from '../../context/UserContext';

export default function UserSelector() {
  const { user, users, selectUser } = useUser();

  return (
    <select
      value={user?.id ?? ''}
      onChange={(e) => selectUser(Number(e.target.value))}
      className="cursor-pointer rounded-md border border-gray-600 bg-gray-700 px-3 py-1.5 text-sm font-medium text-white shadow-sm hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-blue-500"
    >
      {users.map((u) => (
        <option key={u.id} value={u.id}>
          {u.name} ({u.email})
        </option>
      ))}
    </select>
  );
}
