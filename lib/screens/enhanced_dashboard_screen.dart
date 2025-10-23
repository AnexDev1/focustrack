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
    extends ConsumerState<EnhancedDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appUsageServiceProvider).startTracking();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Glassmorphic Effect
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.2),
                    AppTheme.secondaryColor.withOpacity(0.1),
                  ],
                ),
              ),
              child: FlexibleSpaceBar(
                title: const Text(
                  'FocusTrack',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _showSettingsDialog(context),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Current Activity Card
                _buildCurrentActivityCard(currentApp, isTracking),
                const SizedBox(height: 24),

                // Stats Overview
                sessionsAsync.when(
                  data: (sessions) {
                    final totalTime = sessions.fold<int>(
                      0,
                      (sum, session) => sum + session.durationMs,
                    );

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: 'Today',
                                value: _formatDuration(totalTime),
                                icon: Icons.access_time_rounded,
                                color: AppTheme.primaryColor,
                                subtitle: 'Total screen time',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StatCard(
                                title: 'Apps',
                                value: sessions
                                    .map((s) => s.appName)
                                    .toSet()
                                    .length
                                    .toString(),
                                icon: Icons.apps_rounded,
                                color: AppTheme.accentColor,
                                subtitle: 'Different apps used',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: 'Sessions',
                                value: sessions.length.toString(),
                                icon: Icons.splitscreen_rounded,
                                color: AppTheme.successColor,
                                subtitle: 'App switches',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StatCard(
                                title: 'Focus',
                                value: _calculateFocusScore(sessions),
                                icon: Icons.psychology_rounded,
                                color: AppTheme.warningColor,
                                subtitle: 'Productivity score',
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('Error: $error'),
                ),

                const SizedBox(height: 32),

                // Tab Navigation
                Container(
                  decoration: AppTheme.glassmorphicDecoration,
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: AppTheme.textSecondary,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Analytics'),
                      Tab(text: 'Timeline'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Tab Content
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(sessionsAsync),
                      _buildAnalyticsTab(sessionsAsync),
                      _buildTimelineTab(sessionsAsync),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
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

  Widget _buildOverviewTab(AsyncValue sessionsAsync) {
    return sessionsAsync.when(
      data: (sessions) {
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

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Usage Distribution',
                subtitle: 'Last 24 hours',
              ),
              GlassCard(child: SizedBox(height: 250, child: UsageChart())),
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Top Applications',
                subtitle: '${sortedApps.length} apps used',
              ),
              ...sortedApps.take(5).map((entry) {
                final percentage = (entry.value / totalTime) * 100;
                final category = AppCategoryExtension.fromAppName(entry.key);
                final color = AppTheme.getCategoryColor(category.displayName);

                return AppUsageListItem(
                  appName: entry.key,
                  timeSpent: _formatDuration(entry.value),
                  percentage: percentage,
                  color: color,
                );
              }),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Widget _buildAnalyticsTab(AsyncValue sessionsAsync) {
    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return _buildEmptyState();
        }

        // Group by category
        final categoryTime = <String, int>{};
        for (var session in sessions) {
          final category = AppCategoryExtension.fromAppName(
            session.appName,
          ).displayName;
          final current = categoryTime[category] ?? 0;
          categoryTime[category] = current + session.durationMs as int;
        }

        final sortedCategories = categoryTime.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final totalTime = sortedCategories.fold<int>(
          0,
          (sum, e) => sum + e.value,
        );

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Category Breakdown',
                subtitle: 'Time spent by category',
              ),
              ...sortedCategories.map((entry) {
                final percentage = (entry.value / totalTime) * 100;
                final color = AppTheme.getCategoryColor(entry.key);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              _formatDuration(entry.value),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AnimatedProgressBar(
                          progress: percentage / 100,
                          color: color,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Widget _buildTimelineTab(AsyncValue sessionsAsync) {
    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return _buildEmptyState();
        }

        final sortedSessions = List.from(sessions)
          ..sort((a, b) => b.startTime.compareTo(a.startTime));

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Session History',
                subtitle: '${sessions.length} sessions today',
              ),
              ...sortedSessions.map((session) {
                final category = AppCategoryExtension.fromAppName(
                  session.appName,
                );
                final color = AppTheme.getCategoryColor(category.displayName);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.appName,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatTime(session.startTime)} • ${_formatDuration(session.durationMs)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category.displayName,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined_rounded,
            size: 80,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 16),
          Text('No data yet', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Start using apps to see your usage statistics',
            style: Theme.of(context).textTheme.bodyMedium,
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

    // Calculate based on session switches and productive apps
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
