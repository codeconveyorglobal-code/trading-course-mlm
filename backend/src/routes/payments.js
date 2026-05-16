const express = require('express');
const router = express.Router();
const { initiatePayment, paymentCallback, checkPaymentStatus, getTransactionHistory, getSupportedCurrencies } = require('../controllers/paymentController');
const { protect } = require('../middleware/auth');

router.post('/callback', paymentCallback); // NOWPayments IPN (no auth)
router.get('/currencies', getSupportedCurrencies);

router.post('/initiate', protect, initiatePayment);
router.get('/status/:paymentId', protect, checkPaymentStatus);
router.get('/history', protect, getTransactionHistory);

module.exports = router;
