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
              <div style={{
                width: 56, height: 56, borderRadius: 14,
                background: `radial-gradient(circle at 30% 30%, ${card.color}33, ${card.color}11)`,
                border: `1px solid ${card.color}33`,
                display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 24, color: card.color,
                boxShadow: `0 0 20px ${card.color}22`,
              }}>
                {card.icon}
              </div>
              <div style={{ flex: 1 }}>
                <Text style={{ color: '#8899aa', fontSize: 12, textTransform: 'uppercase', letterSpacing: '0.5px' }}>{card.title}</Text>
                <div style={{ fontSize: 28, fontWeight: 800, color: '#fff', lineHeight: 1.2, marginTop: 2 }}>{card.value ?? '—'}</div>
                {card.suffix && <Text style={{ color: '#4a7c8e', fontSize: 12 }}>{card.suffix}</Text>}
              </div>
            </div>
          </Col>
        ))}
      </Row>

      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={24} lg={16}>
          <Card bordered={false}
            title={
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <div style={{ width: 4, height: 18, background: 'linear-gradient(#00d2ff,#7b2ff7)', borderRadius: 2 }} />
                <Text style={{ color: '#fff' }}>Monthly Revenue</Text>
              </div>
            }
          >
            {revenueData.length > 0 ? (
              <ResponsiveContainer width="100%" height={260}>
                <LineChart data={revenueData}>
                  <defs>
                    <linearGradient id="revenueGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#00d2ff" stopOpacity={0.2} />
                      <stop offset="95%" stopColor="#00d2ff" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#1e2d40" />
                  <XAxis dataKey="month" stroke="#1e2d40" tick={{ fill: '#8899aa', fontSize: 11 }} />
                  <YAxis stroke="#1e2d40" tick={{ fill: '#8899aa', fontSize: 11 }} tickFormatter={v => `$${v}`} />
                  <Tooltip contentStyle={{ background: '#0d1526', border: '1px solid #1e2d40', borderRadius: 10 }} formatter={v => [`$${Number(v).toFixed(2)}`, 'Revenue']} labelStyle={{ color: '#8899aa' }} />
                  <Line type="monotone" dataKey="revenue" stroke="#00d2ff" strokeWidth={2.5} dot={{ fill: '#00d2ff', r: 4 }} activeDot={{ r: 6, fill: '#7b2ff7' }} />
                </LineChart>
              </ResponsiveContainer>
            ) : (
              <div style={{ height: 260, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#4a5568' }}>No revenue data yet</div>
            )}
          </Card>
        </Col>
        <Col xs={24} lg={8}>
          <Card bordered={false} style={{ height: '100%' }}
            title={
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <div style={{ width: 4, height: 18, background: 'linear-gradient(#00d2ff,#7b2ff7)', borderRadius: 2 }} />
                <Text style={{ color: '#fff' }}>Recent Members</Text>
              </div>
            }
          >
            {recentUsers?.slice(0, 5).map(u => (
              <div key={u._id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 0', borderBottom: '1px solid #0f1d30' }}>
                <div style={{ width: 38, height: 38, borderRadius: 10, background: 'linear-gradient(135deg,#00d2ff22,#7b2ff722)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#00d2ff', fontWeight: 700, fontSize: 15, flexShrink: 0 }}>
                  {u.name?.[0]?.toUpperCase()}
                </div>
                <div style={{ flex: 1, overflow: 'hidden' }}>
                  <Text style={{ color: '#fff', display: 'block', fontSize: 13, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{u.name}</Text>
                  <Text style={{ color: '#4a5568', fontSize: 11 }}>{dayjs(u.createdAt).format('MMM D, YYYY')}</Text>
                </div>
                <span className={u.isActive ? 'tag-success' : 'tag-danger'} style={{ flexShrink: 0, fontSize: 11 }}>
                  {u.isActive ? 'Active' : 'Off'}
                </span>
              </div>
            ))}
          </Card>
        </Col>
      </Row>

      <Card bordered={false}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ width: 4, height: 18, background: 'linear-gradient(#00d2ff,#7b2ff7)', borderRadius: 2 }} />
            <Text style={{ color: '#fff' }}>Recent Transactions</Text>
          </div>
        }
      >
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
