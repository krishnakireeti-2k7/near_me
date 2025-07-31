// file: lib/features/map/widgets/mini_profile_header.dart

import 'package:flutter/material.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class MiniProfileHeader extends StatelessWidget {
  final UserProfileModel user;
  final bool isCurrentUser;
  final String? imageUrlToShow;

  const MiniProfileHeader({
    super.key,
    required this.user,
    required this.isCurrentUser,
    required this.imageUrlToShow,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage:
              imageUrlToShow != null && imageUrlToShow!.isNotEmpty
                  ? NetworkImage(imageUrlToShow!)
                  : null,
          child:
              imageUrlToShow == null || imageUrlToShow!.isEmpty
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
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
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
                  const SizedBox(width: 8),
                  if (isCurrentUser)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'You',
                        style: TextStyle(
                          color: Colors.blueGrey[400],
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              // --- MODIFICATION STARTS HERE ---
              // ONLY show last active if it's NOT the current user
              if (!isCurrentUser) // <--- ADD THIS CONDITION
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

              // --- MODIFICATION ENDS HERE ---
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
