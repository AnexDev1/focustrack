import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focustrack/providers/app_usage_provider.dart';
import 'package:focustrack/providers/database_provider.dart';
import 'package:focustrack/services/app_usage_service.dart';
import 'package:focustrack/widgets/current_app_display.dart';
import 'package:focustrack/widgets/usage_chart.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Start tracking when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appUsageServiceProvider).startTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTracking = ref.watch(
      appUsageNotifierProvider.select((state) => state.isTracking),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('FocusTrack'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: isTracking ? 'Pause tracking' : 'Start tracking',
            icon: Icon(
              isTracking ? Icons.pause_circle_filled : Icons.play_circle_fill,
            ),
            onPressed: () async {
              final service = ref.read(appUsageServiceProvider);
              if (isTracking) {
                await service.stopTracking();
              } else {
                service.startTracking();
              }
            },
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Settings'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.delete_forever),
                        title: const Text('Clear App Usage Data'),
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Deletion'),
                              content: const Text(
                                'Are you sure you want to delete all app usage data? This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            final database = await ref.read(
                              databaseInitializerProvider.future,
                            );
                            await database.clearAllSessions();
                            ref.invalidate(allSessionsProvider);
                            ref.invalidate(recentSessionsProvider);
                            Navigator.of(context).pop(); // Close settings
                          }
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SizedBox(
        height: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top heading and small subtitle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Dashboard',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Overview of today\'s focus and app usage',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Responsive layout: current activity left, charts right
                  Expanded(
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left column
                              Flexible(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: const [
                                    CurrentAppDisplay(),
                                    SizedBox(height: 20),
                                    // potential place for timeline or recent apps
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              // Right column
                              Flexible(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: const [UsageChart()],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: const [
                              CurrentAppDisplay(),
                              SizedBox(height: 18),
                              UsageChart(),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
