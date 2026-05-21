const { createModel } = require('../lib/PrismaModel');
const MLMSettings = createModel('mLMSettings', ['levelCommissions', 'rankBonuses']);
module.exports = MLMSettings;
