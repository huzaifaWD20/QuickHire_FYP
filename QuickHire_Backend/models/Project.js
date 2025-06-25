// models/Project.js
const mongoose = require('mongoose');

const ProjectSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Please add a project title'],
    trim: true,
    maxlength: [100, 'Title cannot be more than 100 characters']
  },
  description: {
    type: String,
    required: [true, 'Please add a description'],
    maxlength: [2000, 'Description cannot be more than 2000 characters']
  },
  skills: {
    type: [String],
    required: [true, 'Please add required skills']
  },
  location: {
    type: String,
    required: [true, 'Please add a location']
  },
  workType: {
    type: String,
    enum: ['remote', 'onsite', 'hybrid'],
    default: 'remote'
  },
  // Optional GeoJSON location data for more precise location matching
//   geoLocation: {
//     type: {
//       type: String,
//       enum: ['Point'],
//     },
//     coordinates: {
//       type: [Number],
//       index: '2dsphere'
//     }
//   },
  budget: {
    type: Number,
    required: [true, 'Please add a budget']
  },
  duration: {
    type: String,
    required: [true, 'Please specify project duration']
  },
  employer: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
    required: true
  },
  status: {
    type: String,
    enum: ['open', 'in-progress', 'completed', 'cancelled'],
    default: 'open'
  },
  // Store job seekers who have accepted the project
  acceptedBy: [
    {
      jobSeeker: {
        type: mongoose.Schema.ObjectId,
        ref: 'User'
      },
      status: {
        type: String,
        enum: ['pending', 'accepted', 'rejected'],
        default: 'pending'
      },
      acceptedAt: {
        type: Date,
        default: Date.now
      }
    }
  ],
  // Store job seekers who swiped right (interested)
  interestedUsers: [
    {
      user: {
        type: mongoose.Schema.ObjectId,
        ref: 'User',
        required: true
      },
      swipedAt: {
        type: Date,
        default: Date.now
      }
    }
  ],
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Create index on skills for better query performance
ProjectSchema.index({ skills: 1 });
// Create index on location for better query performance
ProjectSchema.index({ location: 'text' });

module.exports = mongoose.model('Project', ProjectSchema);
