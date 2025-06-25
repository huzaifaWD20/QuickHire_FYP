// config/socket.js
const socketio = require('socket.io');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

// User-socket mapping
const userSockets = new Map();

const initializeSocket = (server) => {
  const io = socketio(server, {
    cors: {
      origin: "*", // In production, restrict this to your domains
      methods: ["GET", "POST"]
    }
  });
  // In your config/socket.js file, update the CORS settings:
// const io = socketio(server, {
//   cors: {
//     origin: ["http://localhost:8080", "http://localhost:5000"],
//     methods: ["GET", "POST"]
//   }
// });

  // Authentication middleware for socket
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      
      if (!token) {
        return next(new Error('Authentication error'));
      }

      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your_jwt_secret');
      
      // Get user from token
      const user = await User.findById(decoded.id);
      
      if (!user) {
        return next(new Error('User not found'));
      }
      
      // Check if user is verified
      if (!user.isVerified) {
        return next(new Error('Email not verified'));
      }
      
      // Attach user to socket
      socket.user = user;
      next();
    } catch (error) {
      return next(new Error('Authentication error'));
    }
  });

  io.on('connection', (socket) => {
    console.log(`User connected: ${socket.user.id}`);
    
    // Store user's socket
    userSockets.set(socket.user.id, socket);
    
    // Join a room for a specific project conversation
    socket.on('join_conversation', (conversationId) => {
      socket.join(`conversation_${conversationId}`);
    });
    
    // Handle messages
    socket.on('send_message', (data) => {
      // Emit to the specific receiver if online
      const receiverSocket = userSockets.get(data.receiver);
      if (receiverSocket) {
        receiverSocket.emit('receive_message', {
          sender: socket.user.id,
          content: data.content,
          project: data.project,
          createdAt: new Date()
        });
      }
      
      // Also emit to the project room so all relevant parties can see in real-time
      socket.to(`project_${data.project}`).emit('receive_message', {
        sender: socket.user.id,
        content: data.content,
        project: data.project,
        createdAt: new Date()
      });
    });
    
    // Handle typing indicator
    socket.on('typing', (data) => {
      socket.to(`project_${data.project}`).emit('user_typing', {
        user: socket.user.id,
        project: data.project,
        isTyping: data.isTyping
      });
    });
    
    // Handle read receipts
    socket.on('mark_read', (data) => {
      const receiverSocket = userSockets.get(data.sender);
      if (receiverSocket) {
        receiverSocket.emit('message_read', {
          reader: socket.user.id,
          messageIds: data.messageIds
        });
      }
    });
    
    // Handle disconnect
    socket.on('disconnect', () => {
      console.log(`User disconnected: ${socket.user.id}`);
      userSockets.delete(socket.user.id);
    });
  });

  return io;
};

// Function to get a user's socket
const getUserSocket = (userId) => {
  return userSockets.get(userId);
};

module.exports = { initializeSocket, getUserSocket };