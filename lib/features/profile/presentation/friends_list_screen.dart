// file: lib/features/profile/presentation/friends_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/profile/repository/friendship_repository_provider.dart';
// ✅ NEW IMPORT: Import the new widget file
import 'package:near_me/features/profile/presentation/widgets/friend_profile_tile.dart';

// 1️⃣ Provider to fetch the list of friend UIDs for the current user
final friendsListProvider = StreamProvider<List<String>>((ref) {
  final currentUserProfileAsyncValue = ref.watch(
    currentUserProfileStreamProvider,
  );
  return currentUserProfileAsyncValue.when(
    data: (userProfile) {
      if (userProfile != null && userProfile.friends != null) {
        return Stream.value(userProfile.friends!);
      }
      return Stream.value([]);
    },
    loading: () => Stream.value([]),
    error: (e, st) => Stream.value([]),
  );
});

class FriendsListScreen extends ConsumerWidget {
  const FriendsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsListAsyncValue = ref.watch(friendsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Friends')),
      body: friendsListAsyncValue.when(
        data: (friendUids) {
          if (friendUids.isEmpty) {
            return const Center(
              child: Text("You don't have any friends yet. Add some!"),
            );
          }

          return ListView.builder(
            itemCount: friendUids.length,
            itemBuilder: (context, index) {
              final friendUid = friendUids[index];
              return FriendProfileTile(friendUid: friendUid);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}


