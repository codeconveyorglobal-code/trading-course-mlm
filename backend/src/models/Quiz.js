const mongoose = require('mongoose');

const QuestionSchema = new mongoose.Schema({
  question: { type: String, required: true },
  type: { type: String, enum: ['multiple_choice', 'true_false', 'multiple_select'], default: 'multiple_choice' },
  options: [{ type: String }],
  correctAnswer: { type: mongoose.Schema.Types.Mixed, required: true }, // index or array of indexes
  explanation: { type: String },
  marks: { type: Number, default: 1 },
  imageUrl: { type: String, default: null },
});

const QuizSchema = new mongoose.Schema({
  title: { type: String, required: true },
  courseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', required: true },
  description: { type: String },
  questions: [QuestionSchema],
  passingScore: { type: Number, default: 70 }, // percentage
  timeLimit: { type: Number, default: 30 }, // minutes, 0 = no limit
  totalMarks: { type: Number, default: 0 },
  attempts: { type: Number, default: 3 }, // max attempts, 0 = unlimited
  shuffleQuestions: { type: Boolean, default: false },
  showAnswers: { type: Boolean, default: true },
  isPublished: { type: Boolean, default: false },
  certificateOnPass: { type: Boolean, default: false },
}, { timestamps: true });

QuizSchema.pre('save', function (next) {
  this.totalMarks = this.questions.reduce((sum, q) => sum + q.marks, 0);
  next();
});

module.exports = mongoose.model('Quiz', QuizSchema);
