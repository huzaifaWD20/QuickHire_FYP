// controllers/messageController.js
const Message = require('../models/Message');
const Project = require('../models/Project');
const { getUserSocket } = require('../config/socket');

// Helper to check if user is allowed to access a project's messages
const canAccessProjectMessages = async (userId, projectId) => {
  const project = await Project.findById(projectId);
  
  if (!project) {
    return false;
  }
  
  // Check if user is the employer
  if (project.employer.toString() === userId) {
    return true;
  }
  
  // Check if user is an accepted job seeker
  const isAcceptedApplicant = project.acceptedBy.some(
    applicant => applicant.jobSeeker.toString() === userId && applicant.status === 'accepted'
  );
  
  return isAcceptedApplicant;
};

// @desc    Send a new message
// @route   POST /api/v1/messages
// @access  Private
exports.sendMessage = async (req, res) => {
  try {
    const { receiver, content, project } = req.body;
    
    // Validate input
    if (!receiver || !content || !project) {
      return res.status(400).json({
        success: false,
        message: 'Please provide receiver, content and project ID'
      });
    }
    
    // Check if sender has access to this project
    const hasAccess = await canAccessProjectMessages(req.user.id, project);
    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to send messages for this project'
      });
    }
    
    // Check if receiver has access to this project
    const receiverHasAccess = await canAccessProjectMessages(receiver, project);
    if (!receiverHasAccess) {
      return res.status(400).json({
        success: false,
        message: 'Receiver does not have access to this project'
      });
    }
    
    // Create message
    const message = await Message.create({
      sender: req.user.id,
      receiver,
      content,
      project
    });
    
    // Populate sender details for response
    const populatedMessage = await Message.findById(message._id)
      .populate({
        path: 'sender',
        select: 'name role'
      })
      .populate({
        path: 'receiver',
        select: 'name role'
      });
    
    // Notify the receiver if they're online (via socket)
    const receiverSocket = getUserSocket(receiver);
    if (receiverSocket) {
      receiverSocket.emit('new_message', populatedMessage);
    }
    
    res.status(201).json({
      success: true,
      data: populatedMessage
    });
  } catch (error) {
    console.error('Send Message Error:', error);
    res.status(500).json({
      success: false,
      message: 'Could not send message',
      error: error.message
    });
  }
};

// @desc    Get conversation with a user about a project
// @route   GET /api/v1/messages/conversation/:userId/:projectId
// @access  Private
exports.getConversation = async (req, res) => {
  try {
    const { userId, projectId } = req.params;
    
    // Check if user has access to this project
    const hasAccess = await canAccessProjectMessages(req.user.id, projectId);
    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to view messages for this project'
      });
    }
    
    // Get messages between the two users for this project
    const messages = await Message.find({
      project: projectId,
      $or: [
        { sender: req.user.id, receiver: userId },
        { sender: userId, receiver: req.user.id }
      ]
    })
    .sort({ createdAt: 1 })
    .populate({
      path: 'sender',
      select: 'name role'
    })
    .populate({
      path: 'receiver',
      select: 'name role'
    });
    
    // Mark any unread messages as read
    await Message.updateMany(
      {
        project: projectId,
        sender: userId,
        receiver: req.user.id,
        read: false
      },
      { read: true }
    );
    
    res.status(200).json({
      success: true,
      count: messages.length,
      data: messages
    });
  } catch (error) {
    console.error('Get Conversation Error:', error);
    res.status(500).json({
      success: false,
      message: 'Could not retrieve conversation',
      error: error.message
    });
  }
};

