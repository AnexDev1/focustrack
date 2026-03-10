import 'dart:math';
import 'package:focustrack/database/app_usage_database.dart';
import 'package:focustrack/models/app_category.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

/// Hourly usage for building heatmaps (hour 0‑23 → total ms).
class HourlyUsage {
  final Map<int, int> hourToMs; // 0‑23 → ms
  final int peakHour;
  final int peakMs;

  HourlyUsage({
    required this.hourToMs,
    required this.peakHour,
    required this.peakMs,
  });
}

/// How often the user switches between apps.
class SwitchFrequency {
  final int totalSwitches;
  final double avgSwitchesPerHour;
  final String mostSwitchedFrom;
  final String mostSwitchedTo;

  SwitchFrequency({
    required this.totalSwitches,
    required this.avgSwitchesPerHour,
    required this.mostSwitchedFrom,
    required this.mostSwitchedTo,
  });
}

/// Productivity streak information.
class ProductivityStreak {
  final int currentStreak; // days
  final int longestStreak; // days
  final int todayProductiveMs;
  final int todayGoalMs;
  final double todayProgress; // 0‑1

  ProductivityStreak({
    required this.currentStreak,
    required this.longestStreak,
    required this.todayProductiveMs,
    required this.todayGoalMs,
    required this.todayProgress,
  });
}

/// Session‑length distribution bucket.
class SessionBucket {
  final String label; // e.g. "< 1m", "1‑5m", "5‑15m"
  final int count;
  final int totalMs;

  SessionBucket({
    required this.label,
    required this.count,
    required this.totalMs,
  });
}

/// Week‑over‑week (or day‑over‑day) comparison.
class PeriodComparison {
  final int currentMs;
  final int previousMs;
  final double changePercent; // positive = increase
  final int currentSessions;
  final int previousSessions;

  PeriodComparison({
    required this.currentMs,
    required this.previousMs,
    required this.changePercent,
    required this.currentSessions,
    required this.previousSessions,
  });
}

/// Detailed per‑app stats.
class AppDeepStats {
  final String appName;
  final AppCategory category;
  final int totalMs;
  final int sessionCount;
  final int avgSessionMs;
  final int longestSessionMs;
  final DateTime? firstUsed;
  final DateTime? lastUsed;
  final Map<int, int> hourlyBreakdown; // 0‑23

  AppDeepStats({
    required this.appName,
    required this.category,
    required this.totalMs,
    required this.sessionCount,
    required this.avgSessionMs,
    required this.longestSessionMs,
    this.firstUsed,
    this.lastUsed,
    required this.hourlyBreakdown,
  });
}

/// Multitasking score – how spread the user's focus is.
class MultitaskingScore {
  final double score; // 0‑100 (100 = perfectly focused on 1 app)
  final int uniqueApps;
  final String topApp;
  final double topAppPercent;

  MultitaskingScore({
    required this.score,
    required this.uniqueApps,
    required this.topApp,
    required this.topAppPercent,
  });
}

/// Combined deep‑analytics payload.
class DeepAnalyticsData {
  final HourlyUsage hourlyUsage;
  final SwitchFrequency switchFrequency;
  final ProductivityStreak productivityStreak;
  final List<SessionBucket> sessionDistribution;
  final PeriodComparison dayComparison; // today vs yesterday
  final PeriodComparison weekComparison; // this week vs last week
  final MultitaskingScore multitaskingScore;
  final List<AppDeepStats> appDeepStats;
  final Map<String, int> categoryUsage;
  final int totalScreenTimeMs;
  final String peakProductivityWindow; // e.g. "9 AM – 11 AM"
  final List<String> insights; // natural‑language insights

