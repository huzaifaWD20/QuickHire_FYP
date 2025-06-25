// controllers/authController.js
const User = require('../models/User');
const EmployerProfile = require('../models/Employer');
const JobSeekerProfile = require('../models/JobSeeker');
const nodemailer = require('nodemailer');
const crypto = require('crypto');

// In-memory OTP storage (in production, use Redis or a database)
const otpStore = {};

// Nodemailer transporter setup - Configure with your email provider
const transporter = nodemailer.createTransport({
  service: 'gmail', // Or your email service provider
  auth: {
    user: process.env.EMAIL_USERNAME || 'your-email@gmail.com',
    pass: process.env.EMAIL_PASSWORD || 'your-email-password'
  }
});

// Generate a random 6-digit OTP
const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

// Send OTP via email
const sendOTPEmail = async (email, otp) => {
  const mailOptions = {
    from: process.env.EMAIL_FROM || 'your-email@gmail.com',
    to: email,
    subject: 'QuickHire - Email Verification OTP',
    text: `Your OTP for QuickHire email verification is: ${otp}. This OTP is valid for 10 minutes.`
  };

  await transporter.sendMail(mailOptions);
};

// @desc    Register user (unverified)
// @route   POST /api/v1/auth/register
// @access  Public
exports.register = async (req, res) => {
  try {
    const { 
      name, 
      email, 
      password, 
      role,
      location,
      // JobSeeker specific fields
      bio,
      skills,
      // Employer specific fields
      companyName,
      linkedinUrl,
      phoneNumber 
    } = req.body;

    // Validate required fields
    if (!name || !email || !password || !role || !location) {
      return res.status(400).json({
        success: false,
        message: 'Please provide name, email, password, role and location'
      });
    }

    // Validate role
    if (role !== 'employer' && role !== 'jobseeker') {
      return res.status(400).json({
        success: false,
        message: 'Role must be either employer or jobseeker'
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'Email already registered'
      });
    }

    // Add isVerified field to user model (defaults to false)
    // You'll need to add this field to your User model
    const user = await User.create({
      name,
      email,
      password,
      role,
      location,
      isVerified: false // User starts as unverified
    });

    // Create profile based on role with provided fields
    if (role === 'employer') {
      await EmployerProfile.create({
        user: user._id,
        companyName: companyName || '',
        linkedinUrl: linkedinUrl || '',
        phoneNumber: phoneNumber || ''
      });
    } else { // jobseeker
      // Convert skills string to array if provided as a string
      let skillsArray = [];
      if (skills) {
        skillsArray = typeof skills === 'string' 
          ? skills.split(',').map(skill => skill.trim()) 
          : skills;
      }

      await JobSeekerProfile.create({
        user: user._id,
        bio: bio || '',
        skills: skillsArray || [],
        phoneNumber: phoneNumber || ''
      });
    }

    // Generate and send OTP for email verification
    const otp = generateOTP();
    
    // Store OTP with expiry time (10 minutes)
    otpStore[email] = {
      otp,
      expiresAt: Date.now() + 10 * 60 * 1000, // 10 minutes
      userId: user._id, // Store user ID with OTP for verification
      attempts: 0
    };

    // Send OTP via email
    await sendOTPEmail(email, otp);

    res.status(201).json({
      success: true,
      message: 'Registration successful. Please verify your email with the OTP sent to your email address.',
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        isVerified: false
      }
    });
  } catch (error) {
    console.error('Registration Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error during registration',
      error: error.message
    });
  }
};

// @desc    Verify email with OTP
// @route   POST /api/v1/auth/verify-email
// @access  Public
exports.verifyEmail = async (req, res) => {
  try {
    const { email, otp } = req.body;

    // Check if email and OTP are provided
    if (!email || !otp) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and OTP'
      });
    }

    // Check if OTP exists for this email
    if (!otpStore[email]) {
      return res.status(400).json({
        success: false,
        message: 'OTP not found or expired. Please register again.'
      });
    }

    // Check if OTP has expired
    if (Date.now() > otpStore[email].expiresAt) {
      delete otpStore[email];
      return res.status(400).json({
        success: false,
        message: 'OTP has expired. Please register again.'
      });
    }

    // Check if OTP matches
    if (otpStore[email].otp !== otp) {
      // Increment attempts
      otpStore[email].attempts += 1;
      
      // If more than 3 failed attempts, invalidate the OTP
      if (otpStore[email].attempts >= 3) {
        delete otpStore[email];
        return res.status(400).json({
          success: false,
          message: 'Too many failed attempts. Please register again.'
        });
      }
      
      return res.status(400).json({
        success: false,
        message: 'Invalid OTP'
      });
    }

    // OTP is valid, update user to verified
    const userId = otpStore[email].userId;
    const user = await User.findById(userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Update user to verified
    user.isVerified = true;
    await user.save();

    // Clear OTP from storage
    delete otpStore[email];

    // Generate JWT token now that user is verified
    const token = user.getSignedJwtToken();

    res.status(200).json({
      success: true,
      message: 'Email verified successfully',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        isVerified: true
      }
    });
  } catch (error) {
    console.error('Email Verification Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error verifying email',
      error: error.message
    });
  }
};

