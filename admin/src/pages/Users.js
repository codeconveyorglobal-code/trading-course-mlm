import React, { useEffect, useState, useCallback } from 'react';
import { Table, Input, Select, Button, Tag, Space, Typography, Card, Modal, Form, message, Switch, Row, Col, Tooltip } from 'antd';
import { SearchOutlined, UserAddOutlined, EditOutlined, EyeOutlined, ReloadOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import api from '../services/api';
import dayjs from 'dayjs';

const { Title, Text } = Typography;

export default function Users() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [pagination, setPagination] = useState({ current: 1, pageSize: 20, total: 0 });
  const [filters, setFilters] = useState({ search: '', isActive: '', rank: '' });
  const [editUser, setEditUser] = useState(null);
  const [form] = Form.useForm();
  const navigate = useNavigate();

  const fetchUsers = useCallback(async (page = 1) => {
    setLoading(true);
    try {
      const params = { page, limit: 20, ...filters };
      Object.keys(params).forEach(k => !params[k] && delete params[k]);
      const res = await api.get('/admin/users', { params });
      setUsers(res.data.users);
      setPagination(p => ({ ...p, total: res.data.pagination.total, current: page }));
    } catch (err) {
      message.error('Failed to load users');
    } finally {
      setLoading(false);
    }
  }, [filters]);

  useEffect(() => { fetchUsers(); }, [fetchUsers]);

  const handleEdit = async (values) => {
    try {
      await api.put(`/admin/users/${editUser._id}`, values);
      message.success('User updated');
      setEditUser(null);
      fetchUsers();
    } catch (err) {
      message.error(err.response?.data?.message || 'Update failed');
    }
  };

  const columns = [
    { title: '#', render: (_, __, i) => (pagination.current - 1) * 20 + i + 1, width: 50 },
    {
      title: 'User', render: (_, r) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ width: 36, height: 36, borderRadius: 10, background: 'linear-gradient(135deg, #00d2ff22, #7b2ff722)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#00d2ff', fontWeight: 700 }}>
            {r.name?.[0]?.toUpperCase()}
          </div>
          <div>
            <Text strong style={{ color: '#fff', display: 'block' }}>{r.name}</Text>
            <Text style={{ color: '#4a5568', fontSize: 12 }}>{r.email}</Text>
          </div>
        </div>
      )
    },
    { title: 'Referral Code', dataIndex: 'referralCode', render: v => <Tag color="blue">{v}</Tag> },
    { title: 'Sponsor', render: (_, r) => r.sponsorId?.name || <Text style={{ color: '#4a5568' }}>None</Text> },
    { title: 'Rank', dataIndex: 'rank', render: v => {
      const colors = { Bronze: 'orange', Silver: 'default', Gold: 'gold', Platinum: 'cyan', Diamond: 'purple' };
      return <Tag color={colors[v]}>{v}</Tag>;
    }},
    { title: 'Balance', dataIndex: 'walletBalance', render: v => <Text style={{ color: '#00c48c' }}>${(v || 0).toFixed(2)}</Text> },
    { title: 'Courses', dataIndex: 'purchasedCourses', render: v => v?.length || 0 },
    { title: 'Status', dataIndex: 'isActive', render: v => v ? <span className="tag-success">Active</span> : <span className="tag-danger">Inactive</span> },
    { title: 'Joined', dataIndex: 'createdAt', render: v => dayjs(v).format('MMM D, YYYY') },
    {
      title: 'Actions', render: (_, r) => (
        <Space>
          <Tooltip title="View Details"><Button type="text" icon={<EyeOutlined />} style={{ color: '#00d2ff' }} onClick={() => navigate(`/users/${r._id}`)} /></Tooltip>
          <Tooltip title="Edit"><Button type="text" icon={<EditOutlined />} style={{ color: '#ffa94d' }} onClick={() => { setEditUser(r); form.setFieldsValue({ rank: r.rank, isActive: r.isActive, role: r.role }); }} /></Tooltip>
        </Space>
      )
    },
  ];

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <Title level={3} style={{ color: '#fff', margin: 0 }}>Users Management</Title>
        <Text style={{ color: '#8899aa' }}>{pagination.total} total users</Text>
      </div>

      <Card bordered={false} style={{ marginBottom: 16 }}>
        <Row gutter={12}>
          <Col xs={24} md={10}>
            <Input placeholder="Search name, email, referral code..." prefix={<SearchOutlined style={{ color: '#8899aa' }} />}
              value={filters.search} onChange={e => setFilters(f => ({ ...f, search: e.target.value }))}
              style={{ background: '#0d1526', border: '1px solid #1e2d40', color: '#fff' }} />
          </Col>
          <Col xs={12} md={5}>
            <Select placeholder="Status" value={filters.isActive || undefined} onChange={v => setFilters(f => ({ ...f, isActive: v }))} allowClear style={{ width: '100%' }}>
              <Select.Option value="true">Active</Select.Option>
              <Select.Option value="false">Inactive</Select.Option>
            </Select>
          </Col>
          <Col xs={12} md={5}>
            <Select placeholder="Rank" value={filters.rank || undefined} onChange={v => setFilters(f => ({ ...f, rank: v }))} allowClear style={{ width: '100%' }}>
              {['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'].map(r => <Select.Option key={r} value={r}>{r}</Select.Option>)}
            </Select>
          </Col>
          <Col xs={24} md={4}>
            <Button icon={<ReloadOutlined />} onClick={() => fetchUsers()} block style={{ background: '#1e2d40', border: 'none', color: '#fff' }}>Refresh</Button>
          </Col>
        </Row>
      </Card>

      <Card bordered={false}>
        <Table
          dataSource={users}
          columns={columns}
          rowKey="_id"
          loading={loading}
          pagination={{ ...pagination, onChange: p => fetchUsers(p) }}
          scroll={{ x: 1000 }}
        />
      </Card>

      <Modal
        title={<Text style={{ color: '#fff' }}>Edit User</Text>}
        open={!!editUser}
        onCancel={() => setEditUser(null)}
        footer={null}
        styles={{ content: { background: '#111827', border: '1px solid #1e2d40' }, header: { background: '#111827' } }}
      >
        <Form form={form} layout="vertical" onFinish={handleEdit}>
          <Form.Item name="rank" label={<Text style={{ color: '#8899aa' }}>Rank</Text>}>
            <Select>{['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'].map(r => <Select.Option key={r} value={r}>{r}</Select.Option>)}</Select>
          </Form.Item>
          <Form.Item name="role" label={<Text style={{ color: '#8899aa' }}>Role</Text>}>
            <Select><Select.Option value="user">User</Select.Option><Select.Option value="admin">Admin</Select.Option></Select>
          </Form.Item>
          <Form.Item name="isActive" label={<Text style={{ color: '#8899aa' }}>Active</Text>} valuePropName="checked">
            <Switch />
          </Form.Item>
          <Button type="primary" htmlType="submit" block style={{ background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)', border: 'none' }}>Save Changes</Button>
        </Form>
      </Modal>
    </div>
  );
}
