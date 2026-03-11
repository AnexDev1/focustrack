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

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final events = await AndroidUsageStatsService.getTodayEvents();

    final companions = events
        .where(
          (event) =>
              !event.packageName.contains('focustrack') &&
              event.durationMs > 1000,
        )
        .map(
          (event) => AppUsageSessionsCompanion(
            appName: Value(event.appName),
            windowTitle: const Value(null),
            startTime: Value(
              DateTime.fromMillisecondsSinceEpoch(event.startTime),
            ),
            endTime: Value(DateTime.fromMillisecondsSinceEpoch(event.endTime)),
            durationMs: Value(event.durationMs),
            idleTimeMs: const Value(0),
            isActive: const Value(false),
            source: const Value('mobile'),
          ),
        )
        .toList();

    final deleteStmt = _database.delete(_database.appUsageSessions)
      ..where(
        (tbl) =>
            tbl.source.equals('mobile') &
            tbl.startTime.isBiggerOrEqualValue(startOfDay) &
            tbl.startTime.isSmallerThanValue(
              startOfDay.add(const Duration(days: 1)),
            ),
      );
    await deleteStmt.go();

    if (companions.isNotEmpty) {
      await _database.insertMobileSessions(companions);
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

Future<MobileUsageSyncService> getMobileUsageSyncService(Ref ref) async {
  final database = await ref.read(databaseInitializerProvider.future);
  return MobileUsageSyncService(database);
}

/// Provider for mobile usage sync service.
final mobileUsageSyncProvider = FutureProvider<MobileUsageSyncService>((
  ref,
) async {
  return getMobileUsageSyncService(ref);
});

/// Provider to track permission state.
final usagePermissionProvider = FutureProvider<bool>((ref) async {
  if (!Platform.isAndroid) return true; // Desktop doesn't need this
  return AndroidUsageStatsService.hasPermission();
});
