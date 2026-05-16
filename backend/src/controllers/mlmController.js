const MLMNode = require('../models/MLMNode');
const Commission = require('../models/Commission');
const Withdrawal = require('../models/Withdrawal');
const MLMSettings = require('../models/MLMSettings');
const User = require('../models/User');
const { getTreeData, placeUserManually } = require('../utils/mlmUtils');

// @desc   Get my MLM tree
// @route  GET /api/mlm/tree
const getMyTree = async (req, res) => {
  try {
    const tree = await getTreeData(req.user._id, 4);
    if (!tree) return res.status(404).json({ success: false, message: 'MLM node not found' });
    res.json({ success: true, tree });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get my MLM stats
// @route  GET /api/mlm/stats
const getMyStats = async (req, res) => {
  try {
    const [node, commissions, pendingWithdrawals] = await Promise.all([
      MLMNode.findOne({ userId: req.user._id }),
      Commission.find({ userId: req.user._id }),
      Withdrawal.find({ userId: req.user._id, status: 'pending' }),
    ]);

    const totalCommission = commissions.reduce((sum, c) => sum + c.amount, 0);
    const paidCommission = commissions.filter(c => c.status === 'paid').reduce((sum, c) => sum + c.amount, 0);
    const pendingCommission = commissions.filter(c => c.status === 'pending').reduce((sum, c) => sum + c.amount, 0);

    const user = await User.findById(req.user._id).select('walletBalance totalEarnings totalWithdrawn rank referralCode');

    res.json({
      success: true,
      stats: {
        walletBalance: user.walletBalance,
        totalEarnings: user.totalEarnings,
        totalWithdrawn: user.totalWithdrawn,
        totalCommission,
        paidCommission,
        pendingCommission,
        rank: user.rank,
        referralCode: user.referralCode,
        referralLink: `${process.env.APP_URL}/register?ref=${user.referralCode}`,
        teamStats: {
          totalTeamSize: node?.totalTeamSize || 0,
          leftCount: node?.leftCount || 0,
          rightCount: node?.rightCount || 0,
          totalDirectReferrals: node?.totalDirectReferrals || 0,
          leftVolume: node?.leftVolume || 0,
          rightVolume: node?.rightVolume || 0,
        },
        pendingWithdrawals: pendingWithdrawals.length,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get my commissions
// @route  GET /api/mlm/commissions
const getMyCommissions = async (req, res) => {
  try {
    const { page = 1, limit = 20, type, status } = req.query;
    const query = { userId: req.user._id };
    if (type) query.type = type;
    if (status) query.status = status;

    const skip = (page - 1) * limit;
    const [commissions, total] = await Promise.all([
      Commission.find(query)
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

// @desc   Request withdrawal
// @route  POST /api/mlm/withdraw
const requestWithdrawal = async (req, res) => {
  try {
    const { amount, cryptoAddress, currency = 'USDT', network } = req.body;
    const settings = await MLMSettings.findOne({ singleton: true });

    if (!amount || amount <= 0) return res.status(400).json({ success: false, message: 'Invalid amount' });
    if (settings && amount < settings.minPayout) {
      return res.status(400).json({ success: false, message: `Minimum payout is $${settings.minPayout}` });
    }
    if (!cryptoAddress) return res.status(400).json({ success: false, message: 'Crypto address required' });

    const user = await User.findById(req.user._id);
    if (user.walletBalance < amount) {
      return res.status(400).json({ success: false, message: 'Insufficient balance' });
    }

    // Deduct balance
    await User.findByIdAndUpdate(req.user._id, { $inc: { walletBalance: -amount, totalWithdrawn: amount } });

    const withdrawal = await Withdrawal.create({
      userId: req.user._id,
      amount,
      currency,
      cryptoAddress,
      network,
    });

    res.json({ success: true, message: 'Withdrawal request submitted', withdrawal });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get MLM settings (public)
// @route  GET /api/mlm/settings
const getMLMSettings = async (req, res) => {
  try {
    const settings = await MLMSettings.findOne({ singleton: true });
    res.json({ success: true, settings });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get referral link info
// @route  GET /api/mlm/referral/:code
const getReferralInfo = async (req, res) => {
  try {
    const sponsor = await User.findOne({ referralCode: req.params.code }).select('name profilePicture referralCode');
    if (!sponsor) return res.status(404).json({ success: false, message: 'Invalid referral code' });
    res.json({ success: true, sponsor });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get direct team members
// @route  GET /api/mlm/team
const getMyTeam = async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const skip = (page - 1) * limit;

    const [members, total] = await Promise.all([
      User.find({ sponsorId: req.user._id })
        .select('name email profilePicture rank isActive createdAt purchasedCourses')
        .sort('-createdAt')
        .skip(skip)
        .limit(parseInt(limit)),
      User.countDocuments({ sponsorId: req.user._id }),
    ]);

    res.json({ success: true, members, pagination: { total, page: parseInt(page), pages: Math.ceil(total / limit) } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = { getMyTree, getMyStats, getMyCommissions, requestWithdrawal, getMLMSettings, getReferralInfo, getMyTeam };
