const { createModel } = require('../lib/PrismaModel');
const Quiz = createModel('quiz', ['questions']);
module.exports = Quiz;
