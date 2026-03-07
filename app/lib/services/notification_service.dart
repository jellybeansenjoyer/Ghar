import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../config/app_config.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Function(Map<String, dynamic>)? onVisitorArrived;

  static Future<void> initialize() async {
    // Initialize OneSignal
    if (AppConfig.oneSignalAppId.isNotEmpty) {
      OneSignal.initialize(AppConfig.oneSignalAppId);
      OneSignal.Notifications.requestPermission(true);

      // Handle notification opened
      OneSignal.Notifications.addClickListener((event) {
        final data = event.notification.additionalData;
        if (data != null && data['type'] == 'visitor_arrival') {
          onVisitorArrived?.call(Map<String, dynamic>.from(data));
        }
      });

      // Handle notification received in foreground
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        // Don't show the notification banner, we handle it in-app
        event.preventDefault();
        final data = event.notification.additionalData;
        if (data != null && data['type'] == 'visitor_arrival') {
          onVisitorArrived?.call(Map<String, dynamic>.from(data));
        }
      });
    }

    // Initialize local notifications for full-screen intent
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Create Android notification channel for visitor alerts
    const androidChannel = AndroidNotificationChannel(
      'visitor_alerts',
      'Visitor Alerts',
      description: 'Notifications when a visitor arrives at your door',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  static Future<String?> getPlayerId() async {
    if (AppConfig.oneSignalAppId.isEmpty) return null;
    return OneSignal.User.pushSubscription.id;
  }

  static Future<void> showVisitorNotification({
    required String visitorName,
    required String visitorId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'visitor_alerts',
      'Visitor Alerts',
      channelDescription: 'Visitor arrival alerts',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
      autoCancel: false,
      ongoing: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    await _localNotifications.show(
      visitorId.hashCode,
      '🔔 Visitor at the door!',
      '$visitorName is at your door',
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }

  static Future<void> cancelNotification(String visitorId) async {
    await _localNotifications.cancel(visitorId.hashCode);
  }
}
