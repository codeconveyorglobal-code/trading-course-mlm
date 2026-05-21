const Course = require('../models/Course');
const Enrollment = require('../models/Enrollment');
const User = require('../models/User');

const toPlain = (val) => {
  if (!val) return val;
  if (Array.isArray(val)) return val.map(toPlain);
  if (typeof val.toJSON === 'function') return val.toJSON();
  if (typeof val.toObject === 'function') return val.toObject();
  if (val && typeof val === 'object') {
    const out = {};
    for (const k of Object.keys(val)) { if (!k.startsWith('__')) out[k] = toPlain(val[k]); }
    return out;
  }
  return val;
};

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
    // Map instructor → instructorId (Prisma field)
    courseData.instructorId = req.user._id;
    courseData.instructorName = req.user.name;
    delete courseData.instructor;

    // Generate unique slug from title
    const baseSlug = (courseData.title || 'course')
      .toLowerCase()
      .replace(/[^a-z0-9\s-]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-')
      .trim();
    courseData.slug = `${baseSlug}-${Date.now()}`;

    // Normalize bracket-notation array fields sent by multipart forms
    const normalizeArrayField = (key) => {
      if (courseData[`${key}[]`] !== undefined) {
        const raw = courseData[`${key}[]`];
        courseData[key] = JSON.stringify(Array.isArray(raw) ? raw : [raw]);
        delete courseData[`${key}[]`];
      } else if (Array.isArray(courseData[key])) {
        courseData[key] = JSON.stringify(courseData[key]);
      }
    };
    normalizeArrayField('whatYouLearn');
    normalizeArrayField('requirements');
    normalizeArrayField('tags');

    // Coerce numeric/boolean fields from form strings
    if (courseData.price !== undefined) courseData.price = parseFloat(courseData.price) || 0;
    if (courseData.discountPrice !== undefined) courseData.discountPrice = courseData.discountPrice ? parseFloat(courseData.discountPrice) : null;
    if (courseData.isPublished !== undefined) courseData.isPublished = courseData.isPublished === 'true' || courseData.isPublished === true;
    if (courseData.isFeatured !== undefined) courseData.isFeatured = courseData.isFeatured === 'true' || courseData.isFeatured === true;
    if (courseData.isMLMEligible !== undefined) courseData.isMLMEligible = courseData.isMLMEligible === 'true' || courseData.isMLMEligible === true;

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
    // Normalize bracket-notation array fields sent by multipart forms
    const normalizeArrayField = (key) => {
      if (updateData[`${key}[]`] !== undefined) {
        const raw = updateData[`${key}[]`];
        updateData[key] = JSON.stringify(Array.isArray(raw) ? raw : [raw]);
        delete updateData[`${key}[]`];
      } else if (Array.isArray(updateData[key])) {
        updateData[key] = JSON.stringify(updateData[key]);
      }
    };
    normalizeArrayField('whatYouLearn');
    normalizeArrayField('requirements');
    normalizeArrayField('tags');

    delete updateData.instructor;
    if (updateData.price !== undefined) updateData.price = parseFloat(updateData.price) || 0;
    if (updateData.discountPrice !== undefined) updateData.discountPrice = updateData.discountPrice ? parseFloat(updateData.discountPrice) : null;
    if (updateData.isPublished !== undefined) updateData.isPublished = updateData.isPublished === 'true' || updateData.isPublished === true;
    if (updateData.isFeatured !== undefined) updateData.isFeatured = updateData.isFeatured === 'true' || updateData.isFeatured === true;
    if (updateData.isMLMEligible !== undefined) updateData.isMLMEligible = updateData.isMLMEligible === 'true' || updateData.isMLMEligible === true;

    const course = await Course.findByIdAndUpdate(req.params.id, updateData, { new: true });
    if (!course) return res.status(404).json({ success: false, message: 'Course not found' });
    res.json({ success: true, course: toPlain(course) });
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
    } else if (req.body.externalUrl) {
      url = req.body.externalUrl;
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
    res.json({ success: true, courses: toPlain(courses) });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = { getCourses, getCourse, getMyCourses, updateProgress, createCourse, updateCourse, uploadMaterial, deleteCourse, getAllCoursesAdmin };
