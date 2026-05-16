import React, { useEffect, useState } from 'react';
import { Form, InputNumber, Switch, Button, Card, Typography, Divider, message, Spin, Row, Col, Input, Select } from 'antd';
import api from '../services/api';

const { Title, Text } = Typography;

export default function MLMSettings() {
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    api.get('/mlm/settings').then(res => {
      if (res.data.settings) {
        const s = res.data.settings;
        form.setFieldsValue({
          directReferralCommission: s.directReferralCommission,
          binaryEnabled: s.binaryEnabled,
          binaryMatchingBonus: s.binaryMatchingBonus,
          maxBinaryPercentage: s.maxBinaryPercentage,
          minPayout: s.minPayout,
          payoutSchedule: s.payoutSchedule,
          commissionHoldDays: s.commissionHoldDays,
          commissionCurrency: s.commissionCurrency,
          dailyCap: s.dailyCap,
          // Level commissions
          ...Object.fromEntries((s.levelCommissions || []).map(l => [`level_${l.level}`, l.percentage])),
        });
      }
    }).finally(() => setLoading(false));
  }, []);

  const onFinish = async (values) => {
    setSaving(true);
    try {
      const levelCommissions = [1, 2, 3, 4, 5].map(l => ({ level: l, percentage: values[`level_${l}`] || 0 }));
      const payload = { ...values, levelCommissions };
      [1, 2, 3, 4, 5].forEach(l => delete payload[`level_${l}`]);

      await api.put('/admin/mlm/settings', payload);
      message.success('MLM Settings saved!');
    } catch (err) {
      message.error('Failed to save settings');
    } finally {
      setSaving(false);
    }
  };

  const inputStyle = { background: '#0d1526', border: '1px solid #1e2d40', color: '#fff', width: '100%' };
  const labelStyle = { color: '#8899aa' };

  if (loading) return <div style={{ textAlign: 'center', paddingTop: 100 }}><Spin size="large" /></div>;

  return (
    <div>
      <Title level={3} style={{ color: '#fff', marginBottom: 24 }}>MLM Commission Settings</Title>
      <Form form={form} layout="vertical" onFinish={onFinish}>
        <Row gutter={24}>
          <Col xs={24} lg={12}>
            <Card bordered={false} title={<Text style={{ color: '#00d2ff' }}>Direct Referral</Text>} style={{ marginBottom: 16 }}>
              <Form.Item name="directReferralCommission" label={<Text style={labelStyle}>Direct Referral Commission (%)</Text>}>
                <InputNumber min={0} max={100} style={inputStyle} addonAfter="%" />
              </Form.Item>
            </Card>

            <Card bordered={false} title={<Text style={{ color: '#00d2ff' }}>Level Commissions (Upline)</Text>} style={{ marginBottom: 16 }}>
              {[1, 2, 3, 4, 5].map(l => (
                <Form.Item key={l} name={`level_${l}`} label={<Text style={labelStyle}>Level {l} Commission (%)</Text>}>
                  <InputNumber min={0} max={100} style={inputStyle} addonAfter="%" />
                </Form.Item>
              ))}
            </Card>
          </Col>

          <Col xs={24} lg={12}>
            <Card bordered={false} title={<Text style={{ color: '#7b2ff7' }}>Binary Plan</Text>} style={{ marginBottom: 16 }}>
              <Form.Item name="binaryEnabled" label={<Text style={labelStyle}>Enable Binary Plan</Text>} valuePropName="checked">
                <Switch />
              </Form.Item>
              <Form.Item name="binaryMatchingBonus" label={<Text style={labelStyle}>Binary Matching Bonus (%)</Text>}>
                <InputNumber min={0} max={100} style={inputStyle} addonAfter="%" />
              </Form.Item>
              <Form.Item name="maxBinaryPercentage" label={<Text style={labelStyle}>Max Daily Binary Cap (%)</Text>}>
                <InputNumber min={0} max={100} style={inputStyle} addonAfter="%" />
              </Form.Item>
            </Card>

            <Card bordered={false} title={<Text style={{ color: '#00c48c' }}>Payout Settings</Text>} style={{ marginBottom: 16 }}>
              <Form.Item name="minPayout" label={<Text style={labelStyle}>Minimum Payout (USD)</Text>}>
                <InputNumber min={1} style={inputStyle} addonBefore="$" />
              </Form.Item>
              <Form.Item name="payoutSchedule" label={<Text style={labelStyle}>Payout Schedule</Text>}>
                <Select>
                  <Select.Option value="instant">Instant</Select.Option>
                  <Select.Option value="daily">Daily</Select.Option>
                  <Select.Option value="weekly">Weekly</Select.Option>
                  <Select.Option value="monthly">Monthly</Select.Option>
                </Select>
              </Form.Item>
              <Form.Item name="commissionHoldDays" label={<Text style={labelStyle}>Commission Hold Days</Text>}>
                <InputNumber min={0} style={inputStyle} addonAfter="days" />
              </Form.Item>
              <Form.Item name="commissionCurrency" label={<Text style={labelStyle}>Commission Currency</Text>}>
                <Select>
                  {['USDT', 'USDC', 'BTC', 'ETH', 'BNB'].map(c => <Select.Option key={c} value={c}>{c}</Select.Option>)}
                </Select>
              </Form.Item>
              <Form.Item name="dailyCap" label={<Text style={labelStyle}>Daily Earning Cap (USD, 0=unlimited)</Text>}>
                <InputNumber min={0} style={inputStyle} addonBefore="$" />
              </Form.Item>
            </Card>
          </Col>
        </Row>

        <Button type="primary" htmlType="submit" loading={saving} size="large"
          style={{ background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)', border: 'none', minWidth: 200, height: 48 }}>
          Save Settings
        </Button>
      </Form>
    </div>
  );
}
