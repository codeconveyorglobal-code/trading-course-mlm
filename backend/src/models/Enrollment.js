const { createModel } = require('../lib/PrismaModel');
const Enrollment = createModel('enrollment', ['completedMaterials']);
module.exports = Enrollment;
