// file: lib/features/chat/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/chat/repository/chat_repository_provider.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:near_me/features/chat/widgets/chat_message_bubble.dart';

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
  bool _isChatVanished = false; // ✅ NEW: State to manage vanishing animation

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

  void _showVanishingMessage(
    BuildContext context,
    Duration remainingTime,
    GlobalKey key,
  ) {
    final overlay = Overlay.of(context);

    final renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    final screenWidth = MediaQuery.of(context).size.width;
    const messageWidth = 220.0;
    final leftPosition =
        (position.dx + messageWidth > screenWidth)
            ? screenWidth - messageWidth - 16
            : position.dx;

    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            left: leftPosition,
            top: position.dy + size.height + 4,
            child: SizedBox(
              width: messageWidth,
              child: _FadeMessage(
                message:
                    "⏳ Chat will vanish in ${_formatDuration(remainingTime)}",
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return "${duration.inHours}h ${duration.inMinutes % 60}m";
    } else if (duration.inMinutes > 0) {
      return "${duration.inMinutes}m ${duration.inSeconds % 60}s";
    } else {
      return "${duration.inSeconds}s";
    }
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
    final colorScheme = Theme.of(context).colorScheme;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final gradient = LinearGradient(
      colors: [colorScheme.surface, colorScheme.background],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    // ✅ Listen for the chat vanishing event from the provider
    messages.whenData((messageList) {
      if (messageList.isEmpty && !_isChatVanished) {
        setState(() {
          _isChatVanished = true;
        });
      } else if (messageList.isNotEmpty && _isChatVanished) {
        setState(() {
          _isChatVanished = false;
        });
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Column(
          children: [
            otherUserProfile.when(
              data:
                  (profile) => AppBar(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    titleSpacing: 0,
                    leading: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: colorScheme.onSurface,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: GestureDetector(
                      onTap: () {
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
                            style: TextStyle(
                              color: colorScheme.onSurface,
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
                                      child: CountdownTimer(
                                        key: GlobalKey(),
                                        startTime: startTime,
                                        onTap: (remainingTime, key) {
                                          _showVanishingMessage(
                                            context,
                                            remainingTime,
                                            key,
                                          );
                                        },
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
              child: AnimatedOpacity(
                // ✅ WRAPPED IN ANIMATEDOPACITY
                opacity: _isChatVanished ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 500),
                child: messages.when(
                  data: (messageList) {
                    if (messageList.isEmpty && _isChatVanished) {
                      return Center(
                        child: Text(
                          "This chat has vanished.",
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                      );
                    } else if (messageList.isEmpty && !_isChatVanished) {
                      return Center(
                        child: Text(
                          "No messages yet.",
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
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
                    );
                  },
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      color: colorScheme.background.withOpacity(0.8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
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
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blueGrey,
            child: IconButton(
              icon: Icon(Icons.send, color: colorScheme.onPrimary),
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
  final void Function(Duration remainingTime, GlobalKey key)? onTap;

  const CountdownTimer({super.key, required this.startTime, this.onTap});

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
    final colorScheme = Theme.of(context).colorScheme;

    // ✅ UPDATED: Softer, integrated colors for the timer
    Color timerColor = colorScheme.onSurface;
    if (remainingTime.inHours < 1) {
      timerColor = Colors.red.shade400;
    } else if (remainingTime.inHours < 3) {
      timerColor = Colors.orange.shade400;
    } else if (remainingTime.inHours < 6) {
      timerColor = Colors.amber.shade400;
    } else {
      timerColor = Colors.green.shade400;
    }

    return GestureDetector(
      onTap: () => widget.onTap?.call(remainingTime, widget.key as GlobalKey),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time, color: timerColor, size: 16),
              const SizedBox(width: 6),
              Text(
                '${hours.toString().padLeft(2, '0')}:'
                '${minutes.toString().padLeft(2, '0')}:'
                '${seconds.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: timerColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FadeMessage extends StatefulWidget {
  final String message;
  const _FadeMessage({required this.message});

  @override
  State<_FadeMessage> createState() => _FadeMessageState();
}

class _FadeMessageState extends State<_FadeMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
