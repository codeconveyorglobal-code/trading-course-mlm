require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

async function seedAdmin() {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('Connected to MongoDB');

  const User = require('../models/User');

  const existing = await User.findOne({ role: 'admin' });
  if (existing) {
    console.log(`Admin already exists: ${existing.email}`);
    await mongoose.disconnect();
    return;
  }

  const password = await bcrypt.hash('Admin@123456', 12);
  await User.create({
    name: 'Super Admin',
    email: 'admin@tradingmlm.com',
    password,
    role: 'admin',
    phone: '0000000000',
    referralCode: 'ADMIN001',
    isActive: true,
  });

  console.log('✅ Admin created:');
  console.log('   Email:    admin@tradingmlm.com');
  console.log('   Password: Admin@123456');
  await mongoose.disconnect();
}

seedAdmin().catch(err => { console.error(err); process.exit(1); });
