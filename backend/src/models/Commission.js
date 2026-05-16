const mongoose = require('mongoose');

const CommissionSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },       // Who receives the commission
  fromUserId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },   // Who triggered the commission
  transactionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Transaction' },
  courseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Course' },

  type: { 
    type: String, 
    enum: ['direct_referral', 'binary_matching', 'level_override', 'rank_bonus', 'leadership_bonus'], 
    required: true 
  },
  level: { type: Number, default: 1 }, // Level in the upline chain
  percentage: { type: Number },        // Percentage applied

  baseAmount: { type: Number, required: true }, // Original sale amount
  amount: { type: Number, required: true },     // Commission amount

  status: { type: String, enum: ['pending', 'approved', 'paid', 'cancelled'], default: 'pending' },
  paidAt: { type: Date },
  paidVia: { type: String }, // crypto address or wallet

  description: { type: String },
}, { timestamps: true });

CommissionSchema.index({ userId: 1, status: 1 });
CommissionSchema.index({ fromUserId: 1 });

module.exports = mongoose.model('Commission', CommissionSchema);
