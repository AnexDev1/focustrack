// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_usage_database.dart';

// ignore_for_file: type=lint
class $AppUsageSessionsTable extends AppUsageSessions
    with TableInfo<$AppUsageSessionsTable, AppUsageSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppUsageSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _appNameMeta = const VerificationMeta(
    'appName',
  );
  @override
  late final GeneratedColumn<String> appName = GeneratedColumn<String>(
    'app_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _windowTitleMeta = const VerificationMeta(
    'windowTitle',
  );
  @override
  late final GeneratedColumn<String> windowTitle = GeneratedColumn<String>(
    'window_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idleTimeMsMeta = const VerificationMeta(
    'idleTimeMs',
  );
  @override
  late final GeneratedColumn<int> idleTimeMs = GeneratedColumn<int>(
    'idle_time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    appName,
    windowTitle,
    startTime,
    endTime,
    durationMs,
    idleTimeMs,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_usage_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppUsageSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('app_name')) {
      context.handle(
        _appNameMeta,
        appName.isAcceptableOrUnknown(data['app_name']!, _appNameMeta),
      );
    } else if (isInserting) {
      context.missing(_appNameMeta);
    }
    if (data.containsKey('window_title')) {
      context.handle(
        _windowTitleMeta,
        windowTitle.isAcceptableOrUnknown(
          data['window_title']!,
          _windowTitleMeta,
        ),
      );
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('idle_time_ms')) {
      context.handle(
        _idleTimeMsMeta,
        idleTimeMs.isAcceptableOrUnknown(
          data['idle_time_ms']!,
          _idleTimeMsMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppUsageSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppUsageSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      appName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_name'],
      )!,
      windowTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}window_title'],
      ),
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      idleTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}idle_time_ms'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $AppUsageSessionsTable createAlias(String alias) {
    return $AppUsageSessionsTable(attachedDatabase, alias);
  }
}

