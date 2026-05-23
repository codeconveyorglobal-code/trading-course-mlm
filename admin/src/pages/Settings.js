import React, { useState, useEffect } from 'react';
import { Card, Typography, Form, Input, Button, message, Row, Col, Divider, Switch, Tag, Spin, Alert } from 'antd';
import { KeyOutlined, SafetyOutlined, LinkOutlined, CheckCircleOutlined, CloseCircleOutlined } from '@ant-design/icons';
import { useAuth } from '../contexts/AuthContext';
import api from '../services/api';

const { Title, Text } = Typography;

export default function Settings() {
  const { admin } = useAuth();
  const [pwForm] = Form.useForm();
  const [adminForm] = Form.useForm();
  const [payForm] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [creating, setCreating] = useState(false);
  const [payLoading, setPayLoading] = useState(false);
  const [paySettingsLoading, setPaySettingsLoading] = useState(true);
  const [testingKey, setTestingKey] = useState(false);
  const [keyStatus, setKeyStatus] = useState(null); // 'ok' | 'fail' | null
  const [hasApiKey, setHasApiKey] = useState(false);

  const inputStyle = { background: '#0d1526', border: '1px solid #1e2d40', color: '#fff' };

  useEffect(() => {
    loadPaymentSettings();
  }, []);

  const loadPaymentSettings = async () => {
    setPaySettingsLoading(true);
    try {
      const res = await api.get('/admin/payment-settings');
      const s = res.data.settings;
      payForm.setFieldsValue({
        nowpaymentsCallbackUrl: s.nowpaymentsCallbackUrl || '',
        testMode: s.testMode || false,
      });
      setHasApiKey(!!(s.nowpaymentsApiKeyMasked));
      // Show masked values as placeholder
      payForm.setFields([
        { name: 'nowpaymentsApiKey', value: '' },
        { name: 'nowpaymentsIpnSecret', value: '' },
      ]);
      // store masked for display
      if (s.nowpaymentsApiKeyMasked) payForm.setFields([{ name: 'nowpaymentsApiKey', value: '', placeholder: s.nowpaymentsApiKeyMasked }]);
    } catch (_) {}
    setPaySettingsLoading(false);
  };

  const savePaymentSettings = async (values) => {
    setPayLoading(true);
    try {
      const payload = { nowpaymentsCallbackUrl: values.nowpaymentsCallbackUrl, testMode: values.testMode };
      if (values.nowpaymentsApiKey && values.nowpaymentsApiKey.trim()) payload.nowpaymentsApiKey = values.nowpaymentsApiKey.trim();
      if (values.nowpaymentsIpnSecret && values.nowpaymentsIpnSecret.trim()) payload.nowpaymentsIpnSecret = values.nowpaymentsIpnSecret.trim();
      await api.put('/admin/payment-settings', payload);
      message.success('Payment settings saved!');
      setKeyStatus(null);
      loadPaymentSettings();
    } catch (err) {
      message.error(err.response?.data?.message || 'Failed to save');
    }
    setPayLoading(false);
  };

  const testApiKey = async () => {
    setTestingKey(true);
    setKeyStatus(null);
    try {
      await api.get('/payments/currencies');
      setKeyStatus('ok');
      message.success('API key is working!');
    } catch (_) {
      setKeyStatus('fail');
      message.error('API key test failed — check the key and try again');
    }
    setTestingKey(false);
  };

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

      {/* Payment Gateway */}
      <Card
        bordered={false}
        style={{ marginBottom: 24 }}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <KeyOutlined style={{ color: '#f0a500', fontSize: 18 }} />
            <Text style={{ color: '#f0a500', fontSize: 16 }}>NOWPayments API Configuration</Text>
            {hasApiKey && <Tag color="green" icon={<CheckCircleOutlined />}>Key Saved</Tag>}
            {!hasApiKey && <Tag color="orange">No Key Set</Tag>}
          </div>
        }
      >
        {paySettingsLoading ? (
          <div style={{ textAlign: 'center', padding: 24 }}><Spin /></div>
        ) : (
          <>
            <Alert
              message="Your NOWPayments API key is stored securely in the database. Leave the key field blank to keep the current saved key."
              type="info"
              showIcon
              style={{ marginBottom: 16, background: '#0d1526', border: '1px solid #1e2d40' }}
            />
            <Form form={payForm} layout="vertical" onFinish={savePaymentSettings} initialValues={{ testMode: false }}>
              <Row gutter={16}>
                <Col xs={24} md={12}>
                  <Form.Item
                    name="nowpaymentsApiKey"
                    label={<Text style={{ color: '#8899aa' }}>API Key {hasApiKey && <Text style={{ color: '#52c41a', fontSize: 11 }}>(key is saved — enter new to replace)</Text>}</Text>}
                  >
                    <Input.Password
                      prefix={<KeyOutlined style={{ color: '#8899aa' }} />}
                      style={inputStyle}
                      placeholder={hasApiKey ? '••••••••  (saved)' : 'Enter NOWPayments API key'}
                    />
                  </Form.Item>
                </Col>
                <Col xs={24} md={12}>
                  <Form.Item
                    name="nowpaymentsIpnSecret"
                    label={<Text style={{ color: '#8899aa' }}>IPN Secret {hasApiKey && <Text style={{ color: '#52c41a', fontSize: 11 }}>(enter new to replace)</Text>}</Text>}
                  >
                    <Input.Password
                      prefix={<SafetyOutlined style={{ color: '#8899aa' }} />}
                      style={inputStyle}
                      placeholder="IPN secret for webhook verification"
                    />
                  </Form.Item>
                </Col>
                <Col xs={24} md={18}>
                  <Form.Item
                    name="nowpaymentsCallbackUrl"
                    label={<Text style={{ color: '#8899aa' }}>IPN Callback URL</Text>}
                  >
                    <Input
                      prefix={<LinkOutlined style={{ color: '#8899aa' }} />}
                      style={inputStyle}
                      placeholder="https://your-backend.up.railway.app/api/payments/callback"
                    />
                  </Form.Item>
                </Col>
                <Col xs={24} md={6}>
                  <Form.Item name="testMode" label={<Text style={{ color: '#8899aa' }}>Sandbox / Test Mode</Text>} valuePropName="checked">
                    <Switch checkedChildren="Test" unCheckedChildren="Live" />
                  </Form.Item>
                </Col>
              </Row>
              <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap' }}>
                <Button
                  type="primary"
                  htmlType="submit"
                  loading={payLoading}
                  icon={<KeyOutlined />}
                  style={{ background: 'linear-gradient(135deg, #f0a500, #e05c00)', border: 'none' }}
                >
                  Save Payment Settings
                </Button>
                <Button
                  onClick={testApiKey}
                  loading={testingKey}
                  style={{ background: '#0d1526', border: '1px solid #1e2d40', color: '#fff' }}
                  icon={keyStatus === 'ok' ? <CheckCircleOutlined style={{ color: '#52c41a' }} /> : keyStatus === 'fail' ? <CloseCircleOutlined style={{ color: '#ff4d4f' }} /> : null}
                >
                  {keyStatus === 'ok' ? 'Key Working ✓' : keyStatus === 'fail' ? 'Key Failed ✗' : 'Test API Key'}
                </Button>
              </div>
            </Form>
          </>
        )}
      </Card>

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
