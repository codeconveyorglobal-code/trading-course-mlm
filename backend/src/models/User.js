const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

const UserSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true, maxlength: 100 },
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  password: { type: String, required: true, minlength: 6 },
  phone: { type: String, trim: true },
  role: { type: String, enum: ['user', 'admin'], default: 'user' },
  profilePicture: { type: String, default: null },

  // MLM Fields
  referralCode: { type: String, unique: true },
  referredBy: { type: String, default: null },  // referral code of sponsor
  sponsorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },

  // Account Status
  isActive: { type: Boolean, default: true },
  isEmailVerified: { type: Boolean, default: false },
  emailVerificationToken: { type: String },
  resetPasswordToken: { type: String },
  resetPasswordExpire: { type: Date },

  // Financial
  walletBalance: { type: Number, default: 0 },
  totalEarnings: { type: Number, default: 0 },
  totalWithdrawn: { type: Number, default: 0 },
  cryptoWalletAddress: { type: String, default: null },

  // Rank / Level
  rank: { type: String, enum: ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'], default: 'Bronze' },
  
  // Courses purchased
  purchasedCourses: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Course' }],
  
  // KYC
  kycStatus: { type: String, enum: ['pending', 'submitted', 'approved', 'rejected'], default: 'pending' },
  kycDocuments: [{ type: String }],

  lastLogin: { type: Date },
  joinDate: { type: Date, default: Date.now },
}, { timestamps: true });

// Generate referral code before save
UserSchema.pre('save', async function (next) {
  if (!this.referralCode) {
    this.referralCode = this.name.toUpperCase().replace(/\s+/g, '').substring(0, 4) + 
      Math.random().toString(36).substring(2, 6).toUpperCase();
  }
  if (this.isModified('password')) {
    const salt = await bcrypt.genSalt(12);
    this.password = await bcrypt.hash(this.password, salt);
  }
  next();
});

UserSchema.methods.matchPassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

UserSchema.methods.toSafeObject = function () {
  const obj = this.toObject();
  delete obj.password;
  delete obj.emailVerificationToken;
  delete obj.resetPasswordToken;
  return obj;
};

UserSchema.index({ email: 1 });
UserSchema.index({ referralCode: 1 });
UserSchema.index({ sponsorId: 1 });

module.exports = mongoose.model('User', UserSchema);
