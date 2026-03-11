import 'dart:io' show Platform;
import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Centralized notification service for FocusTrack.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Initialize the notification plugin. Call once at app startup.
  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;

    // Request notification permission on Android 13+
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  // --- Channel definitions ---

  static const _limitsChannel = AndroidNotificationDetails(
    'app_limits',
    'App Limits',
    channelDescription:
        'Notifications when app time limits are approaching or reached',
    importance: Importance.high,
    priority: Priority.high,
    color: Color(0xFF6C63FF),
  );

  static const _milestonesChannel = AndroidNotificationDetails(
    'milestones',
    'Screen Time Milestones',
    channelDescription: 'Notifications for screen time milestones',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    color: Color(0xFF00E676),
  );

  static const _goalChannel = AndroidNotificationDetails(
    'daily_goal',
    'Daily Goal',
    channelDescription: 'Notification when daily screen time goal is reached',
    importance: Importance.high,
    priority: Priority.high,
    color: Color(0xFFFF9800),
  );

  static const _reminderChannel = AndroidNotificationDetails(
    'reminders',
    'Reminders',
    channelDescription: 'Break reminders and usage check-ins',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    color: Color(0xFF0EA5E9),
  );

  /// Notification when an app is approaching its time limit (80%).
  static Future<void> showLimitWarning(
    String appName,
    int limitMinutes,
    int usedMinutes,
  ) async {
    await _ensureInit();
    final remaining = limitMinutes - usedMinutes;
    await _plugin.show(
      appName.hashCode,
      '$appName — Limit Warning',
      'You\'ve used ${_formatMinutes(usedMinutes)} of your ${_formatMinutes(limitMinutes)} limit. ~${_formatMinutes(remaining)} remaining.',
      const NotificationDetails(android: _limitsChannel),
    );
  }

  /// Notification when an app has reached its time limit.
  static Future<void> showLimitReached(String appName, int limitMinutes) async {
    await _ensureInit();
    await _plugin.show(
      appName.hashCode + 1000,
      '$appName — Time Limit Reached',
      'You\'ve reached your ${_formatMinutes(limitMinutes)} daily limit for $appName. Consider taking a break.',
      const NotificationDetails(android: _limitsChannel),
    );
  }

  /// Notification for screen time milestone (1h, 2h, 4h, etc).
  static Future<void> showScreenTimeMilestone(
    int hours,
    int totalMinutes,
  ) async {
    await _ensureInit();
    await _plugin.show(
      2000 + hours,
      'Screen Time: ${_formatMinutes(totalMinutes)}',
      'You\'ve been on your phone for ${hours}h today. Time for a break?',
      const NotificationDetails(android: _milestonesChannel),
    );
  }

  /// Notification when daily screen time goal is reached.
  static Future<void> showDailyGoalReached(int goalMinutes) async {
    await _ensureInit();
    await _plugin.show(
      3000,
      'Daily Screen Time Goal Reached',
      'You\'ve hit your ${_formatMinutes(goalMinutes)} daily screen time goal. Great awareness!',
      const NotificationDetails(android: _goalChannel),
    );
  }

  /// Break reminder notification.
  static Future<void> showBreakReminder(int minutesSinceLastBreak) async {
    await _ensureInit();
    await _plugin.show(
      4000,
      'Time for a Break',
      'You\'ve been using your phone for ${_formatMinutes(minutesSinceLastBreak)} straight. Rest your eyes!',
      const NotificationDetails(android: _reminderChannel),
    );
  }

  /// Format minutes to human readable.
  static String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    return '${minutes}m';
  }

  static Future<void> _ensureInit() async {
    if (!_initialized) await init();
  }
}
