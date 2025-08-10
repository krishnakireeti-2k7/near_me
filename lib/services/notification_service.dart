// file: lib/services/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ✅ NEW: Import for sending notifications
import 'package:http/http.dart' as http;
// ✅ NEW: Import for encoding data
import 'dart:convert';
import 'package:flutter/foundation.dart'; // To use debugPrint

final notificationServiceProvider = Provider((ref) => NotificationService(ref));

// ✅ NEW: Provider for the outgoing notification service
final outgoingNotificationServiceProvider = Provider(
  (ref) => OutgoingNotificationService(),
);

// Your existing NotificationService class for INCOMING notifications
class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService(this._ref);

  Future<void> initNotifications() async {
    debugPrint('NotificationService: initNotifications started.');

    try {
      // --- LOCAL NOTIFICATIONS SETUP ---
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
      debugPrint('NotificationService: Local notifications initialized.');

      // --- FCM SPECIFIC SETUP ---
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );
      debugPrint(
        'NotificationService: User granted notification permission status: ${settings.authorizationStatus}',
      );

      String? token = await _firebaseMessaging.getToken();
      debugPrint('NotificationService: FCM Token retrieved: $token');

      if (token != null) {
        await _saveFcmToken(token);
      } else {
        debugPrint('NotificationService: FCM Token is null, cannot save.');
      }

      // 4. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          'NotificationService: Got a message whilst in the foreground!',
        );
        debugPrint('NotificationService: Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint(
            'NotificationService: Message also contained a notification: ${message.notification}',
          );
          showNotification(
            title: message.notification!.title!,
            body: message.notification!.body!,
          );
        }
      });
      debugPrint('NotificationService: Foreground message listener set.');
    } catch (e) {
      debugPrint('NotificationService: Error during initialization: $e');
    }

    debugPrint('NotificationService: initNotifications finished.');
  }

  Future<void> _saveFcmToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _ref
            .read(profileRepositoryProvider)
            .updateUserProfileField(
              uid: user.uid,
              field: 'fcmToken',
              value: token,
            );
        debugPrint(
          'NotificationService: FCM token saved to Firestore for user: ${user.uid}',
        );
      } catch (e) {
        debugPrint(
          'NotificationService: Error saving FCM token to Firestore: $e',
        );
      }
    } else {
      debugPrint(
        'NotificationService: User not logged in, cannot save FCM token.',
      );
    }
  }

  void showNotification({required String title, required String body}) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    _flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      platformChannelSpecifics,
    );
  }
}

// ✅ NEW: Class for OUTGOING notifications
class OutgoingNotificationService {
  // IMPORTANT: Replace with your Cloud Function URL
  final String _cloudFunctionUrl = 'YOUR_CLOUD_FUNCTION_URL';

  Future<void> sendNotification({
    required String recipientToken,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    final Map<String, dynamic> notificationData = {
      'token': recipientToken,
      'title': title,
      'body': body,
      'data': data,
    };

    try {
      final response = await http.post(
        Uri.parse(_cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(notificationData),
      );
      if (response.statusCode != 200) {
        debugPrint('Failed to send notification: ${response.body}');
      } else {
        debugPrint('Notification successfully sent!');
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }
}
