import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focustrack/database/app_usage_database.dart';
import 'package:focustrack/providers/database_provider.dart';
import 'package:focustrack/services/android_usage_service.dart';

/// Service that syncs Android UsageStats data into the local Drift database
/// so the existing analytics pipeline works seamlessly.
class MobileUsageSyncService {
  final AppUsageDatabase _database;
  Timer? _syncTimer;

  MobileUsageSyncService(this._database);

  /// Start periodic syncing of usage data from Android.
  void startSync() {
    // Initial sync
    syncNow();
    // Sync every 60 seconds
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 60), (_) => syncNow());
  }

  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Perform an immediate sync of today's usage events into the database.
  Future<void> syncNow() async {
    if (!Platform.isAndroid) return;

    final hasPermission = await AndroidUsageStatsService.hasPermission();
    if (!hasPermission) return;

    final events = await AndroidUsageStatsService.getTodayEvents();
    if (events.isEmpty) return;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    // Only compare against existing mobile sessions for today.
    final existingSessions = await _database.getMobileSessionsInDateRange(
      startOfDay,
      now,
    );

    for (final event in events) {
      // Skip our own app
      if (event.packageName.contains('focustrack')) continue;

      final startDt = DateTime.fromMillisecondsSinceEpoch(event.startTime);
      final endDt = DateTime.fromMillisecondsSinceEpoch(event.endTime);

      // Find matching session in DB (same app name, start time within 5 seconds)
      AppUsageSession? existing;
      for (final s in existingSessions) {
        if (s.appName == event.appName &&
            (s.startTime.millisecondsSinceEpoch - event.startTime).abs() <
                5000) {
          existing = s;
          break;
        }
      }

      if (existing != null) {
        // Always update with the latest data — the Kotlin side now caps durations
        // against UsageStats totals, so the new value is authoritative.
        if (event.durationMs != existing.durationMs) {
          await _database.updateSession(
            existing.copyWith(
              endTime: Value(endDt),
              durationMs: event.durationMs,
              source: 'mobile',
            ),
          );
          // Keep local list in sync so we don't re-match on a second pass
          final idx = existingSessions.indexOf(existing);
          if (idx != -1) {
            existingSessions[idx] = existing.copyWith(
              endTime: Value(endDt),
              durationMs: event.durationMs,
              source: 'mobile',
            );
          }
        } else if (existing.source != 'mobile') {
          await _database.updateSession(existing.copyWith(source: 'mobile'));
        }
      } else if (event.durationMs > 1000) {
        // New session — insert it
        final session = AppUsageSessionsCompanion(
          appName: Value(event.appName),
          windowTitle: const Value(null),
          startTime: Value(startDt),
          endTime: Value(endDt),
          durationMs: Value(event.durationMs),
          idleTimeMs: const Value(0),
          isActive: const Value(false),
          source: const Value('mobile'),
        );
        await _database.insertSession(session);
      }
    }
  }

  /// Sync usage stats for a specific time range (for historical data).
  Future<void> syncRange(DateTime start, DateTime end) async {
    if (!Platform.isAndroid) return;

    final stats = await AndroidUsageStatsService.getUsageStats(start, end);
    // Stats are aggregated — we only use them for overview,
    // detailed events come from getTodayEvents/syncNow
    // This could be extended for multi-day historical import
  }
}

/// Provider for mobile usage sync service.
final mobileUsageSyncProvider = Provider<MobileUsageSyncService>((ref) {
  final database = ref.watch(databaseInitializerProvider).value!;
  return MobileUsageSyncService(database);
});

/// Provider to track permission state.
final usagePermissionProvider = FutureProvider<bool>((ref) async {
  if (!Platform.isAndroid) return true; // Desktop doesn't need this
  return AndroidUsageStatsService.hasPermission();
});
