import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/widgets/showFloatingsnackBar.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final yearController = TextEditingController();
  final branchController = TextEditingController();
  final interestsController = TextEditingController();
  final instagramController = TextEditingController();
  final twitterController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    yearController.dispose();
    branchController.dispose();
    interestsController.dispose();
    instagramController.dispose();
    twitterController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    print("Form is valid. Submitting...");

    setState(() => isLoading = true);

    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      print("User is null. Aborting.");
      return;
    }

    print("User UID: ${user.uid}");

    final profileRepo = ref.read(profileRepositoryProvider);

    final profile = UserProfileModel(
      uid: user.uid,
      name: nameController.text.trim(),
      collegeYear: yearController.text.trim(),
      branch: branchController.text.trim(),
      interests:
          interestsController.text
              .trim()
              .split(',')
              .map((e) => e.trim())
              .toList(),
      profileImageUrl: user.photoURL ?? '',
      socialHandles: {
        'instagram': instagramController.text.trim(),
        'twitter': twitterController.text.trim(),
      },
    );

    print("Profile object created. Saving to Firestore...");
    try {
      await profileRepo.createOrUpdateProfile(profile);
      print("Profile saved successfully.");
      setState(() => isLoading = false);
      // Show snackbar
      showFloatingSnackBar(context, "Profile saved!");
    } catch (e) {
      print("Error saving profile: $e");
      setState(() => isLoading = false);
      showFloatingSnackBar(context, "Failed to save profile.");
    }
  }
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool requiredField = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        validator:
            requiredField
                ? (val) => val == null || val.isEmpty ? 'Required' : null
                : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Profile'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: nameController,
                        label: 'Name',
                        requiredField: true,
                      ),
                      _buildTextField(
                        controller: yearController,
                        label: 'College Year',
                        hint: 'e.g. 1st, 2nd',
                      ),
                      _buildTextField(
                        controller: branchController,
                        label: 'Branch / Department',
                      ),
                      _buildTextField(
                        controller: interestsController,
                        label: 'Interests',
                        hint: 'e.g. Flutter, Web Dev (comma separated)',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: instagramController,
                        label: 'Instagram (optional)',
                        hint: '@yourhandle',
                      ),
                      _buildTextField(
                        controller: twitterController,
                        label: 'Twitter (optional)',
                        hint: '@yourhandle',
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.black,
                          ),
                          onPressed: _submitProfile,
                          child: const Text(
                            'Save & Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
