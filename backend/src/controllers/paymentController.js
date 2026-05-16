const Transaction = require('../models/Transaction');
const Course = require('../models/Course');
const User = require('../models/User');
const Enrollment = require('../models/Enrollment');
const { createPayment, getPaymentStatus, verifyIPN, mapPaymentStatus } = require('../utils/cryptoPayment');
const { processCommissions } = require('../utils/mlmUtils');
const { v4: uuidv4 } = require('uuid');

// @desc   Initiate course purchase payment
// @route  POST /api/payments/initiate
const initiatePayment = async (req, res) => {
  try {
    const { courseId, payCurrency = 'USDT' } = req.body;
    const course = await Course.findById(courseId);
    if (!course) return res.status(404).json({ success: false, message: 'Course not found' });
    if (!course.isPublished) return res.status(400).json({ success: false, message: 'Course not available' });

    // Check if already purchased
    const user = await User.findById(req.user._id);
    if (user.purchasedCourses.includes(courseId)) {
      return res.status(400).json({ success: false, message: 'Already purchased' });
    }

    const price = course.discountPrice || course.price;
    const orderId = `ORDER-${uuidv4()}`;

    // Create NOWPayments payment
    const payment = await createPayment({
      priceAmount: price,
      priceCurrency: 'USD',
      payCurrency,
      orderId,
      orderDescription: `Purchase: ${course.title}`,
      successUrl: `${process.env.APP_URL}/payment/success`,
      cancelUrl: `${process.env.APP_URL}/payment/cancel`,
    });

    // Create transaction record
    const transaction = await Transaction.create({
      userId: req.user._id,
      courseId,
      type: 'course_purchase',
      amount: price,
      currency: 'USD',
      cryptoCurrency: payCurrency,
      cryptoAmount: payment.pay_amount,
      cryptoAddress: payment.pay_address,
      paymentId: payment.payment_id,
      paymentStatus: payment.payment_status,
      status: 'pending',
      metadata: { orderId, nowPaymentsData: payment },
    });

    res.json({
      success: true,
      transaction,
      payment: {
        paymentId: payment.payment_id,
        payAddress: payment.pay_address,
        payAmount: payment.pay_amount,
        payCurrency: payment.pay_currency,
        priceAmount: payment.price_amount,
        priceCurrency: payment.price_currency,
        expirationEstimate: payment.expiration_estimate_date,
        qrCode: `crypto:${payment.pay_address}?amount=${payment.pay_amount}`,
      },
    });
  } catch (error) {
    console.error('initiatePayment error:', error);
    res.status(500).json({ success: false, message: 'Payment initiation failed', error: error.message });
  }
};

// @desc   NOWPayments IPN Callback
// @route  POST /api/payments/callback
const paymentCallback = async (req, res) => {
  try {
    const hmacHeader = req.headers['x-nowpayments-sig'];
    if (!verifyIPN(req.body, hmacHeader)) {
      return res.status(400).json({ success: false, message: 'Invalid signature' });
    }

    const { payment_id, payment_status, order_id } = req.body;
    const transaction = await Transaction.findOne({ paymentId: payment_id });
    if (!transaction) return res.status(404).json({ success: false, message: 'Transaction not found' });

    const internalStatus = mapPaymentStatus(payment_status);
    transaction.paymentStatus = payment_status;
    transaction.status = internalStatus;

    if (internalStatus === 'completed' && transaction.status !== 'completed') {
      transaction.completedAt = new Date();
      await transaction.save();

      // Enroll user in course
      await Enrollment.findOneAndUpdate(
        { userId: transaction.userId, courseId: transaction.courseId },
        { userId: transaction.userId, courseId: transaction.courseId, transactionId: transaction._id },
        { upsert: true, new: true }
      );

      // Add to user's purchased courses
      await User.findByIdAndUpdate(transaction.userId, {
        $addToSet: { purchasedCourses: transaction.courseId },
      });

      // Increment enrolled count
      await Course.findByIdAndUpdate(transaction.courseId, { $inc: { enrolledCount: 1 } });

      // Process MLM commissions
      await processCommissions(transaction.userId, transaction.courseId, transaction.amount, transaction._id);

      // Notify via socket
      // req.app.get('io').to(`user_${transaction.userId}`).emit('payment_completed', { transactionId: transaction._id });
    } else {
      await transaction.save();
    }

    res.json({ success: true });
  } catch (error) {
    console.error('paymentCallback error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Check payment status
// @route  GET /api/payments/status/:paymentId
const checkPaymentStatus = async (req, res) => {
  try {
    const transaction = await Transaction.findOne({ paymentId: req.params.paymentId, userId: req.user._id });
    if (!transaction) return res.status(404).json({ success: false, message: 'Transaction not found' });

    // Fetch latest from NOWPayments
    const paymentData = await getPaymentStatus(req.params.paymentId);
    const internalStatus = mapPaymentStatus(paymentData.payment_status);

    if (internalStatus !== transaction.status) {
      transaction.paymentStatus = paymentData.payment_status;
      transaction.status = internalStatus;
      if (internalStatus === 'completed') transaction.completedAt = new Date();
      await transaction.save();
    }

    res.json({ success: true, status: internalStatus, transaction });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get transaction history
// @route  GET /api/payments/history
const getTransactionHistory = async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const skip = (page - 1) * limit;
    const [transactions, total] = await Promise.all([
      Transaction.find({ userId: req.user._id })
        .populate('courseId', 'title thumbnail')
        .sort('-createdAt')
        .skip(skip)
        .limit(parseInt(limit)),
      Transaction.countDocuments({ userId: req.user._id }),
    ]);
    res.json({ success: true, transactions, pagination: { total, page: parseInt(page), pages: Math.ceil(total / limit) } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get supported crypto currencies
// @route  GET /api/payments/currencies
const getSupportedCurrencies = async (req, res) => {
  try {
    const { getAvailableCurrencies } = require('../utils/cryptoPayment');
    const data = await getAvailableCurrencies();
    res.json({ success: true, currencies: data.currencies });
  } catch (error) {
    // Fallback list
    res.json({
      success: true,
      currencies: ['BTC', 'ETH', 'USDT', 'USDC', 'BNB', 'TRX', 'LTC', 'DOGE', 'SOL', 'XRP'],
    });
  }
};

module.exports = { initiatePayment, paymentCallback, checkPaymentStatus, getTransactionHistory, getSupportedCurrencies };
