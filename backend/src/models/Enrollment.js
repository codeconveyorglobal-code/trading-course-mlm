const mongoose = require('mongoose');

const EnrollmentSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  courseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', required: true },
  transactionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Transaction' },
  progress: { type: Number, default: 0 }, // percentage
  completedMaterials: [{ type: String }], // material IDs
  completedAt: { type: Date, default: null },
  certificateUrl: { type: String, default: null },
  lastAccessedAt: { type: Date, default: Date.now },
}, { timestamps: true });

EnrollmentSchema.index({ userId: 1, courseId: 1 }, { unique: true });

module.exports = mongoose.model('Enrollment', EnrollmentSchema);
