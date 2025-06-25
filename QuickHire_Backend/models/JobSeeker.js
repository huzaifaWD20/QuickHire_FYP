// models/JobSeekerProfile.js
const mongoose = require('mongoose');

const JobSeekerProfileSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  bio: {
    type: String,
    required: [true, 'Please add a small bio']
  },
  skills: [{
    type: String,
    required: [true, 'Please add at least one skill']
  }],
  phoneNumber: {
    type: String
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('JobSeekerProfile', JobSeekerProfileSchema);