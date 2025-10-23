import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focustrack/providers/app_usage_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class UsageChart extends ConsumerStatefulWidget {
  const UsageChart({super.key});

  @override
  ConsumerState<UsageChart> createState() => _UsageChartState();
}

class _UsageChartState extends ConsumerState<UsageChart> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.invalidate(recentSessionsProvider);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(recentSessionsProvider);

    return sessionsAsync.when(
      data: (sessions) {
        // Aggregate usage per app
        final Map<String, int> appUsage = {};
        for (final session in sessions) {
          appUsage[session.appName] =
              (appUsage[session.appName] ?? 0) + session.durationMs;
        }

        final sortedApps = appUsage.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final totalMs = appUsage.values.fold<int>(0, (p, e) => p + e);

        // Colors for chart and legend
        final colors = [
          Colors.blue,
          Colors.green,
          Colors.orange,
          Colors.red,
          Colors.purple,
          Colors.teal,
          Colors.pink,
          Colors.indigo,
        ];

        // Empty state
        if (sessions.isEmpty) {
          return Card(
            child: SizedBox(
              height: 220,
              child: Center(
                child: Text(
                  'No usage data available',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          );
        }

        return Card(
          child: SizedBox(
            height: 300,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'App Usage (Last 24h)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        icon: const Icon(Icons.refresh_outlined),
                        onPressed: () => ref.refresh(recentSessionsProvider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      children: [
                        // Chart
                        Expanded(
                          flex: 3,
                          child: PieChart(
                            PieChartData(
                              sections: sortedApps.take(8).map((entry) {
                                final index = sortedApps.indexOf(entry);
                                final color = colors[index % colors.length];
                                final percentage = totalMs > 0
                                    ? (entry.value / totalMs) * 100
                                    : 0.0;
                                return PieChartSectionData(
                                  value: entry.value.toDouble(),
                                  title: '${percentage.toStringAsFixed(1)}%',
                                  radius: 64,
                                  color: color,
                                  titleStyle: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                              sectionsSpace: 2,
                              centerSpaceRadius: 36,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Legend
                        Expanded(
                          flex: 2,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: sortedApps.take(8).map((entry) {
                                final index = sortedApps.indexOf(entry);
                                final color = colors[index % colors.length];
                                final minutes = (entry.value / 60000).round();
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ),
                                      Text(
                                        '${minutes}m',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
