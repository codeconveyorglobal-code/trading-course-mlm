const User = require('../models/User');
const Course = require('../models/Course');
const Transaction = require('../models/Transaction');
const Commission = require('../models/Commission');
const MLMSettings = require('../models/MLMSettings');
const MLMNode = require('../models/MLMNode');
const Withdrawal = require('../models/Withdrawal');
const Enrollment = require('../models/Enrollment');
const { placeUserManually, getTreeData } = require('../utils/mlmUtils');

// @desc   Dashboard stats
// @route  GET /api/admin/dashboard
const getDashboardStats = async (req, res) => {
  try {
    const [
      totalUsers, activeUsers, totalCourses, publishedCourses,
      totalRevenue, pendingWithdrawals, totalCommissions,
      recentTransactions, recentUsers,
    ] = await Promise.all([
      User.countDocuments({ role: 'user' }),
      User.countDocuments({ role: 'user', isActive: true }),
      Course.countDocuments(),
      Course.countDocuments({ isPublished: true }),
      Transaction.aggregate([{ $match: { status: 'completed', type: 'course_purchase' } }, { $group: { _id: null, total: { $sum: '$amount' } } }]),
      Withdrawal.countDocuments({ status: 'pending' }),
      Commission.aggregate([{ $group: { _id: null, total: { $sum: '$amount' } } }]),
      Transaction.find({ type: 'course_purchase' }).sort('-createdAt').limit(10).populate('userId', 'name email').populate('courseId', 'title'),
      User.find({ role: 'user' }).sort('-createdAt').limit(10).select('name email rank isActive createdAt'),
    ]);

    // Monthly revenue for chart
    const monthlyRevenue = await Transaction.aggregate([
      { $match: { status: 'completed', type: 'course_purchase' } },
      { $group: { _id: { month: { $month: '$createdAt' }, year: { $year: '$createdAt' } }, total: { $sum: '$amount' }, count: { $sum: 1 } } },
      { $sort: { '_id.year': -1, '_id.month': -1 } },
      { $limit: 12 },
    ]);

    res.json({
      success: true,
      stats: {
        users: { total: totalUsers, active: activeUsers, inactive: totalUsers - activeUsers },
        courses: { total: totalCourses, published: publishedCourses },
        revenue: { total: totalRevenue[0]?.total || 0 },
        commissions: { total: totalCommissions[0]?.total || 0 },
        pendingWithdrawals,
      },
      recentTransactions,
      recentUsers,
      monthlyRevenue: monthlyRevenue.reverse(),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get all users
// @route  GET /api/admin/users
const getUsers = async (req, res) => {
  try {
    const { page = 1, limit = 20, search, role, isActive, rank } = req.query;
    const query = {};
    if (role) query.role = role;
    if (isActive !== undefined) query.isActive = isActive === 'true';
    if (rank) query.rank = rank;
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { referralCode: { $regex: search, $options: 'i' } },
      ];
    }

    const skip = (page - 1) * limit;
    const [users, total] = await Promise.all([
      User.find(query)
        .select('-password')
        .populate('sponsorId', 'name email')
        .sort('-createdAt')
        .skip(skip)
        .limit(parseInt(limit)),
      User.countDocuments(query),
    ]);

    res.json({ success: true, users, pagination: { total, page: parseInt(page), pages: Math.ceil(total / limit) } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get user details
// @route  GET /api/admin/users/:id
const getUserDetail = async (req, res) => {
  try {
    const user = await User.findById(req.params.id)
      .select('-password')
      .populate('sponsorId', 'name email referralCode')
      .populate('purchasedCourses', 'title price thumbnail');

    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    const [node, commissions, transactions] = await Promise.all([
      MLMNode.findOne({ userId: user._id }),
      Commission.find({ userId: user._id }).limit(10).sort('-createdAt'),
      Transaction.find({ userId: user._id }).limit(10).sort('-createdAt'),
    ]);

    res.json({ success: true, user, node, commissions, transactions });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Update user (activate/deactivate, change rank, etc.)
// @route  PUT /api/admin/users/:id
const updateUser = async (req, res) => {
  try {
    const { isActive, rank, role, walletBalance } = req.body;
    const updateData = {};
    if (isActive !== undefined) updateData.isActive = isActive;
    if (rank) updateData.rank = rank;
    if (role) updateData.role = role;
    if (walletBalance !== undefined) updateData.walletBalance = walletBalance;

    const user = await User.findByIdAndUpdate(req.params.id, updateData, { new: true }).select('-password');
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    res.json({ success: true, user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Place user in MLM tree manually
// @route  POST /api/admin/mlm/place-user
const placeUserInTree = async (req, res) => {
  try {
    const { userId, parentUserId, position } = req.body;
    if (!userId || !parentUserId || !position) {
      return res.status(400).json({ success: false, message: 'userId, parentUserId, and position are required' });
    }
    if (!['left', 'right'].includes(position)) {
      return res.status(400).json({ success: false, message: 'Position must be left or right' });
    }

    const node = await placeUserManually(userId, parentUserId, position);
    res.json({ success: true, message: 'User placed successfully', node });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get full MLM tree
// @route  GET /api/admin/mlm/tree
const getAdminTree = async (req, res) => {
  try {
    const { userId, depth = 5 } = req.query;
    let targetUserId = userId;
    if (!targetUserId) {
      // Get root node
      const rootNode = await MLMNode.findOne({ parentId: null });
      if (!rootNode) return res.json({ success: true, tree: null });
      targetUserId = rootNode.userId;
    }
    const tree = await getTreeData(targetUserId, parseInt(depth));
    res.json({ success: true, tree });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Update MLM settings
// @route  PUT /api/admin/mlm/settings
const updateMLMSettings = async (req, res) => {
  try {
    const settings = await MLMSettings.findOneAndUpdate(
      { singleton: true },
      { ...req.body, updatedBy: req.user._id },
      { upsert: true, new: true }
    );
    res.json({ success: true, settings });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get all commissions
// @route  GET /api/admin/commissions
const getAllCommissions = async (req, res) => {
  try {
    const { page = 1, limit = 20, status, type } = req.query;
    const query = {};
    if (status) query.status = status;
    if (type) query.type = type;

    const skip = (page - 1) * limit;
    const [commissions, total] = await Promise.all([
      Commission.find(query)
        .populate('userId', 'name email')
        .populate('fromUserId', 'name email')
        .populate('courseId', 'title')
        .sort('-createdAt')
        .skip(skip)
        .limit(parseInt(limit)),
      Commission.countDocuments(query),
    ]);

    res.json({ success: true, commissions, pagination: { total, page: parseInt(page), pages: Math.ceil(total / limit) } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Approve/reject commission
// @route  PUT /api/admin/commissions/:id
const updateCommission = async (req, res) => {
  try {
    const { status } = req.body;
    const commission = await Commission.findByIdAndUpdate(req.params.id, { status, paidAt: status === 'paid' ? new Date() : undefined }, { new: true });
    res.json({ success: true, commission });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get all withdrawals
// @route  GET /api/admin/withdrawals
const getWithdrawals = async (req, res) => {
  try {
    const { page = 1, limit = 20, status } = req.query;
    const query = status ? { status } : {};
    const skip = (page - 1) * limit;

    const [withdrawals, total] = await Promise.all([
      Withdrawal.find(query)
        .populate('userId', 'name email')
        .sort('-createdAt')
        .skip(skip)
        .limit(parseInt(limit)),
      Withdrawal.countDocuments(query),
    ]);

    res.json({ success: true, withdrawals, pagination: { total, page: parseInt(page), pages: Math.ceil(total / limit) } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Process withdrawal
// @route  PUT /api/admin/withdrawals/:id
const processWithdrawal = async (req, res) => {
  try {
    const { status, txHash, adminNote } = req.body;
    const updateData = { status, adminNote, processedBy: req.user._id };
    if (status === 'completed' || status === 'rejected') updateData.processedAt = new Date();
    if (txHash) updateData.txHash = txHash;

    const withdrawal = await Withdrawal.findByIdAndUpdate(req.params.id, updateData, { new: true })
      .populate('userId', 'name email');

    if (status === 'rejected') {
      // Refund balance
      await User.findByIdAndUpdate(withdrawal.userId._id, {
        $inc: { walletBalance: withdrawal.amount, totalWithdrawn: -withdrawal.amount },
      });
    }

    res.json({ success: true, withdrawal });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Manually enroll user in course
// @route  POST /api/admin/enroll
const manualEnroll = async (req, res) => {
  try {
    const { userId, courseId } = req.body;
    await Enrollment.findOneAndUpdate(
      { userId, courseId },
      { userId, courseId },
      { upsert: true, new: true }
    );
    await User.findByIdAndUpdate(userId, { $addToSet: { purchasedCourses: courseId } });
    await Course.findByIdAndUpdate(courseId, { $inc: { enrolledCount: 1 } });
    res.json({ success: true, message: 'User enrolled successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Create admin user
// @route  POST /api/admin/create-admin
const createAdmin = async (req, res) => {
  try {
    const { name, email, password } = req.body;
    const existing = await User.findOne({ email });
    if (existing) return res.status(400).json({ success: false, message: 'Email already exists' });

    const admin = await User.create({ name, email, password, role: 'admin' });
    res.json({ success: true, admin: admin.toSafeObject() });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Create a regular user (admin action) with optional tree placement
// @route  POST /api/admin/create-user
const createUser = async (req, res) => {
  try {
    const { name, email, password, phone, referralCode, parentUserId, position } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ success: false, message: 'Name, email and password are required' });
    }

    const existing = await User.findOne({ email });
    if (existing) return res.status(400).json({ success: false, message: 'Email already exists' });

    let sponsorId = null;
    if (referralCode) {
      const sponsor = await User.findOne({ referralCode });
      if (!sponsor) return res.status(400).json({ success: false, message: 'Invalid referral code' });
      sponsorId = sponsor._id;
    }

    const { createMLMNode, placeUserManually } = require('../utils/mlmUtils');
    const user = await User.create({ name, email, password, phone: phone || null, referredBy: referralCode || null, sponsorId });

    // Place in MLM tree
    if (parentUserId && position) {
      await placeUserManually(user._id, parentUserId, position);
    } else {
      await createMLMNode(user._id, sponsorId);
    }

    res.status(201).json({ success: true, user: user.toSafeObject() });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get all transactions
// @route  GET /api/admin/transactions
const getAllTransactions = async (req, res) => {
  try {
    const { page = 1, limit = 20, status, type } = req.query;
    const query = {};
    if (status) query.status = status;
    if (type) query.type = type;
    const skip = (page - 1) * limit;

    const [transactions, total] = await Promise.all([
      Transaction.find(query)
        .populate('userId', 'name email')
        .populate('courseId', 'title price')
        .sort('-createdAt')
        .skip(skip)
        .limit(parseInt(limit)),
      Transaction.countDocuments(query),
    ]);

    res.json({ success: true, transactions, pagination: { total, page: parseInt(page), pages: Math.ceil(total / limit) } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getDashboardStats, getUsers, getUserDetail, updateUser,
  placeUserInTree, getAdminTree, updateMLMSettings,
  getAllCommissions, updateCommission, getWithdrawals, processWithdrawal,
  manualEnroll, createAdmin, createUser, getAllTransactions,
};