// @desc    Get all conversations for user (grouped by project)
// @route   GET /api/v1/messages/conversations
// @access  Private
exports.getConversations = async (req, res) => {
  try {
    // Get all projects the user has access to
    const employerProjects = await Project.find({ employer: req.user.id });
    
    const acceptedProjects = await Project.find({
      'acceptedBy.jobSeeker': req.user.id,
      'acceptedBy.status': 'accepted'
    });
    
    const allProjectIds = [
      ...employerProjects.map(p => p._id),
      ...acceptedProjects.map(p => p._id)
    ];
    
    // Find the latest message for each project-user pair
    const conversations = await Message.aggregate([
      {
        $match: {
          project: { $in: allProjectIds },
          $or: [
            { sender: req.user._id },
            { receiver: req.user._id }
          ]
        }
      },
      {
        $sort: { createdAt: -1 }
      },
      {
        $group: {
          _id: {
            project: '$project',
            otherUser: {
              $cond: [
                { $eq: ['$sender', req.user._id] },
                '$receiver',
                '$sender'
              ]
            }
          },
          lastMessage: { $first: '$$ROOT' },
          unreadCount: {
            $sum: {
              $cond: [
                { $and: [
                  { $eq: ['$receiver', req.user._id] },
                  { $eq: ['$read', false] }
                ]},
                1,
                0
              ]
            }
          }
        }
      },
      {
        $lookup: {
          from: 'users',
          localField: '_id.otherUser',
          foreignField: '_id',
          as: 'otherUserDetails'
        }
      },
      {
        $lookup: {
          from: 'projects',
          localField: '_id.project',
          foreignField: '_id',
          as: 'projectDetails'
        }
      },
      {
        $project: {
          _id: 0,
          project: '$_id.project',
          otherUser: '$_id.otherUser',
          otherUserName: { $arrayElemAt: ['$otherUserDetails.name', 0] },
          otherUserRole: { $arrayElemAt: ['$otherUserDetails.role', 0] },
          projectTitle: { $arrayElemAt: ['$projectDetails.title', 0] },
          lastMessage: '$lastMessage.content',
          lastMessageTime: '$lastMessage.createdAt',
          unreadCount: '$unreadCount'
        }
      },
      {
        $sort: { lastMessageTime: -1 }
      }
    ]);
    
    res.status(200).json({
      success: true,
      count: conversations.length,
      data: conversations
    });
  } catch (error) {
    console.error('Get Conversations Error:', error);
    res.status(500).json({
      success: false,
      message: 'Could not retrieve conversations',
      error: error.message
    });
  }
};

// @desc    Mark messages as read
// @route   PUT /api/v1/messages/read
// @access  Private
exports.markAsRead = async (req, res) => {
  try {
    const { messageIds } = req.body;
    
    if (!messageIds || !Array.isArray(messageIds)) {
      return res.status(400).json({
        success: false,
        message: 'Please provide an array of message IDs'
      });
    }
    
    // Find messages that are sent to the current user and are unread
    const messages = await Message.find({
      _id: { $in: messageIds },
      receiver: req.user.id,
      read: false
    });
    
    if (messages.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No valid unread messages found'
      });
    }
    
    // Update all matching messages
    await Message.updateMany(
      {
        _id: { $in: messageIds },
        receiver: req.user.id,
        read: false
      },
      { read: true }
    );
    
    // Get the senders to notify
    const senderIds = [...new Set(messages.map(msg => msg.sender.toString()))];
    
    // Notify senders that messages were read (via socket)
    senderIds.forEach(senderId => {
      const senderSocket = getUserSocket(senderId);
      if (senderSocket) {
        const senderMessages = messages
          .filter(msg => msg.sender.toString() === senderId)
          .map(msg => msg._id);
          
        senderSocket.emit('messages_read', {
          reader: req.user.id,
          messageIds: senderMessages
        });
      }
    });
    
    res.status(200).json({
      success: true,
      message: 'Messages marked as read',
      count: messages.length
    });
  } catch (error) {
    console.error('Mark as Read Error:', error);
    res.status(500).json({
      success: false,
      message: 'Could not mark messages as read',
      error: error.message
    });
  }
};

// @desc    Delete a message
// @route   DELETE /api/v1/messages/:id
// @access  Private (sender only)
exports.deleteMessage = async (req, res) => {
  try {
    const message = await Message.findById(req.params.id);
    
    if (!message) {
      return res.status(404).json({
        success: false,
        message: 'Message not found'
      });
    }
    
    // Check if the requesting user is the sender of the message
    if (message.sender.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to delete this message'
      });
    }
    
    // Check if message was sent within the last 10 minutes
    const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000);
    if (message.createdAt < tenMinutesAgo) {
      return res.status(400).json({
        success: false,
        message: 'Messages can only be deleted within 10 minutes of sending'
      });
    }
    
    await message.remove();
    
    // Notify the receiver if they're online (via socket)
    const receiverSocket = getUserSocket(message.receiver.toString());
    if (receiverSocket) {
      receiverSocket.emit('message_deleted', {
        messageId: message._id,
        project: message.project
      });
    }
    
    res.status(200).json({
      success: true,
      message: 'Message deleted successfully'
    });
  } catch (error) {
    console.error('Delete Message Error:', error);
    res.status(500).json({
      success: false,
      message: 'Could not delete message',
      error: error.message
    });
  }
};

// @desc    Get unread message count
// @route   GET /api/v1/messages/unread
// @access  Private
exports.getUnreadCount = async (req, res) => {
  try {
    const unreadCount = await Message.countDocuments({
      receiver: req.user.id,
      read: false
    });
    
    res.status(200).json({
      success: true,
      data: { unreadCount }
    });
  } catch (error) {
    console.error('Unread Count Error:', error);
    res.status(500).json({
      success: false,
      message: 'Could not get unread message count',
      error: error.message
    });
  }
};