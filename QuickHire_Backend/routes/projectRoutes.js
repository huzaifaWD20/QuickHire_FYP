// routes/projectRoutes.js
const express = require('express');
const {
  createProject,
  getProjects,
  getProject,
  updateProject,
  getMatchedProjects,
  acceptProject,
  getProjectApplicants,
  updateApplicantStatus,
  getEmployerProjects,
  getAcceptedProjects,  
  getJobSeekerProfile,
  markProjectAsCompleted
} = require('../controllers/projectController');

const { protect, authorize } = require('../middlewares/auth');

const router = express.Router();

// Public routes
router.get('/', getProjects);
router.get('/:id', getProject);

// Protected routes
router.post('/', protect, authorize('employer'), createProject);
router.put('/:id', protect, authorize('employer'), updateProject);
router.get('/matches/find', protect, authorize('jobseeker'), getMatchedProjects);
router.post('/:id/accept', protect, authorize('jobseeker'), acceptProject);
router.get('/:id/applicants', protect, authorize('employer'), getProjectApplicants);
router.put('/:id/applicants/:applicantId', protect, authorize('employer'), updateApplicantStatus);
router.get('/employer/list', protect, authorize('employer'), getEmployerProjects);
router.get('/jobseeker/accepted', protect, authorize('jobseeker'), getAcceptedProjects);
router.get('/jobseeker-profile/:userId', protect, authorize('employer'), getJobSeekerProfile);
router.put('/:id/complete', protect, authorize('jobseeker'), markProjectAsCompleted);

module.exports = router;