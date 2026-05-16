import React, { useEffect, useState } from 'react';
import { Row, Col, Card, Statistic, Table, Tag, Typography, Spin } from 'antd';
import { UserOutlined, BookOutlined, DollarOutlined, WalletOutlined, ArrowUpOutlined } from '@ant-design/icons';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import api from '../services/api';
import dayjs from 'dayjs';

const { Title, Text } = Typography;

export default function Dashboard() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get('/admin/dashboard').then(res => {
      setData(res.data);
    }).finally(() => setLoading(false));
  }, []);

  if (loading) return <div style={{ textAlign: 'center', paddingTop: 100 }}><Spin size="large" /></div>;

  const { stats, recentTransactions, recentUsers, monthlyRevenue } = data || {};

  const statCards = [
    { title: 'Total Users', value: stats?.users?.total, suffix: `${stats?.users?.active} active`, icon: <UserOutlined />, color: '#00d2ff', bg: 'rgba(0,210,255,0.1)' },
    { title: 'Published Courses', value: stats?.courses?.published, suffix: `${stats?.courses?.total} total`, icon: <BookOutlined />, color: '#7b2ff7', bg: 'rgba(123,47,247,0.1)' },
    { title: 'Total Revenue', value: `$${(stats?.revenue?.total || 0).toFixed(2)}`, icon: <DollarOutlined />, color: '#00c48c', bg: 'rgba(0,196,140,0.1)' },
    { title: 'Pending Withdrawals', value: stats?.pendingWithdrawals, icon: <WalletOutlined />, color: '#ffa94d', bg: 'rgba(255,169,77,0.1)' },
  ];

  const revenueData = monthlyRevenue?.map(m => ({ month: `${m._id.month}/${m._id.year}`, revenue: m.total })) || [];

  const txColumns = [
    { title: 'User', dataIndex: ['userId', 'name'], render: (_, r) => r.userId?.name || 'N/A' },
    { title: 'Course', dataIndex: ['courseId', 'title'], render: (_, r) => r.courseId?.title || 'N/A' },
    { title: 'Amount', dataIndex: 'amount', render: v => `$${v?.toFixed(2)}` },
    { title: 'Crypto', dataIndex: 'cryptoCurrency', render: v => v ? <Tag color="cyan">{v}</Tag> : '-' },
    { title: 'Status', dataIndex: 'status', render: v => <Tag color={v === 'completed' ? 'success' : v === 'pending' ? 'warning' : 'error'}>{v}</Tag> },
    { title: 'Date', dataIndex: 'createdAt', render: v => dayjs(v).format('MMM D, HH:mm') },
  ];

  return (
    <div>
      <Title level={3} style={{ color: '#fff', marginBottom: 24 }}>
        Dashboard <span style={{ color: '#00d2ff', fontSize: 14, fontWeight: 400 }}>— Overview</span>
      </Title>

      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        {statCards.map((card, i) => (
          <Col xs={24} sm={12} xl={6} key={i}>
            <div className="stat-card" style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
              <div style={{ width: 56, height: 56, borderRadius: 14, background: card.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 24, color: card.color }}>
                {card.icon}
              </div>
              <div>
                <Text style={{ color: '#8899aa', fontSize: 13 }}>{card.title}</Text>
                <div style={{ fontSize: 26, fontWeight: 700, color: '#fff', lineHeight: 1.2 }}>{card.value}</div>
                {card.suffix && <Text style={{ color: '#4a7c8e', fontSize: 12 }}>{card.suffix}</Text>}
              </div>
            </div>
          </Col>
        ))}
      </Row>

      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={24} lg={16}>
          <Card title={<Text style={{ color: '#fff' }}>Monthly Revenue</Text>} bordered={false}>
            {revenueData.length > 0 ? (
              <ResponsiveContainer width="100%" height={260}>
                <LineChart data={revenueData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#1e2d40" />
                  <XAxis dataKey="month" stroke="#8899aa" tick={{ fill: '#8899aa', fontSize: 12 }} />
                  <YAxis stroke="#8899aa" tick={{ fill: '#8899aa', fontSize: 12 }} tickFormatter={v => `$${v}`} />
                  <Tooltip contentStyle={{ background: '#111827', border: '1px solid #1e2d40', borderRadius: 8 }} formatter={v => [`$${Number(v).toFixed(2)}`, 'Revenue']} />
                  <Line type="monotone" dataKey="revenue" stroke="#00d2ff" strokeWidth={2} dot={false} />
                </LineChart>
              </ResponsiveContainer>
            ) : <Text style={{ color: '#8899aa' }}>No revenue data yet</Text>}
          </Card>
        </Col>
        <Col xs={24} lg={8}>
          <Card title={<Text style={{ color: '#fff' }}>New Users</Text>} bordered={false} style={{ height: '100%' }}>
            {recentUsers?.slice(0, 5).map(u => (
              <div key={u._id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '8px 0', borderBottom: '1px solid #1a2535' }}>
                <div style={{ width: 36, height: 36, borderRadius: 10, background: 'linear-gradient(135deg, #00d2ff22, #7b2ff722)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#00d2ff', fontWeight: 700, fontSize: 14 }}>
                  {u.name?.[0]?.toUpperCase()}
                </div>
                <div>
                  <Text style={{ color: '#fff', display: 'block', fontSize: 13 }}>{u.name}</Text>
                  <Text style={{ color: '#4a5568', fontSize: 11 }}>{dayjs(u.createdAt).fromNow?.() || dayjs(u.createdAt).format('MMM D')}</Text>
                </div>
                <Tag color={u.isActive ? 'success' : 'error'} style={{ marginLeft: 'auto' }}>
                  {u.isActive ? 'Active' : 'Inactive'}
                </Tag>
              </div>
            ))}
          </Card>
        </Col>
      </Row>

      <Card title={<Text style={{ color: '#fff' }}>Recent Transactions</Text>} bordered={false}>
        <Table
          dataSource={recentTransactions}
          columns={txColumns}
          rowKey="_id"
          pagination={false}
          scroll={{ x: 700 }}
        />
      </Card>
    </div>
  );
}
