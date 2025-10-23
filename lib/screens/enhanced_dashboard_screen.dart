import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focustrack/providers/app_usage_provider.dart';
import 'package:focustrack/providers/database_provider.dart';
import 'package:focustrack/services/app_usage_service.dart';
import 'package:focustrack/theme/app_theme.dart';
import 'package:focustrack/widgets/custom_widgets.dart';
import 'package:focustrack/models/app_category.dart';
import 'package:focustrack/widgets/usage_chart.dart';

class EnhancedDashboardScreen extends ConsumerStatefulWidget {
  const EnhancedDashboardScreen({super.key});

  @override
  ConsumerState<EnhancedDashboardScreen> createState() =>
      _EnhancedDashboardScreenState();
}

class _EnhancedDashboardScreenState
    extends ConsumerState<EnhancedDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appUsageServiceProvider).startTracking();
    });
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

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(recentSessionsProvider);
    final currentApp = ref.watch(
      appUsageNotifierProvider.select((state) => state.currentApp),
    );
    final isTracking = ref.watch(
      appUsageNotifierProvider.select((state) => state.isTracking),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('FocusTrack'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: sessionsAsync.when(
          data: (sessions) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column - Stats & History
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Activity
                    _buildCurrentActivityCard(currentApp, isTracking),
                    const SizedBox(height: 20),

                    // Quick Stats
                    _buildQuickStats(sessions),
                    const SizedBox(height: 20),

                    // Session History
                    Expanded(child: _buildSessionHistory(sessions)),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Right Column - App Lists & Chart
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Usage Chart
                    _buildUsageChart(),
                    const SizedBox(height: 20),

                    // Top Apps List
                    Expanded(child: _buildTopAppsList(sessions)),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildCurrentActivityCard(String? currentApp, bool isTracking) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isTracking
                      ? AppTheme.successColor.withOpacity(0.2)
                      : AppTheme.textTertiary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isTracking ? Icons.circle : Icons.pause_circle_outline,
                  color: isTracking
                      ? AppTheme.successColor
                      : AppTheme.textTertiary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTracking ? 'Currently Active' : 'Idle',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentApp ?? 'No app detected',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(List sessions) {
    final totalTime = sessions.fold<int>(
      0,
      (sum, session) => sum + (session.durationMs as int),
    );
    final appCount = sessions.map((s) => s.appName).toSet().length;
    final focusScore = _calculateFocusScore(sessions);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Statistics',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            'Total Time',
            _formatDuration(totalTime),
            Icons.access_time_rounded,
            AppTheme.primaryColor,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            'Apps Used',
            appCount.toString(),
            Icons.apps_rounded,
            AppTheme.accentColor,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            'Sessions',
            sessions.length.toString(),
            Icons.splitscreen_rounded,
            AppTheme.successColor,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            'Focus Score',
            focusScore,
            Icons.psychology_rounded,
            AppTheme.warningColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionHistory(List sessions) {
    if (sessions.isEmpty) {
      return _buildEmptyState();
    }

    final sortedSessions = List.from(sessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent Sessions',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${sessions.length} total',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: sortedSessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final session = sortedSessions[index];
                final category = AppCategoryExtension.fromAppName(
                  session.appName,
                );
                final color = AppTheme.getCategoryColor(category.displayName);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
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
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(session.startTime),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageChart() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage Overview',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 250, child: UsageChart()),
        ],
      ),
    );
  }

  Widget _buildTopAppsList(List sessions) {
    if (sessions.isEmpty) {
      return _buildEmptyState();
    }

    final appUsageMap = <String, int>{};
    for (var session in sessions) {
      final current = appUsageMap[session.appName] ?? 0;
      appUsageMap[session.appName] = current + session.durationMs as int;
    }

    final sortedApps = appUsageMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalTime = sortedApps.fold<int>(0, (sum, e) => sum + e.value);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Top Applications',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${sortedApps.length} apps',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: sortedApps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = sortedApps[index];
                final percentage = (entry.value / totalTime) * 100;
                final category = AppCategoryExtension.fromAppName(entry.key);
                final color = AppTheme.getCategoryColor(category.displayName);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                category.displayName,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(color: color),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatDuration(entry.value),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: color.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined_rounded,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 16),
          Text('No data yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Start using apps to see statistics',
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

    final score = ((productiveTime / totalTime) * 100).toInt();
    return '$score%';
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Clear All Data'),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm'),
                    content: const Text(
                      'Are you sure you want to clear all data?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  final database = await ref.read(
                    databaseInitializerProvider.future,
                  );
                  await database.clearAllSessions();
                  if (context.mounted) {
                    ref.invalidate(recentSessionsProvider);
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
