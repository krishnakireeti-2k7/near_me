// file: lib/widgets/profile_form.dart

import 'package:flutter/material.dart';
import 'package:near_me/widgets/custom_text_field.dart';

class ProfileForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  // REMOVED: yearController and branchController
  final TextEditingController
  bioController; // Now corresponds to shortBio in model
  final TextEditingController
  tagsController; // MODIFIED: Renamed from interestsController
  final TextEditingController instagramController;
  final TextEditingController twitterController;
  final VoidCallback onSubmit;

  const ProfileForm({
    super.key,
    required this.formKey,
    required this.nameController,
    // REMOVED: required this.yearController,
    // REMOVED: required this.branchController,
    required this.bioController, // ADDED: bioController for shortBio
    required this.tagsController, // MODIFIED: Renamed
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
          // REMOVED: CustomTextField for College Year
          // CustomTextField(
          //   controller: yearController,
          //   label: 'College Year',
          //   hint: 'e.g. 1st, 2nd',
          // ),
          // REMOVED: CustomTextField for Branch / Department
          // CustomTextField(
          //   controller: branchController,
          //   label: 'Branch / Department',
          // ),
          CustomTextField(
            controller: bioController,
            label: 'Short Bio', // Adjusted label to match model
            hint: 'e.g. I love coding and startups!',
          ),
          CustomTextField(
            controller: tagsController, // MODIFIED: Renamed controller
            label: 'Tags', // MODIFIED: Generalised label
            hint:
                'e.g. Hiking, Cooking, Tech (comma separated)', // MODIFIED: Generalised hint
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
            prefixIcon:
                Icons
                    .alternate_email, // You might want to use a custom Instagram icon here
          ),
          CustomTextField(
            controller: twitterController,
            label: 'Twitter',
            hint: '@yourhandle',
            isSocial: true,
            prefixIcon:
                Icons
                    .alternate_email, // You might want to use a custom Twitter icon here
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
