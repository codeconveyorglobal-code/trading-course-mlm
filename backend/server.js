require('dotenv').config();

// Ensure DATABASE_URL is set before anything loads Prisma
if (!process.env.DATABASE_URL) {
  process.env.DATABASE_URL = 'file:./trading-mlm.db';
}

// Run Prisma DB push to ensure schema is applied (using node directly for reliability)
try {
  const { execFileSync } = require('child_process');
  const fs = require('fs');
  const path = require('path');
  // Use the Prisma Node.js binary directly (not the shell script wrapper)
  const prismaCli = path.join(__dirname, 'node_modules', 'prisma', 'build', 'index.js');
  if (fs.existsSync(prismaCli)) {
    console.log('🔧 Running prisma db push...');
    execFileSync(process.execPath, [prismaCli, 'db', 'push', '--accept-data-loss'], {
      stdio: 'inherit',
      env: { ...process.env },
    });
    console.log('✅ Prisma DB ready');
  } else {
    console.warn('⚠️  Prisma CLI not found — skipping migration');
  }
} catch (e) {
  console.warn('⚠️  prisma db push warning:', e.message);
}

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const http = require('http');
const { Server } = require('socket.io');
const path = require('path');

const authRoutes = require('./src/routes/auth');
const courseRoutes = require('./src/routes/courses');
const mlmRoutes = require('./src/routes/mlm');
const paymentRoutes = require('./src/routes/payments');
const adminRoutes = require('./src/routes/admin');
const quizRoutes = require('./src/routes/quizzes');
const userRoutes = require('./src/routes/users');

const app = express();

// Trust Railway/Vercel proxy — required for rate-limiting and correct IP detection
app.set('trust proxy', 1);

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: (origin, callback) => {
      if (!origin) return callback(null, true);
      const allowed = [process.env.ADMIN_URL, process.env.APP_URL, 'http://localhost:3000', 'http://localhost:3001'].filter(Boolean);
      callback(null, allowed.includes(origin) || allowed.length === 0);
    },
    methods: ['GET', 'POST'],
  },
});

// Security Middleware
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
}));

// CORS must be first — before rate limiters — so 429 responses still include CORS headers
const allowedOrigins = [
  ...(process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : []),
  process.env.ADMIN_URL,
  process.env.APP_URL,
  // Vercel production URLs
  'https://admin-steel-ten.vercel.app',
  'https://app-orcin-beta-93.vercel.app',
  'http://localhost:3000',
  'http://localhost:3001',
].filter(Boolean);
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, Postman, server-to-server)
    if (!origin) return callback(null, true);
    if (allowedOrigins.includes(origin) || allowedOrigins.length === 0) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
}));

// Rate Limiting (after CORS so 429s include CORS headers)
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Too many requests, please try again later.' },
});
app.use('/api/', limiter);

// Auth rate limiting — raised to 30 per 15 min to avoid false positives
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Too many auth attempts, please try again later.' },
});
app.use('/api/auth/login', authLimiter);
app.use('/api/auth/register', authLimiter);

// General Middleware
app.use(compression());
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Disable ETag / caching on auth routes to prevent 304 responses
app.use('/api/auth', (req, res, next) => {
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
  res.setHeader('Pragma', 'no-cache');
  res.setHeader('Expires', '0');
  next();
});

// Static files
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Socket.IO for real-time notifications
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);
  socket.on('join_room', (userId) => {
    socket.join(`user_${userId}`);
  });
  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});
app.set('io', io);

// API Routes
app.use('/api/public', require('./src/routes/public'));
app.use('/api/auth', authRoutes);
app.use('/api/courses', courseRoutes);
app.use('/api/mlm', mlmRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/quizzes', quizRoutes);
app.use('/api/users', userRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ success: true, message: 'Trading MLM API is running', timestamp: new Date(), db: 'sqlite', version: '2.0' });
});

// One-time admin seed endpoint (protected by setup secret)
app.post('/setup/seed-admin', async (req, res) => {
  const secret = req.headers['x-setup-secret'];
  if (secret !== process.env.SETUP_SECRET) return res.status(403).json({ error: 'Forbidden' });
  try {
    await seedAdminIfNeeded();
    const User = require('./src/models/User');
    const existing = await User.findOne({ role: 'admin' });
    if (existing) return res.json({ success: true, message: 'Admin ready', email: existing.email });
    res.status(500).json({ error: 'Seed failed silently' });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 404 Handler
app.use('*', (req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  const statusCode = err.statusCode || 500;
  res.status(statusCode).json({
    success: false,
    message: err.message || 'Internal Server Error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
});

const seedAdminIfNeeded = async () => {
  try {
    const User = require('./src/models/User');
    const existing = await User.findOne({ role: 'admin' });
    if (existing) { console.log(`ℹ️  Admin already exists: ${existing.email}`); return; }
    await User.create({ name: 'Super Admin', email: 'admin@tradingmlm.com', password: 'Admin@123456', role: 'admin', phone: '0000000000', referralCode: 'ADMIN001', isActive: true });
    console.log('✅ Admin seeded: admin@tradingmlm.com / Admin@123456');
  } catch (e) { console.error('⚠️  Admin seed error:', e.message); }
};

const PORT = process.env.PORT || 5000;
server.listen(PORT, async () => {
  console.log(`🚀 Server running on port ${PORT} (SQLite mode)`);
  console.log(`📊 Admin Panel: ${process.env.ADMIN_URL}`);
  console.log(`📱 App URL: ${process.env.APP_URL}`);
  // Seed admin on startup (SQLite is always available)
  setTimeout(() => seedAdminIfNeeded(), 2000);
});

module.exports = { app, io };
