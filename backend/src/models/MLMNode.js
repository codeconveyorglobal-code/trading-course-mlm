const { createModel } = require('../lib/PrismaModel');
const MLMNode = createModel('mLMNode', []);
module.exports = MLMNode;
