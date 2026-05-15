import 'package:flutter/material.dart';
import 'package:learnhub/domain/entities/instructor.dart';
import 'package:learnhub/core/theme/app_colors.dart';

class InstructorMessagingScreen extends StatefulWidget {
  const InstructorMessagingScreen({super.key, required this.instructor});

  final Instructor instructor;

  @override
  State<InstructorMessagingScreen> createState() =>
      _InstructorMessagingScreenState();
}

class _InstructorMessagingScreenState extends State<InstructorMessagingScreen> {
  late TextEditingController _messageController;
  final List<_Message> _messages = [
    _Message(
      id: '1',
      senderId: 'instructor_123',
      senderName: 'Ahmed Hassan',
      senderAvatar: 'https://i.pravatar.cc/150?img=10',
      content: 'Hello! How can I help you with the course?',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isFromInstructor: true,
    ),
    _Message(
      id: '2',
      senderId: 'student_456',
      senderName: 'You',
      senderAvatar: 'https://i.pravatar.cc/150?img=11',
      content: 'Hi Ahmed, I have a question about lesson 5.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isFromInstructor: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        _Message(
          id: '${_messages.length}',
          senderId: 'student_456',
          senderName: 'You',
          senderAvatar: 'https://i.pravatar.cc/150?img=11',
          content: text,
          timestamp: DateTime.now(),
          isFromInstructor: false,
        ),
      );
    });

    _messageController.clear();

    // Simulate instructor response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add(
            _Message(
              id: '${_messages.length}',
              senderId: 'instructor_123',
              senderName: widget.instructor.name,
              senderAvatar: widget.instructor.avatarUrl,
              content: 'Thanks for your question! Let me help you with that.',
              timestamp: DateTime.now(),
              isFromInstructor: true,
            ),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.instructor.name),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return Align(
                  alignment: message.isFromInstructor
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: message.isFromInstructor
                          ? (isDark
                              ? colorScheme.surface
                              : const Color(0xFFF0F0F0))
                          : const Color(AppColors.primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: message.isFromInstructor
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        Text(
                          message.content,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: message.isFromInstructor
                                ? colorScheme.onSurface
                                : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: message.isFromInstructor
                                ? colorScheme.onSurface.withValues(alpha: 0.65)
                                : Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surface : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? colorScheme.outline.withValues(alpha: 0.3)
                      : const Color(AppColors.line),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: const Color(AppColors.primary),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: _sendMessage,
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}

class _Message {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final DateTime timestamp;
  final bool isFromInstructor;

  _Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.content,
    required this.timestamp,
    required this.isFromInstructor,
  });
}
