// file: lib/features/auth/auth_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart'; // Keep if used elsewhere, otherwise can remove
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Keep if used elsewhere, otherwise can remove
import 'auth_repository.dart';
import 'package:near_me/services/notification_service.dart'; // Keep this import, even if not directly used in AuthController itself,
// it's good for overall project structure knowledge.

// Repository provider
final authRepositoryProvider = Provider((ref) => AuthRepository());

// Auth state stream provider
final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

// Auth controller for sign-in / sign-out
final authControllerProvider = Provider<AuthController>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});

class AuthController {
  final AuthRepository _repo;
  AuthController(this._repo);

  // REMOVE THE ENTIRE initPushNotifications() METHOD FROM HERE

  Future<void> signInWithGoogle() => _repo.signInWithGoogle();
  Future<void> signOut() => _repo.signOut();
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print("Signup failed: $e");
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print("Signin failed: $e");
      rethrow;
    }
  }
}
