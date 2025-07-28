// file: lib/features/map/widgets/mini_profile_header.dart

import 'package:flutter/material.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:timeago/timeago.dart' as timeago; // NEW: Import timeago

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
    // Determine active status for display purposes
    String lastActiveText = "Never active";
    Color lastActiveColor = Colors.grey;

    if (user.lastActive != null) {
      final DateTime lastActiveDateTime = user.lastActive!.toDate();
      lastActiveText = 'Last active: ${timeago.format(lastActiveDateTime)}';
      // Check if active within 5 minutes
      if (DateTime.now().difference(lastActiveDateTime).inMinutes <= 5) {
        lastActiveColor = Colors.green[700]!; // Vibrant green for active
      }
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start, // Align top for better layout
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
          backgroundColor: Colors.grey[200], // Placeholder background
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.baseline, // Align text baselines
                textBaseline:
                    TextBaseline
                        .alphabetic, // Required for crossAxisAlignment.baseline
                children: [
                  Flexible(
                    // Use Flexible to prevent overflow
                    child: Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis, // Handle long names
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
              // NEW: Display Last Active status
              Padding(
                padding: const EdgeInsets.only(top: 2.0), // Smaller padding
                child: Text(
                  lastActiveText,
                  style: TextStyle(
                    fontSize: 12, // Smaller font for detail
                    color: lastActiveColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              if (user.shortBio.isNotEmpty) // Changed from shortBio to bio directly
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    user.shortBio, // Display the full bio if needed
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
