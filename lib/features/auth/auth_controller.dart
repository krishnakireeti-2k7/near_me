import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'auth_repository.dart';
import 'package:near_me/services/notification_service.dart'; // <-- ADD THIS IMPORT

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
    final _firestore = FirebaseFirestore.instance;

    // ADD THIS - Instantiate and initialize our new notification service
    final notificationService = NotificationService();
    await notificationService.initNotifications();

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

    // ADD THIS - Handle messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      if (message.notification != null) {
        notificationService.showNotification(
          title: message.notification!.title!,
          body: message.notification!.body!,
        );
      }
    });
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
