const mongoose = require('mongoose');

const WithdrawalSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  amount: { type: Number, required: true },
  currency: { type: String, default: 'USDT' },
  cryptoAddress: { type: String, required: true },
  network: { type: String }, // TRC20, ERC20, BEP20
  status: { type: String, enum: ['pending', 'processing', 'completed', 'rejected'], default: 'pending' },
  txHash: { type: String },
  adminNote: { type: String },
  processedAt: { type: Date },
  processedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
}, { timestamps: true });

WithdrawalSchema.index({ userId: 1 });
WithdrawalSchema.index({ status: 1 });

module.exports = mongoose.model('Withdrawal', WithdrawalSchema);
