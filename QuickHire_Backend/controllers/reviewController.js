const Review = require('../models/Review');
const Project = require('../models/Project');
const User = require('../models/User');

// Create a review (employer or jobseeker)
exports.createReview = async (req, res) => {
  try {
    const { project, reviewee, rating, comment } = req.body;
    const reviewer = req.user.id;

    // Check project exists and is completed
    const proj = await Project.findById(project);
    if (!proj || proj.status !== 'completed') {
      return res.status(400).json({ success: false, message: 'Project not completed or not found' });
    }

    // Prevent duplicate reviews
    const existing = await Review.findOne({ project, reviewer });
    if (existing) {
      return res.status(400).json({ success: false, message: 'You have already reviewed this project' });
    }

    // Only allow employer or jobseeker who participated
    if (
      !(proj.employer.toString() === reviewer || proj.acceptedBy.some(a => a.jobSeeker.toString() === reviewer))
    ) {
      return res.status(403).json({ success: false, message: 'Not authorized to review this project' });
    }

    const review = await Review.create({
      project,
      reviewer,
      reviewee,
      rating,
      comment
    });

    res.status(201).json({ success: true, data: review, message: 'Review submitted for admin approval' });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

// Get reviews for a user (jobseeker or employer)
exports.getReviewsForUser = async (req, res) => {
  try {
    const userId = req.params.id;
    const reviews = await Review.find({ reviewee: userId, approved: true })
      .populate('reviewer', 'name')
      .populate('project', 'title');
    res.status(200).json({ success: true, data: reviews });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

// Get reviews for a project (for UI to check if reviewed)
exports.getReviewsForProject = async (req, res) => {
  try {
    const projectId = req.params.id;
    const reviews = await Review.find({ project: projectId })
      .populate('reviewer', 'name')
      .populate('reviewee', 'name');
    res.status(200).json({ success: true, data: reviews });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

// Admin: get pending reviews
exports.getPendingReviews = async (req, res) => {
  try {
    const reviews = await Review.find({ approved: false })
      .populate('reviewer', 'name')
      .populate('reviewee', 'name')
      .populate('project', 'title');
    res.status(200).json({ success: true, data: reviews });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

// Admin: approve review
exports.approveReview = async (req, res) => {
  try {
    const review = await Review.findByIdAndUpdate(
      req.params.id,
      { approved: true },
      { new: true }
    );
    res.status(200).json({ success: true, data: review });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

// Admin: delete review
exports.deleteReview = async (req, res) => {
  try {
    await Review.findByIdAndDelete(req.params.id);
    res.status(200).json({ success: true, message: 'Review deleted' });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};