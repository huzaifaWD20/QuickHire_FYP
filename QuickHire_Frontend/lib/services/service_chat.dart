// ignore_for_file: unused_import, unused_field

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:get/get.dart';
import '../config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService extends GetxService {
  late IO.Socket socket;

  final messages = <Map<String, dynamic>>[].obs;
  final chatRooms = <Map<String, dynamic>>[].obs;
  final isConnected = false.obs;
  final connectionError = ''.obs;

  Future<bool> canAccessConversation({
    required String otherUserId,
    required String projectId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/messages/conversation/$otherUserId/$projectId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    // 200 means access granted (and you get messages), 403/400 means denied
    return response.statusCode == 200;
  }

  Future<void> markMessagesAsRead(List<String> messageIds) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/messages/read'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'messageIds': messageIds}),
    );
  }
  
  // Static data for demo purposes
  final Map<String, List<Map<String, dynamic>>> _staticMessages = {
    'room1': [
      {
        'senderId': 'other-user-1',
        'message': 'Hello! I saw your profile and I think you would be a great fit for our company.',
        'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
      },
      {
        'senderId': 'your-user-id',
        'message': 'Hi there! Thank you for reaching out. I would love to hear more about the opportunity.',
        'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 45)).toIso8601String(),
      },
      {
        'senderId': 'other-user-1',
        'message': 'Great! We are looking for someone with your skills. Are you available for an interview next week?',
        'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 30)).toIso8601String(),
      },
      {
        'senderId': 'your-user-id',
        'message': 'Yes, I am available. What day and time works best for you?',
        'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 1)).toIso8601String(),
      },
    ],
    'room2': [
      {
        'senderId': 'other-user-2',
        'message': 'Hi, I noticed you have experience with Flutter development.',
        'timestamp': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      },
      {
        'senderId': 'your-user-id',
        'message': 'Yes, I have been working with Flutter for about 2 years now.',
        'timestamp': DateTime.now().subtract(const Duration(hours: 4, minutes: 50)).toIso8601String(),
      },
      {
        'senderId': 'other-user-2',
        'message': 'That\'s great! We have a project that might interest you.',
        'timestamp': DateTime.now().subtract(const Duration(hours: 4, minutes: 45)).toIso8601String(),
      },
    ],
    'room3': [
      {
        'senderId': 'other-user-3',
        'message': 'Hello, are you still looking for job opportunities?',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
      },
      {
        'senderId': 'your-user-id',
        'message': 'Yes, I am actively looking for new opportunities.',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 25)).toIso8601String(),
      },
      {
        'senderId': 'other-user-3',
        'message': 'Perfect! I have a position that matches your profile. Would you like to discuss it further?',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 20)).toIso8601String(),
      },
      {
        'senderId': 'your-user-id',
        'message': 'Absolutely! I would love to hear more details.',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
      },
    ],
  };

  // Constructor to immediately load static data
  ChatService() {
    _loadStaticData();
  }

  Future<ChatService> init() async {
    try {
      // Make sure static data is loaded
      if (chatRooms.isEmpty) {
        _loadStaticData();
      }
      // Still attempt to connect to socket for future real implementation
      _initSocket();
      return this;
    } catch (e) {
      connectionError.value = 'Error initializing: $e';
      // Ensure static data is loaded even if there's an error
      if (chatRooms.isEmpty) {
        _loadStaticData();
      }
      return this;
    }
  }
  
  // Public method to load static data
  void loadStaticData() {
    _loadStaticData();
  }
  
  void _loadStaticData() {
    // Load static chat rooms
    chatRooms.assignAll([
      {
        'roomId': 'room1',
        'roomName': 'Tech Innovations Inc.',
        'lastMessage': 'Yes, I am available. What day and time works best for you?',
        'unreadCount': 0,
        'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 1)).toIso8601String(),
      },
      {
        'roomId': 'room2',
        'roomName': 'Flutter Projects',
        'lastMessage': 'That\'s great! We have a project that might interest you.',
        'unreadCount': 2,
        'timestamp': DateTime.now().subtract(const Duration(hours: 4, minutes: 45)).toIso8601String(),
      },
      {
        'roomId': 'room3',
        'roomName': 'Job Connect',
        'lastMessage': 'Absolutely! I would love to hear more details.',
        'unreadCount': 0,
        'timestamp': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
      },
    ]);
  }
  
  void _initSocket() {
    SharedPreferences.getInstance().then((prefs) {
      final userId = prefs.getString('user_id') ?? '';
      final token = prefs.getString('auth_token') ?? '';

      // Correct: send token in 'auth'
      socket = IO.io(AppConfig.socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {
          'token': token,
        },
        'query': {
          'userId': userId,
        },
      });

      _setupSocketEventHandlers();
      socket.connect();
    });
  }
  
  void _setupSocketEventHandlers() {
    socket.onConnecting((_) {});
    socket.onConnectError((data) {
      connectionError.value = 'Connection error: $data';
    });
    socket.onError((data) {
      connectionError.value = 'Socket error: $data';
    });

    socket.onConnect((_) {
      isConnected.value = true;
      connectionError.value = '';
      fetchChatRooms();
    });

    socket.on('receive_message', (data) {
      messages.add(data);
    });

    socket.on('chat_rooms', (data) {
      // For demo, we'll keep using static data
      // chatRooms.assignAll(List<Map<String, dynamic>>.from(data));
    });

    socket.onDisconnect((_) {
      isConnected.value = false;
    });

    socket.on('access_denied', (data) {
      // Show error in UI or set a variable for your widget to display
    });
  }

  Future<void> sendMessage(String conversationId, String message, String senderId, String receiverId, String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/messages'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'receiver': receiverId,
        'content': message,
        'project': projectId,
      }),
    );
    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      messages.add(data['data']);
      // Optionally emit via socket for real-time
      if (isConnected.value) {
        socket.emit('send_message', {
          'conversationId': conversationId,
          'message': message,
          'senderId': senderId,
          'receiverId': receiverId,
          'projectId': projectId,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  void fetchChatRooms() {
    // For demo, we already loaded static data
    // Still try to fetch via socket for future real implementation
    if (isConnected.value) {
      socket.emit('get_chat_rooms');
    }
  }

  void joinRoom(String conversationId, String otherUserId, String projectId) async {
    messages.clear();
    // Fetch messages from backend
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/messages/conversation/$otherUserId/$projectId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Assuming data['data'] is a list of messages
      messages.assignAll(List<Map<String, dynamic>>.from(data['data']));
    }
    // Join socket room for real-time updates
    if (isConnected.value) {
      socket.emit('join_conversation', conversationId);
    }
  }

  void leaveRoom(String conversationId) {
    // For demo, just clear messages
    messages.clear();
    // Still try to leave via socket for future real implementation
    if (isConnected.value) {
      socket.emit('leave_room', conversationId);
    }
  }

  void reconnect() {
    if (!socket.connected) {
      socket.connect();
    }
  }

  @override
  void onClose() {
    socket.dispose();
    super.onClose();
  }
}