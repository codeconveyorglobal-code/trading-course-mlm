import React, { useEffect, useState, useCallback } from 'react';
import { Table, Tag, Button, Card, Typography, Select, Space, message, Modal } from 'antd';
import api from '../services/api';
import dayjs from 'dayjs';

const { Title, Text } = Typography;

export default function Commissions() {
  const [commissions, setCommissions] = useState([]);
  const [loading, setLoading] = useState(false);
  const [pagination, setPagination] = useState({ current: 1, pageSize: 20, total: 0 });
  const [filters, setFilters] = useState({ status: '', type: '' });

  const fetchCommissions = useCallback(async (page = 1) => {
    setLoading(true);
    try {
      const params = { page, limit: 20, ...filters };
      Object.keys(params).forEach(k => !params[k] && delete params[k]);
      const res = await api.get('/admin/commissions', { params });
      setCommissions(res.data.commissions);
      setPagination(p => ({ ...p, total: res.data.pagination.total, current: page }));
    } finally {
      setLoading(false);
    }
  }, [filters]);

  useEffect(() => { fetchCommissions(); }, [fetchCommissions]);

  const updateStatus = async (id, status) => {
    try {
      await api.put(`/admin/commissions/${id}`, { status });
      message.success('Commission updated');
      fetchCommissions();
    } catch {
      message.error('Failed');
    }
  };

  const typeColors = { direct_referral: 'cyan', binary_matching: 'purple', level_override: 'blue', rank_bonus: 'gold', leadership_bonus: 'orange' };

  const columns = [
    { title: 'User', render: (_, r) => (
      <div><Text strong style={{ color: '#fff' }}>{r.userId?.name}</Text><br /><Text style={{ color: '#4a5568', fontSize: 12 }}>{r.userId?.email}</Text></div>
    )},
    { title: 'Type', dataIndex: 'type', render: v => <Tag color={typeColors[v] || 'default'}>{v?.replace(/_/g, ' ')}</Tag> },
    { title: 'From', render: (_, r) => r.fromUserId?.name || 'N/A' },
    { title: 'Course', render: (_, r) => r.courseId?.title || 'N/A' },
    { title: 'Base Amt', dataIndex: 'baseAmount', render: v => `$${v?.toFixed(2)}` },
    { title: 'Commission', dataIndex: 'amount', render: v => <Text style={{ color: '#00c48c', fontWeight: 600 }}>${v?.toFixed(2)}</Text> },
    { title: '%', dataIndex: 'percentage', render: v => v ? `${v}%` : '-' },
    { title: 'Level', dataIndex: 'level' },
    { title: 'Status', dataIndex: 'status', render: (v, r) => (
      <Select size="small" value={v} onChange={val => updateStatus(r._id, val)} style={{ width: 110 }}>
        <Select.Option value="pending">Pending</Select.Option>
        <Select.Option value="approved">Approved</Select.Option>
        <Select.Option value="paid">Paid</Select.Option>
        <Select.Option value="cancelled">Cancelled</Select.Option>
      </Select>
    )},
    { title: 'Date', dataIndex: 'createdAt', render: v => dayjs(v).format('MMM D, YYYY') },
  ];

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <Title level={3} style={{ color: '#fff', margin: 0 }}>Commissions</Title>
        <Space>
          <Select placeholder="Type" allowClear style={{ width: 160 }} onChange={v => setFilters(f => ({ ...f, type: v || '' }))}>
            {['direct_referral', 'binary_matching', 'level_override', 'rank_bonus'].map(t => <Select.Option key={t} value={t}>{t.replace(/_/g, ' ')}</Select.Option>)}
          </Select>
          <Select placeholder="Status" allowClear style={{ width: 120 }} onChange={v => setFilters(f => ({ ...f, status: v || '' }))}>
            {['pending', 'approved', 'paid', 'cancelled'].map(s => <Select.Option key={s} value={s}>{s}</Select.Option>)}
          </Select>
        </Space>
      </div>
      <Card bordered={false}>
        <Table dataSource={commissions} columns={columns} rowKey="_id" loading={loading}
          pagination={{ ...pagination, onChange: p => fetchCommissions(p) }} scroll={{ x: 1000 }} />
      </Card>
    </div>
  );
}
