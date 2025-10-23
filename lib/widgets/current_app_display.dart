import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focustrack/providers/app_usage_provider.dart';

class CurrentAppDisplay extends ConsumerWidget {
  const CurrentAppDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appUsageNotifierProvider);

    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                // App icon / avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white12,
                  child: const Icon(
                    Icons.schedule,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Currently Active',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      if (state.isTracking && state.currentApp != null)
                        Text(
                          state.currentApp!,
                          style: Theme.of(context).textTheme.headlineSmall,
                        )
                      else
                        Text(
                          'No active tracking',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      if (state.detectedApp != null)
                        Text(
                          'Detected: ${state.detectedApp}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (state.startTime != null)
                            Text(
                              'Started: ${state.startTime!.toLocal().toString().split('.')[0]}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          const Spacer(),
                          if (state.startTime != null)
                            Text(
                              'Duration: ${DateTime.now().difference(state.startTime!).inMinutes}m ${(DateTime.now().difference(state.startTime!).inSeconds % 60)}s',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          const Spacer(),
                          Text(
                            'Idle: ${(state.totalIdleTime / 1000).round()}s',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Quick actions
                Column(
                  children: [
                    IconButton(
                      tooltip: 'Stop tracking',
                      icon: const Icon(Icons.stop_circle_outlined),
                      onPressed: () async {
                        await ref
                            .read(appUsageNotifierProvider.notifier)
                            .stopTracking();
                      },
                    ),
                    IconButton(
                      tooltip: 'View details',
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
