// src/shared/components/Layout.tsx

import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { clsx } from 'clsx';
import UserSelector from './UserSelector';

const NAV_ITEMS = [
  { path: '/', label: 'Dashboard' },
  { path: '/orders', label: 'Orders' },
  { path: '/account', label: 'Account' },
];

const EXTERNAL_LINKS = [
  { href: '/api-docs', label: 'API Docs' },
  { href: '/admin', label: 'Admin Panel' },
];

export default function Layout({ children }: { children: React.ReactNode }) {
  const location = useLocation();

  return (
    <div className="min-h-screen">
      <header className="border-b border-gray-200 bg-white shadow-sm">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-4 py-3">
          <div className="flex items-center gap-8">
            <Link to="/" className="cursor-pointer text-xl font-bold text-blue-600">
              AUROSPACE
            </Link>
            <nav className="flex gap-1">
              {NAV_ITEMS.map((item) => (
                <Link
                  key={item.path}
                  to={item.path}
                  className={clsx(
                    'cursor-pointer rounded-md px-3 py-2 text-sm font-medium transition-colors',
                    location.pathname === item.path
                      ? 'bg-blue-100 text-blue-700'
                      : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900',
                  )}
                >
                  {item.label}
                </Link>
              ))}
              {EXTERNAL_LINKS.map((item) => (
                <a
                  key={item.href}
                  href={item.href}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="cursor-pointer rounded-md px-3 py-2 text-sm font-medium text-gray-600 transition-colors hover:bg-gray-100 hover:text-gray-900"
                >
                  {item.label}
                </a>
              ))}
            </nav>
          </div>
          <UserSelector />
        </div>
      </header>
      <main className="mx-auto max-w-7xl px-4 py-6">{children}</main>
    </div>
  );
}
