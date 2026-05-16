import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Row, Col, Card, Typography, Tag, Button, Tabs, Table, Space, Modal, Form, Select, message, Spin, Descriptions } from 'antd';
import { ArrowLeftOutlined, ApartmentOutlined } from '@ant-design/icons';
import api from '../services/api';
import dayjs from 'dayjs';

const { Title, Text } = Typography;

export default function UserDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [placeModal, setPlaceModal] = useState(false);
  const [placeForm] = Form.useForm();

  const fetchUser = async () => {
    try {
      const res = await api.get(`/admin/users/${id}`);
      setData(res.data);
    } catch (err) {
      message.error('Failed to load user');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchUser(); }, [id]);

  const handlePlaceUser = async (values) => {
    try {
      await api.post('/admin/mlm/place-user', { userId: id, ...values });
      message.success('User placed in tree');
      setPlaceModal(false);
      fetchUser();
    } catch (err) {
      message.error(err.response?.data?.message || 'Failed to place user');
    }
  };

  if (loading) return <div style={{ textAlign: 'center', paddingTop: 100 }}><Spin size="large" /></div>;
  if (!data) return null;

  const { user, node, commissions, transactions } = data;
  const rankColors = { Bronze: 'orange', Silver: 'default', Gold: 'gold', Platinum: 'cyan', Diamond: 'purple' };

  const commissionColumns = [
    { title: 'Type', dataIndex: 'type', render: v => <Tag color="blue">{v?.replace(/_/g, ' ')}</Tag> },
    { title: 'Amount', dataIndex: 'amount', render: v => <Text style={{ color: '#00c48c' }}>${v?.toFixed(2)}</Text> },
    { title: 'From', render: (_, r) => r.fromUserId?.name || 'N/A' },
    { title: 'Status', dataIndex: 'status', render: v => <Tag color={v === 'paid' ? 'success' : 'warning'}>{v}</Tag> },
    { title: 'Date', dataIndex: 'createdAt', render: v => dayjs(v).format('MMM D, YYYY') },
  ];

  return (
    <div>
      <Button icon={<ArrowLeftOutlined />} type="text" style={{ color: '#8899aa', marginBottom: 20 }} onClick={() => navigate('/users')}>Back to Users</Button>

      <Row gutter={[16, 16]}>
        <Col xs={24} lg={8}>
          <Card bordered={false}>
            <div style={{ textAlign: 'center', marginBottom: 20 }}>
              <div style={{ width: 80, height: 80, borderRadius: 20, background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 32, color: '#fff', margin: '0 auto 12px' }}>
                {user.name?.[0]?.toUpperCase()}
              </div>
              <Title level={4} style={{ color: '#fff', margin: 0 }}>{user.name}</Title>
              <Text style={{ color: '#8899aa' }}>{user.email}</Text>
              <div style={{ marginTop: 10 }}>
                <Tag color={rankColors[user.rank]}>{user.rank}</Tag>
                <Tag color={user.isActive ? 'success' : 'error'}>{user.isActive ? 'Active' : 'Inactive'}</Tag>
              </div>
            </div>

            <Descriptions column={1} size="small" labelStyle={{ color: '#8899aa' }} contentStyle={{ color: '#fff' }}>
              <Descriptions.Item label="Referral Code"><Tag color="blue">{user.referralCode}</Tag></Descriptions.Item>
              <Descriptions.Item label="Sponsor">{user.sponsorId?.name || 'None'}</Descriptions.Item>
              <Descriptions.Item label="Wallet Balance"><Text style={{ color: '#00c48c' }}>${(user.walletBalance || 0).toFixed(2)}</Text></Descriptions.Item>
              <Descriptions.Item label="Total Earnings"><Text style={{ color: '#7b2ff7' }}>${(user.totalEarnings || 0).toFixed(2)}</Text></Descriptions.Item>
              <Descriptions.Item label="Total Withdrawn">${(user.totalWithdrawn || 0).toFixed(2)}</Descriptions.Item>
              <Descriptions.Item label="Courses Purchased">{user.purchasedCourses?.length || 0}</Descriptions.Item>
              <Descriptions.Item label="Joined">{dayjs(user.createdAt).format('MMM D, YYYY')}</Descriptions.Item>
            </Descriptions>

            <Button block icon={<ApartmentOutlined />} style={{ marginTop: 16, background: '#1e2d40', border: 'none', color: '#fff' }} onClick={() => setPlaceModal(true)}>
              Place in MLM Tree
            </Button>
          </Card>

          {node && (
            <Card bordered={false} style={{ marginTop: 16 }}>
              <Text strong style={{ color: '#fff', display: 'block', marginBottom: 12 }}>MLM Tree Stats</Text>
              <Descriptions column={2} size="small" labelStyle={{ color: '#8899aa' }} contentStyle={{ color: '#fff' }}>
                <Descriptions.Item label="Level">{node.level}</Descriptions.Item>
                <Descriptions.Item label="Position"><Tag>{node.position}</Tag></Descriptions.Item>
                <Descriptions.Item label="Left Team">{node.leftCount}</Descriptions.Item>
                <Descriptions.Item label="Right Team">{node.rightCount}</Descriptions.Item>
                <Descriptions.Item label="Left Vol">${node.leftVolume?.toFixed(2)}</Descriptions.Item>
                <Descriptions.Item label="Right Vol">${node.rightVolume?.toFixed(2)}</Descriptions.Item>
              </Descriptions>
            </Card>
          )}
        </Col>

        <Col xs={24} lg={16}>
          <Tabs
            items={[
              { key: 'commissions', label: 'Commissions', children: (
                <Table dataSource={commissions} columns={commissionColumns} rowKey="_id" pagination={false} scroll={{ x: 500 }} />
              )},
              { key: 'transactions', label: 'Transactions', children: (
                <Table dataSource={transactions} columns={[
                  { title: 'Course', render: (_, r) => r.courseId?.title || 'N/A' },
                  { title: 'Amount', dataIndex: 'amount', render: v => `$${v?.toFixed(2)}` },
                  { title: 'Crypto', dataIndex: 'cryptoCurrency', render: v => v ? <Tag color="cyan">{v}</Tag> : '-' },
                  { title: 'Status', dataIndex: 'status', render: v => <Tag color={v === 'completed' ? 'success' : 'warning'}>{v}</Tag> },
                  { title: 'Date', dataIndex: 'createdAt', render: v => dayjs(v).format('MMM D, YYYY') },
                ]} rowKey="_id" pagination={false} scroll={{ x: 500 }} />
              )},
              { key: 'courses', label: 'Purchased Courses', children: (
                <div>{user.purchasedCourses?.map(c => (
                  <div key={c._id} style={{ padding: '10px 0', borderBottom: '1px solid #1a2535', display: 'flex', justifyContent: 'space-between' }}>
                    <Text style={{ color: '#fff' }}>{c.title}</Text>
                    <Text style={{ color: '#00d2ff' }}>${c.price}</Text>
                  </div>
                ))}</div>
              )},
            ]}
          />
        </Col>
      </Row>

      <Modal
        title="Place User in MLM Tree"
        open={placeModal}
        onCancel={() => setPlaceModal(false)}
        footer={null}
        styles={{ content: { background: '#111827' }, header: { background: '#111827' } }}
      >
        <Form form={placeForm} layout="vertical" onFinish={handlePlaceUser}>
          <Form.Item name="parentUserId" label={<Text style={{ color: '#8899aa' }}>Parent User ID</Text>} rules={[{ required: true }]}>
            <Select showSearch placeholder="Search parent user..." filterOption={false} style={{ width: '100%' }} />
          </Form.Item>
          <Form.Item name="position" label={<Text style={{ color: '#8899aa' }}>Position</Text>} rules={[{ required: true }]}>
            <Select>
              <Select.Option value="left">Left</Select.Option>
              <Select.Option value="right">Right</Select.Option>
            </Select>
          </Form.Item>
          <Button type="primary" htmlType="submit" block style={{ background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)', border: 'none' }}>Place User</Button>
        </Form>
      </Modal>
    </div>
  );
}
