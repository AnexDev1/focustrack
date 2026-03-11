import 'dart:async';
import 'package:flutter/services.dart';

/// Data class for an app usage session from Android UsageStats.
class AndroidAppSession {
  final String packageName;
  final String appName;
  final int startTime;
  final int endTime;
  final int durationMs;

  AndroidAppSession({
    required this.packageName,
    required this.appName,
    required this.startTime,
    required this.endTime,
    required this.durationMs,
  });

  factory AndroidAppSession.fromMap(Map<dynamic, dynamic> map) {
    return AndroidAppSession(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? 'Unknown',
      startTime: map['startTime'] as int? ?? 0,
      endTime: map['endTime'] as int? ?? 0,
      durationMs: map['durationMs'] as int? ?? 0,
    );
  }
}

/// Data class for aggregated app usage stats.
class AndroidAppStats {
  final String packageName;
  final String appName;
  final int totalTimeMs;
  final int lastTimeUsed;

  AndroidAppStats({
    required this.packageName,
    required this.appName,
    required this.totalTimeMs,
    required this.lastTimeUsed,
  });

  factory AndroidAppStats.fromMap(Map<dynamic, dynamic> map) {
    return AndroidAppStats(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? 'Unknown',
      totalTimeMs: map['totalTimeMs'] as int? ?? 0,
      lastTimeUsed: map['lastTimeUsed'] as int? ?? 0,
    );
  }
}

/// Platform channel service to interact with Android's UsageStatsManager.
class AndroidUsageStatsService {
  static const _channel = MethodChannel('com.focustrack/usage_stats');

  /// Check if we have the PACKAGE_USAGE_STATS permission.
  static Future<bool> hasPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasUsagePermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Open the system settings page for granting usage access.
  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestUsagePermission');
    } on PlatformException {
      // ignore
    }
  }

  /// Check if we have the SYSTEM_ALERT_WINDOW (overlay) permission.
  static Future<bool> hasOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasOverlayPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Open settings to grant overlay permission.
  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } on PlatformException {
      // ignore
    }
  }

  /// Check if the app is subject to battery optimization.
  static Future<bool> isBatteryOptimized() async {
    try {
      final result = await _channel.invokeMethod<bool>('isBatteryOptimized');
      return result ?? true;
    } on PlatformException {
      return true;
    }
  }

  /// Request to disable battery optimization for uninterrupted background running.
  static Future<void> requestBatteryOptimization() async {
    try {
      await _channel.invokeMethod('requestBatteryOptimization');
    } on PlatformException {
      // ignore
    }
  }

  /// Start the foreground service for background tracking.
  static Future<void> startForegroundService() async {
    try {
      await _channel.invokeMethod('startForegroundService');
    } on PlatformException {
      // ignore
    }
  }

  /// Stop the foreground service.
  static Future<void> stopForegroundService() async {
    try {
      await _channel.invokeMethod('stopForegroundService');
    } on PlatformException {
      // ignore
    }
  }

  /// Get aggregated usage stats for a time range.
  static Future<List<AndroidAppStats>> getUsageStats(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final result = await _channel
          .invokeMethod<List<dynamic>>('getUsageStats', {
            'startTime': start.millisecondsSinceEpoch,
            'endTime': end.millisecondsSinceEpoch,
          });
      if (result == null) return [];
      return result
          .cast<Map<dynamic, dynamic>>()
          .map((m) => AndroidAppStats.fromMap(m))
          .toList();
    } on PlatformException {
      return [];
    }
  }

  /// Get detailed usage events (individual sessions) for today.
  static Future<List<AndroidAppSession>> getTodayEvents() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getTodayUsageEvents',
      );
      if (result == null) return [];
      return result
          .cast<Map<dynamic, dynamic>>()
          .map((m) => AndroidAppSession.fromMap(m))
          .toList();
    } on PlatformException {
      return [];
    }
  }

  /// Get the human-readable display name for a package.
  static Future<String> getAppDisplayName(String packageName) async {
    try {
      final result = await _channel.invokeMethod<String>('getAppDisplayName', {
        'packageName': packageName,
      });
      return result ?? packageName;
    } on PlatformException {
      return packageName;
    }
  }

  /// Get list of installed (non-system) apps.
  static Future<List<Map<String, String>>> getInstalledApps() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getInstalledApps',
      );
      if (result == null) return [];
      return result.map((item) {
        final map = item as Map<dynamic, dynamic>;
        return {
          'packageName': map['packageName'] as String? ?? '',
          'appName': map['appName'] as String? ?? '',
        };
      }).toList();
    } on PlatformException {
      return [];
    }
  }

  /// Check if we have Do Not Disturb access.
  static Future<bool> hasDndAccess() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasDndAccess');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Open settings to grant DND access.
  static Future<void> requestDndAccess() async {
    try {
      await _channel.invokeMethod('requestDndAccess');
    } on PlatformException {
      // ignore
    }
  }

  /// Check if notification permission is granted (Android 13+).
  static Future<bool> hasNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'hasNotificationPermission',
      );
      return result ?? true;
    } on PlatformException {
      return true;
    }
  }

  /// Request notification permission (Android 13+).
  static Future<void> requestNotificationPermission() async {
    try {
      await _channel.invokeMethod('requestNotificationPermission');
    } on PlatformException {
      // ignore
    }
  }
}
