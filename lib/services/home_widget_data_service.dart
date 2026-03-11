import 'dart:io' show Platform;
import 'package:home_widget/home_widget.dart';
import 'package:focustrack/services/android_usage_service.dart';
import 'package:focustrack/widgets/home_widgets.dart';

/// Updates home screen widget data from current usage stats.
class HomeWidgetDataService {
  /// Refresh all widget data keys with the latest tracking information.
  static Future<void> updateWidgetData() async {
    if (!Platform.isAndroid) return;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    // Fetch today's usage stats
    final stats = await AndroidUsageStatsService.getUsageStats(startOfDay, now);
    stats.sort((a, b) => b.totalTimeMs.compareTo(a.totalTimeMs));

    // Filter out very short sessions (< 1 second)
    final meaningful = stats.where((s) => s.totalTimeMs > 1000).toList();

    // Total screen time
    final totalMs = meaningful.fold<int>(0, (sum, s) => sum + s.totalTimeMs);
    final totalHrs = totalMs / 3600000;
    final timeStr = totalHrs >= 1
        ? '${totalHrs.toStringAsFixed(1)}h'
        : '${(totalMs / 60000).round()}m';

    // Top app
    final topApp = meaningful.isNotEmpty ? meaningful.first.appName : 'No data';

    // Session count (approx from events)
    final events = await AndroidUsageStatsService.getTodayEvents();
    final sessionCount = events.length;

    // App count
    final appCount = meaningful.length;

    // Focus score (simple: fewer switches = higher focus)
    final focusScore = _computeFocusScore(events, totalMs);
    final focusLabel = focusScore >= 80
        ? 'Excellent'
        : focusScore >= 60
        ? 'Good'
        : focusScore >= 40
        ? 'Fair'
        : 'Low';

    // Top 3 apps
    String topName(int i) =>
        i < meaningful.length ? meaningful[i].appName : '--';
    String topTime(int i) {
      if (i >= meaningful.length) return '--';
      final ms = meaningful[i].totalTimeMs;
      if (ms >= 3600000) return '${(ms / 3600000).toStringAsFixed(1)}h';
      return '${(ms / 60000).round()}m';
    }

    // Save all data keys via home_widget
    final data = <String, String>{
      // Screen Time Widget
      'todayTime': timeStr,
      'topApp': '\u25b8 $topApp',
      'sessionCount': '$sessionCount',
      'appCount': '$appCount',

      // Focus Score Widget
      'focusScore': '$focusScore',
      'focusLabel': focusLabel,

      // Top Apps Widget
      'top1Name': topName(0),
      'top1Time': topTime(0),
      'top2Name': topName(1),
      'top2Time': topTime(1),
      'top3Name': topName(2),
      'top3Time': topTime(2),

      // Quick Stats Widget
      'qsTime': timeStr,
      'qsApps': '$appCount',
      'qsSessions': '$sessionCount',
      'qsFocus': '$focusScore',
    };

    for (final entry in data.entries) {
      await HomeWidget.saveWidgetData(entry.key, entry.value);
    }

    // Trigger widget refresh
    await updateAllHomeWidgets();
  }

  /// A simple focus score based on switch frequency.
  static int _computeFocusScore(List<AndroidAppSession> events, int totalMs) {
    if (totalMs < 60000 || events.isEmpty) return 0;

    int switches = 0;
    for (int i = 1; i < events.length; i++) {
      if (events[i].packageName != events[i - 1].packageName) {
        switches++;
      }
    }

    final hours = totalMs / 3600000;
    if (hours <= 0) return 50;
    final switchesPerHour = switches / hours;

    final score = (100 - (switchesPerHour * 1.5)).clamp(10, 100).round();
    return score;
  }
}
