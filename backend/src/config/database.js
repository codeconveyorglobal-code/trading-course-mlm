// MongoDB replaced by Prisma + SQLite. This file is kept to avoid import errors.
// Prisma connects automatically on first use; no explicit connect call needed.
const connectDB = async () => {
  console.log('ℹ️  Using SQLite via Prisma (MongoDB removed)');
};
module.exports = connectDB;
