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

    setState(() => isLoading = true);

    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      setState(() => isLoading = false);
      showFloatingSnackBar(context, "User not authenticated.");
      return;
    }

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

    try {
      await profileRepo.createOrUpdateProfile(profile);
      setState(() => isLoading = false);
      showFloatingSnackBar(context, "Profile saved!");
    } catch (e) {
      setState(() => isLoading = false);
      showFloatingSnackBar(context, "Failed to save profile.");
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool requiredField = false,
    bool isSocial = false,
    IconData? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        validator:
            requiredField
                ? (val) => val == null || val.isEmpty ? 'Required' : null
                : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon:
              isSocial
                  ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(prefixIcon, color: Colors.grey[600]),
                  )
                  : null,
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Create Your Profile',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tell us about yourself to connect with others.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
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
                        const Divider(height: 32),
                        Text(
                          'Social Links (Optional)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: instagramController,
                          label: 'Instagram',
                          hint: '@yourhandle',
                          isSocial: true,
                          prefixIcon: Icons.alternate_email,
                        ),
                        _buildTextField(
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
                            onPressed: _submitProfile,
                            child: const Text(
                              'Save & Continue',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
