// Ensure DATABASE_URL is set before PrismaClient is instantiated
if (!process.env.DATABASE_URL) {
  process.env.DATABASE_URL = 'file:./trading-mlm.db';
}

const { PrismaClient } = require('@prisma/client');

let prisma = global._prismaInstance;
if (!prisma) {
  prisma = new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['error', 'warn'] : ['error'],
  });
  global._prismaInstance = prisma;
}

module.exports = prisma;
