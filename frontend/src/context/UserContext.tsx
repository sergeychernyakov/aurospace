// src/context/UserContext.tsx

import React, { createContext, useContext, useState, useMemo } from 'react';
import type { User } from '../api/types';
import { getDemoUsers } from '../api/users';

interface UserContextValue {
  user: User | null;
  users: User[];
  selectUser: (userId: number) => void;
}

const UserContext = createContext<UserContextValue | null>(null);

export function UserProvider({ children }: { children: React.ReactNode }) {
  const users = getDemoUsers();
  const [selectedId, setSelectedId] = useState<number>(users[0]?.id ?? 0);

  const value = useMemo(() => {
    const user = users.find((u) => u.id === selectedId) ?? null;
    return { user, users, selectUser: setSelectedId };
  }, [selectedId, users]);

  return <UserContext.Provider value={value}>{children}</UserContext.Provider>;
}

export function useUser(): UserContextValue {
  const ctx = useContext(UserContext);
  if (!ctx) {
    throw new Error('useUser must be used within a UserProvider');
  }
  return ctx;
}
