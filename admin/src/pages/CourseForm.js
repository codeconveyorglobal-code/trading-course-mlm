import React, { useEffect, useState } from 'react';
import {
  Form, Input, Select, InputNumber, Button, Card, Typography, Switch,
  Upload, message, Row, Col, List, Modal, Tabs, Tag, Space, Divider,
} from 'antd';
import {
  UploadOutlined, PlusOutlined, ArrowLeftOutlined,
  LinkOutlined, FilePdfOutlined, PlayCircleOutlined, FileTextOutlined,
  SaveOutlined,
} from '@ant-design/icons';
import { useNavigate, useParams } from 'react-router-dom';
import api from '../services/api';

const { Title, Text } = Typography;
const { TextArea } = Input;
const BASE_URL = 'https://hopeful-energy-production.up.railway.app';
const CATEGORIES = ['Forex', 'Crypto', 'Stocks', 'Options', 'Futures', 'Technical Analysis', 'Fundamental Analysis', 'Risk Management', 'Advanced Strategies', 'Beginner'];

export default function CourseForm() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [fetchLoading, setFetchLoading] = useState(!!id);
  const [thumbnail, setThumbnail] = useState(null);
  const [thumbnailPreview, setThumbnailPreview] = useState(null);
  const [materials, setMaterials] = useState([]);
  const [materialModal, setMaterialModal] = useState(false);
  const [materialForm] = Form.useForm();
  const [uploadingMaterial, setUploadingMaterial] = useState(false);
  const [useExternalUrl, setUseExternalUrl] = useState(false);
  const isEdit = !!id;

  useEffect(() => {
    if (isEdit) {
      api.get(`/courses/${id}`)
        .then(res => {
          const c = res.data.course;
          form.setFieldsValue({
            ...c,
            whatYouLearn: Array.isArray(c.whatYouLearn) ? c.whatYouLearn.join('\n') : (c.whatYouLearn || ''),
            requirements: Array.isArray(c.requirements) ? c.requirements.join('\n') : (c.requirements || ''),
          });
          if (c.thumbnail) setThumbnailPreview(`${BASE_URL}${c.thumbnail}`);
          setMaterials(c.materials || []);
        })
        .catch(() => message.error('Failed to load course'))
        .finally(() => setFetchLoading(false));
    }
  }, [id]);

  const onFinish = async (values) => {
    setLoading(true);
    try {
      const formData = new FormData();
      Object.entries(values).forEach(([k, v]) => {
        if (v === undefined || v === null) return;
        if (k === 'whatYouLearn' || k === 'requirements') {
          const arr = String(v).split('\n').filter(s => s.trim());
          formData.append(k, JSON.stringify(arr));
        } else if (typeof v === 'boolean') {
          formData.append(k, v ? 'true' : 'false');
        } else {
          formData.append(k, v);
        }
      });
      if (thumbnail) formData.append('thumbnail', thumbnail);
      if (isEdit) {
        await api.put(`/courses/${id}`, formData, { headers: { 'Content-Type': 'multipart/form-data' } });
        message.success('Course updated successfully!');
      } else {
        await api.post('/courses', formData, { headers: { 'Content-Type': 'multipart/form-data' } });
        message.success('Course created successfully!');
        navigate('/courses');
      }
    } catch (err) {
      message.error(err.response?.data?.message || 'Failed to save course');
    } finally {
      setLoading(false);
    }
  };

  const uploadMaterial = async (values) => {
    setUploadingMaterial(true);
    try {
      const formData = new FormData();
      formData.append('title', values.title);
      formData.append('type', values.type || 'pdf');
      formData.append('isPreview', values.isPreview ? 'true' : 'false');
      if (useExternalUrl && values.externalUrl) {
        formData.append('externalUrl', values.externalUrl);
      } else if (values.file?.fileList?.[0]?.originFileObj) {
        formData.append('material', values.file.fileList[0].originFileObj);
      }
      const res = await api.post(`/courses/${id}/materials`, formData, { headers: { 'Content-Type': 'multipart/form-data' } });
      setMaterials(res.data.course.materials || []);
      message.success('Material added!');
      setMaterialModal(false);
      materialForm.resetFields();
      setUseExternalUrl(false);
    } catch (err) {
      message.error(err.response?.data?.message || 'Upload failed');
    } finally {
      setUploadingMaterial(false);
    }
  };

  const s = {
    input: { background: '#0d1526', border: '1px solid #1e2d40', color: '#fff', borderRadius: 8 },
    label: { color: '#8899aa', fontWeight: 500 },
  };

  const matIcon = { pdf: <FilePdfOutlined style={{ color: '#e53e3e' }} />, video: <PlayCircleOutlined style={{ color: '#00d2ff' }} />, article: <FileTextOutlined style={{ color: '#ffa94d' }} />, link: <LinkOutlined style={{ color: '#7b2ff7' }} /> };

  const tabItems = [
    {
      key: 'basic', label: 'Basic Info',
      children: (
        <>
          <Form.Item name="title" label={<Text style={s.label}>Course Title *</Text>} rules={[{ required: true, message: 'Title required' }]}>
            <Input placeholder="e.g. Advanced Crypto Trading Masterclass" style={s.input} size="large" />
          </Form.Item>
          <Row gutter={16}>
            <Col xs={24} md={12}>
              <Form.Item name="category" label={<Text style={s.label}>Category *</Text>} rules={[{ required: true }]}>
                <Select placeholder="Select category">{CATEGORIES.map(c => <Select.Option key={c} value={c}>{c}</Select.Option>)}</Select>
              </Form.Item>
            </Col>
            <Col xs={24} md={12}>
              <Form.Item name="level" label={<Text style={s.label}>Level</Text>} initialValue="Beginner">
                <Select><Select.Option value="Beginner">Beginner</Select.Option><Select.Option value="Intermediate">Intermediate</Select.Option><Select.Option value="Advanced">Advanced</Select.Option></Select>
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="shortDescription" label={<Text style={s.label}>Short Description</Text>}>
            <Input placeholder="Brief overview shown in course listings" style={s.input} maxLength={300} showCount />
          </Form.Item>
          <Form.Item name="description" label={<Text style={s.label}>Full Description *</Text>} rules={[{ required: true }]}>
            <TextArea rows={6} placeholder="Detailed course description..." style={s.input} />
          </Form.Item>
          <Row gutter={16}>
            <Col xs={24} md={12}>
              <Form.Item name="duration" label={<Text style={s.label}>Duration</Text>}>
                <Input placeholder="e.g. 12 hours" style={s.input} />
              </Form.Item>
            </Col>
            <Col xs={24} md={12}>
              <Form.Item name="language" label={<Text style={s.label}>Language</Text>} initialValue="English">
                <Input placeholder="English" style={s.input} />
              </Form.Item>
            </Col>
          </Row>
        </>
      ),
    },
    {
      key: 'curriculum', label: 'Curriculum & Resources',
      children: (
        <>
          <Form.Item name="whatYouLearn" label={<Text style={s.label}>What Students Will Learn (one per line)</Text>}>
            <TextArea rows={6} placeholder={'Master technical analysis\nUnderstand risk management\nBuild a trading strategy'} style={s.input} />
          </Form.Item>
          <Form.Item name="requirements" label={<Text style={s.label}>Prerequisites (one per line)</Text>}>
            <TextArea rows={4} placeholder={'Basic understanding of finance\nInternet connection and a computer'} style={s.input} />
          </Form.Item>
          <Divider style={{ borderColor: '#1e2d40' }} />
          <Form.Item name="previewVideo" label={<Text style={s.label}>Preview Video URL</Text>}>
            <Input prefix={<PlayCircleOutlined style={{ color: '#8899aa' }} />} placeholder="https://youtube.com/watch?v=..." style={s.input} />
          </Form.Item>
          <Form.Item name="pdfResourceUrl" label={<Text style={s.label}>Course PDF / Syllabus URL</Text>}>
            <Input prefix={<FilePdfOutlined style={{ color: '#e53e3e' }} />} placeholder="https://drive.google.com/file/d/..." style={s.input} />
          </Form.Item>
          <div style={{ padding: '10px 14px', background: 'rgba(0,210,255,0.04)', borderRadius: 8, border: '1px dashed #1e3d50' }}>
            <Text style={{ color: '#4a5568', fontSize: 12 }}>💡 Paste any public PDF link (Google Drive, Dropbox, Notion, etc.) that students can access.</Text>
          </div>
        </>
      ),
    },
    {
      key: 'pricing', label: 'Pricing',
      children: (
        <>
          <Row gutter={16}>
            <Col xs={24} md={12}>
              <Form.Item name="price" label={<Text style={s.label}>Price (USD) *</Text>} rules={[{ required: true, message: 'Price required' }]}>
                <InputNumber prefix="$" style={{ ...s.input, width: '100%' }} min={0} precision={2} placeholder="0.00" />
              </Form.Item>
            </Col>
            <Col xs={24} md={12}>
              <Form.Item name="discountPrice" label={<Text style={s.label}>Sale Price (USD)</Text>}>
                <InputNumber prefix="$" style={{ ...s.input, width: '100%' }} min={0} precision={2} placeholder="Optional discount price" />
              </Form.Item>
            </Col>
          </Row>
          <div style={{ padding: '12px 16px', background: 'rgba(0,210,255,0.04)', borderRadius: 8, border: '1px dashed #1e3d50' }}>
            <Text style={{ color: '#4a5568', fontSize: 13 }}>💡 Setting a sale price will display the original price as struck-through on course cards.</Text>
          </div>
        </>
      ),
    },
    {
      key: 'settings', label: 'Settings',
      children: (
        <Row gutter={[16, 16]}>
          {[
            { name: 'isPublished', on: 'Published', off: 'Draft', desc: 'Visible to all students' },
            { name: 'isFeatured', on: 'Featured', off: 'Normal', desc: 'Shown in featured section' },
            { name: 'isMLMEligible', on: 'MLM Enabled', off: 'MLM Off', desc: 'Earns referral commissions', initial: true },
          ].map(item => (
            <Col xs={24} md={8} key={item.name}>
              <div style={{ padding: 20, background: '#0d1526', borderRadius: 10, border: '1px solid #1e2d40', textAlign: 'center' }}>
                <Form.Item name={item.name} valuePropName="checked" initialValue={item.initial} style={{ marginBottom: 8 }}>
                  <Switch checkedChildren={item.on} unCheckedChildren={item.off} />
                </Form.Item>
                <Text style={{ color: '#4a5568', fontSize: 12 }}>{item.desc}</Text>
              </div>
            </Col>
          ))}
        </Row>
      ),
    },
  ];

  if (fetchLoading) return (
    <div style={{ textAlign: 'center', paddingTop: 80 }}>
      <div style={{ width: 40, height: 40, border: '3px solid #1e2d40', borderTopColor: '#00d2ff', borderRadius: '50%', animation: 'spin 0.8s linear infinite', margin: '0 auto 12px' }} />
      <Text style={{ color: '#8899aa' }}>Loading course...</Text>
    </div>
  );

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 24 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <Button icon={<ArrowLeftOutlined />} type="text" style={{ color: '#8899aa' }} onClick={() => navigate('/courses')} />
          <div>
            <Title level={3} style={{ color: '#fff', margin: 0 }}>{isEdit ? 'Edit Course' : 'Create New Course'}</Title>
            <Text style={{ color: '#4a5568', fontSize: 13 }}>{isEdit ? 'Update course details below' : 'Fill in the details to publish a new course'}</Text>
          </div>
        </div>
        <Button
          type="primary" icon={<SaveOutlined />} loading={loading}
          onClick={() => form.submit()}
          style={{ background: 'linear-gradient(135deg,#00d2ff,#7b2ff7)', border: 'none', height: 40, paddingInline: 24 }}
        >
          {isEdit ? 'Save Changes' : 'Create Course'}
        </Button>
      </div>

      <Form form={form} layout="vertical" onFinish={onFinish}>
        <Row gutter={24}>
          <Col xs={24} lg={16}>
            <Card bordered={false}>
              <Tabs items={tabItems} type="card" />
            </Card>
          </Col>
          <Col xs={24} lg={8}>
            {/* Thumbnail */}
            <Card bordered={false} style={{ marginBottom: 16 }}
              title={<span style={{ display: 'flex', alignItems: 'center', gap: 8 }}><span style={{ width: 3, height: 14, background: 'linear-gradient(#00d2ff,#7b2ff7)', borderRadius: 2, display: 'inline-block' }} /><Text style={{ color: '#fff', fontSize: 14 }}>Thumbnail</Text></span>}
            >
              {thumbnailPreview && <img src={thumbnailPreview} alt="" style={{ width: '100%', borderRadius: 8, marginBottom: 10, objectFit: 'cover', maxHeight: 150 }} />}
              <Upload beforeUpload={f => { setThumbnail(f); setThumbnailPreview(URL.createObjectURL(f)); return false; }} maxCount={1} accept="image/*" showUploadList={false}>
                <Button icon={<UploadOutlined />} style={{ background: '#1e2d40', border: 'none', color: '#fff', width: '100%' }}>
                  {thumbnailPreview ? 'Change Image' : 'Upload Image'}
                </Button>
              </Upload>
              <Text style={{ color: '#4a5568', fontSize: 11, marginTop: 6, display: 'block' }}>Recommended: 1280×720px · JPG/PNG</Text>
            </Card>

            {/* Materials (edit only) */}
            {isEdit ? (
              <Card bordered={false}
                title={<span style={{ display: 'flex', alignItems: 'center', gap: 8 }}><span style={{ width: 3, height: 14, background: 'linear-gradient(#00d2ff,#7b2ff7)', borderRadius: 2, display: 'inline-block' }} /><Text style={{ color: '#fff', fontSize: 14 }}>Materials</Text><Tag style={{ marginLeft: 6, background: '#1e2d40', border: 'none', color: '#00d2ff', fontSize: 11 }}>{materials.length}</Tag></span>}
                extra={<Button size="small" icon={<PlusOutlined />} onClick={() => setMaterialModal(true)} style={{ background: 'linear-gradient(135deg,#00d2ff,#7b2ff7)', border: 'none', color: '#fff' }}>Add</Button>}
              >
                {materials.length === 0 ? (
                  <div style={{ textAlign: 'center', padding: '20px 0' }}>
                    <FileTextOutlined style={{ fontSize: 28, color: '#1e2d40' }} />
                    <Text style={{ color: '#4a5568', display: 'block', marginTop: 8, fontSize: 12 }}>No materials yet</Text>
                  </div>
                ) : (
                  <List dataSource={materials} renderItem={m => (
                    <List.Item style={{ borderBottom: '1px solid #0d1526', padding: '8px 0' }}>
                      <Space><span>{matIcon[m.type] || <FileTextOutlined />}</span><div><Text style={{ color: '#d1d5db', fontSize: 13 }}>{m.title}</Text><div style={{ marginTop: 2 }}><Tag color="blue" style={{ fontSize: 10 }}>{m.type}</Tag>{m.isPreview && <Tag color="green" style={{ fontSize: 10 }}>Free</Tag>}</div></div></Space>
                    </List.Item>
                  )} />
                )}
              </Card>
            ) : (
              <div style={{ padding: 14, background: 'rgba(123,47,247,0.05)', borderRadius: 8, border: '1px dashed rgba(123,47,247,0.3)' }}>
                <Text style={{ color: '#8899aa', fontSize: 12 }}><span style={{ color: '#7b2ff7', fontWeight: 600 }}>Tip:</span> Create the course first, then add materials from the edit page.</Text>
              </div>
            )}
          </Col>
        </Row>
      </Form>

      {/* Material Modal */}
      <Modal
        title={<Text style={{ color: '#fff' }}>Add Course Material</Text>}
        open={materialModal}
        onCancel={() => { setMaterialModal(false); materialForm.resetFields(); setUseExternalUrl(false); }}
        footer={null}
        styles={{ content: { background: '#111827', border: '1px solid #1e2d40' }, header: { background: '#111827' } }}
      >
        <Form form={materialForm} layout="vertical" onFinish={uploadMaterial}>
          <Form.Item name="title" label={<Text style={s.label}>Title *</Text>} rules={[{ required: true }]}>
            <Input style={s.input} placeholder="e.g. Module 1: Introduction PDF" />
          </Form.Item>
          <Row gutter={12}>
            <Col span={14}>
              <Form.Item name="type" label={<Text style={s.label}>Type</Text>} initialValue="pdf">
                <Select><Select.Option value="pdf">PDF Document</Select.Option><Select.Option value="video">Video</Select.Option><Select.Option value="article">Article</Select.Option><Select.Option value="link">External Link</Select.Option></Select>
              </Form.Item>
            </Col>
            <Col span={10}>
              <Form.Item name="isPreview" label={<Text style={s.label}>Free Preview</Text>} valuePropName="checked">
                <Switch />
              </Form.Item>
            </Col>
          </Row>
          <div style={{ display: 'flex', gap: 8, marginBottom: 14 }}>
            <Button size="small" icon={<UploadOutlined />} onClick={() => setUseExternalUrl(false)}
              style={!useExternalUrl ? { background: 'linear-gradient(135deg,#00d2ff,#7b2ff7)', border: 'none', color: '#fff' } : { background: '#1e2d40', border: 'none', color: '#8899aa' }}>File Upload</Button>
            <Button size="small" icon={<LinkOutlined />} onClick={() => setUseExternalUrl(true)}
              style={useExternalUrl ? { background: 'linear-gradient(135deg,#00d2ff,#7b2ff7)', border: 'none', color: '#fff' } : { background: '#1e2d40', border: 'none', color: '#8899aa' }}>External URL</Button>
          </div>
          {useExternalUrl
            ? <Form.Item name="externalUrl" label={<Text style={s.label}>URL *</Text>} rules={[{ required: true, type: 'url', message: 'Enter a valid URL' }]}><Input prefix={<LinkOutlined style={{ color: '#8899aa' }} />} placeholder="https://..." style={s.input} /></Form.Item>
            : <Form.Item name="file" label={<Text style={s.label}>File (PDF / Video)</Text>}><Upload beforeUpload={() => false} maxCount={1} accept=".pdf,.mp4,.webm,.doc,.docx"><Button icon={<UploadOutlined />} style={{ background: '#1e2d40', border: 'none', color: '#fff' }}>Choose File</Button></Upload></Form.Item>
          }
          <Button type="primary" htmlType="submit" loading={uploadingMaterial} block style={{ background: 'linear-gradient(135deg,#00d2ff,#7b2ff7)', border: 'none', height: 40, marginTop: 8 }}>Add Material</Button>
        </Form>
      </Modal>
    </div>
  );
}
