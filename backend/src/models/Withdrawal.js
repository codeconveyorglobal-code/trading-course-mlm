const { createModel } = require('../lib/PrismaModel');

const populateMap = {
  userId: { model: 'user', foreignKey: 'userId' },
  processedById: { model: 'user', foreignKey: 'processedById' },
};

const Withdrawal = createModel('withdrawal', [], populateMap);
module.exports = Withdrawal;
