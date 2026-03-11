import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:focustrack/database/app_usage_database.dart';
import 'package:focustrack/services/android_usage_service.dart';
import 'package:path/path.dart' as p;

class DataTransferService {
  const DataTransferService._();

  static Future<String?> pickSavePath({
    required String suggestedName,
    required String extension,
    required String dialogTitle,
  }) async {
    if (Platform.isAndroid) {
      if (suggestedName.toLowerCase().endsWith('.$extension')) {
        return suggestedName;
      }
      return '$suggestedName.$extension';
    }

    String? path;

    try {
      path = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: [extension],
      );
    } catch (_) {
      path = null;
    }

    path ??= await FilePicker.platform
        .getDirectoryPath(dialogTitle: dialogTitle)
        .then((dir) => dir == null ? null : p.join(dir, suggestedName));

    if (path == null) return null;
    if (!path.toLowerCase().endsWith('.$extension')) {
      return '$path.$extension';
    }
    return path;
  }

  static Future<String?> pickImportPath({required String dialogTitle}) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle,
      type: FileType.custom,
      allowedExtensions: const ['csv', 'json'],
      allowMultiple: false,
    );
    return result?.files.single.path;
  }

  static Future<String> exportSessionsCsv(
    List<AppUsageSession> sessions, {
    required String outputPath,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('App Name,Start Time,End Time,Duration (seconds),Source');
    for (final session in sessions) {
      final end = session.endTime ?? session.startTime;
      final duration = session.durationMs ~/ 1000;
      buffer.writeln(
        '"${session.appName.replaceAll('"', '""')}","${session.startTime.toIso8601String()}","${end.toIso8601String()}",$duration,"${session.source}"',
      );
    }

    return _writeTextContent(
      content: buffer.toString(),
      outputPath: outputPath,
      mimeType: 'text/csv',
    );
  }

  static Future<String> exportSessionsJson(
    List<AppUsageSession> sessions, {
    required String outputPath,
  }) async {
    return _writeTextContent(
      content: const JsonEncoder.withIndent('  ').convert({
        'version': 1,
        'sessions': sessions
            .map(
              (session) => {
                'appName': session.appName,
                'windowTitle': session.windowTitle,
                'startTime': session.startTime.toIso8601String(),
                'endTime': session.endTime?.toIso8601String(),
                'durationMs': session.durationMs,
                'idleTimeMs': session.idleTimeMs,
                'isActive': session.isActive,
                'source': session.source,
              },
            )
            .toList(),
      }),
      outputPath: outputPath,
      mimeType: 'application/json',
    );
  }

  static Future<String> writeTextContent({
    required String content,
    required String outputPath,
    required String mimeType,
  }) async {
    return _writeTextContent(
      content: content,
      outputPath: outputPath,
      mimeType: mimeType,
    );
  }

  static Future<int> importSessionsFromFile(
    AppUsageDatabase database,
    String inputPath,
  ) async {
    final file = File(inputPath);
    final content = await file.readAsString();
    final existing = await database.getAllSessions();
    final existingKeys = existing.map(_sessionKey).toSet();

    final extension = p.extension(inputPath).toLowerCase();
    final sessions = extension == '.json'
        ? _parseJsonSessions(content)
        : _parseCsvSessions(content);

    var importedCount = 0;
    for (final session in sessions) {
      final key = _sessionKey(session);
      if (existingKeys.contains(key)) {
        continue;
      }

      await database.insertSession(
        AppUsageSessionsCompanion(
          appName: Value(session.appName),
          windowTitle: Value(session.windowTitle),
          startTime: Value(session.startTime),
          endTime: Value(session.endTime),
          durationMs: Value(session.durationMs),
          idleTimeMs: Value(session.idleTimeMs),
          isActive: Value(session.isActive),
          source: Value(session.source),
        ),
      );
      existingKeys.add(key);
      importedCount++;
    }

    return importedCount;
  }

  static List<_ImportedSession> _parseJsonSessions(String content) {
    final decoded = jsonDecode(content);
    final rawSessions =
        (decoded as Map<String, dynamic>)['sessions'] as List<dynamic>?;
    if (rawSessions == null) return const [];

    return rawSessions
        .cast<Map<String, dynamic>>()
        .map(
          (row) => _ImportedSession(
            appName: row['appName'] as String? ?? 'Unknown',
            windowTitle: row['windowTitle'] as String?,
            startTime: DateTime.parse(row['startTime'] as String),
            endTime: row['endTime'] == null
                ? null
                : DateTime.parse(row['endTime'] as String),
            durationMs: row['durationMs'] as int? ?? 0,
            idleTimeMs: row['idleTimeMs'] as int? ?? 0,
            isActive: row['isActive'] as bool? ?? false,
            source: row['source'] as String? ?? 'desktop',
          ),
        )
        .toList();
  }

  static List<_ImportedSession> _parseCsvSessions(String content) {
    final lines = const LineSplitter().convert(content).skip(1);
    final sessions = <_ImportedSession>[];
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final columns = _parseCsvLine(line);
      if (columns.length < 5) continue;

      final start = DateTime.tryParse(columns[1]);
      final end = DateTime.tryParse(columns[2]);
      final durationSeconds = int.tryParse(columns[3]);
      if (start == null || end == null || durationSeconds == null) continue;

      sessions.add(
        _ImportedSession(
          appName: columns[0],
          windowTitle: null,
          startTime: start,
          endTime: end,
          durationMs: durationSeconds * 1000,
          idleTimeMs: 0,
          isActive: false,
          source: columns[4].isEmpty ? 'desktop' : columns[4],
        ),
      );
    }
    return sessions;
  }

  static List<String> _parseCsvLine(String line) {
    final values = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var index = 0; index < line.length; index++) {
      final char = line[index];
      if (char == '"') {
        final nextIsQuote = index + 1 < line.length && line[index + 1] == '"';
        if (inQuotes && nextIsQuote) {
          buffer.write('"');
          index++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        values.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    values.add(buffer.toString());
    return values;
  }

  static String _sessionKey(dynamic session) {
    return [
      session.appName,
      session.startTime.toIso8601String(),
      session.endTime?.toIso8601String() ?? '',
      session.durationMs.toString(),
      session.source,
    ].join('|');
  }

  static Future<String> _writeTextContent({
    required String content,
    required String outputPath,
    required String mimeType,
  }) async {
    if (Platform.isAndroid) {
      final savedUri = await AndroidUsageStatsService.saveTextFile(
        fileName: p.basename(outputPath),
        content: content,
        mimeType: mimeType,
      );
      if (savedUri == null || savedUri.isEmpty) {
        throw const FileSystemException('Export cancelled or failed');
      }
      return savedUri;
    }

    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    return file.path;
  }
}

class _ImportedSession {
  final String appName;
  final String? windowTitle;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMs;
  final int idleTimeMs;
  final bool isActive;
  final String source;

  const _ImportedSession({
    required this.appName,
    required this.windowTitle,
    required this.startTime,
    required this.endTime,
    required this.durationMs,
    required this.idleTimeMs,
    required this.isActive,
    required this.source,
  });
}
