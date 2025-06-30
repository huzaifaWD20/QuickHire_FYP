// controllers/projectController.js
const Project = require('../models/Project');
const JobSeekerProfile = require('../models/JobSeeker');
const User = require('../models/User');

// @desc    Create a new project
// @route   POST /api/v1/projects
// @access  Private (Employers only)
exports.createProject = async (req, res) => {
  try {
    // Check if user is an employer
    if (req.user.role !== 'employer') {
      return res.status(403).json({
        success: false,
        message: 'Only employers can create projects'
      });
    }

    // Add employer ID to project data
    req.body.employer = req.user.id;

    // Convert skills string to array if it's a string
    if (req.body.skills && typeof req.body.skills === 'string') {
      req.body.skills = req.body.skills.split(',').map(skill => skill.trim());
    }

    // Create project
    const project = await Project.create(req.body);

    res.status(201).json({
      success: true,
      data: project
    });
  } catch (error) {
    console.error('Create Project Error:', error);
    res.status(500).json({
      success: false,
      message: 'Could not create project',
      error: error.message
    });
  }
};

// @desc    Get all projects
// @route   GET /api/v1/projects
// @access  Public
exports.getProjects = async (req, res) => {
  try {
    const projects = await Project.find().populate({
      path: 'employer',
      select: 'name'
    });

    res.status(200).json({
      success: true,
      count: projects.length,
      data: projects
    });
  } catch (error) {
    console.error('Get Projects Error:', error);
    res.status(500).json({
      success: false,
      message: 'Could not fetch projects',
      error: error.message
    });
  }
};

// @desc    Get project by ID
// @route   GET /api/v1/projects/:id
// @access  Public
exports.getProject = async (req, res) => {
  try {
    const project = await Project.findById(req.params.id).populate({
      path: 'employer',
      select: 'name'
    }).populate({
      path: 'acceptedBy.jobSeeker',
      select: 'name email'
    });

    if (!project) {
      return res.status(404).json({
        success: false,
        message: 'Project not found'
      });
    }

    res.status(200).json({
      success: true,
      data: project
    });
  } catch (error) {
    console.error('Get Project Error:', error);
    res.status(500).json({
      success: false,
      message: 'Could not fetch project',
      error: error.message
    });
  }
};

// @desc    Update project details
// @route   PUT /api/v1/projects/:id
// @access  Private (Project owner/employer only)
exports.updateProject = async (req, res) => {
    try {
      let project = await Project.findById(req.params.id);
      
      if (!project) {
        return res.status(404).json({
          success: false,
          message: 'Project not found'
        });
      }
      
      // Check if user is the project owner
      if (project.employer.toString() !== req.user.id) {
        return res.status(403).json({
          success: false,
          message: 'You are not authorized to update this project'
        });
      }
      
      // Convert skills string to array if it's a string
      if (req.body.skills && typeof req.body.skills === 'string') {
        req.body.skills = req.body.skills.split(',').map(skill => skill.trim());
      }
      
      // Don't allow changing certain fields if the project already has applicants
      if (project.acceptedBy && project.acceptedBy.length > 0) {
        const safeFields = ['title', 'description', 'budget', 'duration', 'status'];
        const updateFields = Object.keys(req.body);
        
        const unsafeUpdate = updateFields.some(field => !safeFields.includes(field));
        
        if (unsafeUpdate) {
          return res.status(400).json({
            success: false,
            message: 'Cannot update core project details (skills, location) after receiving applications'
          });
        }
      }
      
      // Update project
      project = await Project.findByIdAndUpdate(req.params.id, req.body, {
        new: true,
        runValidators: true
      });
      
      res.status(200).json({
        success: true,
        data: project,
        message: 'Project updated successfully'
      });
    } catch (error) {
      console.error('Update Project Error:', error);
      res.status(500).json({
        success: false,
        message: 'Could not update project',
        error: error.message
      });
    }
  };

