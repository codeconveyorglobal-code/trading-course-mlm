const mongoose = require('mongoose');

const MLMSettingsSchema = new mongoose.Schema({
  // Only one settings document
  singleton: { type: Boolean, default: true, unique: true },

  // Direct Referral Commission
  directReferralCommission: { type: Number, default: 10 }, // % of course price

  // Level Commissions (upline levels)
  levelCommissions: [{
    level: { type: Number },
    percentage: { type: Number },
  }],

  // Binary Plan Settings
  binaryEnabled: { type: Boolean, default: true },
  binaryMatchingBonus: { type: Number, default: 10 }, // % on matched pairs
  binaryWeakLegPercentage: { type: Number, default: 100 }, // % of weak leg considered
  maxBinaryPercentage: { type: Number, default: 50 }, // daily cap % of PV

  // Rank Bonuses
  rankBonuses: [{
    rank: { type: String },
    directRequired: { type: Number },
    teamRequired: { type: Number },
    bonus: { type: Number },
    monthlyBonus: { type: Number },
  }],

  // Payout Settings
  minPayout: { type: Number, default: 50 }, // USD
  payoutSchedule: { type: String, enum: ['instant', 'daily', 'weekly', 'monthly'], default: 'weekly' },
  payoutDay: { type: Number, default: 1 }, // day of week/month

  // Commission Hold
  commissionHoldDays: { type: Number, default: 7 }, // days before commission is payable

  // Currency
  commissionCurrency: { type: String, default: 'USDT' },

  // Capping
  dailyCap: { type: Number, default: 0 }, // 0 = no cap
  weeklyCap: { type: Number, default: 0 },
  monthlyCap: { type: Number, default: 0 },

  updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
}, { timestamps: true });

// Default level commissions
MLMSettingsSchema.pre('save', function (next) {
  if (!this.levelCommissions || this.levelCommissions.length === 0) {
    this.levelCommissions = [
      { level: 1, percentage: 10 },
      { level: 2, percentage: 5 },
      { level: 3, percentage: 3 },
      { level: 4, percentage: 2 },
      { level: 5, percentage: 1 },
    ];
  }
  if (!this.rankBonuses || this.rankBonuses.length === 0) {
    this.rankBonuses = [
      { rank: 'Bronze', directRequired: 0, teamRequired: 0, bonus: 0, monthlyBonus: 0 },
      { rank: 'Silver', directRequired: 3, teamRequired: 10, bonus: 50, monthlyBonus: 100 },
      { rank: 'Gold', directRequired: 6, teamRequired: 30, bonus: 200, monthlyBonus: 500 },
      { rank: 'Platinum', directRequired: 12, teamRequired: 100, bonus: 1000, monthlyBonus: 2000 },
      { rank: 'Diamond', directRequired: 25, teamRequired: 300, bonus: 5000, monthlyBonus: 10000 },
    ];
  }
  next();
});

module.exports = mongoose.model('MLMSettings', MLMSettingsSchema);
