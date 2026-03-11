import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:focustrack/providers/app_usage_provider.dart';
import 'package:focustrack/services/deep_analytics_service.dart';
import 'package:focustrack/theme/app_theme.dart';
import 'package:focustrack/models/app_category.dart';

class MobileInsightsScreen extends ConsumerWidget {
  const MobileInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(deepAnalyticsProvider);

    return SafeArea(
      child: analyticsAsync.when(
        data: (data) => _InsightsBody(data: data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _InsightsBody extends StatelessWidget {
  final DeepAnalyticsData data;
  const _InsightsBody({required this.data});

  String _fmtMs(int ms) {
    final h = ms ~/ 3600000;
    final m = (ms % 3600000) ~/ 60000;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '< 1m';
  }

  String _hourLabel(int h) {
    if (h == 0) return '12a';
    if (h < 12) return '${h}a';
    if (h == 12) return '12p';
    return '${h - 12}p';
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Insights',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),

        SliverList(
          delegate: SliverChildListDelegate([
            const SizedBox(height: 20),

            // AI Insights Banner
            _buildInsightsBanner(context),
            const SizedBox(height: 16),

            // Productivity Streak
            _buildStreakCard(context),
            const SizedBox(height: 16),

            // Period Comparisons
            _buildComparisonCard(context),
            const SizedBox(height: 16),

            // Focus Score
            _buildFocusCard(context),
            const SizedBox(height: 16),

            // Hourly Activity
            _buildHourlyChart(context),
            const SizedBox(height: 16),

            // Session Distribution
            _buildSessionDistribution(context),
            const SizedBox(height: 16),

            // Context Switching
            _buildSwitchingCard(context),
            const SizedBox(height: 16),

            // Category Breakdown
            _buildCategoryCard(context),
            const SizedBox(height: 100),
          ]),
        ),
      ],
    );
  }

  Widget _buildInsightsBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.15),
              AppTheme.secondaryColor.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.warningColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...data.insights.map(
              (insight) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '  •  ',
                      style: TextStyle(color: AppTheme.accentColor),
                    ),
                    Expanded(
                      child: Text(
                        insight,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context) {
    final streak = data.productivityStreak;

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
                const Icon(
                  Icons.local_fire_department,
                  color: AppTheme.warningColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Productivity Streak',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _bigStat(
                  context,
                  '${streak.currentStreak}',
                  'days',
                  AppTheme.warningColor,
                ),
                const SizedBox(width: 32),
                _bigStat(
                  context,
                  '${streak.longestStreak}',
                  'best',
                  AppTheme.textTertiary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Daily Goal Progress',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: streak.todayProgress.clamp(0.0, 1.0),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(
                  streak.todayProgress >= 1.0
                      ? AppTheme.successColor
                      : AppTheme.primaryColor,
                ),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_fmtMs(streak.todayProductiveMs)} / ${_fmtMs(streak.todayGoalMs)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(BuildContext context) {
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
                const Icon(
                  Icons.compare_arrows,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Comparisons',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _comparisonRow(context, 'vs Yesterday', data.dayComparison),
            Divider(height: 24, color: AppTheme.cardColor),
            _comparisonRow(context, 'vs Last Week', data.weekComparison),
          ],
        ),
      ),
    );
  }