// @desc    Get matched projects for job seeker
// @route   GET /api/v1/projects/matches
// @access  Private (Job seekers only)
exports.getMatchedProjects = async (req, res) => {
    try {
      // Check if user is a job seeker
      if (req.user.role !== 'jobseeker') {
        return res.status(403).json({
          success: false,
          message: 'Only job seekers can access project matches'
        });
      }
      
      // Get job seeker profile to find skills
      const jobSeekerProfile = await JobSeekerProfile.findOne({ user: req.user.id });
      
      if (!jobSeekerProfile) {
        return res.status(404).json({
          success: false,
          message: 'Job seeker profile not found'
        });
      }
      
      // Get skills from job seeker profile, but location from the user object
      const { skills } = jobSeekerProfile;
      const { location } = req.user; // Get location from user object instead
      
      // Query params for filtering
      const { locationPreference } = req.query;
      
      // Base query for open projects only
      let query = { status: 'open' };
      
      // Match by location if locationPreference is true
      if (locationPreference === 'true' && location) {
        // Use exact location match (case-insensitive)
        query.location = new RegExp(`^${location}$`, 'i');
      }
      
      // Find all open projects that match the query
      let projects = await Project.find(query)
        .populate({
          path: 'employer',
          select: 'name'
        });
      
      // Calculate skill match score for all projects
      let matchedProjects = projects.map(project => {
        // Calculate match score based on skills overlap
        let matchScore = 0;
        let matchedSkills = [];
        
        if (skills && skills.length > 0 && project.skills && project.skills.length > 0) {
          const userSkillsSet = new Set(skills.map(s => s.toLowerCase()));
          
          project.skills.forEach(skill => {
            const lowerSkill = skill.toLowerCase();
            if (userSkillsSet.has(lowerSkill)) {
              matchScore++;
              matchedSkills.push(skill);
            }
          });
          
          // Convert to percentage based on total required skills
          matchScore = (matchScore / project.skills.length) * 100;
        }
        
        // Check if job seeker has already accepted this project
        const alreadyAccepted = project.acceptedBy.some(
          item => item.jobSeeker.toString() === req.user.id
        );
        
        return {
          ...project.toObject(),
          matchScore: Math.round(matchScore),
          matchedSkills,
          alreadyAccepted
        };
      });
      
      // Filter out projects with zero skill matches
      matchedProjects = matchedProjects.filter(project => project.matchScore > 0);
      
      // Sort by match score (highest first)
      matchedProjects.sort((a, b) => b.matchScore - a.matchScore);
      
      res.status(200).json({
        success: true,
        count: matchedProjects.length,
        data: matchedProjects
      });
    } catch (error) {
      console.error('Get Matched Projects Error:', error);
      res.status(500).json({
        success: false,
        message: 'Could not fetch matched projects',
        error: error.message
      });
    }
  };

// @desc    Accept a project (for job seekers)
// @route   POST /api/v1/projects/:id/accept
// @access  Private (Job seekers only)
exports.acceptProject = async (req, res) => {
  try {
    // Check if user is a job seeker
    if (req.user.role !== 'jobseeker') {
      return res.status(403).json({
        success: false,
        message: 'Only job seekers can accept projects'
      });
    }
    
    const project = await Project.findById(req.params.id);
    
    if (!project) {
      return res.status(404).json({
        success: false,
        message: 'Project not found'
      });
    }
    
    // Check if project is still open
    if (project.status !== 'open') {
      return res.status(400).json({
        success: false,
        message: 'This project is no longer accepting applications'
      });
    }
    
    // Check if job seeker has already accepted this project
    const alreadyAccepted = project.acceptedBy.some(
      item => item.jobSeeker.toString() === req.user.id
    );
    
    if (alreadyAccepted) {
      return res.status(400).json({
        success: false,
        message: 'You have already accepted this project'
      });
    }
    
    // Add job seeker to acceptedBy array
    project.acceptedBy.push({
      jobSeeker: req.user.id,
      status: 'pending',
      acceptedAt: Date.now()
    });
    
    await project.save();
    
    res.status(200).json({
      success: true,
      message: 'Project accepted successfully',
      data: project
    });
  } catch (error) {
    console.error('Accept Project Error:', error);
    res.status(500).json({
      success: false,
      message: 'Could not accept project',
      error: error.message
    });
  }
};

