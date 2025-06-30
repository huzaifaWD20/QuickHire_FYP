const express = require('express');
const {
  createReview,
  getReviewsForUser,
  getReviewsForProject,
  getPendingReviews,
  approveReview,
  deleteReview
} = require('../controllers/reviewController');

const { protect, adminOnly } = require('../middlewares/auth');

const router = express.Router();

// Public routes
router.get('/user/:id', getReviewsForUser);
router.get('/project/:id', getReviewsForProject);

// Protected routes
router.post('/', protect, createReview);
router.get('/pending', getPendingReviews);
router.put('/:id/approve', approveReview);
router.delete('/:id', deleteReview);

module.exports = router;