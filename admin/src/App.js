import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ConfigProvider, theme } from 'antd';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import Layout from './components/Layout';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Users from './pages/Users';
import UserDetail from './pages/UserDetail';
import Courses from './pages/Courses';
import CourseForm from './pages/CourseForm';
import MLMTree from './pages/MLMTree';
import MLMSettings from './pages/MLMSettings';
import Commissions from './pages/Commissions';
import Withdrawals from './pages/Withdrawals';
import Transactions from './pages/Transactions';
import Quizzes from './pages/Quizzes';
import Settings from './pages/Settings';

const PrivateRoute = ({ children }) => {
  const { admin, loading } = useAuth();
  if (loading) return <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh', background: '#0a0e1a', color: '#00d2ff' }}>Loading...</div>;
  return admin ? children : <Navigate to="/login" />;
};

const darkTheme = {
  algorithm: theme.darkAlgorithm,
  token: {
    colorPrimary: '#00d2ff',
    colorBgBase: '#0a0e1a',
    colorBgContainer: '#111827',
    colorBgElevated: '#111827',
    colorBorder: '#1e2d40',
    colorText: '#e8ecf4',
    colorTextSecondary: '#8899aa',
    borderRadius: 8,
    fontFamily: "'Inter', -apple-system, sans-serif",
  },
};

function AppRoutes() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/" element={<PrivateRoute><Layout /></PrivateRoute>}>
        <Route index element={<Dashboard />} />
        <Route path="users" element={<Users />} />
        <Route path="users/:id" element={<UserDetail />} />
        <Route path="courses" element={<Courses />} />
        <Route path="courses/new" element={<CourseForm />} />
        <Route path="courses/:id/edit" element={<CourseForm />} />
        <Route path="courses/:id/quizzes" element={<Quizzes />} />
        <Route path="mlm/tree" element={<MLMTree />} />
        <Route path="mlm/settings" element={<MLMSettings />} />
        <Route path="commissions" element={<Commissions />} />
        <Route path="withdrawals" element={<Withdrawals />} />
        <Route path="transactions" element={<Transactions />} />
        <Route path="settings" element={<Settings />} />
      </Route>
    </Routes>
  );
}

export default function App() {
  return (
    <ConfigProvider theme={darkTheme}>
      <BrowserRouter>
        <AuthProvider>
          <AppRoutes />
        </AuthProvider>
      </BrowserRouter>
    </ConfigProvider>
  );
}
