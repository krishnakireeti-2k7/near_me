// file: lib/features/chat/repository/chat_repository_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/chat/chat_model.dart';
import 'package:near_me/features/chat/repository/chat_repository.dart';

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
  return ref
      .read(chatRepositoryProvider)
      .getMessages(currentUser!.uid, otherUserId);
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
