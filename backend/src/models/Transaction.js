const { createModel } = require('../lib/PrismaModel');

const populateMap = {
  userId: { model: 'user', foreignKey: 'userId' },
  courseId: { model: 'course', foreignKey: 'courseId' },
};

const Transaction = createModel('transaction', ['metadata'], populateMap);
module.exports = Transaction;
