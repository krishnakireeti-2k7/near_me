// file: lib/features/profile/presentation/friends_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:near_me/features/profile/presentation/widgets/friend_profile_tile.dart';

final friendsListProvider = StreamProvider<List<String>>((ref) {
  final currentUserProfileAsyncValue = ref.watch(
    currentUserProfileStreamProvider,
  );
  return currentUserProfileAsyncValue.when(
    data: (userProfile) {
      if (userProfile != null) {
        return Stream.value(userProfile.friends);
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Friends',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.surface, colorScheme.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: friendsListAsyncValue.when(
          data: (friendUids) {
            if (friendUids.isEmpty) {
              return Center(
                child: Text(
                  "You don't have any friends yet. Add some!",
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
                ),
              );
            }

            // ✅ Directory mode only
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: friendUids.length,
              separatorBuilder:
                  (_, __) =>
                      Divider(height: 1, color: colorScheme.outlineVariant),
              itemBuilder: (context, index) {
                final friendUid = friendUids[index];
                return FriendProfileTile(friendUid: friendUid);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (e, st) => Center(
                child: Text(
                  'Error: $e',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
        ),
      ),
    );
  }
}