class AppUsageSession extends DataClass implements Insertable<AppUsageSession> {
  final int id;
  final String appName;
  final String? windowTitle;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMs;
  final int idleTimeMs;
  final bool isActive;
  const AppUsageSession({
    required this.id,
    required this.appName,
    this.windowTitle,
    required this.startTime,
    this.endTime,
    required this.durationMs,
    required this.idleTimeMs,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['app_name'] = Variable<String>(appName);
    if (!nullToAbsent || windowTitle != null) {
      map['window_title'] = Variable<String>(windowTitle);
    }
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    map['idle_time_ms'] = Variable<int>(idleTimeMs);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  AppUsageSessionsCompanion toCompanion(bool nullToAbsent) {
    return AppUsageSessionsCompanion(
      id: Value(id),
      appName: Value(appName),
      windowTitle: windowTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(windowTitle),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      durationMs: Value(durationMs),
      idleTimeMs: Value(idleTimeMs),
      isActive: Value(isActive),
    );
  }

  factory AppUsageSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppUsageSession(
      id: serializer.fromJson<int>(json['id']),
      appName: serializer.fromJson<String>(json['appName']),
      windowTitle: serializer.fromJson<String?>(json['windowTitle']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      idleTimeMs: serializer.fromJson<int>(json['idleTimeMs']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'appName': serializer.toJson<String>(appName),
      'windowTitle': serializer.toJson<String?>(windowTitle),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'durationMs': serializer.toJson<int>(durationMs),
      'idleTimeMs': serializer.toJson<int>(idleTimeMs),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  AppUsageSession copyWith({
    int? id,
    String? appName,
    Value<String?> windowTitle = const Value.absent(),
    DateTime? startTime,
    Value<DateTime?> endTime = const Value.absent(),
    int? durationMs,
    int? idleTimeMs,
    bool? isActive,
  }) => AppUsageSession(
    id: id ?? this.id,
    appName: appName ?? this.appName,
    windowTitle: windowTitle.present ? windowTitle.value : this.windowTitle,
    startTime: startTime ?? this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    durationMs: durationMs ?? this.durationMs,
    idleTimeMs: idleTimeMs ?? this.idleTimeMs,
    isActive: isActive ?? this.isActive,
  );
  AppUsageSession copyWithCompanion(AppUsageSessionsCompanion data) {
    return AppUsageSession(
      id: data.id.present ? data.id.value : this.id,
      appName: data.appName.present ? data.appName.value : this.appName,
      windowTitle: data.windowTitle.present
          ? data.windowTitle.value
          : this.windowTitle,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      idleTimeMs: data.idleTimeMs.present
          ? data.idleTimeMs.value
          : this.idleTimeMs,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppUsageSession(')
          ..write('id: $id, ')
          ..write('appName: $appName, ')
          ..write('windowTitle: $windowTitle, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationMs: $durationMs, ')
          ..write('idleTimeMs: $idleTimeMs, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    appName,
    windowTitle,
    startTime,
    endTime,
    durationMs,
    idleTimeMs,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppUsageSession &&
          other.id == this.id &&
          other.appName == this.appName &&
          other.windowTitle == this.windowTitle &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.durationMs == this.durationMs &&
          other.idleTimeMs == this.idleTimeMs &&
          other.isActive == this.isActive);
}

class AppUsageSessionsCompanion extends UpdateCompanion<AppUsageSession> {
  final Value<int> id;
  final Value<String> appName;
  final Value<String?> windowTitle;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<int> durationMs;
  final Value<int> idleTimeMs;
  final Value<bool> isActive;
  const AppUsageSessionsCompanion({
    this.id = const Value.absent(),
    this.appName = const Value.absent(),
    this.windowTitle = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.idleTimeMs = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  AppUsageSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String appName,
    this.windowTitle = const Value.absent(),
    required DateTime startTime,
    this.endTime = const Value.absent(),
    required int durationMs,
    this.idleTimeMs = const Value.absent(),
    this.isActive = const Value.absent(),
  }) : appName = Value(appName),
       startTime = Value(startTime),
       durationMs = Value(durationMs);
  static Insertable<AppUsageSession> custom({
    Expression<int>? id,
    Expression<String>? appName,
    Expression<String>? windowTitle,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<int>? durationMs,
    Expression<int>? idleTimeMs,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (appName != null) 'app_name': appName,
      if (windowTitle != null) 'window_title': windowTitle,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (durationMs != null) 'duration_ms': durationMs,
      if (idleTimeMs != null) 'idle_time_ms': idleTimeMs,
      if (isActive != null) 'is_active': isActive,
    });
  }

  AppUsageSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? appName,
    Value<String?>? windowTitle,
    Value<DateTime>? startTime,
    Value<DateTime?>? endTime,
    Value<int>? durationMs,
    Value<int>? idleTimeMs,
    Value<bool>? isActive,
  }) {
    return AppUsageSessionsCompanion(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      windowTitle: windowTitle ?? this.windowTitle,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMs: durationMs ?? this.durationMs,
      idleTimeMs: idleTimeMs ?? this.idleTimeMs,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (appName.present) {
      map['app_name'] = Variable<String>(appName.value);
    }
    if (windowTitle.present) {
      map['window_title'] = Variable<String>(windowTitle.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (idleTimeMs.present) {
      map['idle_time_ms'] = Variable<int>(idleTimeMs.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppUsageSessionsCompanion(')
          ..write('id: $id, ')
          ..write('appName: $appName, ')
          ..write('windowTitle: $windowTitle, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationMs: $durationMs, ')
          ..write('idleTimeMs: $idleTimeMs, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppUsageDatabase extends GeneratedDatabase {
  _$AppUsageDatabase(QueryExecutor e) : super(e);
  $AppUsageDatabaseManager get managers => $AppUsageDatabaseManager(this);
  late final $AppUsageSessionsTable appUsageSessions = $AppUsageSessionsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [appUsageSessions];
}

typedef $$AppUsageSessionsTableCreateCompanionBuilder =
    AppUsageSessionsCompanion Function({
      Value<int> id,
      required String appName,
      Value<String?> windowTitle,
      required DateTime startTime,
      Value<DateTime?> endTime,
      required int durationMs,
      Value<int> idleTimeMs,
      Value<bool> isActive,
    });
typedef $$AppUsageSessionsTableUpdateCompanionBuilder =
    AppUsageSessionsCompanion Function({
      Value<int> id,
      Value<String> appName,
      Value<String?> windowTitle,
      Value<DateTime> startTime,
      Value<DateTime?> endTime,
      Value<int> durationMs,
      Value<int> idleTimeMs,
      Value<bool> isActive,
    });

class $$AppUsageSessionsTableFilterComposer
    extends Composer<_$AppUsageDatabase, $AppUsageSessionsTable> {
  $$AppUsageSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get windowTitle => $composableBuilder(
    column: $table.windowTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get idleTimeMs => $composableBuilder(
    column: $table.idleTimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppUsageSessionsTableOrderingComposer
    extends Composer<_$AppUsageDatabase, $AppUsageSessionsTable> {
  $$AppUsageSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get windowTitle => $composableBuilder(
    column: $table.windowTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get idleTimeMs => $composableBuilder(
    column: $table.idleTimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppUsageSessionsTableAnnotationComposer
    extends Composer<_$AppUsageDatabase, $AppUsageSessionsTable> {
  $$AppUsageSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get appName =>
      $composableBuilder(column: $table.appName, builder: (column) => column);

  GeneratedColumn<String> get windowTitle => $composableBuilder(
    column: $table.windowTitle,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get idleTimeMs => $composableBuilder(
    column: $table.idleTimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$AppUsageSessionsTableTableManager
    extends
        RootTableManager<
          _$AppUsageDatabase,
          $AppUsageSessionsTable,
          AppUsageSession,
          $$AppUsageSessionsTableFilterComposer,
          $$AppUsageSessionsTableOrderingComposer,
          $$AppUsageSessionsTableAnnotationComposer,
          $$AppUsageSessionsTableCreateCompanionBuilder,
          $$AppUsageSessionsTableUpdateCompanionBuilder,
          (
            AppUsageSession,
            BaseReferences<
              _$AppUsageDatabase,
              $AppUsageSessionsTable,
              AppUsageSession
            >,
          ),
          AppUsageSession,
          PrefetchHooks Function()
        > {
  $$AppUsageSessionsTableTableManager(
    _$AppUsageDatabase db,
    $AppUsageSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppUsageSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppUsageSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppUsageSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> appName = const Value.absent(),
                Value<String?> windowTitle = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int> idleTimeMs = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => AppUsageSessionsCompanion(
                id: id,
                appName: appName,
                windowTitle: windowTitle,
                startTime: startTime,
                endTime: endTime,
                durationMs: durationMs,
                idleTimeMs: idleTimeMs,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String appName,
                Value<String?> windowTitle = const Value.absent(),
                required DateTime startTime,
                Value<DateTime?> endTime = const Value.absent(),
                required int durationMs,
                Value<int> idleTimeMs = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => AppUsageSessionsCompanion.insert(
                id: id,
                appName: appName,
                windowTitle: windowTitle,
                startTime: startTime,
                endTime: endTime,
                durationMs: durationMs,
                idleTimeMs: idleTimeMs,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppUsageSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppUsageDatabase,
      $AppUsageSessionsTable,
      AppUsageSession,
      $$AppUsageSessionsTableFilterComposer,
      $$AppUsageSessionsTableOrderingComposer,
      $$AppUsageSessionsTableAnnotationComposer,
      $$AppUsageSessionsTableCreateCompanionBuilder,
      $$AppUsageSessionsTableUpdateCompanionBuilder,
      (
        AppUsageSession,
        BaseReferences<
          _$AppUsageDatabase,
          $AppUsageSessionsTable,
          AppUsageSession
        >,
      ),
      AppUsageSession,
      PrefetchHooks Function()
    >;

class $AppUsageDatabaseManager {
  final _$AppUsageDatabase _db;
  $AppUsageDatabaseManager(this._db);
  $$AppUsageSessionsTableTableManager get appUsageSessions =>
      $$AppUsageSessionsTableTableManager(_db, _db.appUsageSessions);
}
