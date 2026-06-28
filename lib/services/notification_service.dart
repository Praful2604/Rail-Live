import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ── Background message handler (must be top-level function) ──────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message: ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // Android notification channel
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'rail_live_channel',
    'RailLive Notifications',
    description: 'Train updates, PNR alerts and live status notifications',
    importance: Importance.high,
    playSound: true,
  );

  // Global navigator key — set this in main.dart
  static GlobalKey<NavigatorState>? navigatorKey;

  // ── Init ────────────────────────────────────────────────────────────
  Future<void> init() async {
    // 1. Request permission
    await _requestPermission();

    // 2. Setup local notifications
    await _setupLocalNotifications();

    // 3. Create Android channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 4. Handle messages
    _handleForegroundMessages();
    _handleNotificationTap();

    // 5. Print FCM token (for testing)
    final token = await _fcm.getToken();
    print('📱 FCM Token: $token');

    // 6. Token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      print('🔄 FCM Token refreshed: $newToken');
      // TODO: send newToken to your backend
    });
  }

  // ── Permission ──────────────────────────────────────────────────────
  Future<void> _requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print('🔔 Notification permission: ${settings.authorizationStatus}');
  }

  // ── Local notifications setup ───────────────────────────────────────
  Future<void> _setupLocalNotifications() async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationPayload(details.payload);
      },
    );
  }

  // ── Foreground messages ─────────────────────────────────────────────
  void _handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });
  }

  // ── Notification tap (app opened from notification) ─────────────────
  void _handleNotificationTap() {
    // App opened from terminated state
    _fcm.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationPayload(jsonEncode(message.data));
      }
    });

    // App opened from background state
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationPayload(jsonEncode(message.data));
    });
  }

  // ── Show local notification ─────────────────────────────────────────
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF1565C0),
      styleInformation: BigTextStyleInformation(
        notification.body ?? '',
        htmlFormatBigText: false,
        contentTitle: notification.title,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: jsonEncode(message.data),
    );
  }

  // ── Handle payload / navigation ─────────────────────────────────────
  void _handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final type = data['type']?.toString();

      // Navigate based on notification type
      // Add your own routes here as needed
      switch (type) {
        case 'pnr':
          navigatorKey?.currentState?.pushNamed(
            '/pnr',
            arguments: data['pnr'],
          );
          break;
        case 'train_status':
          navigatorKey?.currentState?.pushNamed(
            '/train',
            arguments: data['train_number'],
          );
          break;
        default:
          break;
      }
    } catch (e) {
      print('⚠️ Notification payload parse error: $e');
    }
  }

  // ── Subscribe / Unsubscribe to topics ───────────────────────────────

  /// Subscribe to updates for a specific train
  Future<void> subscribeToTrain(String trainNumber) async {
    await _fcm.subscribeToTopic('train_$trainNumber');
    print('✅ Subscribed to train_$trainNumber');
  }

  Future<void> unsubscribeFromTrain(String trainNumber) async {
    await _fcm.unsubscribeFromTopic('train_$trainNumber');

  }

  /// Subscribe to general RailLive alerts
  Future<void> subscribeToGeneralAlerts() async {
    await _fcm.subscribeToTopic('rail_live_general');

  }

  // ── Get FCM token (to send to backend) ──────────────────────────────
  Future<String?> getToken() => _fcm.getToken();
}