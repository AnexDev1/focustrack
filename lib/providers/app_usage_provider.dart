import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focustrack/database/app_usage_database.dart';
import 'package:focustrack/providers/database_provider.dart';
import 'package:drift/drift.dart';

// Provider for all app usage sessions
final allSessionsProvider = FutureProvider<List<AppUsageSession>>((ref) async {
  final database = await ref.watch(databaseInitializerProvider.future);
  return database.getAllSessions();
});

// Provider for active session
final activeSessionProvider = FutureProvider<AppUsageSession?>((ref) async {
  final database = await ref.watch(databaseInitializerProvider.future);
  return database.getActiveSession();
});

// Provider for sessions in the last 24 hours
final recentSessionsProvider = FutureProvider<List<AppUsageSession>>((
  ref,
) async {
  final database = await ref.watch(databaseInitializerProvider.future);
  final now = DateTime.now();
  final yesterday = now.subtract(const Duration(days: 1));
  final sessions = await database.getSessionsInDateRange(yesterday, now);
  final activeSession = await database.getActiveSession();
  if (activeSession != null) {
    final currentDuration = now
        .difference(activeSession.startTime)
        .inMilliseconds;
    final updatedActive = activeSession.copyWith(durationMs: currentDuration);
    // Replace the active session in the list or add it if not present
    final index = sessions.indexWhere((s) => s.id == activeSession.id);
    if (index != -1) {
      sessions[index] = updatedActive;
    } else {
      sessions.add(updatedActive);
    }
  }
  return sessions;
});

// State notifier for tracking current app usage
class AppUsageNotifier extends StateNotifier<AppUsageState> {
  AppUsageNotifier(this._ref) : super(AppUsageState());

  final Ref _ref;

  Future<AppUsageDatabase> get _database async {
    return _ref.read(databaseInitializerProvider.future);
  }

  // Start tracking a new app
  Future<void> startTracking(String appName, String? windowTitle) async {
    final database = await _database;
    final now = DateTime.now();
    // Deactivate any existing active sessions
    await (database.update(database.appUsageSessions)
          ..where((tbl) => tbl.isActive.equals(true)))
        .write(const AppUsageSessionsCompanion(isActive: Value(false)));
    final session = AppUsageSessionsCompanion(
      appName: Value(appName),
      windowTitle: Value(windowTitle),
      startTime: Value(now),
      durationMs: const Value(0),
      idleTimeMs: const Value(0),
      isActive: const Value(true),
    );
    await database.insertSession(session);
    state = state.copyWith(
      currentApp: appName,
      isTracking: true,
      startTime: now,
    );
  }

  // Stop tracking current app
  Future<void> stopTracking() async {
    if (state.isTracking && state.startTime != null) {
      final database = await _database;
      final now = DateTime.now();
      final duration = now.difference(state.startTime!).inMilliseconds;
      // Update the active session
      final session = await database.getActiveSession();
      if (session != null) {
        final companion = AppUsageSessionsCompanion(
          id: Value(session.id),
          appName: Value(session.appName),
          windowTitle: Value(session.windowTitle),
          startTime: Value(session.startTime),
          endTime: Value(now),
          durationMs: Value(duration),
          idleTimeMs: Value(session.idleTimeMs),
          isActive: const Value(false),
        );
        await database.update(database.appUsageSessions).replace(companion);
      }
      state = state.copyWith(
        currentApp: null,
        isTracking: false,
        startTime: null,
      );
    }
  }

  // Update idle time
  void addIdleTime(int idleMs) {
    state = state.copyWith(totalIdleTime: state.totalIdleTime + idleMs);
  }

  // Set detected app
  void setDetectedApp(String? appName) {
    state = state.copyWith(detectedApp: appName);
  }
}

// State class
class AppUsageState {
  final String? currentApp;
  final bool isTracking;
  final DateTime? startTime;
  final int totalIdleTime;
  final String? detectedApp;

  AppUsageState({
    this.currentApp,
    this.isTracking = false,
    this.startTime,
    this.totalIdleTime = 0,
    this.detectedApp,
  });

  AppUsageState copyWith({
    String? currentApp,
    bool? isTracking,
    DateTime? startTime,
    int? totalIdleTime,
    String? detectedApp,
  }) {
    return AppUsageState(
      currentApp: currentApp ?? this.currentApp,
      isTracking: isTracking ?? this.isTracking,
      startTime: startTime ?? this.startTime,
      totalIdleTime: totalIdleTime ?? this.totalIdleTime,
      detectedApp: detectedApp ?? this.detectedApp,
    );
  }
}

// Provider for the app usage notifier
final appUsageNotifierProvider =
    StateNotifierProvider<AppUsageNotifier, AppUsageState>((ref) {
      return AppUsageNotifier(ref);
    });
