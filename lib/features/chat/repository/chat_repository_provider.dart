// file: lib/features/chat/repository/chat_repository_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/chat/chat_model.dart';
import 'package:near_me/features/chat/repository/chat_repository.dart';
import 'package:rxdart/rxdart.dart'; // ✅ NEW IMPORT

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(firestore: FirebaseFirestore.instance, ref: ref);
});

final messagesProvider = StreamProvider.family<List<ChatMessage>, String>((
  ref,
  otherUserId,
) {
  final currentUser = ref.watch(authStateProvider).value;
  if (currentUser?.uid == null) {
    return Stream.value([]);
  }

  final chatRepo = ref.read(chatRepositoryProvider);

  // Stream for the chat messages
  final messagesStream = chatRepo.getMessages(currentUser!.uid, otherUserId);

  // Stream for the chat batch start time
  final startTimeStream = chatRepo.getChatBatchStartTime(
    currentUser.uid,
    otherUserId,
  );

  // ✅ Combine the two streams using Rx.combineLatest2
  return Rx.combineLatest2(messagesStream, startTimeStream, (
    List<ChatMessage> messages,
    Timestamp? startTime,
  ) {
    if (startTime == null) {
      // Chat batch has been deleted from Firestore, return an empty list.
      return <ChatMessage>[];
    }

    final now = DateTime.now();
    final chatEndTime = startTime.toDate().add(const Duration(hours: 12));

    if (now.isAfter(chatEndTime)) {
      // If the chat has expired based on local time, return an empty list immediately.
      return <ChatMessage>[];
    }

    // Otherwise, return the actual messages.
    return messages;
  });
});

final chatBatchStartTimeProvider = StreamProvider.family<Timestamp?, String>((
  ref,
  otherUserId,
) {
  final currentUser = ref.watch(authStateProvider).value;
  if (currentUser?.uid == null) {
    return Stream.value(null);
  }
  return ref
      .read(chatRepositoryProvider)
      .getChatBatchStartTime(currentUser!.uid, otherUserId);
});
