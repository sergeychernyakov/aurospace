// src/shared/components/UserSelector.tsx

import { useUser } from '../../context/UserContext';

export default function UserSelector() {
  const { user, users, selectUser } = useUser();

  return (
    <select
      value={user?.id ?? ''}
      onChange={(e) => selectUser(Number(e.target.value))}
      className="cursor-pointer rounded-md border border-gray-300 bg-white px-3 py-1.5 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
    >
      {users.map((u) => (
        <option key={u.id} value={u.id}>
          {u.name} ({u.email})
        </option>
      ))}
    </select>
  );
}