// @desc    Resend verification OTP
// @route   POST /api/v1/auth/resend-verification
// @access  Public
exports.resendVerification = async (req, res) => {
  try {
    const { email } = req.body;

    // Check if email is provided
    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Please provide an email'
      });
    }

    // Find the user
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Check if user is already verified
    if (user.isVerified) {
      return res.status(400).json({
        success: false,
        message: 'Email is already verified'
      });
    }

    // Generate new OTP
    const otp = generateOTP();
    
    // Store OTP with expiry time
    otpStore[email] = {
      otp,
      expiresAt: Date.now() + 10 * 60 * 1000, // 10 minutes
      userId: user._id,
      attempts: 0
    };

    // Send OTP via email
    await sendOTPEmail(email, otp);

    res.status(200).json({
      success: true,
      message: 'Verification OTP resent to your email'
    });
  } catch (error) {
    console.error('Resend Verification Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error sending verification OTP',
      error: error.message
    });
  }
};

// @desc    Login user
// @route   POST /api/v1/auth/login
// @access  Public
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Check if email and password are provided
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password'
      });
    }

    // Find user by email and include password for comparison
    const user = await User.findOne({ email }).select('+password');

    // Check if user exists
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Check if password is correct
    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Check if email is verified
    if (!user.isVerified) {
      // Generate new OTP for verification
      const otp = generateOTP();
      
      otpStore[email] = {
        otp,
        expiresAt: Date.now() + 10 * 60 * 1000, // 10 minutes
        userId: user._id,
        attempts: 0
      };

      // Send OTP via email
      await sendOTPEmail(email, otp);

      return res.status(401).json({
        success: false,
        message: 'Email not verified. We have sent a new verification OTP to your email.',
        requiresVerification: true
      });
    }

    // Generate JWT token
    const token = user.getSignedJwtToken();

    res.status(200).json({
      success: true,
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        isVerified: user.isVerified
      }
    });
  } catch (error) {
    console.error('Login Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error during login',
      error: error.message
    });
  }
};

// @desc    Forgot password - Send OTP
// @route   POST /api/v1/auth/forgot-password
// @access  Public
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    // Check if email is provided
    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Please provide an email'
      });
    }

    // Check if user exists
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Generate OTP
    const otp = generateOTP();
    
    // Store OTP with expiry time (10 minutes)
    otpStore[email] = {
      otp,
      expiresAt: Date.now() + 10 * 60 * 1000, // 10 minutes
      purpose: 'reset-password',
      userId: user._id,
      attempts: 0
    };

    // Send OTP via email
    await sendOTPEmail(email, otp);

    res.status(200).json({
      success: true,
      message: 'Password reset OTP sent to your email'
    });
  } catch (error) {
    console.error('Forgot Password Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error sending reset OTP',
      error: error.message
    });
  }
};

// @desc    Reset password with OTP
// @route   POST /api/v1/auth/reset-password
// @access  Public
exports.resetPassword = async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;

    // Check if all required fields are provided
    if (!email || !otp || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email, OTP and new password'
      });
    }

    // Check if OTP exists for this email
    if (!otpStore[email] || otpStore[email].purpose !== 'reset-password') {
      return res.status(400).json({
        success: false,
        message: 'Please request a password reset OTP first'
      });
    }

    // Check if OTP has expired
    if (Date.now() > otpStore[email].expiresAt) {
      delete otpStore[email];
      return res.status(400).json({
        success: false,
        message: 'OTP has expired. Please request a new one'
      });
    }

    // Check if OTP matches
    if (otpStore[email].otp !== otp) {
      // Increment attempts
      otpStore[email].attempts += 1;
      
      // If more than 3 failed attempts, invalidate the OTP
      if (otpStore[email].attempts >= 3) {
        delete otpStore[email];
        return res.status(400).json({
          success: false,
          message: 'Too many failed attempts. Please request a new OTP'
        });
      }
      
      return res.status(400).json({
        success: false,
        message: 'Invalid OTP'
      });
    }

    // OTP is valid, clear it from storage
    delete otpStore[email];

    // Find user
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Update password
    user.password = newPassword;
    await user.save();

    res.status(200).json({
      success: true,
      message: 'Password reset successful'
    });
  } catch (error) {
    console.error('Reset Password Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error resetting password',
      error: error.message
    });
  }
};

