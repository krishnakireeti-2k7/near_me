// file: lib/features/auth/auth_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/widgets/google_sign_in_button.dart';

class AuthView extends ConsumerStatefulWidget {
  const AuthView({super.key});

  @override
  ConsumerState<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends ConsumerState<AuthView> {
  // ✅ NEW: Added a boolean to track loading state for the button.
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authController = ref.read(authControllerProvider);

    // ✅ NEW: Replaced the old form-based UI with a simpler, cleaner design
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Your app's logo or a large icon
              //
              const SizedBox(height: 48),
              Text(
                "NearMe",
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Discover people and places near you.",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              // ✅ NEW: Google Sign-In Button with loading state
              _isLoading
                  ? const CircularProgressIndicator()
                  : GoogleSignInButton(
                    onPressed: () async {
                      // Set loading to true to show the progress indicator
                      setState(() {
                        _isLoading = true;
                      });
                      try {
                        await authController.signInWithGoogle();
                      } catch (e) {
                        // Handle any sign-in errors gracefully
                        debugPrint('Google Sign-In failed: $e');
                      } finally {
                        // Set loading to false once the process is complete
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    },
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
