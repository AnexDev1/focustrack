import 'package:flutter/material.dart' hide Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focustrack/providers/app_usage_provider.dart';
import 'package:focustrack/providers/database_provider.dart';
import 'package:focustrack/services/app_usage_service.dart';
import 'package:focustrack/services/data_transfer_service.dart';
import 'package:focustrack/services/sync_server.dart';
import 'package:focustrack/theme/app_icons.dart';
import 'package:focustrack/theme/app_theme.dart';
import 'package:focustrack/widgets/custom_widgets.dart';
import 'package:focustrack/models/app_category.dart';
import 'package:focustrack/widgets/usage_chart.dart';
import 'package:focustrack/screens/analytics_screen.dart';
import 'package:focustrack/screens/insights_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  SyncServer? _syncServer;
  bool _syncServerRunning = false;
  List<String> _localIPs = [];

  // Source filter labels
  static const _sourceLabels = {
    null: 'Combined',
    'desktop': 'Desktop',
    'mobile': 'Mobile',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appUsageServiceProvider)?.startTracking();
    });
  }

  @override
  void dispose() {
    _syncServer?.stop();
    super.dispose();
  }

  Future<void> _startSyncServer() async {
    if (_syncServer != null && _syncServerRunning) return;
    final database = await ref.read(databaseInitializerProvider.future);
    _syncServer = SyncServer(
      database: database,
      onSyncReceived: () {
        // Invalidate providers so dashboard refreshes automatically
        ref.invalidate(recentSessionsProvider);
        ref.invalidate(filteredSessionsProvider);
        ref.invalidate(mobileSessionsProvider);
      },
    );
    await _syncServer!.start();
    final ips = await _syncServer!.getLocalIPs();
    setState(() {
      _syncServerRunning = true;
      _localIPs = ips;
    });
  }

  Future<void> _stopSyncServer() async {
    await _syncServer?.stop();
    setState(() {
      _syncServerRunning = false;
      _localIPs = [];
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
    final sessionsAsync = ref.watch(filteredSessionsProvider);
    final sourceFilter = ref.watch(sourceFilterProvider);
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
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Deep Insights',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InsightsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnalyticsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: sessionsAsync.when(
          data: (sessions) => LayoutBuilder(
            builder: (context, constraints) {
              // Use single-column scrollable layout for narrow/short windows
              if (constraints.maxWidth < 800) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCurrentActivityCard(currentApp, isTracking),
                      const SizedBox(height: 12),
                      _buildSourceToggle(sourceFilter),
                      const SizedBox(height: 20),
                      _buildQuickStats(sessions),
                      const SizedBox(height: 20),
                      _buildMobileStatsCard(),
                      const SizedBox(height: 20),
                      _buildInsightsMiniCard(),
                      const SizedBox(height: 20),
                      SizedBox(height: 250, child: _buildUsageChart()),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 400,
                        child: _buildSessionHistory(sessions),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(height: 400, child: _buildTopAppsList(sessions)),
                    ],
                  ),
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column - scrollable
                  Expanded(
                    flex: 2,
                    child: ListView(
                      children: [
                        _buildCurrentActivityCard(currentApp, isTracking),
                        const SizedBox(height: 12),
                        _buildSourceToggle(sourceFilter),
                        const SizedBox(height: 20),
                        _buildQuickStats(sessions),
                        const SizedBox(height: 20),
                        _buildMobileStatsCard(),
                        const SizedBox(height: 20),
                        _buildInsightsMiniCard(),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: (constraints.maxHeight - 80).clamp(300, 600),
                          child: _buildSessionHistory(sessions),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right Column
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUsageChart(),
                        const SizedBox(height: 20),
                        Expanded(child: _buildTopAppsList(sessions)),
                      ],
                    ),
                  ),
                ],
              );
            },
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

  Widget _buildSourceToggle(String? currentSource) {
    return Row(
      children: [
        for (final entry in _sourceLabels.entries)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: currentSource == entry.key,
              onSelected: (_) {
                ref.read(sourceFilterProvider.notifier).state = entry.key;
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.3),
              backgroundColor: AppTheme.surfaceColor,
              labelStyle: TextStyle(
                color: currentSource == entry.key
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
                fontWeight: currentSource == entry.key
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
              side: BorderSide(
                color: currentSource == entry.key
                    ? AppTheme.primaryColor
                    : Colors.white.withOpacity(0.1),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickStats(List sessions) {
    final totalTime = sessions.fold<int>(
      0,
      (sum, session) => sum + (session.durationMs as int),
    );
    final appCount = sessions.map((s) => s.appName).toSet().length;
    final focusScore = _calculateFocusScore(sessions);
    final sourceFilter = ref.read(sourceFilterProvider);
    final label = sourceFilter == null
        ? 'Today\'s Statistics'
        : sourceFilter == 'desktop'
        ? 'Desktop Statistics'
        : 'Mobile Statistics';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
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

  Widget _buildInsightsMiniCard() {
    final deepAsync = ref.watch(filteredDeepAnalyticsProvider);
    return deepAsync.when(
      data: (data) {
        final streak = data.productivityStreak;
        final switches = data.switchFrequency;
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: AppTheme.warningColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Insights',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InsightsScreen(),
                        ),
                      );
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: AppTheme.warningColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${streak.currentStreak}-day streak',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 20),
                  Icon(Icons.swap_horiz, color: AppTheme.accentColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${switches.totalSwitches} switches',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (data.insights.isNotEmpty)
                Text(
                  data.insights.first,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMobileStatsCard() {
    // Use a dedicated provider-based approach for reactivity
    final mobileAsync = ref.watch(mobileSessionsProvider);
    return mobileAsync.when(
      data: (sessions) {
        if (sessions.isEmpty && !_syncServerRunning) {
          return const SizedBox.shrink();
        }

        final totalTime = sessions.fold<int>(
          0,
          (sum, session) => sum + (session.durationMs as int),
        );
        final appCount = sessions.map((s) => s.appName).toSet().length;

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.phone_android,
                    color: AppTheme.accentColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mobile Stats',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _syncServerRunning
                          ? AppTheme.successColor.withOpacity(0.2)
                          : AppTheme.textTertiary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _syncServerRunning ? 'Server On' : 'Server Off',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _syncServerRunning
                            ? AppTheme.successColor
                            : AppTheme.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (sessions.isEmpty)
                Text(
                  _syncServerRunning
                      ? 'No mobile data synced yet. Open FocusTrack on your phone and sync.'
                      : 'Start the sync server in Settings to receive mobile data.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                )
              else ...[
                _buildStatRow(
                  'Mobile Screen Time',
                  _formatDuration(totalTime),
                  Icons.phone_android,
                  AppTheme.accentColor,
                ),
                const SizedBox(height: 12),
                _buildStatRow(
                  'Mobile Apps Used',
                  appCount.toString(),
                  Icons.apps_rounded,
                  AppTheme.primaryColor,
                ),
                const SizedBox(height: 12),
                _buildStatRow(
                  'Mobile Sessions',
                  sessions.length.toString(),
                  Icons.splitscreen_rounded,
                  AppTheme.warningColor,
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<List> _getMobileSessions() async {
    try {
      final database = await ref.read(databaseInitializerProvider.future);
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      return await database.getMobileSessionsInDateRange(startOfDay, now);
    } catch (_) {
      return [];
    }
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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sync Server section
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Mobile Sync',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  _syncServerRunning ? Icons.sync : Icons.sync_disabled,
                  color: _syncServerRunning
                      ? AppTheme.successColor
                      : AppTheme.textTertiary,
                ),
                title: Text(
                  _syncServerRunning
                      ? 'Sync Server Running'
                      : 'Start Sync Server',
                ),
                subtitle: _syncServerRunning && _localIPs.isNotEmpty
                    ? Text(
                        '${_localIPs.first}:${_syncServer?.port ?? 8742}',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    : const Text('Receive data from mobile'),
                trailing: Switch(
                  value: _syncServerRunning,
                  onChanged: (val) async {
                    if (val) {
                      await _startSyncServer();
                    } else {
                      await _stopSyncServer();
                    }
                    setDialogState(() {});
                  },
                ),
              ),
              if (_syncServerRunning && _localIPs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter this address in FocusTrack mobile:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ..._localIPs.map(
                        (ip) => SelectableText(
                          '$ip:${_syncServer?.port ?? 8742}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontFamily: 'monospace',
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(),
              // Data section
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 8),
                child: Text(
                  'Data',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('Export Data'),
                onTap: () async {
                  Navigator.pop(context);
                  final database = await ref.read(
                    databaseInitializerProvider.future,
                  );
                  final sessions = await database.getAllSessions();
                  if (sessions.isEmpty && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No data to export')),
                    );
                    return;
                  }
                  final path = await DataTransferService.pickSavePath(
                    suggestedName:
                        'focustrack_sessions_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv',
                    extension: 'csv',
                    dialogTitle: 'Choose where to export your data',
                  );
                  if (path == null) return;
                  final exportedPath =
                      await DataTransferService.exportSessionsCsv(
                        sessions,
                        outputPath: path,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Exported data to $exportedPath')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Import Data'),
                onTap: () async {
                  Navigator.pop(context);
                  final selectedPath = await DataTransferService.pickImportPath(
                    dialogTitle: 'Choose exported data to import',
                  );
                  if (selectedPath == null) return;
                  final database = await ref.read(
                    databaseInitializerProvider.future,
                  );
                  final importedCount =
                      await DataTransferService.importSessionsFromFile(
                        database,
                        selectedPath,
                      );
                  ref.invalidate(recentSessionsProvider);
                  ref.invalidate(filteredSessionsProvider);
                  ref.invalidate(todayAnalyticsProvider);
                  ref.invalidate(yesterdayAnalyticsProvider);
                  ref.invalidate(weekAnalyticsProvider);
                  ref.invalidate(monthAnalyticsProvider);
                  ref.invalidate(deepAnalyticsProvider);
                  ref.invalidate(filteredDeepAnalyticsProvider);
                  ref.invalidate(mobileSessionsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          importedCount > 0
                              ? 'Imported $importedCount sessions'
                              : 'No new sessions were imported',
                        ),
                      ),
                    );
                  }
                },
              ),
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
                    // stop desktop tracking before clearing
                    ref.read(appUsageServiceProvider)?.stopTracking();
                    await database.clearAllSessions();
                    // invalidate all relevant providers so UI updates
                    ref.invalidate(allSessionsProvider);
                    ref.invalidate(recentSessionsProvider);
                    ref.invalidate(filteredSessionsProvider);
                    ref.invalidate(todayAnalyticsProvider);
                    ref.invalidate(yesterdayAnalyticsProvider);
                    ref.invalidate(weekAnalyticsProvider);
                    ref.invalidate(monthAnalyticsProvider);
                    ref.invalidate(deepAnalyticsProvider);
                    ref.invalidate(filteredDeepAnalyticsProvider);
                    ref.invalidate(mobileSessionsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All data cleared')),
                      );
                    }
                    // restart tracking immediately
                    ref.read(appUsageServiceProvider)?.startTracking();
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
      ),
    );
  }
}
