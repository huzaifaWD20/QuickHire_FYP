import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/service_chat.dart';
import 'chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatListScreen extends StatefulWidget {
  static const String id = 'chat_list_screen';

  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService chatService = Get.find<ChatService>();
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  String getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _fetchChats() async {
    setState(() {
      _loading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    // Fetch ongoing conversations from backend
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/messages/conversations'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _conversations = List<Map<String, dynamic>>.from(data['data']);
    } else {
      _conversations = [];
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_conversations.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chats')),
        body: const Center(
          child: Text('No Conversations'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final chat = _conversations[index];
          final conversationId = '${chat['otherUser']}-${chat['project']}';
          final otherUserId = chat['otherUser'];
          final projectId = chat['project'];
          final roomName = chat['otherUserName'] ?? 'Chat';
          final lastMessage = chat['lastMessage'] ?? '';
          final unreadCount = chat['unreadCount'] ?? 0;
          final lastMessageTime = chat['lastMessageTime'] ?? '';

          // Format time (optional)
          String formattedTime = '';
          try {
            if (lastMessageTime != null && lastMessageTime.toString().isNotEmpty) {
              final timestamp = DateTime.parse(lastMessageTime);
              final now = DateTime.now();
              final difference = now.difference(timestamp);
              if (difference.inDays > 0) {
                formattedTime = '${difference.inDays}d ago';
              } else if (difference.inHours > 0) {
                formattedTime = '${difference.inHours}h ago';
              } else if (difference.inMinutes > 0) {
                formattedTime = '${difference.inMinutes}m ago';
              } else {
                formattedTime = 'Just now';
              }
            }
          } catch (_) {
            formattedTime = '';
          }

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.amber,
              child: Text(
                getInitials(roomName),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    roomName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  formattedTime,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unreadCount != null && unreadCount > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final yourUserId = prefs.getString('user_id') ?? '';
              chatService.joinRoom(conversationId, otherUserId, projectId);
              Navigator.pushNamed(
                context,
                ChatScreen.id,
                arguments: {
                  'conversationId': conversationId,
                  'roomName': roomName,
                  'otherUserId': otherUserId,
                  'projectId': projectId,
                  'yourUserId': yourUserId,
                },
              );
            },
          );
        },
      ),
    );
  }
}