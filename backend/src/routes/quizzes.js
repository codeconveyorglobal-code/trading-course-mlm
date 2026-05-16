const express = require('express');
const router = express.Router();
const { getQuizzesByCourse, submitQuiz, getMyAttempts, createQuiz, updateQuiz, deleteQuiz } = require('../controllers/quizController');
const { protect, adminOnly } = require('../middleware/auth');

// User routes
router.get('/course/:courseId', protect, getQuizzesByCourse);
router.post('/:quizId/submit', protect, submitQuiz);
router.get('/:quizId/attempts', protect, getMyAttempts);

// Admin routes
router.post('/', protect, adminOnly, createQuiz);
router.put('/:id', protect, adminOnly, updateQuiz);
router.delete('/:id', protect, adminOnly, deleteQuiz);

module.exports = router;
