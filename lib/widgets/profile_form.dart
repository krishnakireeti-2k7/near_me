import 'package:flutter/material.dart';
import 'package:near_me/widgets/custom_text_field.dart';

class ProfileForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController yearController;
  final TextEditingController branchController;
  final TextEditingController bioController;
  final TextEditingController interestsController;
  final TextEditingController instagramController;
  final TextEditingController twitterController;
  final VoidCallback onSubmit;

  const ProfileForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.yearController,
    required this.branchController,
    required this.bioController,
    required this.interestsController,
    required this.instagramController,
    required this.twitterController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tell us about yourself to connect with others.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            controller: nameController,
            label: 'Name',
            requiredField: true,
          ),
          CustomTextField(
            controller: yearController,
            label: 'College Year',
            hint: 'e.g. 1st, 2nd',
          ),
          CustomTextField(
            controller: branchController,
            label: 'Branch / Department',
          ),
          CustomTextField(
            controller: bioController,
            label: 'Short Bio',
            hint: 'e.g. I love coding and startups!',
          ),
          CustomTextField(
            controller: interestsController,
            label: 'Interests',
            hint: 'e.g. Flutter, Web Dev (comma separated)',
          ),
          const SizedBox(height: 12),
          const Divider(height: 32),
          Text(
            'Social Links (Optional)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: instagramController,
            label: 'Instagram',
            hint: '@yourhandle',
            isSocial: true,
            prefixIcon: Icons.alternate_email,
          ),
          CustomTextField(
            controller: twitterController,
            label: 'Twitter',
            hint: '@yourhandle',
            isSocial: true,
            prefixIcon: Icons.alternate_email,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: onSubmit,
              child: const Text(
                'Save & Continue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
