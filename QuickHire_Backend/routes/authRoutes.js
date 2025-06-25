// routes/auth.js
const express = require('express');
const {
  register,
  verifyEmail,
  resendVerification,
  login,
  getMe,
  forgotPassword,
  resetPassword,
  updateDetails,
  updatePassword,
  updateEmployerProfile,
  updateJobSeekerProfile,
  logout
} = require('../controllers/authController');
const { protect } = require('../middlewares/auth');

const router = express.Router();

// Public routes
router.post('/register', register);
router.post('/verify-email', verifyEmail);
router.post('/resend-verification', resendVerification);
router.post('/login', login);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);

// Protected routes
router.get('/me', protect, getMe);
router.put('/updatedetails', protect, updateDetails);
router.put('/employer-profile', protect, updateEmployerProfile);
router.put('/jobseeker-profile', protect, updateJobSeekerProfile);
router.put('/updatepassword', protect, updatePassword);
router.get('/logout', protect, logout);

module.exports = router;