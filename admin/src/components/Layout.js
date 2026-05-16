import React, { useState } from 'react';
import { Layout as AntLayout, Menu, Avatar, Dropdown, Badge, Typography, Button } from 'antd';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import {
  DashboardOutlined, UserOutlined, BookOutlined, ApartmentOutlined,
  DollarOutlined, TransactionOutlined, SettingOutlined, LogoutOutlined,
  BellOutlined, ThunderboltOutlined, TeamOutlined, WalletOutlined,
  MenuFoldOutlined, MenuUnfoldOutlined, FileTextOutlined,
} from '@ant-design/icons';
import { useAuth } from '../contexts/AuthContext';

const { Sider, Content, Header } = AntLayout;
const { Text } = Typography;

const menuItems = [
  { key: '/', icon: <DashboardOutlined />, label: 'Dashboard' },
  { key: 'users', icon: <UserOutlined />, label: 'Users', children: [
    { key: '/users', label: 'All Users' },
  ]},
  { key: 'courses-group', icon: <BookOutlined />, label: 'Courses', children: [
    { key: '/courses', label: 'All Courses' },
    { key: '/courses/new', label: 'Add Course' },
  ]},
  { key: 'mlm-group', icon: <ApartmentOutlined />, label: 'MLM System', children: [
    { key: '/mlm/tree', label: 'Binary Tree' },
    { key: '/mlm/settings', label: 'MLM Settings' },
  ]},
  { key: '/commissions', icon: <DollarOutlined />, label: 'Commissions' },
  { key: '/withdrawals', icon: <WalletOutlined />, label: 'Withdrawals' },
  { key: '/transactions', icon: <TransactionOutlined />, label: 'Transactions' },
  { key: '/settings', icon: <SettingOutlined />, label: 'Settings' },
];

export default function Layout() {
  const { admin, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [collapsed, setCollapsed] = useState(false);

  const handleMenuClick = ({ key }) => {
    navigate(key);
  };

  const dropdownItems = [
    { key: 'profile', icon: <UserOutlined />, label: 'Profile' },
    { type: 'divider' },
    { key: 'logout', icon: <LogoutOutlined />, label: 'Logout', danger: true },
  ];

  const handleDropdown = ({ key }) => {
    if (key === 'logout') logout();
  };

  return (
    <AntLayout style={{ minHeight: '100vh' }}>
      <Sider
        collapsed={collapsed}
        width={240}
        style={{ background: '#0d1526', borderRight: '1px solid #1e2d40', position: 'fixed', height: '100vh', overflow: 'auto', zIndex: 100 }}
      >
        {/* Logo */}
        <div style={{ padding: collapsed ? '20px 8px' : '20px 24px', display: 'flex', alignItems: 'center', gap: 12, borderBottom: '1px solid #1e2d40' }}>
          <div style={{ width: 36, height: 36, borderRadius: 10, background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <ThunderboltOutlined style={{ color: '#fff', fontSize: 18 }} />
          </div>
          {!collapsed && <Text strong style={{ color: '#fff', fontSize: 18 }}>TradeMLM</Text>}
        </div>

        <Menu
          theme="dark"
          mode="inline"
          selectedKeys={[location.pathname]}
          defaultOpenKeys={['users', 'courses-group', 'mlm-group']}
          items={menuItems}
          onClick={handleMenuClick}
          style={{ background: 'transparent', border: 'none', marginTop: 8 }}
        />
      </Sider>

      <AntLayout style={{ marginLeft: collapsed ? 80 : 240, transition: 'margin 0.2s' }}>
        <Header style={{
          background: 'rgba(13,21,38,0.95)', backdropFilter: 'blur(10px)',
          borderBottom: '1px solid #1e2d40', padding: '0 24px',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          position: 'sticky', top: 0, zIndex: 99,
        }}>
          <Button
            type="text"
            icon={collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
            onClick={() => setCollapsed(!collapsed)}
            style={{ color: '#8899aa', fontSize: 18 }}
          />
          <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
            <Badge count={5}>
              <BellOutlined style={{ fontSize: 20, color: '#8899aa', cursor: 'pointer' }} />
            </Badge>
            <Dropdown menu={{ items: dropdownItems, onClick: handleDropdown }} placement="bottomRight">
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer' }}>
                <Avatar style={{ background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)' }}>
                  {admin?.name?.[0]?.toUpperCase()}
                </Avatar>
                <div>
                  <Text strong style={{ color: '#fff', display: 'block', lineHeight: 1.2 }}>{admin?.name}</Text>
                  <Text style={{ color: '#00d2ff', fontSize: 11 }}>Administrator</Text>
                </div>
              </div>
            </Dropdown>
          </div>
        </Header>

        <Content style={{ padding: '24px', minHeight: 'calc(100vh - 64px)' }}>
          <Outlet />
        </Content>
      </AntLayout>
    </AntLayout>
  );
}
