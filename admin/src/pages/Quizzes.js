import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Card, Typography, Button, Modal, Form, Input, InputNumber, Switch, Select, message, List, Tag, Collapse, Popconfirm, Space } from 'antd';
import { PlusOutlined, DeleteOutlined, ArrowLeftOutlined } from '@ant-design/icons';
import api from '../services/api';

const { Title, Text } = Typography;

export default function Quizzes() {
  const { id: courseId } = useParams();
  const navigate = useNavigate();
  const [quizzes, setQuizzes] = useState([]);
  const [quizModal, setQuizModal] = useState(false);
  const [quizForm] = Form.useForm();
  const [questions, setQuestions] = useState([]);
  const [saving, setSaving] = useState(false);

  const fetchQuizzes = async () => {
    try {
      const res = await api.get(`/quizzes/course/${courseId}`);
      // Admin can see all quizzes directly
    } catch {}
    // Fallback: get from course
    try {
      const res = await api.get(`/courses/${courseId}`);
      // quizzes in the course
    } catch {}
  };

  const addQuestion = () => {
    setQuestions(q => [...q, { question: '', type: 'multiple_choice', options: ['', '', '', ''], correctAnswer: 0, explanation: '', marks: 1 }]);
  };

  const updateQuestion = (i, field, val) => {
    setQuestions(q => q.map((item, idx) => idx === i ? { ...item, [field]: val } : item));
  };

  const updateOption = (qi, oi, val) => {
    setQuestions(q => q.map((item, idx) => idx === qi ? { ...item, options: item.options.map((o, j) => j === oi ? val : o) } : item));
  };

  const removeQuestion = (i) => {
    setQuestions(q => q.filter((_, idx) => idx !== i));
  };

  const saveQuiz = async (values) => {
    setSaving(true);
    try {
      await api.post('/quizzes', { ...values, courseId, questions });
      message.success('Quiz created!');
      setQuizModal(false);
      quizForm.resetFields();
      setQuestions([]);
    } catch (err) {
      message.error('Failed to save quiz');
    } finally {
      setSaving(false);
    }
  };

  const inputStyle = { background: '#0d1526', border: '1px solid #1e2d40', color: '#fff' };

  return (
    <div>
      <Button icon={<ArrowLeftOutlined />} type="text" style={{ color: '#8899aa', marginBottom: 20 }} onClick={() => navigate('/courses')}>Back to Courses</Button>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 24 }}>
        <Title level={3} style={{ color: '#fff', margin: 0 }}>Course Quizzes</Title>
        <Button type="primary" icon={<PlusOutlined />} onClick={() => setQuizModal(true)}
          style={{ background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)', border: 'none' }}>Create Quiz</Button>
      </div>

      <Modal
        title={<Text style={{ color: '#fff' }}>Create Quiz</Text>}
        open={quizModal}
        onCancel={() => { setQuizModal(false); setQuestions([]); }}
        footer={null}
        width={800}
        styles={{ content: { background: '#111827', maxHeight: '85vh', overflowY: 'auto' }, header: { background: '#111827' } }}
      >
        <Form form={quizForm} layout="vertical" onFinish={saveQuiz}>
          <Form.Item name="title" label={<Text style={{ color: '#8899aa' }}>Quiz Title</Text>} rules={[{ required: true }]}>
            <Input style={inputStyle} />
          </Form.Item>
          <Form.Item name="description" label={<Text style={{ color: '#8899aa' }}>Description</Text>}>
            <Input.TextArea rows={2} style={inputStyle} />
          </Form.Item>
          <Space style={{ width: '100%' }} size={16}>
            <Form.Item name="passingScore" label={<Text style={{ color: '#8899aa' }}>Passing Score (%)</Text>} initialValue={70}>
              <InputNumber min={0} max={100} style={{ ...inputStyle, width: 120 }} />
            </Form.Item>
            <Form.Item name="timeLimit" label={<Text style={{ color: '#8899aa' }}>Time Limit (min, 0=none)</Text>} initialValue={30}>
              <InputNumber min={0} style={{ ...inputStyle, width: 120 }} />
            </Form.Item>
            <Form.Item name="attempts" label={<Text style={{ color: '#8899aa' }}>Max Attempts</Text>} initialValue={3}>
              <InputNumber min={0} style={{ ...inputStyle, width: 100 }} />
            </Form.Item>
          </Space>
          <Form.Item name="isPublished" label={<Text style={{ color: '#8899aa' }}>Published</Text>} valuePropName="checked">
            <Switch />
          </Form.Item>

          <Title level={5} style={{ color: '#00d2ff', marginTop: 16 }}>Questions ({questions.length})</Title>
          {questions.map((q, i) => (
            <Card key={i} bordered={false} style={{ marginBottom: 12, background: '#0d1526', border: '1px solid #1e2d40' }}
              extra={<Button type="text" icon={<DeleteOutlined />} danger onClick={() => removeQuestion(i)} />}
              title={<Text style={{ color: '#fff' }}>Q{i + 1}</Text>}
            >
              <Form.Item label={<Text style={{ color: '#8899aa' }}>Question</Text>}>
                <Input.TextArea value={q.question} onChange={e => updateQuestion(i, 'question', e.target.value)} rows={2} style={inputStyle} />
              </Form.Item>
              <Form.Item label={<Text style={{ color: '#8899aa' }}>Type</Text>}>
                <Select value={q.type} onChange={v => updateQuestion(i, 'type', v)} style={{ width: 200 }}>
                  <Select.Option value="multiple_choice">Multiple Choice</Select.Option>
                  <Select.Option value="true_false">True/False</Select.Option>
                </Select>
              </Form.Item>
              {q.type === 'multiple_choice' && (
                <div>
                  {q.options.map((opt, j) => (
                    <div key={j} style={{ display: 'flex', gap: 8, marginBottom: 8, alignItems: 'center' }}>
                      <input type="radio" checked={q.correctAnswer === j} onChange={() => updateQuestion(i, 'correctAnswer', j)} />
                      <Input value={opt} onChange={e => updateOption(i, j, e.target.value)} placeholder={`Option ${j + 1}`} style={{ ...inputStyle, flex: 1 }} />
                    </div>
                  ))}
                </div>
              )}
              {q.type === 'true_false' && (
                <Select value={q.correctAnswer} onChange={v => updateQuestion(i, 'correctAnswer', v)} style={{ width: 120 }}>
                  <Select.Option value={0}>True</Select.Option>
                  <Select.Option value={1}>False</Select.Option>
                </Select>
              )}
              <Form.Item label={<Text style={{ color: '#8899aa' }}>Explanation</Text>} style={{ marginTop: 8 }}>
                <Input value={q.explanation} onChange={e => updateQuestion(i, 'explanation', e.target.value)} style={inputStyle} />
              </Form.Item>
            </Card>
          ))}

          <Button block style={{ background: '#1e2d40', border: '1px dashed #1e2d40', color: '#8899aa', marginBottom: 16 }}
            onClick={addQuestion} icon={<PlusOutlined />}>Add Question</Button>

          <Button type="primary" htmlType="submit" loading={saving} block
            style={{ background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)', border: 'none' }}>Save Quiz</Button>
        </Form>
      </Modal>

      <Card bordered={false}>
        <Text style={{ color: '#8899aa' }}>Quiz management for this course. Quizzes are accessed via the course view.</Text>
      </Card>
    </div>
  );
}
