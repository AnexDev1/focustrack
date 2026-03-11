import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:flutter/services.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focustrack/database/app_usage_database.dart';
import 'package:focustrack/providers/database_provider.dart';
import 'package:focustrack/services/android_usage_service.dart';
import 'package:focustrack/services/notification_service.dart';

/// Represents a time limit set on an app.
class AppLimit {
  final String appName;
  final int limitMinutes; // daily limit in minutes
  final bool enabled;

  AppLimit({
    required this.appName,
    required this.limitMinutes,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'appName': appName,
    'limitMinutes': limitMinutes,
    'enabled': enabled,
  };

  factory AppLimit.fromJson(Map<String, dynamic> json) => AppLimit(
    appName: json['appName'] as String,
    limitMinutes: json['limitMinutes'] as int,
    enabled: json['enabled'] as bool? ?? true,
  );
}

/// Tracks app limits and checks usage against them.
class AppLimitsService {
  static const _limitsKey = 'app_limits';
  static const _dailyGoalKey = 'daily_screen_time_goal';
  static const _notifiedAppsKey = 'notified_limit_apps';
  static const _notifiedMilestonesKey = 'notified_milestones';
  static const _notifMilestonesEnabledKey = 'notif_milestones';
  static const _notifUsageScopeKey = 'notif_usage_scope';
  static const _channel = MethodChannel('com.focustrack/usage_stats');

  Timer? _checkTimer;

  /// Load all saved app limits.
  static Future<List<AppLimit>> getLimits() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_limitsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => AppLimit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Save all app limits.
  static Future<void> saveLimits(List<AppLimit> limits) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(limits.map((l) => l.toJson()).toList());
    await prefs.setString(_limitsKey, json);
  }

  /// Add or update a limit for a specific app.
  static Future<void> setLimit(String appName, int limitMinutes) async {
    final limits = await getLimits();
    final index = limits.indexWhere((l) => l.appName == appName);
    if (index >= 0) {
      limits[index] = AppLimit(
        appName: appName,
        limitMinutes: limitMinutes,
        enabled: true,
      );
    } else {
      limits.add(AppLimit(appName: appName, limitMinutes: limitMinutes));
    }
    await saveLimits(limits);
  }

  /// Remove a limit for a specific app.
  static Future<void> removeLimit(String appName) async {
    final limits = await getLimits();
    limits.removeWhere((l) => l.appName == appName);
    await saveLimits(limits);
  }

  /// Toggle enable/disable of a limit.
  static Future<void> toggleLimit(String appName, bool enabled) async {
    final limits = await getLimits();
    final index = limits.indexWhere((l) => l.appName == appName);
    if (index >= 0) {
      limits[index] = AppLimit(
        appName: limits[index].appName,
        limitMinutes: limits[index].limitMinutes,
        enabled: enabled,
      );
      await saveLimits(limits);
    }
  }

