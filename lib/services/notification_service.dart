import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Initialize the notification service
  Future<void> initialize(GlobalKey<NavigatorState>? navigatorKey) async {
    if (_initialized) return;

    _navigatorKey = navigatorKey;

    // Initialize timezone database and set local timezone
    tz.initializeTimeZones();
    try {
      final String localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone));
      debugPrint('🕐 Timezone set to: $localTimezone');
    } catch (e) {
      debugPrint(
        '⚠️ Could not determine local timezone, falling back to UTC: $e',
      );
    }

    // Android settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;

    // Request permissions right after init
    await requestPermissions();
  }

  /// Request notification permissions for both iOS and Android 13+
  Future<bool> requestPermissions() async {
    if (!_initialized) return false;

    // Android 13+ requires runtime POST_NOTIFICATIONS permission
    final androidResult = await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // iOS requires explicit permission grant
    final iosResult = await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final granted = (androidResult ?? true) && (iosResult ?? true);
    debugPrint(
      granted
          ? '✅ Notification permissions granted'
          : '⚠️ Notification permissions denied',
    );
    return granted;
  }

  /// Schedule a notification for a schedule reminder
  Future<void> scheduleReminder({
    required String scheduleId,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!_initialized) await initialize(null);

    // Generate a unique notification ID from the schedule ID
    final notificationId = _generateNotificationId(scheduleId);

    // Convert to TZDateTime
    final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

    // Check if the scheduled time is in the future
    if (tzDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint('⚠️ Cannot schedule notification in the past: $scheduledTime');
      return;
    }

    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      tzDateTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'schedule_reminders',
          'Schedule Reminders',
          channelDescription: 'Notifications for scheduled pet care events',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: scheduleId, // Pass the schedule ID as payload
    );

    debugPrint(
      '✅ Notification scheduled for $scheduledTime (ID: $notificationId)',
    );
  }

  /// Cancel a scheduled notification
  Future<void> cancelReminder(String scheduleId) async {
    if (!_initialized) await initialize(null);

    final notificationId = _generateNotificationId(scheduleId);
    await _notifications.cancel(notificationId);
    debugPrint('🗑️ Notification cancelled (ID: $notificationId)');
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllReminders() async {
    if (!_initialized) await initialize(null);
    await _notifications.cancelAll();
    debugPrint('🗑️ All notifications cancelled');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && _navigatorKey?.currentContext != null) {
      debugPrint('Notification tapped with schedule ID: $payload');
      _navigateToScheduleDetail(payload);
    }
  }

  /// Navigate to schedule detail view
  Future<void> _navigateToScheduleDetail(String scheduleId) async {
    try {
      // Fetch the schedule from Firestore
      final scheduleDoc = await FirebaseFirestore.instance
          .collection('schedules')
          .doc(scheduleId)
          .get();

      if (!scheduleDoc.exists) {
        debugPrint('Schedule not found: $scheduleId');
        return;
      }

      // Navigate to home with calendar tab selected
      final context = _navigatorKey?.currentContext;
      if (context != null && context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
          arguments: 1, // Calendar tab index
        );
      }
    } catch (e) {
      debugPrint('Error navigating to schedule: $e');
    }
  }

  /// Generate a consistent notification ID from schedule ID
  int _generateNotificationId(String scheduleId) {
    // Use hashCode to generate a consistent integer ID
    return scheduleId.hashCode.abs() % 2147483647;
  }

  /// Get all pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) await initialize(null);
    return await _notifications.pendingNotificationRequests();
  }
}
