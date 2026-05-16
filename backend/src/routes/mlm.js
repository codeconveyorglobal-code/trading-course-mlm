const express = require('express');
const router = express.Router();
const { getMyTree, getMyStats, getMyCommissions, requestWithdrawal, getMLMSettings, getReferralInfo, getMyTeam } = require('../controllers/mlmController');
const { protect } = require('../middleware/auth');

router.get('/settings', getMLMSettings);
router.get('/referral/:code', getReferralInfo);

router.get('/tree', protect, getMyTree);
router.get('/stats', protect, getMyStats);
router.get('/commissions', protect, getMyCommissions);
router.get('/team', protect, getMyTeam);
router.post('/withdraw', protect, requestWithdrawal);

module.exports = router;
