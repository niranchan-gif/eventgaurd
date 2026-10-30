import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

class AlarmNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static bool _isVibrating = false;

  static const String channelId = 'eventguard_deploy_alarm';
  static const String channelName = 'EventGuard Emergency Deploy Alarms';

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[NOTIFICATION] Clicked payload: ${response.payload}');
          stopAlarm();
        },
      );

      // Create Android Notification Channel with maximum importance and alarm vibration
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Request notification permissions for Android 13+
        await androidImplementation.requestNotificationsPermission();

        final AndroidNotificationChannel channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description:
              'Urgent crowd safety dispatch alarms that ring and vibrate even when screen is locked or app is in background',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 400, 1000, 400, 1500]),
        );

        await androidImplementation.createNotificationChannel(channel);
      }

      _isInitialized = true;
      debugPrint('[NOTIFICATION] AlarmNotificationService initialized successfully.');
    } catch (e) {
      debugPrint('[NOTIFICATION INIT ERROR] $e');
    }
  }

  /// Triggers full emergency notification with sound and vibration
  static Future<void> triggerDeployAlarm({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await initialize();

      // Start hardware vibration
      startVibration();

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'EventGuard Urgent Deployment Alarms',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 400, 1000, 400, 1500]),
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        playSound: true,
        ongoing: true, // Keep notification visible until acknowledged
        autoCancel: false,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id: 999,
        title: '🚨 $title',
        body: body,
        notificationDetails: platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[TRIGGER ALARM ERROR] $e');
    }
  }

  /// Start repeating heavy vibration pattern for emergency alarms
  static Future<void> startVibration() async {
    try {
      final hasVib = await Vibration.hasVibrator();
      if (hasVib == true && !_isVibrating) {
        _isVibrating = true;
        // [delay, vibrate, sleep, vibrate, sleep, vibrate]
        Vibration.vibrate(
          pattern: [0, 800, 300, 800, 300, 1200],
          intensities: [0, 255, 0, 255, 0, 255],
          repeat: 0, // 0 means repeat continuously from pattern start
        );
      }
    } catch (e) {
      debugPrint('[VIBRATION ERROR] $e');
    }
  }

  /// Cancel both notification and continuous vibration
  static Future<void> stopAlarm() async {
    try {
      _isVibrating = false;
      await Vibration.cancel();
      await _notificationsPlugin.cancel(id: 999);
      debugPrint('[ALARM] Alarm sound and vibration stopped.');
    } catch (e) {
      debugPrint('[STOP ALARM ERROR] $e');
    }
  }
}
