const Quiz = require('../models/Quiz');
const QuizAttempt = require('../models/QuizAttempt');
const User = require('../models/User');

// @desc   Get quiz for a course (user must be enrolled)
// @route  GET /api/quizzes/course/:courseId
const getQuizzesByCourse = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    const isPurchased = user.purchasedCourses.some(id => id.toString() === req.params.courseId);
    if (!isPurchased) return res.status(403).json({ success: false, message: 'Enroll in course first' });

    const quizzes = await Quiz.find({ courseId: req.params.courseId, isPublished: true })
      .select('-questions.correctAnswer -questions.explanation');

    res.json({ success: true, quizzes });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Submit quiz
// @route  POST /api/quizzes/:quizId/submit
const submitQuiz = async (req, res) => {
  try {
    const { answers, timeTaken } = req.body;
    const quiz = await Quiz.findById(req.params.quizId);
    if (!quiz) return res.status(404).json({ success: false, message: 'Quiz not found' });

    // Check max attempts
    if (quiz.attempts > 0) {
      const attemptCount = await QuizAttempt.countDocuments({ userId: req.user._id, quizId: quiz._id });
      if (attemptCount >= quiz.attempts) {
        return res.status(400).json({ success: false, message: `Maximum ${quiz.attempts} attempts reached` });
      }
    }

    // Grade quiz
    let score = 0;
    const results = quiz.questions.map((q, i) => {
      const userAnswer = answers[i]?.answer;
      const correct = JSON.stringify(userAnswer) === JSON.stringify(q.correctAnswer);
      if (correct) score += q.marks;
      return { correct, correctAnswer: q.correctAnswer, explanation: q.explanation };
    });

    const percentage = quiz.totalMarks > 0 ? (score / quiz.totalMarks) * 100 : 0;
    const passed = percentage >= quiz.passingScore;

    const attempt = await QuizAttempt.create({
      userId: req.user._id,
      quizId: quiz._id,
      courseId: quiz.courseId,
      answers,
      score,
      totalMarks: quiz.totalMarks,
      percentage: Math.round(percentage),
      passed,
      timeTaken,
    });

    res.json({ success: true, attempt, results: quiz.showAnswers ? results : undefined, passed, score, percentage: Math.round(percentage) });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get my quiz attempts
// @route  GET /api/quizzes/:quizId/attempts
const getMyAttempts = async (req, res) => {
  try {
    const attempts = await QuizAttempt.find({ userId: req.user._id, quizId: req.params.quizId }).sort('-createdAt');
    res.json({ success: true, attempts });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ADMIN
const createQuiz = async (req, res) => {
  try {
    const quiz = await Quiz.create(req.body);
    res.status(201).json({ success: true, quiz });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const updateQuiz = async (req, res) => {
  try {
    const quiz = await Quiz.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!quiz) return res.status(404).json({ success: false, message: 'Quiz not found' });
    res.json({ success: true, quiz });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const deleteQuiz = async (req, res) => {
  try {
    await Quiz.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Quiz deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = { getQuizzesByCourse, submitQuiz, getMyAttempts, createQuiz, updateQuiz, deleteQuiz };