// @desc    Get job seekers who accepted a project (for employers)
// @route   GET /api/v1/projects/:id/applicants
// @access  Private (Project owner only)
exports.getProjectApplicants = async (req, res) => {
  try {
    const project = await Project.findById(req.params.id);
    
    if (!project) {
      return res.status(404).json({
        success: false,
        message: 'Project not found'
      });
    }
    
    // Check if the requesting user is the project owner
    if (project.employer.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to view applicants for this project'
      });
    }
    
    // Populate job seeker details
    const populatedProject = await Project.findById(req.params.id)
      .populate({
        path: 'acceptedBy.jobSeeker',
        select: 'name email'
      });
    
    // Get detailed profiles for each job seeker
    const applicants = await Promise.all(
      populatedProject.acceptedBy.map(async (applicant) => {
        const profile = await JobSeekerProfile.findOne({ 
          user: applicant.jobSeeker._id 
        });
        
        return {
          id: applicant.jobSeeker._id,
          name: applicant.jobSeeker.name,
          email: applicant.jobSeeker.email,
          status: applicant.status,
          acceptedAt: applicant.acceptedAt,
          profile: profile || {}
        };
      })
    );
    
    res.status(200).json({
      success: true,
      count: applicants.length,
      data: applicants
    });
  } catch (error) {
    console.error('Get Project Applicants Error:', error);
    res.status(500).json({
      success: false,
      message: 'Could not fetch project applicants',
      error: error.message
    });
  }
};

// @desc    Update applicant status (accept/reject)
// @route   PUT /api/v1/projects/:id/applicants/:applicantId
// @access  Private (Project owner only)
exports.updateApplicantStatus = async (req, res) => {
  try {
    const { status } = req.body;
    
    // Validate status
    if (!status || !['accepted', 'rejected'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid status (accepted or rejected)'
      });
    }
    
    const project = await Project.findById(req.params.id);
    
    if (!project) {
      return res.status(404).json({
        success: false,
        message: 'Project not found'
      });
    }
    
    // Check if the requesting user is the project owner
    if (project.employer.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to update applicants for this project'
      });
    }
    
    // Find the applicant in the project
    const applicantIndex = project.acceptedBy.findIndex(
      item => item.jobSeeker.toString() === req.params.applicantId
    );
    
    if (applicantIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'Applicant not found for this project'
      });
    }
    
    // Update the applicant status
    project.acceptedBy[applicantIndex].status = status;
    project.markModified('acceptedBy');
    await project.save();
    
    res.status(200).json({
      success: true,
      message: `Applicant status updated to ${status}`,
      data: project.acceptedBy[applicantIndex]
    });
  } catch (error) {
    console.error('Update Applicant Status Error:', error);
    res.status(500).json({
      success: false,
      message: 'Could not update applicant status',
      error: error.message
    });
  }
};

// @desc    Get projects created by the employer
// @route   GET /api/v1/projects/employer
// @access  Private (Employers only)
exports.getEmployerProjects = async (req, res) => {
  try {
    if (req.user.role !== 'employer') {
      return res.status(403).json({
        success: false,
        message: 'Only employers can access their projects'
      });
    }

    // Populate acceptedBy.jobSeeker with name and email
    const projects = await Project.find({ employer: req.user.id })
      .populate({
        path: 'acceptedBy.jobSeeker',
        select: 'name email'
      });

    res.status(200).json({
      success: true,
      count: projects.length,
      data: projects
    });
  } catch (error) {
    console.error('Get Employer Projects Error:', error);
    res.status(500).json({
      success: false,
      message: 'Could not fetch employer projects',
      error: error.message
    });
  }
};

