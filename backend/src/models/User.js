const bcrypt = require('bcryptjs');
const { createModel } = require('../lib/PrismaModel');

async function preSave(data) {
  if (!data.referralCode) {
    const prefix = (data.name || 'USER').toUpperCase().replace(/\s+/g, '').substring(0, 4);
    data.referralCode = prefix + Math.random().toString(36).substring(2, 6).toUpperCase();
  }
  if (data.password && !data.password.startsWith('$2')) {
    const salt = await bcrypt.genSalt(12);
    data.password = await bcrypt.hash(data.password, salt);
  }
}

const populateMap = {
  sponsorId: { model: 'user', foreignKey: 'sponsorId' },
  purchasedCourses: { model: 'course', type: 'array', foreignKey: 'purchasedCourses', jsonFields: ['materials', 'tags', 'requirements', 'whatYouLearn'] },
};

const User = createModel('user', ['purchasedCourses', 'kycDocuments'], populateMap, preSave);
module.exports = User;
