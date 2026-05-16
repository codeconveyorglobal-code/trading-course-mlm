const express = require('express');
const router = express.Router();
const User = require('../models/User');
const { protect } = require('../middleware/auth');

// Get public profile by referral code
router.get('/profile/:referralCode', async (req, res) => {
  try {
    const user = await User.findOne({ referralCode: req.params.referralCode })
      .select('name profilePicture rank referralCode');
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    res.json({ success: true, user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
