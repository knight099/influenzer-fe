import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'data/notification_repository.dart';

/// Top-level handler for background FCM messages (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are auto-shown by the OS when app is terminated.
  // Nothing needed here unless you want custom processing.
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final _localNotif = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'influenzer_high',
    'Influenzer Notifications',
    description: 'Proposals, messages, and campaign alerts',
    importance: Importance.high,
    playSound: true,
  );

  Future<void> init(NotificationRepository repo) async {
    // Request permission (iOS + Android 13+)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Create Android notification channel
    await _localNotif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Init local notifications plugin
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotif.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotifTap,
    );

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground message handler — show local notification
    FirebaseMessaging.onMessage.listen((message) {
      final notif = message.notification;
      if (notif == null) return;
      _localNotif.show(
        notif.hashCode,
        notif.title,
        notif.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    });

    // Register FCM token with backend
    await _registerToken(repo);

    // Handle token refresh
    _fcm.onTokenRefresh.listen((newToken) => repo.registerDeviceToken(
          newToken,
          Platform.isAndroid ? 'android' : 'ios',
        ));
  }

  Future<void> _registerToken(NotificationRepository repo) async {
    try {
      final token = kIsWeb
          ? await _fcm.getToken(vapidKey: null)
          : await _fcm.getToken();
      if (token != null) {
        await repo.registerDeviceToken(
          token,
          kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : 'ios'),
        );
      }
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }
  }

  void _onNotifTap(NotificationResponse response) {
    // TODO: Navigate based on payload when deep linking is implemented
    debugPrint('[Notif] Tapped: ${response.payload}');
  }
}
