const mongoose = require('mongoose');

const ReviewSchema = new mongoose.Schema({
  project: { type: mongoose.Schema.Types.ObjectId, ref: 'Project', required: true },
  reviewer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, // employer
  reviewee: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, // jobseeker
  rating: { type: Number, min: 1, max: 5, required: true },
  comment: { type: String, maxlength: 2000 },
  approved: { type: Boolean, default: false }, // admin approval
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Review', ReviewSchema);