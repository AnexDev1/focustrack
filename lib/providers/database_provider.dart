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

// Future provider to initialize the database
final databaseInitializerProvider = FutureProvider<AppUsageDatabase>((
  ref,
) async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'app_usage.db'));
  final database = AppUsageDatabase(NativeDatabase(file));
  return database;
});