  /// Get the daily screen time goal in minutes (0 = no goal).
  static Future<int> getDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyGoalKey) ?? 0;
  }

  /// Set the daily screen time goal in minutes.
  static Future<void> setDailyGoal(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyGoalKey, minutes);
  }

  /// Clear the "already notified" set (call at midnight or on new day).
  static Future<void> resetNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notifiedAppsKey);
    await prefs.remove(_notifiedMilestonesKey);
  }

  static Future<String> getNotificationUsageScope() async {
    final prefs = await SharedPreferences.getInstance();
    final scope = prefs.getString(_notifUsageScopeKey);
    return scope == 'combined' ? 'combined' : 'mobile';
  }

  static Future<void> setNotificationUsageScope(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = scope == 'combined' ? 'combined' : 'mobile';
    await prefs.setString(_notifUsageScopeKey, normalized);
    await prefs.remove(_notifiedMilestonesKey);
  }

  /// Check all limits against current usage and fire notifications.
  Future<void> checkLimits() async {
    if (!Platform.isAndroid) return;
    final hasPermission = await AndroidUsageStatsService.hasPermission();
    if (!hasPermission) return;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final stats = await AndroidUsageStatsService.getUsageStats(startOfDay, now);

    final limits = await getLimits();
    final prefs = await SharedPreferences.getInstance();

    // Per-app limits
    final notifiedApps = (prefs.getStringList(_notifiedAppsKey) ?? []).toSet();

    final blockedPackages = <String>[];

    for (final limit in limits) {
      if (!limit.enabled) continue;
      final stat = stats.firstWhere(
        (s) => s.appName == limit.appName,
        orElse: () => AndroidAppStats(
          packageName: '',
          appName: limit.appName,
          totalTimeMs: 0,
          lastTimeUsed: 0,
        ),
      );
      final usedMinutes = stat.totalTimeMs ~/ 60000;

      // 80% warning
      final warningKey = '${limit.appName}_80';
      if (usedMinutes >= (limit.limitMinutes * 0.8).round() &&
          !notifiedApps.contains(warningKey)) {
        await NotificationService.showLimitWarning(
          limit.appName,
          limit.limitMinutes,
          usedMinutes,
        );
        notifiedApps.add(warningKey);
      }

      // 100% reached
      final reachedKey = '${limit.appName}_100';
      if (usedMinutes >= limit.limitMinutes) {
        if (!notifiedApps.contains(reachedKey)) {
          await NotificationService.showLimitReached(
            limit.appName,
            limit.limitMinutes,
          );
          notifiedApps.add(reachedKey);
        }
        // Add to blocked list using package name
        if (stat.packageName.isNotEmpty) {
          blockedPackages.add(stat.packageName);
        }
      }
    }

    // Update app blocker with exceeded apps
    if (blockedPackages.isNotEmpty) {
      await _startAppBlocker(blockedPackages);
    } else {
      await _stopAppBlocker();
    }

    await prefs.setStringList(_notifiedAppsKey, notifiedApps.toList());

    // Daily screen time milestones
    final notifiedMilestones =
        (prefs.getStringList(_notifiedMilestonesKey) ?? []).toSet();
    final milestonesEnabled = prefs.getBool(_notifMilestonesEnabledKey) ?? true;
    final scope = await getNotificationUsageScope();
    final mobileOnlyNotifications = scope != 'combined';
    final totalMinutes = await _getNotificationTotalMinutes(stats, now, scope);

    // Milestone notifications at 1h, 2h, 4h, 6h, 8h
    if (milestonesEnabled) {
      final reachedMilestones = [
        60,
        120,
        240,
        360,
        480,
      ].where((hourMark) => totalMinutes >= hourMark).toList();
      if (reachedMilestones.isNotEmpty) {
        final highestReached = reachedMilestones.last;
        final key = 'milestone_$highestReached';
        if (!notifiedMilestones.contains(key)) {
          await NotificationService.showScreenTimeMilestone(
            highestReached ~/ 60,
            totalMinutes,
            mobileOnly: mobileOnlyNotifications,
          );
          notifiedMilestones.add(key);
        }
      }
    }

    // Daily goal check
    final dailyGoal = await getDailyGoal();
    if (dailyGoal > 0 && totalMinutes >= dailyGoal) {
      final goalKey = 'daily_goal';
      if (!notifiedMilestones.contains(goalKey)) {
        await NotificationService.showDailyGoalReached(
          dailyGoal,
          mobileOnly: mobileOnlyNotifications,
        );
        notifiedMilestones.add(goalKey);
      }
    }

    await prefs.setStringList(
      _notifiedMilestonesKey,
      notifiedMilestones.toList(),
    );
  }

  /// Start periodic limit checking (every 1 minute).
  void startMonitoring() {
    _checkTimer?.cancel();
    checkLimits(); // immediate check
    _checkTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => checkLimits(),
    );
  }

  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _stopAppBlocker();
  }

  /// Start the app blocker service with the given package names.
  static Future<void> _startAppBlocker(List<String> packageNames) async {
    if (!Platform.isAndroid || packageNames.isEmpty) return;
    try {
      await _channel.invokeMethod('startAppBlocker', {
        'blockedApps': packageNames,
      });
    } on PlatformException {
      // ignore
    }
  }

  /// Stop the app blocker service.
  static Future<void> _stopAppBlocker() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stopAppBlocker');
    } on PlatformException {
      // ignore
    }
  }

  /// Update the list of blocked apps in the running service.
  static Future<void> _updateBlockedApps(List<String> packageNames) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('updateBlockedApps', {
        'blockedApps': packageNames,
      });
    } on PlatformException {
      // ignore
    }
  }

  /// Immediately re-evaluate which apps are blocked and update AppBlockerService.
  /// Call this after any limit change (add/remove/toggle) for instant effect.
  static Future<void> syncBlockerNow() async {
    if (!Platform.isAndroid) return;
    final hasPermission = await AndroidUsageStatsService.hasPermission();
    if (!hasPermission) return;

    final limits = await getLimits();
    final enabledLimits = limits.where((l) => l.enabled).toList();
    if (enabledLimits.isEmpty) {
      await _stopAppBlocker();
      return;
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final stats = await AndroidUsageStatsService.getUsageStats(startOfDay, now);

    final blockedPackages = <String>[];
    for (final limit in enabledLimits) {
      final stat = stats.firstWhere(
        (s) => s.appName == limit.appName,
        orElse: () => AndroidAppStats(
          packageName: '',
          appName: limit.appName,
          totalTimeMs: 0,
          lastTimeUsed: 0,
        ),
      );
      final usedMinutes = stat.totalTimeMs ~/ 60000;
      if (usedMinutes >= limit.limitMinutes && stat.packageName.isNotEmpty) {
        blockedPackages.add(stat.packageName);
      }
    }

    if (blockedPackages.isNotEmpty) {
      await _startAppBlocker(blockedPackages);
    } else {
      await _stopAppBlocker();
    }
  }

  /// Get usage status for each limited app (for UI display).
  static Future<List<AppLimitStatus>> getLimitStatuses() async {
    if (!Platform.isAndroid) return [];

    final limits = await getLimits();
    if (limits.isEmpty) return [];

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final stats = await AndroidUsageStatsService.getUsageStats(startOfDay, now);

    return limits.map((limit) {
      final stat = stats.firstWhere(
        (s) => s.appName == limit.appName,
        orElse: () => AndroidAppStats(
          packageName: '',
          appName: limit.appName,
          totalTimeMs: 0,
          lastTimeUsed: 0,
        ),
      );
      final usedMinutes = stat.totalTimeMs ~/ 60000;
      return AppLimitStatus(
        limit: limit,
        usedMinutes: usedMinutes,
        exceeded: usedMinutes >= limit.limitMinutes,
        percentage: limit.limitMinutes > 0
            ? (usedMinutes / limit.limitMinutes * 100).clamp(0, 100)
            : 0,
      );
    }).toList();
  }

  static Future<int> _getNotificationTotalMinutes(
    List<AndroidAppStats> stats,
    DateTime now,
    String scope,
  ) async {
    final mobileMinutes = stats.fold<int>(0, (sum, stat) {
      return sum + (stat.totalTimeMs ~/ 60000);
    });

    if (scope != 'combined') {
      return mobileMinutes;
    }

    final desktopMinutes = await _getDesktopMinutesFromDatabase(now);
    return mobileMinutes + desktopMinutes;
  }

  static Future<int> _getDesktopMinutesFromDatabase(DateTime now) async {
    final appDir = await resolveDatabaseDirectory();
    final file = File(p.join(appDir.path, 'app_usage.db'));
    final database = AppUsageDatabase(NativeDatabase(file));

    try {
      final startOfDay = DateTime(now.year, now.month, now.day);
      final sessions = await database.getSessionsInDateRangeBySource(
        startOfDay,
        now,
        source: 'desktop',
      );
      final totalMs = sessions.fold<int>(0, (sum, session) {
        return sum + session.durationMs;
      });
      return totalMs ~/ 60000;
    } finally {
      await database.close();
    }
  }
}

/// Status of an app limit including current usage.
class AppLimitStatus {
  final AppLimit limit;
  final int usedMinutes;
  final bool exceeded;
  final double percentage;

  AppLimitStatus({
    required this.limit,
    required this.usedMinutes,
    required this.exceeded,
    required this.percentage,
  });
}

/// Riverpod provider for app limits service.
final appLimitsServiceProvider = Provider<AppLimitsService>((ref) {
  return AppLimitsService();
});

/// Provider for current limit statuses (refreshable).
final appLimitStatusesProvider = FutureProvider<List<AppLimitStatus>>((
  ref,
) async {
  return AppLimitsService.getLimitStatuses();
});
