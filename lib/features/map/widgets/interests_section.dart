import 'package:flutter/material.dart';

class InterestsSection extends StatelessWidget {
  final List<String> interests;

  const InterestsSection({super.key, required this.interests});

  @override
  Widget build(BuildContext context) {
    if (interests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children:
              interests
                  .map(
                    (interest) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        interest,
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
