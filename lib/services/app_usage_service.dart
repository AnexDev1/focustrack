import 'dart:async';
import 'package:focustrack/services/window_tracker.dart';
import 'package:focustrack/providers/app_usage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppUsageService {
  final WindowTracker _windowTracker;
  final AppUsageNotifier _notifier;
  Timer? _timer;
  WindowInfo? _lastWindow;
  bool _checking = false;
  int _idleThresholdMs = 30000; // 30 seconds

  AppUsageService(this._windowTracker, this._notifier);

  void startTracking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), _checkActiveWindow);
  }

  Future<void> stopTracking() async {
    _timer?.cancel();
    _timer = null;
    await _notifier.stopTracking();
    _lastWindow = null;
  }

  void _checkActiveWindow(Timer timer) async {
    if (_checking) return;
    _checking = true;
    try {
      final idleTime = _windowTracker.getIdleTimeMs();

      if (idleTime > _idleThresholdMs) {
        _notifier.addIdleTime(2000); // matches 2-second timer interval
        return;
      }

      final activeWindow = _windowTracker.getActiveWindow();
      _notifier.setDetectedApp(activeWindow?.appName);
      if (activeWindow == null) return;

      // Compare by executable name so tab/title changes don't start new sessions
      final isSameApp =
          _lastWindow != null &&
          _lastWindow!.executableName == activeWindow.executableName;

      if (!isSameApp) {
        await _notifier.stopTracking();
        await _notifier.startTracking(
          activeWindow.appName,
          activeWindow.windowTitle,
        );
        _lastWindow = activeWindow;
      }
    } catch (_) {
      // Swallow errors to keep the timer alive
    } finally {
      _checking = false;
    }
  }

  void setIdleThreshold(int seconds) {
    _idleThresholdMs = seconds * 1000;
  }
}

// Provider for the service
final appUsageServiceProvider = Provider<AppUsageService>((ref) {
  final windowTracker = WindowTrackerImpl();
  final notifier = ref.watch(appUsageNotifierProvider.notifier);
  return AppUsageService(windowTracker, notifier);
});
