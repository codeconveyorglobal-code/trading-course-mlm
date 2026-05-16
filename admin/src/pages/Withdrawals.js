import React, { useEffect, useState, useCallback } from 'react';
import { Table, Tag, Button, Card, Typography, Select, Space, message, Modal, Form, Input } from 'antd';
import api from '../services/api';
import dayjs from 'dayjs';

const { Title, Text } = Typography;

export default function Withdrawals() {
  const [withdrawals, setWithdrawals] = useState([]);
  const [loading, setLoading] = useState(false);
  const [pagination, setPagination] = useState({ current: 1, pageSize: 20, total: 0 });
  const [status, setStatus] = useState('');
  const [processModal, setProcessModal] = useState(null);
  const [form] = Form.useForm();
  const [processing, setProcessing] = useState(false);

  const fetchWithdrawals = useCallback(async (page = 1) => {
    setLoading(true);
    try {
      const params = { page, limit: 20, ...(status ? { status } : {}) };
      const res = await api.get('/admin/withdrawals', { params });
      setWithdrawals(res.data.withdrawals);
      setPagination(p => ({ ...p, total: res.data.pagination.total, current: page }));
    } finally {
      setLoading(false);
    }
  }, [status]);

  useEffect(() => { fetchWithdrawals(); }, [fetchWithdrawals]);

  const handleProcess = async (values) => {
    setProcessing(true);
    try {
      await api.put(`/admin/withdrawals/${processModal._id}`, values);
      message.success('Withdrawal processed');
      setProcessModal(null);
      fetchWithdrawals();
    } catch {
      message.error('Failed');
    } finally {
      setProcessing(false);
    }
  };

  const columns = [
    { title: 'User', render: (_, r) => (
      <div><Text strong style={{ color: '#fff' }}>{r.userId?.name}</Text><br /><Text style={{ color: '#4a5568', fontSize: 12 }}>{r.userId?.email}</Text></div>
    )},
    { title: 'Amount', dataIndex: 'amount', render: (v, r) => <Text style={{ color: '#00d2ff', fontWeight: 600 }}>${v} {r.currency}</Text> },
    { title: 'Crypto Address', dataIndex: 'cryptoAddress', render: v => <Text style={{ color: '#8899aa', fontSize: 11 }}>{v?.slice(0, 20)}...</Text> },
    { title: 'Network', dataIndex: 'network', render: v => v ? <Tag>{v}</Tag> : '-' },
    { title: 'TX Hash', dataIndex: 'txHash', render: v => v ? <Text style={{ color: '#8899aa', fontSize: 11 }}>{v?.slice(0, 16)}...</Text> : '-' },
    { title: 'Status', dataIndex: 'status', render: v => {
      const colors = { pending: 'warning', processing: 'processing', completed: 'success', rejected: 'error' };
      return <Tag color={colors[v]}>{v}</Tag>;
    }},
    { title: 'Date', dataIndex: 'createdAt', render: v => dayjs(v).format('MMM D, YYYY') },
    { title: 'Actions', render: (_, r) => r.status === 'pending' && (
      <Button size="small" type="primary" onClick={() => { setProcessModal(r); form.resetFields(); }}
        style={{ background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)', border: 'none' }}>
        Process
      </Button>
    )},
  ];

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <Title level={3} style={{ color: '#fff', margin: 0 }}>Withdrawals</Title>
        <Select placeholder="Filter by status" allowClear style={{ width: 150 }} onChange={v => setStatus(v || '')}>
          {['pending', 'processing', 'completed', 'rejected'].map(s => <Select.Option key={s} value={s}>{s}</Select.Option>)}
        </Select>
      </div>
      <Card bordered={false}>
        <Table dataSource={withdrawals} columns={columns} rowKey="_id" loading={loading}
          pagination={{ ...pagination, onChange: p => fetchWithdrawals(p) }} scroll={{ x: 900 }} />
      </Card>

      <Modal
        title={<Text style={{ color: '#fff' }}>Process Withdrawal - ${processModal?.amount}</Text>}
        open={!!processModal}
        onCancel={() => setProcessModal(null)}
        footer={null}
        styles={{ content: { background: '#111827' }, header: { background: '#111827' } }}
      >
        {processModal && (
          <>
            <div style={{ background: '#0d1526', padding: 12, borderRadius: 8, marginBottom: 16 }}>
              <Text style={{ color: '#8899aa', fontSize: 12 }}>Send to address:</Text>
              <div style={{ color: '#00d2ff', fontFamily: 'monospace', fontSize: 13, wordBreak: 'break-all', marginTop: 4 }}>{processModal.cryptoAddress}</div>
              <Text style={{ color: '#8899aa', fontSize: 12 }}>Network: {processModal.network || 'N/A'}</Text>
            </div>
            <Form form={form} layout="vertical" onFinish={handleProcess}>
              <Form.Item name="status" label={<Text style={{ color: '#8899aa' }}>Status</Text>} rules={[{ required: true }]} initialValue="completed">
                <Select>
                  <Select.Option value="completed">Completed (Paid)</Select.Option>
                  <Select.Option value="rejected">Rejected</Select.Option>
                </Select>
              </Form.Item>
              <Form.Item name="txHash" label={<Text style={{ color: '#8899aa' }}>Transaction Hash</Text>}>
                <Input placeholder="Blockchain TX hash..." style={{ background: '#0d1526', border: '1px solid #1e2d40', color: '#fff' }} />
              </Form.Item>
              <Form.Item name="adminNote" label={<Text style={{ color: '#8899aa' }}>Note</Text>}>
                <Input.TextArea rows={2} style={{ background: '#0d1526', border: '1px solid #1e2d40', color: '#fff' }} />
              </Form.Item>
              <Button type="primary" htmlType="submit" loading={processing} block style={{ background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)', border: 'none' }}>Confirm</Button>
            </Form>
          </>
        )}
      </Modal>
    </div>
  );
}
