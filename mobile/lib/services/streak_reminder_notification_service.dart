import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Local notification: "Come back or you'll lose your streak."
/// Schedules [inactiveMinutes] after the user opened the app; rescheduled on next open.
class StreakReminderNotificationService {
  static const int _streakReminderId = 9001;
  static const String _channelId = 'streak_reminder';
  static const String _channelName = 'Streak reminder';

  static final StreakReminderNotificationService instance =
      StreakReminderNotificationService._();

  StreakReminderNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Inactive minutes before the reminder fires (5 for testing).
  static const int inactiveMinutes = 5;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Bucharest'));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
    );
    const initSettings = InitializationSettings(
      android: android,
      iOS: ios,
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createChannel();
    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {}

  Future<void> _createChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Reminders so you don\'t lose your streak',
      importance: Importance.defaultImportance,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<bool> requestPermissions() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      return true;
    }
    return true;
  }

  Future<void> cancelStreakReminder() async {
    await _plugin.cancel(_streakReminderId);
  }

  Future<void> scheduleStreakReminder() async {
    if (!_initialized) await initialize();
    await cancelStreakReminder();

    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = now.add(Duration(minutes: inactiveMinutes));

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Reminders so you don\'t lose your streak',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      _streakReminderId,
      'ACIO',
      'Come back! You\'re about to lose your streak 🔥',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
