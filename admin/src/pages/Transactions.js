import React, { useEffect, useState, useCallback } from 'react';
import { Table, Tag, Card, Typography, Select, Space } from 'antd';
import api from '../services/api';
import dayjs from 'dayjs';

const { Title, Text } = Typography;

export default function Transactions() {
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(false);
  const [pagination, setPagination] = useState({ current: 1, pageSize: 20, total: 0 });
  const [filters, setFilters] = useState({ status: '', type: '' });

  const fetchTransactions = useCallback(async (page = 1) => {
    setLoading(true);
    try {
      const params = { page, limit: 20, ...filters };
      Object.keys(params).forEach(k => !params[k] && delete params[k]);
      const res = await api.get('/admin/transactions', { params });
      setTransactions(res.data.transactions);
      setPagination(p => ({ ...p, total: res.data.pagination.total, current: page }));
    } finally {
      setLoading(false);
    }
  }, [filters]);

  useEffect(() => { fetchTransactions(); }, [fetchTransactions]);

  const columns = [
    { title: 'User', render: (_, r) => (
      <div><Text style={{ color: '#fff' }}>{r.userId?.name}</Text><br /><Text style={{ color: '#4a5568', fontSize: 11 }}>{r.userId?.email}</Text></div>
    )},
    { title: 'Course', render: (_, r) => r.courseId?.title || '-' },
    { title: 'Type', dataIndex: 'type', render: v => <Tag color="blue">{v?.replace(/_/g, ' ')}</Tag> },
    { title: 'Amount', dataIndex: 'amount', render: v => <Text style={{ color: '#00d2ff', fontWeight: 600 }}>${v?.toFixed(2)}</Text> },
    { title: 'Crypto', render: (_, r) => r.cryptoCurrency ? (
      <div>
        <Tag color="cyan">{r.cryptoCurrency}</Tag>
        <div style={{ color: '#4a5568', fontSize: 11 }}>{r.cryptoAmount} {r.cryptoCurrency}</div>
      </div>
    ) : '-'},
    { title: 'Payment Status', dataIndex: 'paymentStatus', render: v => v ? <Tag>{v}</Tag> : '-' },
    { title: 'Status', dataIndex: 'status', render: v => {
      const colors = { pending: 'warning', processing: 'processing', completed: 'success', failed: 'error' };
      return <Tag color={colors[v] || 'default'}>{v}</Tag>;
    }},
    { title: 'Date', dataIndex: 'createdAt', render: v => dayjs(v).format('MMM D, YYYY HH:mm') },
  ];

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <Title level={3} style={{ color: '#fff', margin: 0 }}>Transactions</Title>
        <Space>
          <Select placeholder="Type" allowClear style={{ width: 160 }} onChange={v => setFilters(f => ({ ...f, type: v || '' }))}>
            {['course_purchase', 'commission', 'withdrawal', 'refund'].map(t => <Select.Option key={t} value={t}>{t.replace(/_/g, ' ')}</Select.Option>)}
          </Select>
          <Select placeholder="Status" allowClear style={{ width: 130 }} onChange={v => setFilters(f => ({ ...f, status: v || '' }))}>
            {['pending', 'processing', 'completed', 'failed'].map(s => <Select.Option key={s} value={s}>{s}</Select.Option>)}
          </Select>
        </Space>
      </div>
      <Card bordered={false}>
        <Table dataSource={transactions} columns={columns} rowKey="_id" loading={loading}
          pagination={{ ...pagination, onChange: p => fetchTransactions(p) }} scroll={{ x: 1000 }} />
      </Card>
    </div>
  );
}
