import React, { useState, useEffect } from 'react';
import { Form, Input, Button, message, Typography } from 'antd';
import { UserOutlined, LockOutlined, ThunderboltOutlined } from '@ant-design/icons';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';

const { Title, Text } = Typography;

export default function Login() {
  const { login, admin } = useAuth();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);

  // Navigate only after the admin state is actually committed in context
  useEffect(() => {
    if (admin) navigate('/', { replace: true });
  }, [admin, navigate]);

  const onFinish = async ({ email, password }) => {
    setLoading(true);
    try {
      await login(email, password);
      message.success('Welcome back!');
    } catch (err) {
      const msg =
        err.response?.data?.message ||
        err.message ||
        'Login failed. Please check your credentials.';
      message.error(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{
      minHeight: '100vh', background: 'radial-gradient(ellipse at 20% 50%, #0d1f3c 0%, #0a0e1a 70%)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <div style={{ position: 'absolute', inset: 0, overflow: 'hidden', pointerEvents: 'none' }}>
        <div style={{ position: 'absolute', top: '20%', left: '10%', width: 400, height: 400, borderRadius: '50%', background: 'radial-gradient(circle, rgba(0,210,255,0.05) 0%, transparent 70%)' }} />
        <div style={{ position: 'absolute', bottom: '20%', right: '10%', width: 300, height: 300, borderRadius: '50%', background: 'radial-gradient(circle, rgba(123,47,247,0.05) 0%, transparent 70%)' }} />
      </div>

      <div style={{
        width: 420, background: 'rgba(17,24,39,0.9)', backdropFilter: 'blur(20px)',
        border: '1px solid rgba(0,210,255,0.2)', borderRadius: 20, padding: 48,
        boxShadow: '0 0 60px rgba(0,210,255,0.1)',
      }}>
        <div style={{ textAlign: 'center', marginBottom: 40 }}>
          <div style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', width: 64, height: 64, borderRadius: 16, background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)', marginBottom: 16 }}>
            <ThunderboltOutlined style={{ fontSize: 32, color: '#fff' }} />
          </div>
          <Title level={2} style={{ color: '#fff', margin: 0 }}>TradeMLM</Title>
          <Text style={{ color: '#8899aa' }}>Admin Control Panel</Text>
        </div>

        <Form layout="vertical" onFinish={onFinish} size="large">
          <Form.Item name="email" rules={[{ required: true, type: 'email' }]}>
            <Input prefix={<UserOutlined style={{ color: '#8899aa' }} />} placeholder="Admin Email"
              style={{ background: '#0d1526', border: '1px solid #1e2d40', color: '#fff', borderRadius: 10 }} />
          </Form.Item>
          <Form.Item name="password" rules={[{ required: true }]}>
            <Input.Password prefix={<LockOutlined style={{ color: '#8899aa' }} />} placeholder="Password"
              style={{ background: '#0d1526', border: '1px solid #1e2d40', color: '#fff', borderRadius: 10 }} />
          </Form.Item>
          <Button type="primary" htmlType="submit" loading={loading} block style={{
            height: 48, borderRadius: 10, background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)',
            border: 'none', fontSize: 16, fontWeight: 600, marginTop: 8,
          }}>
            Sign In to Admin
          </Button>
        </Form>
      </div>
    </div>
  );
}
