const mongoose = require('mongoose');

const MLMNodeSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  parentId: { type: mongoose.Schema.Types.ObjectId, ref: 'MLMNode', default: null },
  sponsorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },

  position: { type: String, enum: ['left', 'right', 'root'], default: 'left' },
  level: { type: Number, default: 0 },

  leftChild: { type: mongoose.Schema.Types.ObjectId, ref: 'MLMNode', default: null },
  rightChild: { type: mongoose.Schema.Types.ObjectId, ref: 'MLMNode', default: null },

  // Volume tracking
  leftVolume: { type: Number, default: 0 },
  rightVolume: { type: Number, default: 0 },
  leftCount: { type: Number, default: 0 },
  rightCount: { type: Number, default: 0 },

  // Carry forward (binary matching)
  leftCarry: { type: Number, default: 0 },
  rightCarry: { type: Number, default: 0 },

  totalDirectReferrals: { type: Number, default: 0 },
  totalTeamSize: { type: Number, default: 0 },
  totalEarnings: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true },

}, { timestamps: true });

MLMNodeSchema.index({ userId: 1 });
MLMNodeSchema.index({ parentId: 1 });
MLMNodeSchema.index({ sponsorId: 1 });

module.exports = mongoose.model('MLMNode', MLMNodeSchema);