  DeepAnalyticsData({
    required this.hourlyUsage,
    required this.switchFrequency,
    required this.productivityStreak,
    required this.sessionDistribution,
    required this.dayComparison,
    required this.weekComparison,
    required this.multitaskingScore,
    required this.appDeepStats,
    required this.categoryUsage,
    required this.totalScreenTimeMs,
    required this.peakProductivityWindow,
    required this.insights,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class DeepAnalyticsService {
  final AppUsageDatabase database;
  static const int _defaultGoalMs = 4 * 60 * 60 * 1000; // 4 hours

  DeepAnalyticsService(this.database);

  Future<DeepAnalyticsData> compute() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));

    // Fetch sessions for various ranges
    final todaySessions = await database.getSessionsInDateRange(
      todayStart,
      todayEnd,
    );
    final yesterdaySessions = await database.getSessionsInDateRange(
      yesterdayStart,
      todayStart,
    );
    final thisWeekSessions = await database.getSessionsInDateRange(
      weekStart,
      todayEnd,
    );
    final lastWeekSessions = await database.getSessionsInDateRange(
      lastWeekStart,
      weekStart,
    );

    // Also fetch last 30 days for streaks
    final thirtyDaysAgo = todayStart.subtract(const Duration(days: 30));
    final last30Sessions = await database.getSessionsInDateRange(
      thirtyDaysAgo,
      todayEnd,
    );

    // 1. Hourly usage
    final hourly = _computeHourlyUsage(todaySessions);

    // 2. Switch frequency
    final switches = _computeSwitchFrequency(todaySessions);

    // 3. Productivity streak
    final streak = _computeStreak(last30Sessions, todayStart);

    // 4. Session distribution
    final distribution = _computeSessionDistribution(todaySessions);

    // 5. Comparisons
    final dayComp = _computeComparison(todaySessions, yesterdaySessions);
    final weekComp = _computeComparison(thisWeekSessions, lastWeekSessions);

    // 6. Multitasking
    final multitask = _computeMultitasking(todaySessions);

    // 7. Per-app deep stats
    final appStats = _computeAppDeepStats(todaySessions);

    // 8. Category usage
    final catUsage = <String, int>{};
    for (final s in todaySessions) {
      final cat = AppCategoryExtension.fromAppName(s.appName).displayName;
      catUsage[cat] = (catUsage[cat] ?? 0) + s.durationMs;
    }

    // 9. Peak productivity window
    final peakWindow = _findPeakProductivityWindow(todaySessions);

    // 10. Total
    final totalMs = todaySessions.fold<int>(0, (s, e) => s + e.durationMs);

    // 11. Generate insights
    final insights = _generateInsights(
      hourly,
      switches,
      streak,
      dayComp,
      multitask,
      appStats,
      totalMs,
    );

    return DeepAnalyticsData(
      hourlyUsage: hourly,
      switchFrequency: switches,
      productivityStreak: streak,
      sessionDistribution: distribution,
      dayComparison: dayComp,
      weekComparison: weekComp,
      multitaskingScore: multitask,
      appDeepStats: appStats,
      categoryUsage: catUsage,
      totalScreenTimeMs: totalMs,
      peakProductivityWindow: peakWindow,
      insights: insights,
    );
  }

  // -------------------------------------------------------------------------
  HourlyUsage _computeHourlyUsage(List<AppUsageSession> sessions) {
    final map = <int, int>{};
    for (var h = 0; h < 24; h++) {
      map[h] = 0;
    }
    for (final s in sessions) {
      final hour = s.startTime.hour;
      map[hour] = map[hour]! + s.durationMs;
    }
    int peakHour = 0;
    int peakMs = 0;
    map.forEach((h, ms) {
      if (ms > peakMs) {
        peakHour = h;
        peakMs = ms;
      }
    });
    return HourlyUsage(hourToMs: map, peakHour: peakHour, peakMs: peakMs);
  }

