const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth');
const Meeting = require('../models/Meeting');

// Schedule a meeting
router.post('/schedule', protect, async (req, res) => {
  try {
    const { project, employer, jobseeker, scheduledFor } = req.body;
    const meeting = await Meeting.create({
      project,
      employer,
      jobseeker,
      scheduledBy: req.user._id,
      scheduledFor,
      videoRoomId: `${project}-${employer}-${jobseeker}-${Date.now()}`
    });
    res.status(201).json({ success: true, data: meeting });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Get meetings for a user
router.get('/my', protect, async (req, res) => {
  try {
    const meetings = await Meeting.find({
      $or: [{ employer: req.user._id }, { jobseeker: req.user._id }]
    }).sort({ scheduledFor: -1 });
    res.json({ success: true, data: meetings });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;