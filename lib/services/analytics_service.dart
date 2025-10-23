import 'dart:convert';
import 'dart:io';
import 'package:focustrack/database/app_usage_database.dart';
import 'package:focustrack/models/app_category.dart';
import 'package:path_provider/path_provider.dart';

enum AnalyticsPeriod { today, yesterday, thisWeek, thisMonth, custom }

class AnalyticsData {
  final DateTime startDate;
  final DateTime endDate;
  final int totalDuration;
  final int totalSessions;
  final int totalApps;
  final Map<String, int> appUsage;
  final Map<String, int> categoryUsage;
  final Map<DateTime, int> dailyUsage;
  final String focusScore;

  AnalyticsData({
    required this.startDate,
    required this.endDate,
    required this.totalDuration,
    required this.totalSessions,
    required this.totalApps,
    required this.appUsage,
    required this.categoryUsage,
    required this.dailyUsage,
    required this.focusScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'period': {
        'start': startDate.toIso8601String(),
        'end': endDate.toIso8601String(),
      },
      'summary': {
        'totalDuration': totalDuration,
        'totalDurationFormatted': _formatDuration(totalDuration),
        'totalSessions': totalSessions,
        'totalApps': totalApps,
        'focusScore': focusScore,
      },
      'appUsage': appUsage.map(
        (key, value) => MapEntry(key, {
          'duration': value,
          'formatted': _formatDuration(value),
          'percentage': totalDuration > 0
              ? (value / totalDuration * 100).toStringAsFixed(1)
              : '0.0',
        }),
      ),
      'categoryUsage': categoryUsage.map(
        (key, value) => MapEntry(key, {
          'duration': value,
          'formatted': _formatDuration(value),
          'percentage': totalDuration > 0
              ? (value / totalDuration * 100).toStringAsFixed(1)
              : '0.0',
        }),
      ),
      'dailyUsage': dailyUsage.map(
        (key, value) => MapEntry(key.toIso8601String(), {
          'duration': value,
          'formatted': _formatDuration(value),
        }),
      ),
    };
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '< 1m';
    }
  }
}

class AnalyticsService {
  final AppUsageDatabase database;

  AnalyticsService(this.database);

  Future<AnalyticsData> getAnalytics(
    AnalyticsPeriod period, {
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    List<AppUsageSession> sessions;
    DateTime startDate;
    DateTime endDate = DateTime.now();

    switch (period) {
      case AnalyticsPeriod.today:
        sessions = await database.getTodaySessions();
        startDate = DateTime(endDate.year, endDate.month, endDate.day);
        break;
      case AnalyticsPeriod.yesterday:
        sessions = await database.getYesterdaySessions();
        final yesterday = endDate.subtract(const Duration(days: 1));
        startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
        endDate = DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          23,
          59,
          59,
        );
        break;
      case AnalyticsPeriod.thisWeek:
        sessions = await database.getThisWeekSessions();
        startDate = endDate.subtract(Duration(days: endDate.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case AnalyticsPeriod.thisMonth:
        sessions = await database.getThisMonthSessions();
        startDate = DateTime(endDate.year, endDate.month, 1);
        break;
      case AnalyticsPeriod.custom:
        if (customStart == null || customEnd == null) {
          throw ArgumentError('Custom period requires start and end dates');
        }
        sessions = await database.getSessionsInDateRange(
          customStart,
          customEnd,
        );
        startDate = customStart;
        endDate = customEnd;
        break;
    }

    return _processAnalytics(sessions, startDate, endDate);
  }

  AnalyticsData _processAnalytics(
    List<AppUsageSession> sessions,
    DateTime startDate,
    DateTime endDate,
  ) {
    final appUsage = <String, int>{};
    final categoryUsage = <String, int>{};
    final dailyUsage = <DateTime, int>{};
    int totalDuration = 0;
    int productiveDuration = 0;

    for (var session in sessions) {
      final duration = session.durationMs;
      totalDuration += duration;

      // App usage
      appUsage[session.appName] = (appUsage[session.appName] ?? 0) + duration;

      // Category usage
      final category = AppCategoryExtension.fromAppName(session.appName);
      final categoryName = category.displayName;
      categoryUsage[categoryName] =
          (categoryUsage[categoryName] ?? 0) + duration;

      // Productive time
      if (category == AppCategory.work ||
          category == AppCategory.development ||
          category == AppCategory.productivity) {
        productiveDuration += duration;
      }

      // Daily usage
      final day = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      dailyUsage[day] = (dailyUsage[day] ?? 0) + duration;
    }

    final focusScore = totalDuration > 0
        ? '${((productiveDuration / totalDuration) * 100).toInt()}%'
        : '0%';

    return AnalyticsData(
      startDate: startDate,
      endDate: endDate,
      totalDuration: totalDuration,
      totalSessions: sessions.length,
      totalApps: appUsage.keys.length,
      appUsage: appUsage,
      categoryUsage: categoryUsage,
      dailyUsage: dailyUsage,
      focusScore: focusScore,
    );
  }

  Future<String> exportToJson(AnalyticsData data) async {
    final jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(data.toJson());
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/focustrack_export_$timestamp.json');
    await file.writeAsString(jsonString);
    return file.path;
  }

  Future<String> exportToCsv(AnalyticsData data) async {
    final buffer = StringBuffer();

    // Summary
    buffer.writeln('FocusTrack Analytics Export');
    buffer.writeln(
      'Period,${data.startDate.toIso8601String()},${data.endDate.toIso8601String()}',
    );
    buffer.writeln('Total Duration,${data.totalDuration}ms');
    buffer.writeln('Total Sessions,${data.totalSessions}');
    buffer.writeln('Total Apps,${data.totalApps}');
    buffer.writeln('Focus Score,${data.focusScore}');
    buffer.writeln();

    // App usage
    buffer.writeln('App Usage');
    buffer.writeln('App Name,Duration (ms),Percentage');
    final sortedApps = data.appUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (var entry in sortedApps) {
      final percentage = data.totalDuration > 0
          ? (entry.value / data.totalDuration * 100).toStringAsFixed(1)
          : '0.0';
      buffer.writeln('${entry.key},${entry.value},$percentage%');
    }
    buffer.writeln();

    // Category usage
    buffer.writeln('Category Usage');
    buffer.writeln('Category,Duration (ms),Percentage');
    final sortedCategories = data.categoryUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (var entry in sortedCategories) {
      final percentage = data.totalDuration > 0
          ? (entry.value / data.totalDuration * 100).toStringAsFixed(1)
          : '0.0';
      buffer.writeln('${entry.key},${entry.value},$percentage%');
    }
    buffer.writeln();

    // Daily usage
    buffer.writeln('Daily Usage');
    buffer.writeln('Date,Duration (ms)');
    final sortedDays = data.dailyUsage.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (var entry in sortedDays) {
      buffer.writeln('${entry.key.toIso8601String()},${entry.value}');
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/focustrack_export_$timestamp.csv');
    await file.writeAsString(buffer.toString());
    return file.path;
  }
}
