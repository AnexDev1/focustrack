import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focustrack/database/app_usage_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:drift/native.dart';
import 'dart:io';

// Provider for the database
final databaseProvider = Provider<AppUsageDatabase>((ref) {
  throw UnimplementedError('Database provider not initialized');
});

Future<Directory> _resolveDatabaseDirectory() async {
  final candidates = <Future<Directory> Function()>[
    () => getApplicationSupportDirectory(),
    () => getApplicationDocumentsDirectory(),
  ];

  for (final candidate in candidates) {
    try {
      final baseDir = await candidate();
      final appDir = Directory(p.join(baseDir.path, 'FocusTrack'));
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      return appDir;
    } catch (_) {
      // Try the next writable location.
    }
  }

  if (Platform.isWindows) {
    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      final appDir = Directory(p.join(appData, 'FocusTrack'));
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      return appDir;
    }
  }

  final fallbackDir = Directory(
    p.join(Directory.systemTemp.path, 'FocusTrack'),
  );
  if (!await fallbackDir.exists()) {
    await fallbackDir.create(recursive: true);
  }
  return fallbackDir;
}

// Future provider to initialize the database
final databaseInitializerProvider = FutureProvider<AppUsageDatabase>((
  ref,
) async {
  final appDir = await _resolveDatabaseDirectory();
  final file = File(p.join(appDir.path, 'app_usage.db'));
  final database = AppUsageDatabase(NativeDatabase(file));
  return database;
});
