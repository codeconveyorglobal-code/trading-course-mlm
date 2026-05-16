import React, { useEffect, useState, useRef } from 'react';
import { Card, Typography, Input, Button, Select, message, Spin, Row, Col, Tag, Modal, Form, Space } from 'antd';
import { SearchOutlined, ApartmentOutlined, UserOutlined } from '@ant-design/icons';
import api from '../services/api';

const { Title, Text } = Typography;

// Recursive binary tree renderer
function TreeNode({ node, depth = 0, onNodeClick }) {
  if (!node) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
        <div className="mlm-tree-node empty" style={{ minWidth: 110, opacity: 0.4 }}>
          <div style={{ fontSize: 11, color: '#4a5568' }}>+ Empty Slot</div>
        </div>
      </div>
    );
  }

  const rankColors = { Bronze: '#cd7f32', Silver: '#aaa', Gold: '#ffd700', Platinum: '#00d2ff', Diamond: '#7b2ff7' };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '0 8px' }}>
      <div
        className={`mlm-tree-node${!node.user?.isActive ? ' inactive' : ''}`}
        style={{ borderColor: rankColors[node.user?.rank] || '#00d2ff', cursor: 'pointer', minWidth: 110 }}
        onClick={() => onNodeClick?.(node)}
      >
        <div style={{ fontSize: 20, fontWeight: 700, color: rankColors[node.user?.rank] || '#00d2ff' }}>
          {node.user?.name?.[0]?.toUpperCase() || '?'}
        </div>
        <div style={{ fontSize: 11, color: '#fff', fontWeight: 600 }}>{node.user?.name || 'N/A'}</div>
        <Tag style={{ fontSize: 9, margin: 0 }} color={node.user?.rank === 'Diamond' ? 'purple' : 'default'}>{node.user?.rank}</Tag>
      </div>

      {depth < 4 && (node.left || node.right) && (
        <>
          {/* Connector lines */}
          <div style={{ width: 2, height: 20, background: '#1e2d40' }} />
          <div style={{ display: 'flex', position: 'relative' }}>
            <div style={{ position: 'absolute', top: 0, left: '50%', transform: 'translateX(-50%)', height: 1, background: '#1e2d40', width: 'calc(50% + 55px)' }} />
            <div style={{ display: 'flex', gap: 24 }}>
              {/* Left branch */}
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                <div style={{ width: 2, height: 20, background: '#1e2d40' }} />
                <TreeNode node={node.left} depth={depth + 1} onNodeClick={onNodeClick} />
              </div>
              {/* Right branch */}
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                <div style={{ width: 2, height: 20, background: '#1e2d40' }} />
                <TreeNode node={node.right} depth={depth + 1} onNodeClick={onNodeClick} />
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  );
}

