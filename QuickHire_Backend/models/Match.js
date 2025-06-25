// models/Match.js
const mongoose = require('mongoose');

const MatchSchema = new mongoose.Schema({
  job: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Job',
    required: true
  },
  employer: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  jobSeeker: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  employerAccepted: {
    type: Boolean,
    default: false
  },
  jobSeekerAccepted: {
    type: Boolean,
    default: false
  },
  matched: {
    type: Boolean,
    default: false
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Set up compound index to ensure uniqueness of job-jobSeeker pairs
//MatchSchema.index({ job: 1, jobSeeker: 1 }, { unique: true });

module.exports = mongoose.model('Match', MatchSchema);