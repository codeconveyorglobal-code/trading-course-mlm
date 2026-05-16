const Course = require('../models/Course');
const Enrollment = require('../models/Enrollment');
const User = require('../models/User');

// @desc   Get all courses (public)
// @route  GET /api/courses
const getCourses = async (req, res) => {
  try {
    const { category, level, search, page = 1, limit = 12, sort = '-createdAt' } = req.query;
    const query = { isPublished: true };

    if (category) query.category = category;
    if (level) query.level = level;
    if (search) query.$text = { $search: search };

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [courses, total] = await Promise.all([
      Course.find(query)
        .sort(sort)
        .skip(skip)
        .limit(parseInt(limit))
        .populate('instructor', 'name profilePicture'),
      Course.countDocuments(query),
    ]);

    // If user is authenticated, mark purchased courses
    let purchasedIds = [];
    if (req.user) {
      const user = await User.findById(req.user._id).select('purchasedCourses');
      purchasedIds = user.purchasedCourses.map(id => id.toString());
    }

    const coursesWithStatus = courses.map(c => ({
      ...c.toObject(),
      isPurchased: purchasedIds.includes(c._id.toString()),
    }));

    res.json({
      success: true,
      courses: coursesWithStatus,
      pagination: { total, page: parseInt(page), pages: Math.ceil(total / parseInt(limit)) },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get single course
// @route  GET /api/courses/:id
const getCourse = async (req, res) => {
  try {
    const course = await Course.findById(req.params.id)
      .populate('instructor', 'name profilePicture')
      .populate('quizzes', 'title totalMarks passingScore timeLimit');

    if (!course) return res.status(404).json({ success: false, message: 'Course not found' });

    let isPurchased = false;
    if (req.user) {
      const user = await User.findById(req.user._id).select('purchasedCourses');
      isPurchased = user.purchasedCourses.some(id => id.toString() === course._id.toString());
    }

    // If not purchased, hide premium materials
    const courseData = course.toObject();
    if (!isPurchased) {
      courseData.materials = courseData.materials.filter(m => m.isPreview);
    }

    res.json({ success: true, course: { ...courseData, isPurchased } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get my enrolled courses
// @route  GET /api/courses/my-courses
const getMyCourses = async (req, res) => {
  try {
    const enrollments = await Enrollment.find({ userId: req.user._id })
      .populate('courseId')
      .sort('-createdAt');
    res.json({ success: true, enrollments });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Update course progress
// @route  PUT /api/courses/:id/progress
const updateProgress = async (req, res) => {
  try {
    const { materialId, progress } = req.body;
    const enrollment = await Enrollment.findOne({
      userId: req.user._id,
      courseId: req.params.id,
    });
    if (!enrollment) return res.status(404).json({ success: false, message: 'Not enrolled' });

    if (materialId && !enrollment.completedMaterials.includes(materialId)) {
      enrollment.completedMaterials.push(materialId);
    }
    if (progress !== undefined) enrollment.progress = progress;
    if (progress === 100) enrollment.completedAt = new Date();
    enrollment.lastAccessedAt = new Date();
    await enrollment.save();

    res.json({ success: true, enrollment });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ADMIN ROUTES
// @desc   Create course
// @route  POST /api/courses (admin)
const createCourse = async (req, res) => {
  try {
    const courseData = { ...req.body };
    if (req.files) {
      if (req.files.thumbnail) courseData.thumbnail = `/uploads/images/${req.files.thumbnail[0].filename}`;
    }
    courseData.instructor = req.user._id;
    courseData.instructorName = req.user.name;

    const course = await Course.create(courseData);
    res.status(201).json({ success: true, course });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Update course
// @route  PUT /api/courses/:id (admin)
const updateCourse = async (req, res) => {
  try {
    const updateData = { ...req.body };
    if (req.files && req.files.thumbnail) {
      updateData.thumbnail = `/uploads/images/${req.files.thumbnail[0].filename}`;
    }
    const course = await Course.findByIdAndUpdate(req.params.id, updateData, { new: true });
    if (!course) return res.status(404).json({ success: false, message: 'Course not found' });
    res.json({ success: true, course });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Upload course material (PDF)
// @route  POST /api/courses/:id/materials (admin)
const uploadMaterial = async (req, res) => {
  try {
    const { title, type, order, isPreview } = req.body;
    const course = await Course.findById(req.params.id);
    if (!course) return res.status(404).json({ success: false, message: 'Course not found' });

    let url = '';
    if (req.file) {
      const prefix = req.file.mimetype === 'application/pdf' ? 'pdfs' : 'docs';
      url = `/uploads/${prefix}/${req.file.filename}`;
    }

    const material = {
      title,
      type: type || 'pdf',
      url,
      fileSize: req.file ? req.file.size : 0,
      order: parseInt(order) || course.materials.length,
      isPreview: isPreview === 'true',
    };

    course.materials.push(material);
    course.totalLessons = course.materials.length;
    await course.save();

    res.json({ success: true, material, course });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Delete course
// @route  DELETE /api/courses/:id (admin)
const deleteCourse = async (req, res) => {
  try {
    await Course.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Course deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get all courses (admin)
// @route  GET /api/courses/admin/all
const getAllCoursesAdmin = async (req, res) => {
  try {
    const courses = await Course.find({})
      .populate('instructor', 'name')
      .sort('-createdAt');
    res.json({ success: true, courses });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = { getCourses, getCourse, getMyCourses, updateProgress, createCourse, updateCourse, uploadMaterial, deleteCourse, getAllCoursesAdmin };
