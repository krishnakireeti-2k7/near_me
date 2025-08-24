// file: lib/features/chat/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart'; // ✅ NEW IMPORT
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/chat/repository/chat_repository_provider.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:near_me/features/chat/widgets/chat_message_bubble.dart';

// ✅ NEW: Provider to fetch the other user's profile
final otherUserProfileStreamProvider =
    StreamProvider.family<UserProfileModel, String>((ref, userId) {
      return ref.read(profileRepositoryProvider).streamUserProfile(userId);
    });

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

class _ChatScreenState extends ConsumerState<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ✅ New method to show the temporary message
  void _showVanishingMessage(BuildContext context) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top:
                MediaQuery.of(context).padding.top +
                AppBar().preferredSize.height +
                10,
            left: 20,
            right: 20,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'This chat will vanish after 12 hours.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;
    final otherUserProfile = ref.watch(
      otherUserProfileStreamProvider(widget.otherUserId),
    );
    final messages = ref.watch(messagesProvider(widget.otherUserId));
    final batchStartTime = ref.watch(
      chatBatchStartTimeProvider(widget.otherUserId),
    );

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    const gradient = LinearGradient(
      colors: [Color(0xFFF5F5F5), Color(0xFFFFFFFF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: gradient),
        child: Column(
          children: [
            otherUserProfile.when(
              data:
                  (profile) => AppBar(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    titleSpacing: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: GestureDetector(
                      // ✅ WRAPPING WITH GESTURE DETECTOR
                      onTap: () {
                        // Navigate to the other user's profile screen using go_router
                        context.push('/profile/${profile.uid}');
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(
                              profile.profileImageUrl,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            profile.name,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      batchStartTime.when(
                        data:
                            (startTime) =>
                                startTime != null
                                    ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                      ),
                                      child: GestureDetector(
                                        onTap:
                                            () =>
                                                _showVanishingMessage(context),
                                        child: CountdownTimer(
                                          startTime: startTime,
                                        ),
                                      ),
                                    )
                                    : const SizedBox(),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
              loading:
                  () => AppBar(
                    title: const CircularProgressIndicator(),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
              error:
                  (error, _) => AppBar(
                    title: const Text('Error'),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: messages.when(
                  data:
                      (messageList) => ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16.0),
                        itemCount: messageList.length,
                        itemBuilder: (context, index) {
                          final message = messageList[index];
                          final isCurrentUser =
                              message.senderId == currentUser.uid;
                          return ChatMessageBubble(
                            message: message.content,
                            isCurrentUser: isCurrentUser,
                            timestamp: _formatTimestamp(message.timestamp),
                          );
                        },
                      ),
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (error, _) => Center(
                        child: Text(
                          'Error: $error',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                ),
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white.withOpacity(0.8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF616161),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      try {
        await ref
            .read(chatRepositoryProvider)
            .sendMessage(
              senderId: ref.read(authStateProvider).value!.uid,
              receiverId: widget.otherUserId,
              content: message,
            );
        _messageController.clear();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
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
    if (!mounted) return;
    final startDateTime = widget.startTime.toDate();
    final endTime = startDateTime.add(const Duration(hours: 12));
    remainingTime = endTime.difference(DateTime.now());
    if (remainingTime.isNegative) {
      remainingTime = Duration.zero;
    }
    setState(() {});
    if (remainingTime > Duration.zero) {
      Future.delayed(const Duration(seconds: 1), _updateRemainingTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = remainingTime.inHours;
    final minutes = remainingTime.inMinutes % 60;
    final seconds = remainingTime.inSeconds % 60;

    // Determine the color based on remaining time
    Color timerColor = Theme.of(context).colorScheme.onSurface;
    if (remainingTime.inHours < 1) {
      timerColor = Colors.red;
    } else if (remainingTime.inHours < 3) {
      timerColor = Colors.orange;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, color: timerColor, size: 16),
            const SizedBox(width: 6),
            Text(
              '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: timerColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
