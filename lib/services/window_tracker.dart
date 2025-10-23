import 'dart:io' show Platform, Process, Directory, File;

class WindowInfo {
  final String appName;
  final String? windowTitle;
  final int processId;

  WindowInfo({
    required this.appName,
    required this.windowTitle,
    required this.processId,
  });
}

abstract class WindowTracker {
  Future<WindowInfo?> getActiveWindow();
  Future<int> getIdleTime();
}

class WindowTrackerImpl implements WindowTracker {
  @override
  Future<WindowInfo?> getActiveWindow() async {
    if (Platform.isWindows) {
      return await _getActiveWindowWindows();
    } else if (Platform.isLinux) {
      return await _getActiveWindowLinux();
    }
    return null;
  }

  @override
  Future<int> getIdleTime() async {
    if (Platform.isWindows) {
      return await _getIdleTimeWindows();
    } else if (Platform.isLinux) {
      return await _getIdleTimeLinux();
    }
    return 0;
  }

  Future<WindowInfo?> _getActiveWindowWindows() async {
    // Placeholder implementation - need proper win32 integration
    return WindowInfo(appName: 'Unknown', windowTitle: 'Unknown', processId: 0);
  }

  Future<WindowInfo?> _getActiveWindowLinux() async {
    try {
      // Try multiple possible paths for the executable
      final possiblePaths = [
        '${Directory.current.path}/src/active_window_linux',
        '${Directory.current.path}/active_window_linux',
        '${Directory.current.path}/../src/active_window_linux',
        '/usr/local/bin/active_window_linux',
      ];

      String? executablePath;
      for (final path in possiblePaths) {
        final file = File(path);
        if (await file.exists()) {
          executablePath = path;
          break;
        }
      }

      if (executablePath == null) {
        print('ERROR: Executable not found in any of these locations:');
        for (final path in possiblePaths) {
          print('  - $path');
        }
        return null;
      }

      // Pass environment variables including DISPLAY
      final environment = Map<String, String>.from(Platform.environment);
      if (!environment.containsKey('DISPLAY')) {
        environment['DISPLAY'] = ':0';
      }

      final result = await Process.run(
        executablePath,
        [],
        environment: environment,
      );

      if (result.exitCode != 0) {
        print('ERROR: active_window_linux exited with code ${result.exitCode}');
        print('STDERR: ${result.stderr}');
        return null;
      }

      final output = result.stdout.toString().trim();
      if (output.isEmpty) {
        return null;
      }

      final lines = output.split('\n');
      String? appName;
      String? title;

      for (final line in lines) {
        if (line.startsWith('App: ')) {
          appName = line.substring(5).trim();
        } else if (line.startsWith('Title: ')) {
          title = line.substring(7).trim();
        }
      }

      if (appName == null || appName.isEmpty) {
        return null;
      }

      return WindowInfo(
        appName: appName,
        windowTitle: title ?? appName,
        processId: 0,
      );
    } catch (e) {
      print('ERROR getting active window on Linux: $e');
    }
    return null;
  }

  Future<int> _getIdleTimeWindows() async {
    // Placeholder for Windows idle time
    return 0;
  }

  Future<int> _getIdleTimeLinux() async {
    try {
      // Use xprintidle or similar
      final result = await Process.run('xprintidle', []);
      return int.tryParse(result.stdout.toString().trim()) ?? 0;
    } catch (e) {
      print('Error getting idle time on Linux: $e');
      return 0;
    }
  }
}
