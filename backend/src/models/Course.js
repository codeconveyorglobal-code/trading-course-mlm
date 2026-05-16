const mongoose = require('mongoose');

const CourseMaterialSchema = new mongoose.Schema({
  title: { type: String, required: true },
  type: { type: String, enum: ['pdf', 'video', 'article', 'quiz'], required: true },
  url: { type: String },
  fileSize: { type: Number },
  duration: { type: String },
  order: { type: Number, default: 0 },
  isPreview: { type: Boolean, default: false },
});

const CourseSchema = new mongoose.Schema({
  title: { type: String, required: true, trim: true },
  slug: { type: String, unique: true },
  description: { type: String, required: true },
  shortDescription: { type: String, maxlength: 300 },
  category: { type: String, required: true, enum: ['Forex', 'Crypto', 'Stocks', 'Options', 'Futures', 'Technical Analysis', 'Fundamental Analysis', 'Risk Management', 'Advanced Strategies', 'Beginner'] },
  level: { type: String, enum: ['Beginner', 'Intermediate', 'Advanced'], default: 'Beginner' },
  
  price: { type: Number, required: true, min: 0 },
  discountPrice: { type: Number, default: null },
  currency: { type: String, default: 'USD' },

  thumbnail: { type: String, default: null },
  previewVideo: { type: String, default: null },

  instructor: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  instructorName: { type: String },

  materials: [CourseMaterialSchema],
  quizzes: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Quiz' }],

  tags: [{ type: String }],
  language: { type: String, default: 'English' },
  duration: { type: String },
  totalLessons: { type: Number, default: 0 },

  isPublished: { type: Boolean, default: false },
  isFeatured: { type: Boolean, default: false },
  isMLMEligible: { type: Boolean, default: true }, // Eligible for MLM commission

  enrolledCount: { type: Number, default: 0 },
  rating: { type: Number, default: 0 },
  reviewCount: { type: Number, default: 0 },

  requirements: [{ type: String }],
  whatYouLearn: [{ type: String }],

  completionCertificate: { type: Boolean, default: false },

}, { timestamps: true });

CourseSchema.pre('save', function (next) {
  if (this.isModified('title')) {
    this.slug = this.title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '') + '-' + Date.now();
  }
  next();
});

CourseSchema.index({ category: 1 });
CourseSchema.index({ isPublished: 1 });
CourseSchema.index({ slug: 1 });

module.exports = mongoose.model('Course', CourseSchema);
