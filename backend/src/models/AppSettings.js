const { createModel } = require('../lib/PrismaModel');

const AppSettings = createModel('appSettings', []);
module.exports = AppSettings;
