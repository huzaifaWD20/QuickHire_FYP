// ignore_for_file: unnecessary_null_comparison, unused_local_variable

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/service_chat.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatelessWidget {
  final String conversationId;
  final String roomName;
  final String otherUserId;
  final String projectId;
  final String yourUserId;
  final ChatService chatService = Get.find();
  final TextEditingController msgController = TextEditingController();

  static const String id = 'chat_screen';

  ChatScreen({
    required this.conversationId,
    required this.roomName,
    required this.otherUserId,
    required this.projectId,
    required this.yourUserId,
    Key? key,
  }) : super(key: key);

  String getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  void _markMessagesAsRead() {
    // Mark unread messages as read
    final unreadMessageIds = chatService.messages
        .where((msg) =>
            (msg['receiver'] ?? msg['receiverId']) == yourUserId &&
            (msg['read'] == false || msg['read'] == null) &&
            (msg['_id'] != null))
        .map((msg) => msg['_id'] as String)
        .toList();
    if (unreadMessageIds.isNotEmpty) {
      chatService.markMessagesAsRead(unreadMessageIds);
      if (chatService.isConnected.value) {
        chatService.socket.emit('mark_read', {
          'sender': otherUserId,
          'messageIds': unreadMessageIds,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (conversationId.isEmpty) {
      return const Center(child: Text('Chat unavailable'));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(roomName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            chatService.leaveRoom(conversationId);
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              // Mark as read when messages change
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
                  // Support both backend and legacy keys
                  final sender = message['sender'];
                  final receiver = message['receiver'];
                  final senderId = sender is Map ? sender['_id'] ?? sender['id'] ?? '' : sender ?? '';
                  final receiverId = receiver is Map ? receiver['_id'] ?? receiver['id'] ?? '' : receiver ?? '';
                  final senderName = sender is Map ? (sender['name'] ?? '') : '';
                  final receiverName = receiver is Map ? (receiver['name'] ?? '') : '';
                  final msgText = message['content'] ?? message['message'] ?? '';
                  final isMe = senderId == yourUserId;
                  final timestampStr = message['timestamp'] ?? message['createdAt'] ?? '';

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
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe)
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey[300],
                            child: Text(
                              getInitials(receiverName.isNotEmpty ? receiverName : roomName),
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                        if (!isMe) const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.amber : Colors.grey[200],
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 0),
                                    bottomRight: Radius.circular(isMe ? 0 : 16),
                                  ),
                                ),
                                child: Text(
                                  msgText,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black,
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
                        if (isMe) const SizedBox(width: 8),
                        if (isMe)
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.amber,
                            child: Text(
                              getInitials(senderName.isNotEmpty ? senderName : 'Me'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
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
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      if (msgController.text.trim().isNotEmpty) {
                        chatService.sendMessage(
                          conversationId,
                          msgController.text.trim(),
                          yourUserId,
                          otherUserId,
                          projectId,
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