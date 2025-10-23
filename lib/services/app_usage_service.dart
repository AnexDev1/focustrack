import 'dart:async';
import 'package:focustrack/services/window_tracker.dart';
import 'package:focustrack/providers/app_usage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppUsageService {
  final WindowTracker _windowTracker;
  final AppUsageNotifier _notifier;
  Timer? _timer;
  WindowInfo? _lastWindow;
  int _idleThresholdMs = 30000; // 30 seconds

  AppUsageService(this._windowTracker, this._notifier);

  void startTracking() {
    _timer = Timer.periodic(const Duration(seconds: 1), _checkActiveWindow);
  }

  Future<void> stopTracking() async {
    _timer?.cancel();
    _timer = null;
    await _notifier.stopTracking();
  }

  void _checkActiveWindow(Timer timer) async {
    final idleTime = await _windowTracker.getIdleTime();

    if (idleTime > _idleThresholdMs) {
      // User is idle, add idle time
      _notifier.addIdleTime(5000); // Add 5 seconds of idle time
      return;
    }

    final activeWindow = await _windowTracker.getActiveWindow();
    _notifier.setDetectedApp(activeWindow?.appName);
    if (activeWindow == null) return;

    // Use window title as app name if app name is "Unknown"
    String displayAppName = activeWindow.appName;
    String? trackingTitle = activeWindow.windowTitle;

    if (displayAppName == 'Unknown' && activeWindow.windowTitle != null) {
      // For "Unknown" apps, use the window title as the unique identifier
      final title = activeWindow.windowTitle!;

      // Extract a meaningful name from the title
      final dashIndex = title.lastIndexOf(' - ');
      final pipeIndex = title.lastIndexOf(' | ');

      if (dashIndex != -1 && dashIndex + 3 < title.length) {
        displayAppName = title.substring(dashIndex + 3);
      } else if (pipeIndex != -1 && pipeIndex + 3 < title.length) {
        displayAppName = title.substring(pipeIndex + 3);
      } else {
        // Use the first word or whole title
        final firstWord = title.split(' ').first;
        displayAppName = firstWord.isNotEmpty ? firstWord : title;
      }
    }

    // Check if it's the same app by comparing the display name and title
    final isSameApp =
        _lastWindow != null &&
        _lastWindow!.appName == displayAppName &&
        _lastWindow!.windowTitle == trackingTitle;

    if (!isSameApp) {
      // App changed, stop previous tracking and start new
      await _notifier.stopTracking();
      await _notifier.startTracking(displayAppName, trackingTitle);

      // Store with the displayAppName so future comparisons work
      _lastWindow = WindowInfo(
        appName: displayAppName,
        windowTitle: trackingTitle,
        processId: activeWindow.processId,
      );
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
