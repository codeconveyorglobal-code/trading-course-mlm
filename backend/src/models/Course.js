const { createModel } = require('../lib/PrismaModel');

const populateMap = {
  instructor: { model: 'user', foreignKey: 'instructorId' },
  quizzes: { model: 'quiz', type: 'array', foreignKey: 'quizzes' },
};

const Course = createModel('course', ['materials', 'tags', 'requirements', 'whatYouLearn', 'quizzes'], populateMap);
module.exports = Course;
