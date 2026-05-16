const express = require('express');
const router = express.Router();
const { getCourses, getCourse, getMyCourses, updateProgress, createCourse, updateCourse, uploadMaterial, deleteCourse, getAllCoursesAdmin } = require('../controllers/courseController');
const { protect, adminOnly } = require('../middleware/auth');
const upload = require('../middleware/upload');

// Public
router.get('/', protect, getCourses);

// User (authenticated)
router.get('/my-courses', protect, getMyCourses);
router.put('/:id/progress', protect, updateProgress);

// Admin
router.get('/admin/all', protect, adminOnly, getAllCoursesAdmin);
router.post('/', protect, adminOnly, upload.fields([{ name: 'thumbnail', maxCount: 1 }]), createCourse);
router.put('/:id', protect, adminOnly, upload.fields([{ name: 'thumbnail', maxCount: 1 }]), updateCourse);
router.post('/:id/materials', protect, adminOnly, upload.single('material'), uploadMaterial);
router.delete('/:id', protect, adminOnly, deleteCourse);

// Must come last to avoid conflict
router.get('/:id', protect, getCourse);

module.exports = router;
