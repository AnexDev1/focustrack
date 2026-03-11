import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'package:focustrack/database/app_usage_database.dart';

/// HTTP sync server that runs on the desktop app.
/// Mobile clients push their usage data to this server over the local network.
class SyncServer {
  final AppUsageDatabase database;
  final void Function()? onSyncReceived;
  HttpServer? _server;
  final int port;

  SyncServer({required this.database, this.port = 8742, this.onSyncReceived});

  bool get isRunning => _server != null;

  /// Get the local IP addresses the server is reachable at.
  Future<List<String>> getLocalIPs() async {
    final ips = <String>[];
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            ips.add(addr.address);
          }
        }
      }
    } catch (_) {}
    if (ips.isEmpty) ips.add('127.0.0.1');
    return ips;
  }

  /// Start the sync server.
  Future<void> start() async {
    if (_server != null) return;

    final router = Router();

    // Health check
    router.get('/ping', (Request request) {
      return Response.ok(
        jsonEncode({'status': 'ok', 'app': 'FocusTrack', 'version': '0.2.0'}),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // Receive mobile sessions
    router.post('/sync', (Request request) async {
      try {
        final body = await request.readAsString();
        final List<dynamic> sessionsJson = jsonDecode(body);

        final companions = <AppUsageSessionsCompanion>[];
        for (final json in sessionsJson) {
          companions.add(
            AppUsageSessionsCompanion(
              appName: Value(json['appName'] as String),
              windowTitle: Value(json['windowTitle'] as String?),
              startTime: Value(
                DateTime.fromMillisecondsSinceEpoch(json['startTime'] as int),
              ),
              endTime: json['endTime'] != null
                  ? Value(
                      DateTime.fromMillisecondsSinceEpoch(
                        json['endTime'] as int,
                      ),
                    )
                  : const Value.absent(),
              durationMs: Value(json['durationMs'] as int),
              idleTimeMs: Value((json['idleTimeMs'] as int?) ?? 0),
              isActive: const Value(false),
              source: const Value('mobile'),
            ),
          );
        }

        if (companions.isNotEmpty) {
          // Clear old mobile sessions for the same date range, then insert new
          final earliest = companions
              .map((c) => c.startTime.value)
              .reduce((a, b) => a.isBefore(b) ? a : b);
          final latest = companions
              .map((c) => c.startTime.value)
              .reduce((a, b) => a.isAfter(b) ? a : b)
              .add(const Duration(days: 1));

          // Remove existing mobile sessions in this range to avoid duplicates
          final deleteStmt = database.delete(database.appUsageSessions)
            ..where(
              (tbl) =>
                  tbl.source.equals('mobile') &
                  tbl.startTime.isBiggerOrEqualValue(earliest) &
                  tbl.startTime.isSmallerThanValue(latest),
            );
          await deleteStmt.go();

          await database.insertMobileSessions(companions);

          // Notify listeners that new data arrived
          onSyncReceived?.call();
        }

        return Response.ok(
          jsonEncode({'status': 'ok', 'received': companions.length}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'status': 'error', 'message': e.toString()}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    // Get mobile session count (for status)
    router.get('/status', (Request request) async {
      try {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final mobileSessions = await database.getMobileSessionsInDateRange(
          startOfDay,
          now,
        );
        return Response.ok(
          jsonEncode({
            'status': 'ok',
            'mobileSessions': mobileSessions.length,
            'serverTime': now.toIso8601String(),
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'status': 'error', 'message': e.toString()}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router.call);

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  }

  /// Stop the sync server.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }
}
