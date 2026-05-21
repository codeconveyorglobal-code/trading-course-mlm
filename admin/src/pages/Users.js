import React, { useEffect, useState, useCallback } from 'react';
import { Table, Input, Select, Button, Tag, Space, Typography, Card, Modal, Form, message, Switch, Row, Col, Tooltip, Divider } from 'antd';
import { SearchOutlined, UserAddOutlined, EditOutlined, EyeOutlined, ReloadOutlined, PlusOutlined } from '@ant-design/icons';
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
  const [addUserVisible, setAddUserVisible] = useState(false);
  const [addLoading, setAddLoading] = useState(false);
  const [allUsers, setAllUsers] = useState([]);
  const [form] = Form.useForm();
  const [addForm] = Form.useForm();
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

  const fetchAllUsersForSelect = async () => {
    try {
      const res = await api.get('/admin/users', { params: { limit: 500 } });
      setAllUsers(res.data.users || []);
    } catch (_) {}
  };

  const handleAddUser = async (values) => {
    setAddLoading(true);
    try {
      await api.post('/admin/create-user', values);
      message.success('User created successfully');
      setAddUserVisible(false);
      addForm.resetFields();
      fetchUsers();
    } catch (err) {
      message.error(err.response?.data?.message || 'Failed to create user');
    } finally {
      setAddLoading(false);
    }
  };

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
        <Space>
          <Text style={{ color: '#8899aa' }}>{pagination.total} total users</Text>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            style={{ background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)', border: 'none' }}
            onClick={() => { fetchAllUsersForSelect(); setAddUserVisible(true); }}
          >
            Add User
          </Button>
        </Space>
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

      {/* Edit User Modal */}
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

      {/* Add User Modal */}
      <Modal
        title={<Text style={{ color: '#fff' }}>Add New User</Text>}
        open={addUserVisible}
        onCancel={() => { setAddUserVisible(false); addForm.resetFields(); }}
        footer={null}
        width={560}
        styles={{ content: { background: '#111827', border: '1px solid #1e2d40' }, header: { background: '#111827' } }}
      >
        <Form form={addForm} layout="vertical" onFinish={handleAddUser}>
          <Row gutter={12}>
            <Col span={12}>
              <Form.Item name="name" label={<Text style={{ color: '#8899aa' }}>Full Name</Text>} rules={[{ required: true, message: 'Name is required' }]}>
                <Input placeholder="John Doe" style={{ background: '#0d1526', border: '1px solid #1e2d40', color: '#fff' }} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="phone" label={<Text style={{ color: '#8899aa' }}>Phone (optional)</Text>}>
                <Input placeholder="+1234567890" style={{ background: '#0d1526', border: '1px solid #1e2d40', color: '#fff' }} />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="email" label={<Text style={{ color: '#8899aa' }}>Email</Text>} rules={[{ required: true, type: 'email', message: 'Valid email is required' }]}>
            <Input placeholder="user@example.com" style={{ background: '#0d1526', border: '1px solid #1e2d40', color: '#fff' }} />
          </Form.Item>
          <Form.Item name="password" label={<Text style={{ color: '#8899aa' }}>Password</Text>} rules={[{ required: true, min: 6, message: 'Min 6 characters' }]}>
            <Input.Password placeholder="••••••••" style={{ background: '#0d1526', border: '1px solid #1e2d40', color: '#fff' }} />
          </Form.Item>
          <Form.Item name="referralCode" label={<Text style={{ color: '#8899aa' }}>Sponsor Referral Code (optional)</Text>}>
            <Input placeholder="e.g. ABC123" style={{ background: '#0d1526', border: '1px solid #1e2d40', color: '#fff' }} />
          </Form.Item>

          <Divider style={{ borderColor: '#1e2d40', margin: '12px 0' }}>
            <Text style={{ color: '#4a5568', fontSize: 12 }}>Binary Tree Placement (optional)</Text>
          </Divider>

          <Form.Item name="parentUserId" label={<Text style={{ color: '#8899aa' }}>Place under user</Text>}>
            <Select
              showSearch
              placeholder="Search by name or email..."
              optionFilterProp="label"
              allowClear
              options={allUsers.map(u => ({ value: u._id, label: `${u.name} (${u.email})` }))}
            />
          </Form.Item>
          <Form.Item name="position" label={<Text style={{ color: '#8899aa' }}>Position</Text>}>
            <Select placeholder="Select position" allowClear>
              <Select.Option value="left">Left</Select.Option>
              <Select.Option value="right">Right</Select.Option>
            </Select>
          </Form.Item>

          <Button type="primary" htmlType="submit" loading={addLoading} block
            style={{ background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)', border: 'none', marginTop: 8 }}>
            Create User
          </Button>
        </Form>
      </Modal>
    </div>
  );
}
