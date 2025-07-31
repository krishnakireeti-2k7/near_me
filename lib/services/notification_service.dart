// file: lib/services/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

final notificationServiceProvider = Provider((ref) => NotificationService(ref));

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService(this._ref);

  Future<void> initNotifications() async {
    print('NotificationService: initNotifications started.'); // ADD THIS

    try {
      // --- LOCAL NOTIFICATIONS SETUP ---
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
      print(
        'NotificationService: Local notifications initialized.',
      ); // ADD THIS

      // --- FCM SPECIFIC SETUP ---

      // 1. Request permission for notifications
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
      print(
        'NotificationService: User granted notification permission status: ${settings.authorizationStatus}',
      ); // MODIFIED PRINT

      // 2. Get FCM token
      String? token = await _firebaseMessaging.getToken();
      print(
        'NotificationService: FCM Token retrieved: $token',
      ); // MODIFIED PRINT

      // 3. Save FCM token to Firestore
      if (token != null) {
        await _saveFcmToken(token);
      } else {
        print(
          'NotificationService: FCM Token is null, cannot save.',
        ); // ADD THIS
      }

      // 4. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print(
          'NotificationService: Got a message whilst in the foreground!',
        ); // MODIFIED PRINT
        print(
          'NotificationService: Message data: ${message.data}',
        ); // MODIFIED PRINT

        if (message.notification != null) {
          print(
            'NotificationService: Message also contained a notification: ${message.notification}',
          ); // MODIFIED PRINT
          showNotification(
            title: message.notification!.title!,
            body: message.notification!.body!,
          );
        }
      });
      print(
        'NotificationService: Foreground message listener set.',
      ); // ADD THIS
    } catch (e) {
      print('NotificationService: Error during initialization: $e'); // ADD THIS
    }

    print('NotificationService: initNotifications finished.'); // ADD THIS
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
        print(
          'NotificationService: FCM token saved to Firestore for user: ${user.uid}',
        ); // MODIFIED PRINT
      } catch (e) {
        print(
          'NotificationService: Error saving FCM token to Firestore: $e',
        ); // ADD THIS
      }
    } else {
      print(
        'NotificationService: User not logged in, cannot save FCM token.',
      ); // ADD THIS
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
