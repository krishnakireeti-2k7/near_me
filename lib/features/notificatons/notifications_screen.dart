import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allInterests = ref.watch(allInterestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Interest History')),
      body: allInterests.when(
        data: (interests) {
          if (interests.isEmpty) {
            return const Center(child: Text('No interests yet.'));
          }

          return ListView.separated(
            itemCount: interests.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final interest = interests[index];
              final fromUserId = interest['fromUserId'] ?? 'Unknown';
              final timestamp = interest['timestamp']?.toDate();
              final formattedTime =
                  timestamp != null
                      ? '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute}'
                      : 'Unknown time';

              return ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: Text('Got interest from: $fromUserId'),
                subtitle: Text(formattedTime),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