export default function MLMTree() {
  const [tree, setTree] = useState(null);
  const [loading, setLoading] = useState(true);
  const [searchUser, setSearchUser] = useState('');
  const [selectedNode, setSelectedNode] = useState(null);
  const [placeModal, setPlaceModal] = useState(false);
  const [users, setUsers] = useState([]);
  const [placeForm] = Form.useForm();
  const [placing, setPlacing] = useState(false);

  const fetchTree = async (userId = '') => {
    setLoading(true);
    try {
      const params = userId ? { userId } : {};
      const res = await api.get('/admin/mlm/tree', { params });
      setTree(res.data.tree);
    } catch (err) {
      message.error('Failed to load tree');
    } finally {
      setLoading(false);
    }
  };

  const fetchUsers = async (search = '') => {
    const res = await api.get('/admin/users', { params: { search, limit: 20 } });
    setUsers(res.data.users);
  };

  useEffect(() => { fetchTree(); fetchUsers(); }, []);

  const handlePlaceUser = async (values) => {
    setPlacing(true);
    try {
      await api.post('/admin/mlm/place-user', values);
      message.success('User placed successfully');
      setPlaceModal(false);
      placeForm.resetFields();
      fetchTree();
    } catch (err) {
      message.error(err.response?.data?.message || 'Failed');
    } finally {
      setPlacing(false);
    }
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24, flexWrap: 'wrap', gap: 12 }}>
        <Title level={3} style={{ color: '#fff', margin: 0 }}>
          <ApartmentOutlined style={{ marginRight: 10, color: '#00d2ff' }} />MLM Binary Tree
        </Title>
        <Space wrap>
          <Select showSearch placeholder="View tree from user..." optionFilterProp="label"
            style={{ width: 250 }} allowClear onSelect={v => fetchTree(v)} onClear={() => fetchTree()}
            onSearch={fetchUsers}
            options={users.map(u => ({ value: u._id, label: `${u.name} (${u.referralCode})` }))} />
          <Button type="primary" icon={<UserOutlined />} onClick={() => setPlaceModal(true)}
            style={{ background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)', border: 'none' }}>
            Place User Manually
          </Button>
        </Space>
      </div>

      <Card bordered={false} style={{ overflow: 'auto' }}>
        {loading ? (
          <div style={{ textAlign: 'center', padding: 80 }}><Spin size="large" /></div>
        ) : tree ? (
          <div style={{ overflowX: 'auto', padding: '24px 0', minWidth: 600 }}>
            <TreeNode node={tree} onNodeClick={node => setSelectedNode(node)} />
          </div>
        ) : (
          <div style={{ textAlign: 'center', padding: 80, color: '#4a5568' }}>No tree data available. Register the first user to begin.</div>
        )}
      </Card>

      {selectedNode && (
        <Modal
          title={<Text style={{ color: '#fff' }}>Node Details: {selectedNode.user?.name}</Text>}
          open={!!selectedNode}
          onCancel={() => setSelectedNode(null)}
          footer={[<Button key="close" onClick={() => setSelectedNode(null)}>Close</Button>]}
          styles={{ content: { background: '#111827' }, header: { background: '#111827' } }}
        >
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            {[
              ['Name', selectedNode.user?.name],
              ['Rank', <Tag>{selectedNode.user?.rank}</Tag>],
              ['Level', selectedNode.level],
              ['Position', <Tag color="blue">{selectedNode.position}</Tag>],
              ['Left Team', selectedNode.leftCount],
              ['Right Team', selectedNode.rightCount],
              ['Left Volume', `$${(selectedNode.leftVolume || 0).toFixed(2)}`],
              ['Right Volume', `$${(selectedNode.rightVolume || 0).toFixed(2)}`],
            ].map(([k, v]) => (
              <div key={k} style={{ background: '#0d1526', padding: '10px 14px', borderRadius: 8 }}>
                <Text style={{ color: '#8899aa', fontSize: 12 }}>{k}</Text>
                <div style={{ color: '#fff', fontWeight: 600 }}>{v}</div>
              </div>
            ))}
          </div>
        </Modal>
      )}

      <Modal
        title={<Text style={{ color: '#fff' }}>Place User in Tree Manually</Text>}
        open={placeModal}
        onCancel={() => setPlaceModal(false)}
        footer={null}
        styles={{ content: { background: '#111827' }, header: { background: '#111827' } }}
      >
        <Form form={placeForm} layout="vertical" onFinish={handlePlaceUser}>
          <Form.Item name="userId" label={<Text style={{ color: '#8899aa' }}>User to Place</Text>} rules={[{ required: true }]}>
            <Select showSearch placeholder="Select user..." optionFilterProp="label" onSearch={fetchUsers}
              options={users.map(u => ({ value: u._id, label: `${u.name} (${u.email})` }))} />
          </Form.Item>
          <Form.Item name="parentUserId" label={<Text style={{ color: '#8899aa' }}>Parent User</Text>} rules={[{ required: true }]}>
            <Select showSearch placeholder="Select parent user..." optionFilterProp="label" onSearch={fetchUsers}
              options={users.map(u => ({ value: u._id, label: `${u.name} (${u.referralCode})` }))} />
          </Form.Item>
          <Form.Item name="position" label={<Text style={{ color: '#8899aa' }}>Position</Text>} rules={[{ required: true }]}>
            <Select>
              <Select.Option value="left">Left</Select.Option>
              <Select.Option value="right">Right</Select.Option>
            </Select>
          </Form.Item>
          <Button type="primary" htmlType="submit" loading={placing} block
            style={{ background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)', border: 'none' }}>
            Place User
          </Button>
        </Form>
      </Modal>
    </div>
  );
}