// @desc    Get projects accepted by the job seeker
// @route   GET /api/v1/projects/jobseeker
// @access  Private (Job seekers only)
exports.getAcceptedProjects = async (req, res) => {
  try {
    // Check if user is a job seeker
    if (req.user.role !== 'jobseeker') {
      return res.status(403).json({
        success: false,
        message: 'Only job seekers can access their accepted projects'
      });
    }
    
    // Find projects where this job seeker is in the acceptedBy array
    const projects = await Project.find({
      'acceptedBy.jobSeeker': req.user.id
    }).populate({
      path: 'employer',
      select: 'name'
    });
    
    res.status(200).json({
      success: true,
      count: projects.length,
      data: projects
    });
  } catch (error) {
    console.error('Get Accepted Projects Error:', error);
    res.status(500).json({
      success: false,
      message: 'Could not fetch accepted projects',
      error: error.message
    });
  }
};

// @desc    Get jobseeker profile by userId
// @route   GET /api/v1/jobseeker-profile/:userId
// @access  Private (Employer or Jobseeker)
exports.getJobSeekerProfile = async (req, res) => {
  try {
    const user = await User.findById(req.params.userId).select('name email role');
    if (!user || user.role !== 'jobseeker') {
      return res.status(404).json({ success: false, message: 'Jobseeker not found' });
    }
    const profile = await JobSeekerProfile.findOne({ user: req.params.userId });
    if (!profile) {
      return res.status(404).json({ success: false, message: 'Profile not found' });
    }
    res.status(200).json({
      success: true,
      data: {
        name: user.name,
        email: user.email,
        bio: profile.bio,
        skills: profile.skills,
        phoneNumber: profile.phoneNumber,
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Could not fetch profile', error: error.message });
  }
};

// @desc    Mark project as completed by jobseeker
// @route   PUT /api/v1/projects/:id/complete
// @access  Private (Jobseeker only, must be accepted and in-progress)
// exports.markProjectAsCompleted = async (req, res) => {
//   try {
//     if (req.user.role !== 'jobseeker') {
//       return res.status(403).json({ success: false, message: 'Only jobseekers can mark as completed' });
//     }
//     const project = await Project.findById(req.params.id);
//     console.log(project);
//     if (!project) {
//       return res.status(404).json({ success: false, message: 'Project not found' });
//     }
//     // Check if jobseeker is accepted and status is in-progress
//     const accepted = project.acceptedBy.find(
//       a => a.jobSeeker.toString() === req.user.id && a.status === 'accepted'
//     );
//     console.log(accepted);
//     if (!accepted || project.status !== 'in-progress') {
//       return res.status(400).json({ success: false, message: 'You cannot mark this project as completed' });
//     }
//     // Mark both acceptedBy and project status as completed
//     accepted.status = 'completed';
//     project.status = 'completed'; // <-- This line marks the whole project as completed
//     project.markModified('acceptedBy');
//     console.log(project);
//     await project.save();
//     console.log(project);
//     res.status(200).json({ success: true, message: 'Project marked as completed', data: project });
//   } catch (error) {
//     res.status(500).json({ success: false, message: 'Could not mark as completed', error: error.message });
//   }
// };

exports.markProjectAsCompleted = async (req, res) => {
  try {
    if (req.user.role !== 'jobseeker') {
      return res.status(403).json({ success: false, message: 'Only jobseekers can mark as completed' });
    }

    // Find the project and ensure it's in-progress and the user is accepted
    const project = await Project.findOne({
      _id: req.params.id,
      status: 'in-progress',
      'acceptedBy.jobSeeker': req.user.id,
      'acceptedBy.status': 'accepted'
    });

    if (!project) {
      return res.status(400).json({ success: false, message: 'You cannot mark this project as completed' });
    }

    // Update both acceptedBy.$.status and project.status
    const updated = await Project.findOneAndUpdate(
      {
        _id: req.params.id,
        'acceptedBy.jobSeeker': req.user.id,
        'acceptedBy.status': 'accepted'
      },
      {
        $set: {
          'acceptedBy.$.status': 'completed',
          status: 'completed'
        }
      },
      { new: true }
    );

    if (!updated) {
      return res.status(500).json({ success: false, message: 'Failed to update project' });
    }

    res.status(200).json({ success: true, message: 'Project marked as completed', data: updated });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Could not mark as completed', error: error.message });
  }
};