  Widget _comparisonRow(
    BuildContext context,
    String label,
    PeriodComparison comp,
  ) {
    final isUp = comp.changePercent > 0;
    final color = isUp ? AppTheme.errorColor : AppTheme.successColor;
    final icon = isUp ? Icons.trending_up : Icons.trending_down;
    final pct = comp.changePercent.abs().toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              _fmtMs(comp.currentMs),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            if (comp.previousMs > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$pct%',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${comp.currentSessions} sessions (prev: ${comp.previousSessions})',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildFocusCard(BuildContext context) {
    final ms = data.multitaskingScore;
    final focusColor = ms.score > 50
        ? AppTheme.successColor
        : ms.score > 25
        ? AppTheme.warningColor
        : AppTheme.errorColor;

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
                const Icon(
                  Icons.psychology_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Focus Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: ms.score / 100,
                          strokeWidth: 8,
                          backgroundColor: focusColor.withOpacity(0.12),
                          valueColor: AlwaysStoppedAnimation(focusColor),
                        ),
                      ),
                      Center(
                        child: Text(
                          '${ms.score.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: focusColor,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _miniInfo(context, 'Top App', ms.topApp),
                      _miniInfo(
                        context,
                        'Top %',
                        '${ms.topAppPercent.toStringAsFixed(0)}%',
                      ),
                      _miniInfo(context, 'Unique Apps', '${ms.uniqueApps}'),
                      _miniInfo(context, 'Peak', data.peakProductivityWindow),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyChart(BuildContext context) {
    final maxMs = data.hourlyUsage.peakMs.clamp(1, double.maxFinite.toInt());

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
                const Icon(
                  Icons.grid_on_rounded,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Hourly Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: maxMs.toDouble(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, __) {
                        return BarTooltipItem(
                          '${_hourLabel(group.x)}\n${_fmtMs(rod.toY.toInt())}',
                          const TextStyle(color: Colors.white, fontSize: 11),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, _) {
                          if (val.toInt() % 4 != 0) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _hourLabel(val.toInt()),
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(24, (h) {
                    final ms = data.hourlyUsage.hourToMs[h] ?? 0;
                    final intensity = ms / maxMs;
                    final color = Color.lerp(
                      AppTheme.primaryColor.withOpacity(0.15),
                      AppTheme.primaryColor,
                      intensity,
                    )!;
                    return BarChartGroupData(
                      x: h,
                      barRods: [
                        BarChartRodData(
                          toY: ms.toDouble(),
                          color: color,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Peak: ${_hourLabel(data.hourlyUsage.peakHour)} (${_fmtMs(data.hourlyUsage.peakMs)})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionDistribution(BuildContext context) {
    final buckets = data.sessionDistribution;
    final totalCount = buckets.fold<int>(0, (s, b) => s + b.count);
    final colors = [
      AppTheme.successColor,
      AppTheme.accentColor,
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.warningColor,
      AppTheme.errorColor,
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
            Row(
              children: [
                const Icon(
                  Icons.timelapse_rounded,
                  color: AppTheme.secondaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Session Lengths',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...buckets.asMap().entries.map((entry) {
              final i = entry.key;
              final b = entry.value;
              final pct = totalCount > 0 ? b.count / totalCount : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        b.label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: colors[i % colors.length]
                              .withOpacity(0.12),
                          valueColor: AlwaysStoppedAnimation(
                            colors[i % colors.length],
                          ),
                          minHeight: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${b.count}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchingCard(BuildContext context) {
    final sw = data.switchFrequency;

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
                const Icon(
                  Icons.swap_horiz_rounded,
                  color: AppTheme.warningColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Context Switching',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _bigStat(
              context,
              '${sw.totalSwitches}',
              'switches',
              AppTheme.warningColor,
            ),
            const SizedBox(height: 16),
            _switchRow(
              context,
              Icons.speed,
              'Rate',
              '${sw.avgSwitchesPerHour.toStringAsFixed(1)}/hr',
            ),
            _switchRow(context, Icons.logout, 'Most left', sw.mostSwitchedFrom),
            _switchRow(context, Icons.login, 'Most opened', sw.mostSwitchedTo),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    (sw.avgSwitchesPerHour > 20
                            ? AppTheme.errorColor
                            : AppTheme.successColor)
                        .withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                sw.avgSwitchesPerHour > 20
                    ? 'High switching rate. Try time-blocking for deeper focus.'
                    : 'Healthy pace — good focus!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: sw.avgSwitchesPerHour > 20
                      ? AppTheme.errorColor
                      : AppTheme.successColor,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context) {
    final sorted = data.categoryUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
                const Icon(
                  Icons.category_rounded,
                  color: AppTheme.successColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Category Breakdown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sorted.map((entry) {
              final pct = data.totalScreenTimeMs > 0
                  ? (entry.value / data.totalScreenTimeMs * 100)
                  : 0.0;
              final color = AppTheme.getCategoryColor(entry.key);

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      _fmtMs(entry.value),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 42,
                      child: Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Helper widgets
  Widget _bigStat(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }

  Widget _miniInfo(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textTertiary),
          const SizedBox(width: 8),
          Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
