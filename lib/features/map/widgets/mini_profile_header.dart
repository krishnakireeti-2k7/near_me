// file: lib/features/map/widgets/mini_profile_header.dart
import 'package:flutter/material.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/profile/model/friendship_model.dart';

class MiniProfileHeader extends StatelessWidget {
  final UserProfileModel user;
  final bool isCurrentUser;
  final String
  imageUrlToShow; // Changed to non-nullable since fallback is provided
  final AsyncValue<FriendshipModel?>? friendshipStatus;

  const MiniProfileHeader({
    super.key,
    required this.user,
    required this.isCurrentUser,
    required this.imageUrlToShow,
    this.friendshipStatus,
  });

  @override
  Widget build(BuildContext context) {
    String lastActiveText = "Never active";
    Color lastActiveColor = Colors.grey;

    if (user.lastActive != null) {
      final DateTime lastActiveDateTime = user.lastActive!.toDate();
      lastActiveText = 'Last active: ${timeago.format(lastActiveDateTime)}';
      if (DateTime.now().difference(lastActiveDateTime).inMinutes <= 5) {
        lastActiveColor = Colors.green[700]!;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage:
              imageUrlToShow.startsWith('assets/')
                  ? AssetImage(imageUrlToShow)
                  : NetworkImage(imageUrlToShow) as ImageProvider,
          child:
              imageUrlToShow.isEmpty
                  ? const Icon(Icons.person, size: 28)
                  : null,
          backgroundColor: Colors.grey[200],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (isCurrentUser)
                    Chip(
                      label: const Text('You', style: TextStyle(fontSize: 11)),
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.1),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (!isCurrentUser &&
                      friendshipStatus?.value?.status ==
                          FriendshipStatus.accepted)
                    Chip(
                      label: const Text(
                        'Friends',
                        style: TextStyle(fontSize: 11),
                      ),
                      backgroundColor: Colors.green.shade100,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 14,
                      ),
                    ),
                ],
              ),
              if (!isCurrentUser)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    lastActiveText,
                    style: TextStyle(
                      fontSize: 12,
                      color: lastActiveColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              if (user.shortBio.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    user.shortBio,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
