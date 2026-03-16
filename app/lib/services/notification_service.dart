import 'package:flutter/foundation.dart';
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
      debugPrint('[NotificationService] Initializing OneSignal with app ID: ${AppConfig.oneSignalAppId}');
      OneSignal.initialize(AppConfig.oneSignalAppId);
      OneSignal.Notifications.requestPermission(true);
      
      // Listen for subscription changes
      OneSignal.User.pushSubscription.addObserver((state) {
        debugPrint('[NotificationService] Push subscription state changed: ${state.current.id}');
      });

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
    if (AppConfig.oneSignalAppId.isEmpty) {
      debugPrint('[NotificationService] OneSignal not configured (app ID is empty)');
      return null;
    }
    
    try {
      // Wait for subscription to be available (with timeout)
      String? playerId;
      int attempts = 0;
      const maxAttempts = 10;
      
      while (playerId == null && attempts < maxAttempts) {
        playerId = OneSignal.User.pushSubscription.id;
        if (playerId != null && playerId.isNotEmpty) {
          debugPrint('[NotificationService] OneSignal player ID retrieved: $playerId');
          return playerId;
        }
        attempts++;
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      debugPrint('[NotificationService] WARNING: OneSignal player ID not available after ${maxAttempts} attempts');
      return null;
    } catch (e) {
      debugPrint('[NotificationService] Error getting player ID: $e');
      return null;
    }
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
