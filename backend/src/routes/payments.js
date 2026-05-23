const express = require('express');
const router = express.Router();
const { initiatePayment, paymentCallback, checkPaymentStatus, getTransactionHistory, getSupportedCurrencies, getWallet, saveWalletAddress, getEstimate } = require('../controllers/paymentController');
const { protect } = require('../middleware/auth');

router.post('/callback', paymentCallback); // NOWPayments IPN (no auth)
router.get('/currencies', getSupportedCurrencies);
router.get('/estimate', protect, getEstimate);

router.post('/initiate', protect, initiatePayment);
router.get('/status/:paymentId', protect, checkPaymentStatus);
router.get('/history', protect, getTransactionHistory);

router.get('/wallet', protect, getWallet);
router.put('/wallet/address', protect, saveWalletAddress);

module.exports = router;
