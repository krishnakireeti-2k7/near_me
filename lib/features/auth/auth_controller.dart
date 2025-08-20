import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'auth_repository.dart';
import 'package:near_me/services/notification_service.dart';

// Repository provider
final authRepositoryProvider = Provider((ref) => AuthRepository());

// Auth state stream provider
final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

// ✅ NEW: Add a provider to track if a profile has been created
final profileCreationStatusProvider = StateProvider<bool>((ref) => false);

// Auth controller for sign-in / sign-out
final authControllerProvider = Provider<AuthController>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});

class AuthController {
  final AuthRepository _repo;
  AuthController(this._repo);

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
