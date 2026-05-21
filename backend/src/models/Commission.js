const { createModel } = require('../lib/PrismaModel');

const populateMap = {
  userId: { model: 'user', foreignKey: 'userId' },
  fromUserId: { model: 'user', foreignKey: 'fromUserId' },
  courseId: { model: 'course', foreignKey: 'courseId' },
};

const Commission = createModel('commission', [], populateMap);
module.exports = Commission;
