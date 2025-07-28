// file: lib/features/map/widgets/interests_section.dart

import 'package:flutter/material.dart';

class InterestsSection extends StatelessWidget {
  final List<String> tags; // MODIFIED: Renamed from 'interests'

  const InterestsSection({
    super.key,
    required this.tags, // MODIFIED: Renamed parameter
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink(); // Use 'tags' here

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // OPTIONAL: You might want a "Tags:" label here if not present elsewhere
        // const Text(
        //   'Tags:',
        //   style: TextStyle(
        //     fontSize: 14,
        //     fontWeight: FontWeight.bold,
        //   ),
        // ),
        // const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children:
              tags // Use 'tags' here to map to Containers
                  .map(
                    (tag) => Container(
                      // Renamed 'interest' to 'tag' for clarity
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        tag, // Use 'tag' here
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}
