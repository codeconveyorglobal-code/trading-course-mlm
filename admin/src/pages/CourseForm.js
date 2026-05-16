import React, { useEffect, useState } from 'react';
import { Form, Input, Select, InputNumber, Button, Card, Typography, Switch, Upload, message, Row, Col, Divider, Tag, List, Modal } from 'antd';
import { UploadOutlined, PlusOutlined, DeleteOutlined, ArrowLeftOutlined } from '@ant-design/icons';
import { useNavigate, useParams } from 'react-router-dom';
import api from '../services/api';

const { Title, Text } = Typography;
const { TextArea } = Input;

export default function CourseForm() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [thumbnail, setThumbnail] = useState(null);
  const [materials, setMaterials] = useState([]);
  const [materialModal, setMaterialModal] = useState(false);
  const [materialForm] = Form.useForm();
  const [uploadingMaterial, setUploadingMaterial] = useState(false);
  const isEdit = !!id;

  useEffect(() => {
    if (isEdit) {
      api.get(`/courses/${id}`).then(res => {
        const c = res.data.course;
        form.setFieldsValue({ ...c, whatYouLearn: c.whatYouLearn?.join('\n'), requirements: c.requirements?.join('\n') });
        setMaterials(c.materials || []);
      });
    }
  }, [id]);

  const onFinish = async (values) => {
    setLoading(true);
    try {
      const formData = new FormData();
      Object.entries(values).forEach(([k, v]) => {
        if (v !== undefined && v !== null) {
          if (k === 'whatYouLearn' || k === 'requirements') {
            const arr = v.split('\n').filter(Boolean);
            arr.forEach(item => formData.append(`${k}[]`, item));
          } else {
            formData.append(k, v);
          }
        }
      });
      if (thumbnail) formData.append('thumbnail', thumbnail);

      if (isEdit) {
        await api.put(`/courses/${id}`, formData, { headers: { 'Content-Type': 'multipart/form-data' } });
        message.success('Course updated!');
      } else {
        await api.post('/courses', formData, { headers: { 'Content-Type': 'multipart/form-data' } });
        message.success('Course created!');
        navigate('/courses');
      }
    } catch (err) {
      message.error(err.response?.data?.message || 'Failed');
    } finally {
      setLoading(false);
    }
  };

  const uploadMaterial = async (values) => {
    setUploadingMaterial(true);
    try {
      const formData = new FormData();
      formData.append('title', values.title);
      formData.append('type', values.type);
      formData.append('isPreview', values.isPreview ? 'true' : 'false');
      if (values.file?.fileList?.[0]?.originFileObj) {
        formData.append('material', values.file.fileList[0].originFileObj);
      }
      const res = await api.post(`/courses/${id}/materials`, formData, { headers: { 'Content-Type': 'multipart/form-data' } });
      setMaterials(res.data.course.materials);
      message.success('Material uploaded!');
      setMaterialModal(false);
      materialForm.resetFields();
    } catch (err) {
      message.error('Upload failed');
    } finally {
      setUploadingMaterial(false);
    }
  };

  const inputStyle = { background: '#0d1526', border: '1px solid #1e2d40', color: '#fff', borderRadius: 8 };

  return (
    <div>
      <Button icon={<ArrowLeftOutlined />} type="text" style={{ color: '#8899aa', marginBottom: 20 }} onClick={() => navigate('/courses')}>Back to Courses</Button>
      <Title level={3} style={{ color: '#fff', marginBottom: 24 }}>{isEdit ? 'Edit Course' : 'Create New Course'}</Title>

      <Row gutter={24}>
        <Col xs={24} lg={16}>
          <Card bordered={false}>
            <Form form={form} layout="vertical" onFinish={onFinish}>
              <Form.Item name="title" label={<Text style={{ color: '#8899aa' }}>Course Title</Text>} rules={[{ required: true }]}>
                <Input placeholder="e.g. Advanced Crypto Trading" style={inputStyle} />
              </Form.Item>
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item name="category" label={<Text style={{ color: '#8899aa' }}>Category</Text>} rules={[{ required: true }]}>
                    <Select style={{ width: '100%' }}>
                      {['Forex', 'Crypto', 'Stocks', 'Options', 'Futures', 'Technical Analysis', 'Fundamental Analysis', 'Risk Management', 'Advanced Strategies', 'Beginner'].map(c => <Select.Option key={c} value={c}>{c}</Select.Option>)}
                    </Select>
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item name="level" label={<Text style={{ color: '#8899aa' }}>Level</Text>}>
                    <Select><Select.Option value="Beginner">Beginner</Select.Option><Select.Option value="Intermediate">Intermediate</Select.Option><Select.Option value="Advanced">Advanced</Select.Option></Select>
                  </Form.Item>
                </Col>
              </Row>
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item name="price" label={<Text style={{ color: '#8899aa' }}>Price (USD)</Text>} rules={[{ required: true }]}>
                    <InputNumber prefix="$" style={{ ...inputStyle, width: '100%' }} min={0} />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item name="discountPrice" label={<Text style={{ color: '#8899aa' }}>Discount Price (USD)</Text>}>
                    <InputNumber prefix="$" style={{ ...inputStyle, width: '100%' }} min={0} />
                  </Form.Item>
                </Col>
              </Row>
              <Form.Item name="shortDescription" label={<Text style={{ color: '#8899aa' }}>Short Description</Text>}>
                <Input placeholder="Brief course description (max 300 chars)" style={inputStyle} maxLength={300} />
              </Form.Item>
              <Form.Item name="description" label={<Text style={{ color: '#8899aa' }}>Full Description</Text>} rules={[{ required: true }]}>
                <TextArea rows={5} placeholder="Detailed course description..." style={inputStyle} />
              </Form.Item>
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item name="duration" label={<Text style={{ color: '#8899aa' }}>Duration</Text>}>
                    <Input placeholder="e.g. 12 hours" style={inputStyle} />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item name="language" label={<Text style={{ color: '#8899aa' }}>Language</Text>}>
                    <Input placeholder="English" style={inputStyle} />
                  </Form.Item>
                </Col>
              </Row>
              <Form.Item name="whatYouLearn" label={<Text style={{ color: '#8899aa' }}>What You'll Learn (one per line)</Text>}>
                <TextArea rows={4} placeholder="Enter each learning outcome on a new line" style={inputStyle} />
              </Form.Item>
              <Form.Item name="requirements" label={<Text style={{ color: '#8899aa' }}>Requirements (one per line)</Text>}>
                <TextArea rows={3} placeholder="Enter each requirement on a new line" style={inputStyle} />
              </Form.Item>
              <Row gutter={16}>
                <Col span={8}><Form.Item name="isPublished" label={<Text style={{ color: '#8899aa' }}>Published</Text>} valuePropName="checked"><Switch /></Form.Item></Col>
                <Col span={8}><Form.Item name="isFeatured" label={<Text style={{ color: '#8899aa' }}>Featured</Text>} valuePropName="checked"><Switch /></Form.Item></Col>
                <Col span={8}><Form.Item name="isMLMEligible" label={<Text style={{ color: '#8899aa' }}>MLM Eligible</Text>} valuePropName="checked" initialValue={true}><Switch defaultChecked /></Form.Item></Col>
              </Row>
              <Button type="primary" htmlType="submit" loading={loading} block style={{ background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)', border: 'none', height: 44 }}>
                {isEdit ? 'Update Course' : 'Create Course'}
              </Button>
            </Form>
          </Card>
        </Col>

        <Col xs={24} lg={8}>
          <Card bordered={false} title={<Text style={{ color: '#fff' }}>Thumbnail</Text>} style={{ marginBottom: 16 }}>
            <Upload beforeUpload={f => { setThumbnail(f); return false; }} maxCount={1} accept="image/*" listType="picture">
              <Button icon={<UploadOutlined />} style={{ background: '#1e2d40', border: 'none', color: '#fff' }}>Upload Thumbnail</Button>
            </Upload>
          </Card>

          {isEdit && (
            <Card bordered={false} title={<Text style={{ color: '#fff' }}>Course Materials</Text>}
              extra={<Button size="small" type="primary" icon={<PlusOutlined />} onClick={() => setMaterialModal(true)} style={{ background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)', border: 'none' }}>Add</Button>}
            >
              <List dataSource={materials} renderItem={m => (
                <List.Item style={{ borderBottom: '1px solid #1a2535' }}>
                  <div>
                    <Text style={{ color: '#fff', display: 'block' }}>{m.title}</Text>
                    <Tag color="blue" style={{ marginTop: 4 }}>{m.type}</Tag>
                    {m.isPreview && <Tag color="green">Preview</Tag>}
                  </div>
                </List.Item>
              )} locale={{ emptyText: <Text style={{ color: '#4a5568' }}>No materials yet</Text> }} />
            </Card>
          )}
        </Col>
      </Row>

      <Modal title="Upload Course Material" open={materialModal} onCancel={() => setMaterialModal(false)} footer={null}
        styles={{ content: { background: '#111827' }, header: { background: '#111827' } }}>
        <Form form={materialForm} layout="vertical" onFinish={uploadMaterial}>
          <Form.Item name="title" label={<Text style={{ color: '#8899aa' }}>Title</Text>} rules={[{ required: true }]}>
            <Input style={inputStyle} />
          </Form.Item>
          <Form.Item name="type" label={<Text style={{ color: '#8899aa' }}>Type</Text>} rules={[{ required: true }]} initialValue="pdf">
            <Select><Select.Option value="pdf">PDF</Select.Option><Select.Option value="video">Video</Select.Option><Select.Option value="article">Article</Select.Option></Select>
          </Form.Item>
          <Form.Item name="isPreview" label={<Text style={{ color: '#8899aa' }}>Free Preview</Text>} valuePropName="checked">
            <Switch />
          </Form.Item>
          <Form.Item name="file" label={<Text style={{ color: '#8899aa' }}>File</Text>}>
            <Upload beforeUpload={() => false} maxCount={1} accept=".pdf,.mp4,.webm">
              <Button icon={<UploadOutlined />} style={{ background: '#1e2d40', border: 'none', color: '#fff' }}>Choose File</Button>
            </Upload>
          </Form.Item>
          <Button type="primary" htmlType="submit" loading={uploadingMaterial} block style={{ background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)', border: 'none' }}>Upload Material</Button>
        </Form>
      </Modal>
    </div>
  );
}
