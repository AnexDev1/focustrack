import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:focustrack/providers/app_usage_provider.dart';
import 'package:focustrack/services/deep_analytics_service.dart';
import 'package:focustrack/theme/app_theme.dart';
import 'package:focustrack/widgets/custom_widgets.dart';
import 'package:focustrack/models/app_category.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(deepAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Deep Insights'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: analyticsAsync.when(
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Smart Insights Banner ──
          _InsightsBanner(insights: data.insights),
          const SizedBox(height: 24),

          // ── Row 1: Streak · Goal · Comparisons ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _StreakCard(streak: data.productivityStreak)),
              const SizedBox(width: 16),
              Expanded(
                child: _ComparisonCard(
                  day: data.dayComparison,
                  week: data.weekComparison,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FocusCard(
                  multitask: data.multitaskingScore,
                  peak: data.peakProductivityWindow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Row 2: Hourly Heatmap · Session Distribution ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _HourlyHeatmap(hourly: data.hourlyUsage),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _SessionDistribution(buckets: data.sessionDistribution),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Row 3: App Switch Analysis · Category Breakdown ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _SwitchAnalysis(switches: data.switchFrequency)),
              const SizedBox(width: 16),
              Expanded(
                child: _CategoryBreakdown(
                  categoryUsage: data.categoryUsage,
                  totalMs: data.totalScreenTimeMs,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Row 4: Top Apps Deep Stats ──
          _AppDeepStatsTable(
            apps: data.appDeepStats,
            totalMs: data.totalScreenTimeMs,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Smart Insights Banner
// ═══════════════════════════════════════════════════════════════════

class _InsightsBanner extends StatelessWidget {
  final List<String> insights;
  const _InsightsBanner({required this.insights});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.15),
            AppTheme.secondaryColor.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppTheme.warningColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Insights',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('  •  ', style: TextStyle(color: AppTheme.accentColor)),
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Streak & Goal Card
// ═══════════════════════════════════════════════════════════════════

class _StreakCard extends StatelessWidget {
  final ProductivityStreak streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            context,
            'Productivity Streak',
            Icons.local_fire_department,
            AppTheme.warningColor,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _bigNumber(
                context,
                '${streak.currentStreak}',
                'days',
                AppTheme.warningColor,
              ),
              const SizedBox(width: 24),
              _bigNumber(
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
          AnimatedProgressBar(
            progress: streak.todayProgress,
            color: streak.todayProgress >= 1.0
                ? AppTheme.successColor
                : AppTheme.primaryColor,
            height: 10,
          ),
          const SizedBox(height: 6),
          Text(
            '${_fmtMs(streak.todayProductiveMs)} / ${_fmtMs(streak.todayGoalMs)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Day / Week Comparison Card
// ═══════════════════════════════════════════════════════════════════

class _ComparisonCard extends StatelessWidget {
  final PeriodComparison day;
  final PeriodComparison week;
  const _ComparisonCard({required this.day, required this.week});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            context,
            'Period Comparison',
            Icons.compare_arrows,
            AppTheme.accentColor,
          ),
          const SizedBox(height: 16),
          _comparisonRow(context, 'vs Yesterday', day),
          const Divider(height: 24, color: AppTheme.cardColor),
          _comparisonRow(context, 'vs Last Week', week),
        ],
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
}

// ═══════════════════════════════════════════════════════════════════
//  Focus / Multitasking Card
// ═══════════════════════════════════════════════════════════════════

class _FocusCard extends StatelessWidget {
  final MultitaskingScore multitask;
  final String peak;
  const _FocusCard({required this.multitask, required this.peak});

  @override
  Widget build(BuildContext context) {
    final focusColor = multitask.score > 50
        ? AppTheme.successColor
        : multitask.score > 25
        ? AppTheme.warningColor
        : AppTheme.errorColor;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            context,
            'Focus Analysis',
            Icons.psychology_rounded,
            AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: multitask.score / 100,
                      strokeWidth: 8,
                      backgroundColor: focusColor.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation(focusColor),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${multitask.score.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: focusColor,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _miniStat(context, 'Top App', multitask.topApp),
          _miniStat(
            context,
            'Top %',
            '${multitask.topAppPercent.toStringAsFixed(0)}%',
          ),
          _miniStat(context, 'Unique Apps', '${multitask.uniqueApps}'),
          _miniStat(context, 'Peak Window', peak),
        ],
      ),
    );
  }

  Widget _miniStat(BuildContext context, String label, String value) {
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
}

// ═══════════════════════════════════════════════════════════════════
//  Hourly Heatmap
// ═══════════════════════════════════════════════════════════════════

class _HourlyHeatmap extends StatelessWidget {
  final HourlyUsage hourly;
  const _HourlyHeatmap({required this.hourly});

  @override
  Widget build(BuildContext context) {
    final maxMs = hourly.peakMs.clamp(1, double.maxFinite.toInt());

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            context,
            'Hourly Activity Heatmap',
            Icons.grid_on_rounded,
            AppTheme.accentColor,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: maxMs.toDouble(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, gIdx, rod, rIdx) {
                      final h = group.x;
                      return BarTooltipItem(
                        '${_hourLabel(h)}\n${_fmtMs(rod.toY.toInt())}',
                        const TextStyle(color: Colors.white, fontSize: 12),
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
                        final h = val.toInt();
                        if (h % 3 != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _hourLabel(h),
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
                  final ms = hourly.hourToMs[h] ?? 0;
                  final intensity = ms / maxMs;
                  final color = Color.lerp(
                    AppTheme.primaryColor.withOpacity(0.2),
                    AppTheme.primaryColor,
                    intensity,
                  )!;
                  return BarChartGroupData(
                    x: h,
                    barRods: [
                      BarChartRodData(
                        toY: ms.toDouble(),
                        color: color,
                        width: 10,
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
            'Peak hour: ${_hourLabel(hourly.peakHour)} (${_fmtMs(hourly.peakMs)})',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Session Length Distribution
// ═══════════════════════════════════════════════════════════════════

class _SessionDistribution extends StatelessWidget {
  final List<SessionBucket> buckets;
  const _SessionDistribution({required this.buckets});

  @override
  Widget build(BuildContext context) {
    final totalCount = buckets.fold<int>(0, (s, b) => s + b.count);
    final colors = [
      AppTheme.successColor,
      AppTheme.accentColor,
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.warningColor,
      AppTheme.errorColor,
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            context,
            'Session Lengths',
            Icons.timelapse_rounded,
            AppTheme.secondaryColor,
          ),
          const SizedBox(height: 16),
          ...buckets.asMap().entries.map((entry) {
            final i = entry.key;
            final b = entry.value;
            final pct = totalCount > 0 ? b.count / totalCount : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 60,
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
                                .withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation(
                              colors[i % colors.length],
                            ),
                            minHeight: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${b.count}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  App Switch Analysis
// ═══════════════════════════════════════════════════════════════════

class _SwitchAnalysis extends StatelessWidget {
  final SwitchFrequency switches;
  const _SwitchAnalysis({required this.switches});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            context,
            'Context Switching',
            Icons.swap_horiz_rounded,
            AppTheme.warningColor,
          ),
          const SizedBox(height: 16),
          _bigNumber(
            context,
            '${switches.totalSwitches}',
            'switches today',
            AppTheme.warningColor,
          ),
          const SizedBox(height: 12),
          _miniStatRow(
            context,
            Icons.speed,
            'Rate',
            '${switches.avgSwitchesPerHour.toStringAsFixed(1)} / hr',
          ),
          const SizedBox(height: 8),
          _miniStatRow(
            context,
            Icons.logout,
            'Most left',
            switches.mostSwitchedFrom,
          ),
          const SizedBox(height: 8),
          _miniStatRow(
            context,
            Icons.login,
            'Most opened',
            switches.mostSwitchedTo,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  (switches.avgSwitchesPerHour > 20
                          ? AppTheme.errorColor
                          : AppTheme.successColor)
                      .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              switches.avgSwitchesPerHour > 20
                  ? 'High switching rate. Try time-blocking to improve deep work.'
                  : 'Healthy switching pace — good focus!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: switches.avgSwitchesPerHour > 20
                    ? AppTheme.errorColor
                    : AppTheme.successColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStatRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Category Breakdown
// ═══════════════════════════════════════════════════════════════════

class _CategoryBreakdown extends StatelessWidget {
  final Map<String, int> categoryUsage;
  final int totalMs;
  const _CategoryBreakdown({
    required this.categoryUsage,
    required this.totalMs,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = categoryUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            context,
            'Category Breakdown',
            Icons.category_rounded,
            AppTheme.accentColor,
          ),
          const SizedBox(height: 16),
          if (sorted.isEmpty)
            Text('No data yet', style: Theme.of(context).textTheme.bodySmall)
          else
            ...sorted.map((entry) {
              final pct = totalMs > 0 ? entry.value / totalMs : 0.0;
              final color = AppTheme.getCategoryColor(entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          _fmtMs(entry.value),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${(pct * 100).toStringAsFixed(0)}%',
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: color.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  App Deep Stats Table
// ═══════════════════════════════════════════════════════════════════

class _AppDeepStatsTable extends StatelessWidget {
  final List<AppDeepStats> apps;
  final int totalMs;
  const _AppDeepStatsTable({required this.apps, required this.totalMs});

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            context,
            'Detailed App Analysis',
            Icons.apps_rounded,
            AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                AppTheme.surfaceColor.withOpacity(0.3),
              ),
              columnSpacing: 24,
              columns: const [
                DataColumn(
                  label: Text(
                    'App',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Sessions',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Avg Session',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Longest',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Share',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              rows: apps.take(15).map((app) {
                final share = totalMs > 0 ? (app.totalMs / totalMs * 100) : 0.0;
                final catColor = AppTheme.getCategoryColor(
                  app.category.displayName,
                );
                return DataRow(
                  cells: [
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          app.appName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          app.category.displayName,
                          style: TextStyle(color: catColor, fontSize: 11),
                        ),
                      ),
                    ),
                    DataCell(Text(_fmtMs(app.totalMs))),
                    DataCell(Text('${app.sessionCount}')),
                    DataCell(Text(_fmtMs(app.avgSessionMs))),
                    DataCell(Text(_fmtMs(app.longestSessionMs))),
                    DataCell(Text('${share.toStringAsFixed(1)}%')),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Shared helpers
// ═══════════════════════════════════════════════════════════════════

Widget _cardTitle(
  BuildContext context,
  String title,
  IconData icon,
  Color color,
) {
  return Row(
    children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ],
  );
}

Widget _bigNumber(
  BuildContext context,
  String number,
  String label,
  Color color,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        number,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

String _fmtMs(int ms) {
  final d = Duration(milliseconds: ms);
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  if (d.inMinutes > 0) return '${d.inMinutes}m';
  return '< 1m';
}

String _hourLabel(int h) {
  if (h == 0) return '12a';
  if (h < 12) return '${h}a';
  if (h == 12) return '12p';
  return '${h - 12}p';
}
