import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focustrack/services/android_usage_service.dart';

/// Sync client that runs on mobile to push data to the desktop.
class SyncClient {
  static const _prefServerAddress = 'sync_server_address';
  static const _prefLastSync = 'sync_last_timestamp';

  /// Save the desktop server address (e.g. "192.168.1.100:8742").
  static Future<void> setServerAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefServerAddress, address);
  }

  /// Get the saved server address.
  static Future<String?> getServerAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefServerAddress);
  }

  /// Get the last sync timestamp.
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_prefLastSync);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Ping the server to check connectivity.
  static Future<bool> pingServer(String address) async {
    try {
      final uri = Uri.parse('http://$address/ping');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['app'] == 'FocusTrack';
      }
    } catch (_) {}
    return false;
  }

  /// Sync today's mobile usage data to the desktop server.
  /// Returns the number of sessions synced, or -1 on error.
  static Future<int> syncToDesktop() async {
    final address = await getServerAddress();
    if (address == null || address.isEmpty) return -1;

    try {
      // Get today's events from Android UsageStats
      final events = await AndroidUsageStatsService.getTodayEvents();
      if (events.isEmpty) return 0;

      // Convert to JSON, excluding FocusTrack's own usage (consistent with local sync)
      final sessionsJson = events
          .where((e) => !e.packageName.contains('focustrack'))
          .map(
            (e) => {
              'appName': e.appName,
              'windowTitle': null,
              'startTime': e.startTime,
              'endTime': e.endTime,
              'durationMs': e.durationMs,
              'idleTimeMs': 0,
            },
          )
          .toList();

      final uri = Uri.parse('http://$address/sync');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(sessionsJson),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final count = data['received'] as int? ?? 0;

        // Save last sync time
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          _prefLastSync,
          DateTime.now().millisecondsSinceEpoch,
        );

        return count;
      }
    } catch (_) {}
    return -1;
  }
}
