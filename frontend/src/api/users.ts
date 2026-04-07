// src/api/users.ts

import type { User } from './types';

// Demo users are hardcoded to match seeds.
// In production, this would fetch from an API endpoint.
const DEMO_USERS: User[] = [
  {
    id: 1,
    email: 'demo1@aurospace.dev',
    name: 'Demo User 1',
    created_at: new Date().toISOString(),
  },
  {
    id: 2,
    email: 'demo2@aurospace.dev',
    name: 'Demo User 2',
    created_at: new Date().toISOString(),
  },
];

export function getDemoUsers(): User[] {
  return DEMO_USERS;
}
