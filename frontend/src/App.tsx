// src/App.tsx

import { Routes, Route } from 'react-router-dom';
import Layout from './shared/components/Layout';
import DashboardPage from './pages/DashboardPage';
import OrdersListPage from './pages/OrdersListPage';
import OrderDetailPage from './pages/OrderDetailPage';
import AccountPage from './pages/AccountPage';

export default function App() {
  return (
    <Layout>
      <Routes>
        <Route path="/" element={<DashboardPage />} />
        <Route path="/orders" element={<OrdersListPage />} />
        <Route path="/orders/:id" element={<OrderDetailPage />} />
        <Route path="/account" element={<AccountPage />} />
      </Routes>
    </Layout>
  );
}
