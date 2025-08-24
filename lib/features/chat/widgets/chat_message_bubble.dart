// file: lib/features/chat/widgets/chat_message_bubble.dart

import 'package:flutter/material.dart';

class ChatMessageBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final String timestamp;

  const ChatMessageBubble({
    Key? key,
    required this.message,
    required this.isCurrentUser,
    required this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final alignment =
        isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleBorderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft:
          isCurrentUser ? const Radius.circular(16) : const Radius.circular(0),
      bottomRight:
          isCurrentUser ? const Radius.circular(0) : const Radius.circular(16),
    );

    // ✅ New subtle neutral gradients for the chat bubbles
    final bubbleGradient =
        isCurrentUser
            ? LinearGradient(
              colors: [Colors.blueGrey.shade400, Colors.blueGrey.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
            : LinearGradient(
              colors: [Colors.grey.shade300, Colors.grey.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );
    final textColor = isCurrentUser ? Colors.white : Colors.black87;

    return Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(10, 4, 10, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              gradient: bubbleGradient,
              borderRadius: bubbleBorderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Text(
              timestamp,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
