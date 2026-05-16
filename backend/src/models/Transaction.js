const mongoose = require('mongoose');

const TransactionSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  courseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', default: null },

  type: { type: String, enum: ['course_purchase', 'commission', 'withdrawal', 'refund'], required: true },
  amount: { type: Number, required: true }, // USD amount
  currency: { type: String, default: 'USD' },

  // Crypto payment details
  cryptoCurrency: { type: String }, // BTC, ETH, USDT, etc.
  cryptoAmount: { type: Number },
  cryptoAddress: { type: String },
  txHash: { type: String },
  exchangeRate: { type: Number },

  // NOWPayments
  paymentId: { type: String, unique: true, sparse: true },
  paymentStatus: { type: String, enum: ['waiting', 'confirming', 'confirmed', 'sending', 'partially_paid', 'finished', 'failed', 'refunded', 'expired'], default: 'waiting' },

  status: { type: String, enum: ['pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded'], default: 'pending' },

  description: { type: String },
  metadata: { type: mongoose.Schema.Types.Mixed },

  completedAt: { type: Date },
}, { timestamps: true });

TransactionSchema.index({ userId: 1 });
TransactionSchema.index({ paymentId: 1 });
TransactionSchema.index({ status: 1 });

module.exports = mongoose.model('Transaction', TransactionSchema);
