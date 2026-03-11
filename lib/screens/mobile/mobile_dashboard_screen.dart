import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:focustrack/providers/app_usage_provider.dart';
import 'package:focustrack/services/mobile_usage_sync.dart';
import 'package:focustrack/services/android_usage_service.dart';
import 'package:focustrack/theme/app_theme.dart';
import 'package:focustrack/models/app_category.dart';
import 'package:focustrack/services/app_limits_service.dart';

class MobileDashboardScreen extends ConsumerStatefulWidget {
  const MobileDashboardScreen({super.key});

  @override
  ConsumerState<MobileDashboardScreen> createState() =>
      _MobileDashboardScreenState();
}

class _MobileDashboardScreenState extends ConsumerState<MobileDashboardScreen> {
  Timer? _refreshTimer;
  Timer? _tickTimer;
  int _elapsedSinceRefreshMs = 0;
  DateTime _lastRefreshTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMobileTracking();
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!mounted) return;
      // Sync fresh Android data into DB before reloading providers
      if (Platform.isAndroid) {
        await ref.read(mobileUsageSyncProvider).syncNow();
      }
      if (!mounted) return;
      ref.invalidate(recentSessionsProvider);
      ref.invalidate(todayAnalyticsProvider);
      setState(() {
        _lastRefreshTime = DateTime.now();
        _elapsedSinceRefreshMs = 0;
      });
    });
    // 1-second tick for live screen time counter
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedSinceRefreshMs = DateTime.now()
            .difference(_lastRefreshTime)
            .inMilliseconds;
      });
    });
  }

  Future<void> _initMobileTracking() async {
    if (!Platform.isAndroid) return;
    final hasPermission = await AndroidUsageStatsService.hasPermission();
    if (hasPermission) {
      ref.read(mobileUsageSyncProvider).startSync();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m';
    return '< 1m';
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(recentSessionsProvider);
    final permissionAsync = ref.watch(usagePermissionProvider);

    return SafeArea(
      child: RefreshIndicator(
        color: AppTheme.primaryColor,
        backgroundColor: AppTheme.surfaceColor,
        onRefresh: () async {
          if (Platform.isAndroid) {
            await ref.read(mobileUsageSyncProvider).syncNow();
          }
          ref.invalidate(recentSessionsProvider);
          ref.invalidate(todayAnalyticsProvider);
          setState(() {
            _lastRefreshTime = DateTime.now();
            _elapsedSinceRefreshMs = 0;
          });
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.track_changes_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FocusTrack',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _getGreeting(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () async {
                        if (Platform.isAndroid) {
                          await ref.read(mobileUsageSyncProvider).syncNow();
                          if (!mounted) return;
                          ref.invalidate(recentSessionsProvider);
                          setState(() {
                            _lastRefreshTime = DateTime.now();
                            _elapsedSinceRefreshMs = 0;
                          });
                        }
                      },
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Permission Banner (Android only)
            if (Platform.isAndroid)
              permissionAsync.when(
                data: (hasPermission) {
                  if (hasPermission)
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  return SliverToBoxAdapter(child: _buildPermissionBanner());
                },
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

            // Content
            sessionsAsync.when(
              data: (sessions) => SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  _buildScreenTimeCard(sessions),
                  const SizedBox(height: 16),
                  _buildQuickStatsRow(sessions),
                  const SizedBox(height: 16),
                  _buildUsagePieChart(sessions),
                  const SizedBox(height: 16),
                  _buildTopAppsCard(sessions),
                  const SizedBox(height: 16),
                  _buildRecentSessionsCard(sessions),
                  const SizedBox(height: 100),
                ]),
              ),
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildPermissionBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.warningColor.withOpacity(0.15),
              AppTheme.warningColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.security_rounded,
                color: AppTheme.warningColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permission Required',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Grant usage access to track your app screen time',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                await AndroidUsageStatsService.requestPermission();
                // After returning from settings, re-check
                await Future.delayed(const Duration(seconds: 1));
                ref.invalidate(usagePermissionProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Grant',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenTimeCard(List sessions) {
    final totalTime =
        sessions.fold<int>(
          0,
          (sum, session) => sum + (session.durationMs as int),
        ) +
        _elapsedSinceRefreshMs;
    final hours = Duration(milliseconds: totalTime).inHours;
    final minutes = Duration(milliseconds: totalTime).inMinutes.remainder(60);
    final seconds = Duration(milliseconds: totalTime).inSeconds.remainder(60);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'Today\'s Screen Time',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$hours',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'h ',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '$minutes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'm ',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${seconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 36,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    's',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${sessions.map((s) => s.appName).toSet().length} apps  ·  ${sessions.length} sessions',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow(List sessions) {
    final totalTime = sessions.fold<int>(
      0,
      (sum, s) => sum + (s.durationMs as int),
    );
    final appCount = sessions.map((s) => s.appName).toSet().length;
    final focusScore = _calculateFocusScore(sessions);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatTile(
              'Apps',
              '$appCount',
              Icons.apps_rounded,
              AppTheme.accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatTile(
              'Sessions',
              '${sessions.length}',
              Icons.splitscreen_rounded,
              AppTheme.successColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatTile(
              'Focus',
              focusScore,
              Icons.psychology_rounded,
              AppTheme.warningColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildUsagePieChart(List sessions) {
    final appUsage = <String, int>{};
    for (final s in sessions) {
      appUsage[s.appName] = (appUsage[s.appName] ?? 0) + s.durationMs as int;
    }
    if (appUsage.isEmpty) return const SizedBox.shrink();

    final sorted = appUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalMs = sorted.fold<int>(0, (s, e) => s + e.value);

    final colors = [
      AppTheme.primaryColor,
      AppTheme.accentColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      AppTheme.secondaryColor,
      AppTheme.errorColor,
      const Color(0xFF0EA5E9),
      const Color(0xFFEC4899),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usage Breakdown',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sections: sorted.take(6).map((entry) {
                          final index = sorted.indexOf(entry);
                          final color = colors[index % colors.length];
                          final pct = totalMs > 0
                              ? (entry.value / totalMs * 100)
                              : 0.0;
                          return PieChartSectionData(
                            value: entry.value.toDouble(),
                            title: '${pct.toStringAsFixed(0)}%',
                            radius: 50,
                            color: color,
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: sorted.take(6).map((entry) {
                        final index = sorted.indexOf(entry);
                        final color = colors[index % colors.length];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppsCard(List sessions) {
    final appUsage = <String, int>{};
    for (final s in sessions) {
      appUsage[s.appName] = (appUsage[s.appName] ?? 0) + s.durationMs as int;
    }
    if (appUsage.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _buildEmptyCard(),
      );
    }

    final sorted = appUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalTime = sorted.fold<int>(0, (s, e) => s + e.value);

    return FutureBuilder<List<AppLimit>>(
      future: AppLimitsService.getLimits(),
      builder: (context, limitsSnap) {
        final limits = limitsSnap.data ?? [];
        final limitMap = {for (final l in limits) l.appName: l};

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Top Apps',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${sorted.length} apps',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...sorted.take(5).map((entry) {
                  final pct = totalTime > 0
                      ? (entry.value / totalTime * 100)
                      : 0.0;
                  final category = AppCategoryExtension.fromAppName(entry.key);
                  final color = AppTheme.getCategoryColor(category.displayName);
                  final limit = limitMap[entry.key];
                  final usedMin = entry.value ~/ 60000;
                  final limitExceeded =
                      limit != null &&
                      limit.enabled &&
                      usedMin >= limit.limitMinutes;
                  final limitWarning =
                      limit != null &&
                      limit.enabled &&
                      usedMin >= (limit.limitMinutes * 0.8) &&
                      !limitExceeded;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: limitExceeded
                                ? AppTheme.errorColor.withOpacity(0.15)
                                : color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: limitExceeded
                                ? Icon(
                                    Icons.block,
                                    color: AppTheme.errorColor,
                                    size: 22,
                                  )
                                : Text(
                                    entry.key.isNotEmpty
                                        ? entry.key[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      entry.key,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (limitWarning)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Icon(
                                        Icons.warning_amber_rounded,
                                        color: AppTheme.warningColor,
                                        size: 16,
                                      ),
                                    ),
                                  if (limitExceeded)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Icon(
                                        Icons.timer_off,
                                        color: AppTheme.errorColor,
                                        size: 16,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct / 100,
                                  backgroundColor: limitExceeded
                                      ? AppTheme.errorColor.withOpacity(0.12)
                                      : color.withOpacity(0.12),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    limitExceeded ? AppTheme.errorColor : color,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatDuration(entry.value),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: limitExceeded
                                        ? AppTheme.errorColor
                                        : color,
                                  ),
                            ),
                            Text(
                              '${pct.toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentSessionsCard(List sessions) {
    if (sessions.isEmpty) return const SizedBox.shrink();

    final sorted = List.from(sessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${sessions.length} total',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sorted.take(8).map((session) {
              final category = AppCategoryExtension.fromAppName(
                session.appName,
              );
              final color = AppTheme.getCategoryColor(category.displayName);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(left: BorderSide(color: color, width: 3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.appName,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatTime(session.startTime)}  ·  ${category.displayName}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatDuration(session.durationMs),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded, size: 48, color: AppTheme.textTertiary),
          const SizedBox(height: 16),
          Text('No data yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Use your phone and check back to see your screen time analytics',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _calculateFocusScore(List sessions) {
    if (sessions.isEmpty) return '0%';
    final productiveTime = sessions
        .where((s) {
          final category = AppCategoryExtension.fromAppName(s.appName);
          return category == AppCategory.work ||
              category == AppCategory.development ||
              category == AppCategory.productivity;
        })
        .fold<int>(0, (sum, s) => (sum + s.durationMs) as int);

    final totalTime = sessions.fold<int>(
      0,
      (sum, s) => (sum + s.durationMs) as int,
    );
    if (totalTime == 0) return '0%';
    return '${((productiveTime / totalTime) * 100).toInt()}%';
  }
}
