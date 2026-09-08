import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import '../core/config.dart';
import '../providers/user_provider.dart';

final notificationServiceProvider = Provider((ref) => NotificationService(ref));

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this._ref);

  Future<void> init() async {
    // Request permission for iOS
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print('Notification clicked: ${details.payload}');
      },
    );

    // Get FCM Token
    String? token = await _fcm.getToken();
    if (token != null) {
      print('FCM Token (User): $token');
      await _updateTokenOnBackend(token);
    }

    // Listen for token refreshes
    _fcm.onTokenRefresh.listen(_updateTokenOnBackend);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
  }

  Future<void> _updateTokenOnBackend(String token) async {
    final profile = _ref.read(fullUserProfileProvider).value;
    if (profile == null || profile.id.isEmpty) return;

    try {
      final authService = _ref.read(authServiceProvider);
      final headers = await authService.buildAuthHeaders();
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/user/fcm-token'),
        headers: headers,
        body: jsonEncode({
          'userId': profile.id,
          'fcmToken': token,
        }),
      );

      if (response.statusCode == 200) {
        print('FCM Token (User) updated on backend');
      }
    } catch (e) {
      print('Error updating user FCM Token: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'user_notification_channel',
      'User Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }
}
