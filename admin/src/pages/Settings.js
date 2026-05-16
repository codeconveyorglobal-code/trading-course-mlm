import React, { useState } from 'react';
import { Card, Typography, Form, Input, Button, message, Row, Col, Divider } from 'antd';
import { useAuth } from '../contexts/AuthContext';
import api from '../services/api';

const { Title, Text } = Typography;

export default function Settings() {
  const { admin } = useAuth();
  const [pwForm] = Form.useForm();
  const [adminForm] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [creating, setCreating] = useState(false);

  const inputStyle = { background: '#0d1526', border: '1px solid #1e2d40', color: '#fff' };

  const changePassword = async (values) => {
    setLoading(true);
    try {
      await api.put('/auth/change-password', values);
      message.success('Password changed');
      pwForm.resetFields();
    } catch (err) {
      message.error(err.response?.data?.message || 'Failed');
    } finally {
      setLoading(false);
    }
  };

  const createAdmin = async (values) => {
    setCreating(true);
    try {
      await api.post('/admin/create-admin', values);
      message.success('Admin created!');
      adminForm.resetFields();
    } catch (err) {
      message.error(err.response?.data?.message || 'Failed');
    } finally {
      setCreating(false);
    }
  };

  return (
    <div>
      <Title level={3} style={{ color: '#fff', marginBottom: 24 }}>Settings</Title>
      <Row gutter={24}>
        <Col xs={24} lg={12}>
          <Card bordered={false} title={<Text style={{ color: '#00d2ff' }}>Change Password</Text>} style={{ marginBottom: 16 }}>
            <Form form={pwForm} layout="vertical" onFinish={changePassword}>
              <Form.Item name="currentPassword" label={<Text style={{ color: '#8899aa' }}>Current Password</Text>} rules={[{ required: true }]}>
                <Input.Password style={inputStyle} />
              </Form.Item>
              <Form.Item name="newPassword" label={<Text style={{ color: '#8899aa' }}>New Password</Text>} rules={[{ required: true, min: 6 }]}>
                <Input.Password style={inputStyle} />
              </Form.Item>
              <Button type="primary" htmlType="submit" loading={loading} style={{ background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)', border: 'none' }}>
                Update Password
              </Button>
            </Form>
          </Card>
        </Col>
        <Col xs={24} lg={12}>
          <Card bordered={false} title={<Text style={{ color: '#7b2ff7' }}>Create New Admin</Text>}>
            <Form form={adminForm} layout="vertical" onFinish={createAdmin}>
              <Form.Item name="name" label={<Text style={{ color: '#8899aa' }}>Name</Text>} rules={[{ required: true }]}>
                <Input style={inputStyle} />
              </Form.Item>
              <Form.Item name="email" label={<Text style={{ color: '#8899aa' }}>Email</Text>} rules={[{ required: true, type: 'email' }]}>
                <Input style={inputStyle} />
              </Form.Item>
              <Form.Item name="password" label={<Text style={{ color: '#8899aa' }}>Password</Text>} rules={[{ required: true, min: 6 }]}>
                <Input.Password style={inputStyle} />
              </Form.Item>
              <Button type="primary" htmlType="submit" loading={creating} style={{ background: 'linear-gradient(135deg, #7b2ff7, #00d2ff)', border: 'none' }}>
                Create Admin
              </Button>
            </Form>
          </Card>
        </Col>
      </Row>
    </div>
  );
}