// @desc    Get current logged in user profile
// @route   GET /api/v1/auth/me
// @access  Private (requires authentication)
exports.getMe = async (req, res) => {
  try {
    // req.user is already available from the auth middleware
    const user = req.user;
    
    // Get profile based on user role
    let profile = null;
    if (user.role === 'employer') {
      profile = await EmployerProfile.findOne({ user: user._id });
    } else if (user.role === 'jobseeker') {
      profile = await JobSeekerProfile.findOne({ user: user._id });
    }

    res.status(200).json({
      success: true,
      data: {
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          location: user.location,
          role: user.role,
          isVerified: user.isVerified,
          createdAt: user.createdAt
        },
        profile
      }
    });
  } catch (error) {
    console.error('Get Profile Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching user profile',
      error: error.message
    });
  }
};

exports.updateEmployerProfile = async (req, res) => {
  try {
    const { companyName, linkedinUrl, phoneNumber } = req.body;
    const profile = await EmployerProfile.findOneAndUpdate(
      { user: req.user._id },
      { companyName, linkedinUrl, phoneNumber },
      { new: true, runValidators: true }
    );
    res.status(200).json({ success: true, profile });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error updating employer profile', error: error.message });
  }
};

// @desc    Update jobseeker profile
// @route   PUT /api/v1/auth/jobseeker-profile
// @access  Private
exports.updateJobSeekerProfile = async (req, res) => {
  try {
    const { bio, skills, phoneNumber } = req.body;
    const profile = await JobSeekerProfile.findOneAndUpdate(
      { user: req.user._id },
      { bio, skills, phoneNumber },
      { new: true, runValidators: true }
    );
    res.status(200).json({ success: true, profile });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error updating jobseeker profile', error: error.message });
  }
};

// @desc    Update user details (name, email)
// @route   PUT /api/v1/auth/updatedetails
// @access  Private
exports.updateDetails = async (req, res) => {
  try {
    const { name, email } = req.body;
    
    const updateFields = {};
    if (name) updateFields.name = name;
    
    // If email is being changed, set isVerified to false and send new verification OTP
    let emailChanged = false;
    if (email && email !== req.user.email) {
      // Check if new email already exists
      const existingUser = await User.findOne({ email });
      if (existingUser) {
        return res.status(400).json({
          success: false,
          message: 'Email already in use'
        });
      }
      
      updateFields.email = email;
      updateFields.isVerified = false;
      emailChanged = true;
    }

    // Update user
    const user = await User.findByIdAndUpdate(
      req.user._id,
      updateFields,
      { new: true, runValidators: true }
    );

    // If email changed, send verification OTP
    if (emailChanged) {
      const otp = generateOTP();
      
      otpStore[email] = {
        otp,
        expiresAt: Date.now() + 10 * 60 * 1000, // 10 minutes
        userId: user._id,
        attempts: 0
      };

      // Send OTP via email
      await sendOTPEmail(email, otp);
    }

    res.status(200).json({
      success: true,
      message: emailChanged ? 'Details updated. Please verify your new email.' : 'Details updated successfully',
      data: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        isVerified: user.isVerified
      },
      emailChanged
    });
  } catch (error) {
    console.error('Update Details Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating user details',
      error: error.message
    });
  }
};

// @desc    Update password
// @route   PUT /api/v1/auth/updatepassword
// @access  Private
exports.updatePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    // Check if passwords are provided
    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Please provide current and new password'
      });
    }

    // Get user with password
    const user = await User.findById(req.user._id).select('+password');

    // Check if current password matches
    const isMatch = await user.matchPassword(currentPassword);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }

    // Update password
    user.password = newPassword;
    await user.save();

    // Generate new token
    const token = user.getSignedJwtToken();

    res.status(200).json({
      success: true,
      message: 'Password updated successfully',
      token
    });
  } catch (error) {
    console.error('Update Password Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating password',
      error: error.message
    });
  }
};

// @desc    Logout user (clear cookie)
// @route   GET /api/v1/auth/logout
// @access  Private
exports.logout = (req, res) => {
  // Note: For token-based auth, the client should remove the token
  // This endpoint is mainly for clarity and consistency
  res.status(200).json({
    success: true,
    message: 'Logged out successfully'
  });
};