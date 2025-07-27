import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Add this import
import 'auth_repository.dart';

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

  // New method to handle push notifications
  // Inside your AuthController class

  Future<void> initPushNotifications() async {
    final _firebaseMessaging = FirebaseMessaging.instance;
    final _firestore = FirebaseFirestore.instance; // Add this

    // Request permission
    await _firebaseMessaging.requestPermission();

    // Get the token
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Get the current user's UID
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      // Save the token to the user's document in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
      print('FCM token saved for user: ${user.uid}');
    }
  }

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
