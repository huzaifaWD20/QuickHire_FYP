// models/EmployerProfile.js
const mongoose = require('mongoose');

const EmployerProfileSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  companyName: {
    type: String,
    required: [true, 'Please add a company name']
  },
  linkedinUrl: {
    type: String,
    required: [true, 'Please add your linkedin URL']
  },
  // website: {
  //   type: String
  // },
  phoneNumber: {
    type: String
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('EmployerProfile', EmployerProfileSchema);