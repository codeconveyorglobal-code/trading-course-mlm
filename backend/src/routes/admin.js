const express = require('express');
const router = express.Router();
const {
  getDashboardStats, getUsers, getUserDetail, updateUser,
  placeUserInTree, getAdminTree, updateMLMSettings,
  getAllCommissions, updateCommission, getWithdrawals, processWithdrawal,
  manualEnroll, createAdmin, createUser, getAllTransactions,
  getAppSettings, updateAppSettings,
} = require('../controllers/adminController');
const { protect, adminOnly } = require('../middleware/auth');

router.use(protect, adminOnly);

// Dashboard
router.get('/dashboard', getDashboardStats);

// Users
router.get('/users', getUsers);
router.get('/users/:id', getUserDetail);
router.put('/users/:id', updateUser);
router.post('/create-admin', createAdmin);
router.post('/create-user', createUser);
router.post('/enroll', manualEnroll);

// MLM
router.post('/mlm/place-user', placeUserInTree);
router.get('/mlm/tree', getAdminTree);
router.put('/mlm/settings', updateMLMSettings);

// Commissions
router.get('/commissions', getAllCommissions);
router.put('/commissions/:id', updateCommission);

// Withdrawals
router.get('/withdrawals', getWithdrawals);
router.put('/withdrawals/:id', processWithdrawal);

// Transactions
router.get('/transactions', getAllTransactions);

// Payment Gateway Settings
router.get('/payment-settings', getAppSettings);
router.put('/payment-settings', updateAppSettings);

module.exports = router;
