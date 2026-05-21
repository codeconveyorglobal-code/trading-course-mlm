import React, { useEffect, useState } from 'react';
import { Table, Button, Tag, Typography, Card, Space, Switch, message, Popconfirm, Modal, Row, Col, Input } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, UploadOutlined, EyeOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import api from '../services/api';
import dayjs from 'dayjs';

const { Title, Text } = Typography;
const BASE_URL = 'https://hopeful-energy-production.up.railway.app';

export default function Courses() {
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const fetchCourses = async () => {
    setLoading(true);
    try {
      const res = await api.get('/courses/admin/all');
      setCourses(res.data.courses);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchCourses(); }, []);

  const togglePublish = async (id, val) => {
    try {
      await api.put(`/courses/${id}`, { isPublished: val });
      setCourses(c => c.map(x => x._id === id ? { ...x, isPublished: val } : x));
      message.success(val ? 'Course published' : 'Course unpublished');
    } catch {
      message.error('Failed to update');
    }
  };

  const deleteCourse = async (id) => {
    try {
      await api.delete(`/courses/${id}`);
      setCourses(c => c.filter(x => x._id !== id));
      message.success('Course deleted');
    } catch {
      message.error('Delete failed');
    }
  };

  const categoryColors = { Forex: 'blue', Crypto: 'cyan', Stocks: 'green', Options: 'purple', Futures: 'orange', 'Technical Analysis': 'magenta', 'Fundamental Analysis': 'red', 'Risk Management': 'gold', 'Advanced Strategies': 'volcano', Beginner: 'lime' };

  const columns = [
    {
      title: 'Course', render: (_, r) => (
        <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
          {r.thumbnail
            ? <img src={`${BASE_URL}${r.thumbnail}`} alt="" style={{ width: 56, height: 40, borderRadius: 8, objectFit: 'cover' }} />
            : <div style={{ width: 56, height: 40, borderRadius: 8, background: 'linear-gradient(135deg,#1e2d40,#0d1526)', display:'flex', alignItems:'center', justifyContent:'center', color:'#4a5568', fontSize:18 }}>📖</div>
          }
          <div>
            <Text strong style={{ color: '#fff', display: 'block' }}>{r.title}</Text>
            <Text style={{ color: '#4a5568', fontSize: 12 }}>{r.totalLessons || 0} lessons · {r.duration || 'N/A'}</Text>
          </div>
        </div>
      )
    },
    { title: 'Category', dataIndex: 'category', render: v => <Tag color={categoryColors[v] || 'default'}>{v}</Tag> },
    { title: 'Level', dataIndex: 'level', render: v => <Tag>{v}</Tag> },
    { title: 'Price', dataIndex: 'price', render: (v, r) => (
      <div>
        <Text style={{ color: '#00d2ff' }}>${v}</Text>
        {r.discountPrice && <Text style={{ color: '#4a5568', textDecoration: 'line-through', marginLeft: 8, fontSize: 12 }}>${r.discountPrice}</Text>}
      </div>
    )},
    { title: 'Enrolled', dataIndex: 'enrolledCount' },
    { title: 'MLM', dataIndex: 'isMLMEligible', render: v => v ? <span className="tag-success">Yes</span> : <span className="tag-danger">No</span> },
    { title: 'Published', dataIndex: 'isPublished', render: (v, r) => <Switch checked={v} onChange={val => togglePublish(r._id, val)} size="small" /> },
    {
      title: 'Actions', render: (_, r) => (
        <Space>
          <Button type="text" icon={<EditOutlined />} style={{ color: '#ffa94d' }} onClick={() => navigate(`/courses/${r._id}/edit`)} />
          <Button type="text" icon={<UploadOutlined />} style={{ color: '#00d2ff' }} onClick={() => navigate(`/courses/${r._id}/quizzes`)} />
          <Popconfirm title="Delete this course?" onConfirm={() => deleteCourse(r._id)} okText="Yes" cancelText="No">
            <Button type="text" icon={<DeleteOutlined />} style={{ color: '#ff4757' }} />
          </Popconfirm>
        </Space>
      )
    },
  ];

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 24 }}>
        <Title level={3} style={{ color: '#fff', margin: 0 }}>Courses</Title>
        <Button type="primary" icon={<PlusOutlined />} onClick={() => navigate('/courses/new')}
          style={{ background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)', border: 'none' }}>
          Add Course
        </Button>
      </div>
      <Card bordered={false}>
        <Table dataSource={courses} columns={columns} rowKey="_id" loading={loading} scroll={{ x: 900 }} />
      </Card>
    </div>
  );
}
