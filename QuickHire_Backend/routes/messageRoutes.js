// routes/messageRoutes.js
const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth');
const {
  sendMessage,
  getConversation,
  getConversations,
  markAsRead,
  deleteMessage,
  getUnreadCount
} = require('../controllers/messageController');

// All routes require authentication
router.use(protect);

// Message routes
router.post('/', sendMessage);
router.get('/conversations', getConversations);
router.get('/conversation/:userId/:projectId', getConversation);
router.put('/read', markAsRead);
router.get('/unread', getUnreadCount);
router.delete('/:id', deleteMessage);

module.exports = router;