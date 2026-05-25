const express = require('express');
const router = express.Router();
const Course = require('../models/Course');
const User = require('../models/User');
const { v4: uuidv4 } = require('uuid');

// GET /api/public/stats
router.get('/stats', async (req, res) => {
  try {
    const [totalUsers, totalCourses] = await Promise.all([
      User.countDocuments({ role: 'user' }),
      Course.countDocuments({ isPublished: true }),
    ]);
    res.json({
      success: true,
      stats: {
        totalUsers,
        totalCourses,
        totalEarned: 500000,   // Display stat — update with real aggregate if needed
        satisfactionRate: 98,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /api/public/courses?limit=6
router.get('/courses', async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 6, 12);
    const courses = await Course.find({ isPublished: true, isFeatured: true }).limit(limit);
    // If no featured, just return any published
    const result = courses.length ? courses : await Course.find({ isPublished: true }).limit(limit);
    res.json({ success: true, courses: result });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
