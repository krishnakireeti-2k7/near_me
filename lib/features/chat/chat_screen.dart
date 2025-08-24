// file: lib/features/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/chat/repository/chat_repository_provider.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;
    final currentUserProfile =
        ref.watch(currentUserProfileStreamProvider).value;
    final messages = ref.watch(messagesProvider(widget.otherUserId));
    final batchStartTime = ref.watch(
      chatBatchStartTimeProvider(widget.otherUserId),
    );

    if (currentUser == null || currentUserProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.otherUserName}'),
        actions: [
          batchStartTime.when(
            data:
                (startTime) =>
                    startTime != null
                        ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CountdownTimer(startTime: startTime),
                        )
                        : const SizedBox(),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Icon(Icons.error),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              data:
                  (messageList) => ListView.builder(
                    reverse: true,
                    itemCount: messageList.length,
                    itemBuilder: (context, index) {
                      final message = messageList[index];
                      final isCurrentUser = message.senderId == currentUser.uid;
                      return ListTile(
                        title: Align(
                          alignment:
                              isCurrentUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color:
                                  isCurrentUser
                                      ? Colors.blue[100]
                                      : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(message.content),
                          ),
                        ),
                        subtitle: Text(
                          message.timestamp.toDate().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (_messageController.text.trim().isNotEmpty) {
                      try {
                        await ref
                            .read(chatRepositoryProvider)
                            .sendMessage(
                              senderId: currentUser.uid,
                              receiverId: widget.otherUserId,
                              content: _messageController.text.trim(),
                            );
                        _messageController.clear();
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CountdownTimer extends StatefulWidget {
  final Timestamp startTime;

  const CountdownTimer({super.key, required this.startTime});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Duration remainingTime;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
  }

  void _updateRemainingTime() {
    final startDateTime = widget.startTime.toDate();
    final endTime = startDateTime.add(const Duration(hours: 12));
    remainingTime = endTime.difference(DateTime.now());
    if (remainingTime.isNegative) {
      remainingTime = Duration.zero;
    }
    setState(() {});
    Future.delayed(const Duration(seconds: 1), _updateRemainingTime);
  }

  @override
  Widget build(BuildContext context) {
    final hours = remainingTime.inHours;
    final minutes = remainingTime.inMinutes % 60;
    final seconds = remainingTime.inSeconds % 60;
    return Text(
      'Time left: ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
      style: const TextStyle(fontSize: 12),
    );
  }
}
