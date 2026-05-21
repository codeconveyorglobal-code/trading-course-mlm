const { createModel } = require('../lib/PrismaModel');
const QuizAttempt = createModel('quizAttempt', ['answers']);
module.exports = QuizAttempt;
