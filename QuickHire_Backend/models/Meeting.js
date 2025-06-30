const mongoose = require('mongoose');
const meetingSchema = new mongoose.Schema({
  project: { type: mongoose.Schema.Types.ObjectId, ref: 'Project', required: true },
  employer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  jobseeker: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  scheduledBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  scheduledFor: { type: Date, required: true },
  status: { type: String, enum: ['scheduled', 'completed', 'cancelled'], default: 'scheduled' },
  videoRoomId: { type: String }, // for video call room
  createdAt: { type: Date, default: Date.now }
});
module.exports = mongoose.model('Meeting', meetingSchema);