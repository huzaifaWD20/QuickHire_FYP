// ignore_for_file: unnecessary_null_comparison, unused_local_variable

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/service_chat.dart';
import '../services/user_service.dart';
import 'package:intl/intl.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart'; // Import your app config for API base URL
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String roomName;
  final String otherUserId;
  final String projectId;

  static const String id = 'chat_screen';

  const ChatScreen({
    required this.conversationId,
    required this.roomName,
    required this.otherUserId,
    required this.projectId,
    Key? key,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService chatService = Get.find();
  final TextEditingController msgController = TextEditingController();
  String? currentUserId;
  String? currentUserName;
  String? currentUserRole;
  bool _loadingUser = true;
  Map<String, dynamic>? upcomingMeeting;
  var jitsiMeet = JitsiMeet();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _fetchUpcomingMeeting();
  }

  Future<void> _fetchUpcomingMeeting() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/meetings/my'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final meetings = data['data'] as List<dynamic>;
      // Filter for this project/conversation and future meetings
      final now = DateTime.now();
      final filtered = meetings.where((m) {
        final scheduledFor = DateTime.parse(m['scheduledFor']);
        return m['project'] == widget.projectId && scheduledFor.isAfter(now.subtract(const Duration(minutes: 30)));
      }).toList();
      if (filtered.isNotEmpty) {
        // Pick the soonest upcoming meeting
        filtered.sort((a, b) => DateTime.parse(a['scheduledFor']).compareTo(DateTime.parse(b['scheduledFor'])));
        setState(() {
          upcomingMeeting = filtered.first as Map<String, dynamic>;
        });
      } else {
        setState(() {
          upcomingMeeting = null;
        });
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    final profileData = await UserService().fetchProfile();
    final user = profileData?['user'];
    setState(() {
      currentUserId = user?['id'] ?? user?['_id'] ?? '';
      currentUserName = user?['name'] ?? '';
      currentUserRole = user?['role'] ?? '';
      _loadingUser = false;
    });
  }

  String getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  void _markMessagesAsRead() {
    if (currentUserId == null || currentUserId!.isEmpty) return;
    final unreadMessageIds = chatService.messages
        .where((msg) {
          final receiver = msg['receiver'];
          final receiverId = receiver is Map ? receiver['_id'] ?? receiver['id'] ?? '' : receiver ?? '';
          final isRead = msg['read'] ?? false;
          final messageId = msg['_id'];
          return receiverId == currentUserId && !isRead && messageId != null;
        })
        .map((msg) => msg['_id'] as String)
        .toList();

    if (unreadMessageIds.isNotEmpty) {
      chatService.markMessagesAsRead(unreadMessageIds);
      if (chatService.isConnected.value) {
        chatService.socket.emit('mark_read', {
          'sender': widget.otherUserId,
          'messageIds': unreadMessageIds,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (widget.conversationId.isEmpty) {
      return const Center(child: Text('Chat unavailable'));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call),
            tooltip: 'Schedule Meeting',
            onPressed: () async {
              if (currentUserRole != 'employer') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Not Allowed'),
                    content: const Text('Currently, only employers can schedule meetings.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                return;
              }
              // Employer scheduling logic
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (pickedDate == null) return;
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 10, minute: 0),
              );
              if (pickedTime == null) return;
              final scheduledDateTime = DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                pickedTime.hour,
                pickedTime.minute,
              );

              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('auth_token') ?? '';
              final isEmployer = currentUserRole == 'employer';

              final response = await http.post(
                Uri.parse('${AppConfig.apiBaseUrl}/api/v1/meetings/schedule'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({
                  'project': widget.projectId,
                  'employer': isEmployer ? currentUserId : widget.otherUserId,
                  'jobseeker': isEmployer ? widget.otherUserId : currentUserId,
                  'scheduledFor': scheduledDateTime.toIso8601String(),
                }),
              );
              if (response.statusCode == 201) {
                final meeting = json.decode(response.body)['data'];
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Meeting scheduled for ${DateFormat('MMM d, yyyy h:mm a').format(scheduledDateTime)}')),
                );
                await _fetchUpcomingMeeting();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to schedule meeting')),
                );
              }
            },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            chatService.leaveRoom(widget.conversationId);
            Navigator.pop(context, true); // Return true to indicate chat was viewed
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              WidgetsBinding.instance.addPostFrameCallback((_) => _markMessagesAsRead());
              if (chatService.messages.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start the conversation!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                reverse: true,
                itemCount: chatService.messages.length,
                itemBuilder: (context, index) {
                  final message = chatService.messages.reversed.toList()[index];
                  final sender = message['sender'];
                  final receiver = message['receiver'];
                  final senderId = sender is Map ? sender['_id'] ?? sender['id'] ?? '' : sender ?? '';
                  final receiverId = receiver is Map ? receiver['_id'] ?? receiver['id'] ?? '' : receiver ?? '';
                  final senderName = sender is Map ? (sender['name'] ?? '') : '';
                  final msgText = message['content'] ?? message['message'] ?? '';
                  final timestampStr = message['timestamp'] ?? message['createdAt'] ?? '';

                  // Determine if this message is sent by the current user
                  final isSender = senderId == currentUserId;
                  print('Current user ID: $currentUserId');
                  print('Sender ID: $senderId');
                  print('Is sender: $isSender');

                  // Avatar name logic: always use sender's name for the badge
                  final avatarName = senderName.isNotEmpty ? senderName : widget.roomName;

                  // Format timestamp
                  String formattedTime = '';
                  try {
                    if (timestampStr != null && timestampStr.toString().isNotEmpty) {
                      final timestamp = DateTime.parse(timestampStr);
                      formattedTime = DateFormat('MMM d, h:mm a').format(timestamp);
                    }
                  } catch (e) {
                    formattedTime = '';
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar for other person (left side) - only show for received messages
                        if (!isSender) ...[
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey[300],
                            child: Text(
                              getInitials(avatarName),
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        // Message bubble
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSender ? Colors.yellow[700] : Colors.grey[200],
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isSender ? 16 : 4),
                                    bottomRight: Radius.circular(isSender ? 4 : 16),
                                  ),
                                ),
                                child: Text(
                                  msgText,
                                  style: const TextStyle(
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedTime,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Avatar for sender (right side) - only show for sent messages
                        if (isSender) ...[
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.yellow[700],
                            child: Text(
                              getInitials(currentUserName ?? 'Me'),
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            }),
          ),
          // >>> ADD JOIN BUTTON HERE <<<
          if (upcomingMeeting != null) ...[
            Builder(
              builder: (context) {
                final scheduledTime = DateTime.parse(upcomingMeeting!['scheduledFor']);
                final canJoin = DateTime.now().isAfter(scheduledTime.subtract(const Duration(minutes: 5)));
                if (canJoin) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.video_call),
                      label: const Text('Join Meeting'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () async {
                        final roomId = upcomingMeeting!['videoRoomId'];
                        if (roomId == null || roomId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Meeting room not available.')),
                          );
                          return;
                        }
                        var options = JitsiMeetConferenceOptions(room: roomId);
                        await jitsiMeet.join(options);
                      },
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
          // Message input field
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: msgController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.yellow[700],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: () {
                      if (msgController.text.trim().isNotEmpty && currentUserId != null) {
                        chatService.sendMessage(
                          widget.conversationId,
                          msgController.text.trim(),
                          currentUserId!,
                          widget.otherUserId,
                          widget.projectId,
                        );
                        msgController.clear();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}