  // -------------------------------------------------------------------------
  SwitchFrequency _computeSwitchFrequency(List<AppUsageSession> sessions) {
    if (sessions.length < 2) {
      return SwitchFrequency(
        totalSwitches: 0,
        avgSwitchesPerHour: 0,
        mostSwitchedFrom: '-',
        mostSwitchedTo: '-',
      );
    }
    final sorted = List<AppUsageSession>.from(sessions)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    int switches = 0;
    final fromCount = <String, int>{};
    final toCount = <String, int>{};

    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i].appName != sorted[i - 1].appName) {
        switches++;
        fromCount[sorted[i - 1].appName] =
            (fromCount[sorted[i - 1].appName] ?? 0) + 1;
        toCount[sorted[i].appName] = (toCount[sorted[i].appName] ?? 0) + 1;
      }
    }

    final totalHours = max(
      1.0,
      sorted.last.startTime.difference(sorted.first.startTime).inMinutes / 60.0,
    );

    String topFrom = '-';
    int topFromVal = 0;
    fromCount.forEach((k, v) {
      if (v > topFromVal) {
        topFrom = k;
        topFromVal = v;
      }
    });
    String topTo = '-';
    int topToVal = 0;
    toCount.forEach((k, v) {
      if (v > topToVal) {
        topTo = k;
        topToVal = v;
      }
    });

    return SwitchFrequency(
      totalSwitches: switches,
      avgSwitchesPerHour: switches / totalHours,
      mostSwitchedFrom: topFrom,
      mostSwitchedTo: topTo,
    );
  }

  // -------------------------------------------------------------------------
  ProductivityStreak _computeStreak(
    List<AppUsageSession> sessions,
    DateTime todayStart,
  ) {
    // Group by day
    final dayMs = <DateTime, int>{};
    for (final s in sessions) {
      final day = DateTime(
        s.startTime.year,
        s.startTime.month,
        s.startTime.day,
      );
      final cat = AppCategoryExtension.fromAppName(s.appName);
      final isProductive =
          cat == AppCategory.work ||
          cat == AppCategory.development ||
          cat == AppCategory.productivity ||
          cat == AppCategory.browser;
      if (isProductive) {
        dayMs[day] = (dayMs[day] ?? 0) + s.durationMs;
      }
    }

    final todayProductive = dayMs[todayStart] ?? 0;

    // Count streak (consecutive days with > 30 min productive time)
    const streakThresholdMs = 30 * 60 * 1000;
    int current = 0;
    int longest = 0;
    int streak = 0;

    for (var d = 0; d < 30; d++) {
      final day = todayStart.subtract(Duration(days: d));
      if ((dayMs[day] ?? 0) >= streakThresholdMs) {
        streak++;
        if (d == current) current = streak; // contiguous from today
      } else {
        longest = max(longest, streak);
        streak = 0;
      }
    }
    longest = max(longest, streak);

    final progress = (_defaultGoalMs > 0)
        ? (todayProductive / _defaultGoalMs).clamp(0.0, 1.0)
        : 0.0;

    return ProductivityStreak(
      currentStreak: current,
      longestStreak: longest,
      todayProductiveMs: todayProductive,
      todayGoalMs: _defaultGoalMs,
      todayProgress: progress,
    );
  }

  // -------------------------------------------------------------------------
  List<SessionBucket> _computeSessionDistribution(
    List<AppUsageSession> sessions,
  ) {
    final buckets = <String, _BucketAccum>{
      '< 1m': _BucketAccum(),
      '1–5m': _BucketAccum(),
      '5–15m': _BucketAccum(),
      '15–30m': _BucketAccum(),
      '30–60m': _BucketAccum(),
      '> 60m': _BucketAccum(),
    };
    for (final s in sessions) {
      final mins = s.durationMs / 60000;
      String key;
      if (mins < 1) {
        key = '< 1m';
      } else if (mins < 5) {
        key = '1–5m';
      } else if (mins < 15) {
        key = '5–15m';
      } else if (mins < 30) {
        key = '15–30m';
      } else if (mins < 60) {
        key = '30–60m';
      } else {
        key = '> 60m';
      }
      buckets[key]!.count++;
      buckets[key]!.totalMs += s.durationMs;
    }
    return buckets.entries
        .map(
          (e) => SessionBucket(
            label: e.key,
            count: e.value.count,
            totalMs: e.value.totalMs,
          ),
        )
        .toList();
  }

  // -------------------------------------------------------------------------
  PeriodComparison _computeComparison(
    List<AppUsageSession> current,
    List<AppUsageSession> previous,
  ) {
    final curMs = current.fold<int>(0, (s, e) => s + e.durationMs);
    final prevMs = previous.fold<int>(0, (s, e) => s + e.durationMs);
    final change = prevMs > 0 ? ((curMs - prevMs) / prevMs * 100) : 0.0;
    return PeriodComparison(
      currentMs: curMs,
      previousMs: prevMs,
      changePercent: change,
      currentSessions: current.length,
      previousSessions: previous.length,
    );
  }

  // -------------------------------------------------------------------------
  MultitaskingScore _computeMultitasking(List<AppUsageSession> sessions) {
    if (sessions.isEmpty) {
      return MultitaskingScore(
        score: 0,
        uniqueApps: 0,
        topApp: '-',
        topAppPercent: 0,
      );
    }
    final appMs = <String, int>{};
    int total = 0;
    for (final s in sessions) {
      appMs[s.appName] = (appMs[s.appName] ?? 0) + s.durationMs;
      total += s.durationMs;
    }

    String topApp = appMs.entries.first.key;
    int topMs = 0;
    appMs.forEach((k, v) {
      if (v > topMs) {
        topApp = k;
        topMs = v;
      }
    });

    final topPercent = total > 0 ? topMs / total * 100 : 0.0;

    // Focus score: 100 = one app; approaches 0 as usage is split evenly among many apps
    // Using a simplified Herfindahl index
    double hhi = 0;
    appMs.forEach((_, ms) {
      final share = total > 0 ? ms / total : 0.0;
      hhi += share * share;
    });
    final score = (hhi * 100).clamp(0.0, 100.0);

    return MultitaskingScore(
      score: score,
      uniqueApps: appMs.length,
      topApp: topApp,
      topAppPercent: topPercent,
    );
  }

  // -------------------------------------------------------------------------
  List<AppDeepStats> _computeAppDeepStats(List<AppUsageSession> sessions) {
    final map = <String, List<AppUsageSession>>{};
    for (final s in sessions) {
      (map[s.appName] ??= []).add(s);
    }
    final stats = <AppDeepStats>[];
    for (final entry in map.entries) {
      final list = entry.value;
      final totalMs = list.fold<int>(0, (s, e) => s + e.durationMs);
      final longestMs = list.map((e) => e.durationMs).reduce(max);
      final avgMs = totalMs ~/ list.length;

      final hourly = <int, int>{};
      for (var h = 0; h < 24; h++) hourly[h] = 0;
      for (final s in list) {
        hourly[s.startTime.hour] = hourly[s.startTime.hour]! + s.durationMs;
      }

      list.sort((a, b) => a.startTime.compareTo(b.startTime));

      stats.add(
        AppDeepStats(
          appName: entry.key,
          category: AppCategoryExtension.fromAppName(entry.key),
          totalMs: totalMs,
          sessionCount: list.length,
          avgSessionMs: avgMs,
          longestSessionMs: longestMs,
          firstUsed: list.first.startTime,
          lastUsed: list.last.startTime,
          hourlyBreakdown: hourly,
        ),
      );
    }
    stats.sort((a, b) => b.totalMs.compareTo(a.totalMs));
    return stats;
  }

  // -------------------------------------------------------------------------
  String _findPeakProductivityWindow(List<AppUsageSession> sessions) {
    // Find 2‑hour window with most productive ms
    final hourProd = <int, int>{};
    for (var h = 0; h < 24; h++) hourProd[h] = 0;
    for (final s in sessions) {
      final cat = AppCategoryExtension.fromAppName(s.appName);
      final isProductive =
          cat == AppCategory.work ||
          cat == AppCategory.development ||
          cat == AppCategory.productivity;
      if (isProductive) {
        hourProd[s.startTime.hour] = hourProd[s.startTime.hour]! + s.durationMs;
      }
    }

    int bestStart = 0;
    int bestMs = 0;
    for (var h = 0; h < 23; h++) {
      final windowMs = hourProd[h]! + hourProd[h + 1]!;
      if (windowMs > bestMs) {
        bestMs = windowMs;
        bestStart = h;
      }
    }
    if (bestMs == 0) return 'No productive time yet';

    String fmt(int h) {
      if (h == 0) return '12 AM';
      if (h < 12) return '$h AM';
      if (h == 12) return '12 PM';
      return '${h - 12} PM';
    }

    return '${fmt(bestStart)} – ${fmt(bestStart + 2)}';
  }

  // -------------------------------------------------------------------------
  List<String> _generateInsights(
    HourlyUsage hourly,
    SwitchFrequency switches,
    ProductivityStreak streak,
    PeriodComparison dayComp,
    MultitaskingScore multitask,
    List<AppDeepStats> appStats,
    int totalMs,
  ) {
    final list = <String>[];

    // Peak hour insight
    final peakLabel = _hourLabel(hourly.peakHour);
    if (hourly.peakMs > 0) {
      list.add(
        'Your most active hour is $peakLabel with ${_fmtMs(hourly.peakMs)} of screen time.',
      );
    }

    // Comparison
    if (dayComp.previousMs > 0) {
      final pct = dayComp.changePercent.abs().toStringAsFixed(0);
      if (dayComp.changePercent > 10) {
        list.add('Screen time is up $pct% compared to yesterday.');
      } else if (dayComp.changePercent < -10) {
        list.add('Screen time is down $pct% compared to yesterday — nice!');
      } else {
        list.add('Screen time is about the same as yesterday.');
      }
    }

    // Switch frequency
    if (switches.avgSwitchesPerHour > 20) {
      list.add(
        'You\'re switching apps ${switches.avgSwitchesPerHour.toStringAsFixed(0)} times/hr. Try batching tasks to improve focus.',
      );
    } else if (switches.avgSwitchesPerHour > 0) {
      list.add(
        'App switches: ${switches.avgSwitchesPerHour.toStringAsFixed(1)}/hr, which is a healthy pace.',
      );
    }

    // Focus
    if (multitask.score > 50) {
      list.add(
        'Your focus is strong — ${multitask.topApp} dominates at ${multitask.topAppPercent.toStringAsFixed(0)}% of your time.',
      );
    } else if (multitask.uniqueApps > 5) {
      list.add(
        'You used ${multitask.uniqueApps} different apps today. Consider reducing context switches.',
      );
    }

    // Streak
    if (streak.currentStreak > 1) {
      list.add(
        'You\'re on a ${streak.currentStreak}-day productivity streak! Keep it going.',
      );
    }

    // Goal
    if (streak.todayProgress >= 1.0) {
      list.add('You\'ve reached your daily productive-time goal!');
    } else if (streak.todayProgress > 0.5) {
      final remaining = _fmtMs(streak.todayGoalMs - streak.todayProductiveMs);
      list.add('$remaining more of productive work to hit your daily goal.');
    }

    if (list.isEmpty) {
      list.add('Start using apps to see personalised insights here.');
    }

    return list;
  }

  String _hourLabel(int h) {
    if (h == 0) return '12 AM';
    if (h < 12) return '$h AM';
    if (h == 12) return '12 PM';
    return '${h - 12} PM';
  }

  String _fmtMs(int ms) {
    final d = Duration(milliseconds: ms);
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return '< 1m';
  }
}

class _BucketAccum {
  int count = 0;
  int totalMs = 0;
}
