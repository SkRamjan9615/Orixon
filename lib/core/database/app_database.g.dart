// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _rangeStartMeta = const VerificationMeta(
    'rangeStart',
  );
  @override
  late final GeneratedColumn<int> rangeStart = GeneratedColumn<int>(
    'range_start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rangeEndMeta = const VerificationMeta(
    'rangeEnd',
  );
  @override
  late final GeneratedColumn<int> rangeEnd = GeneratedColumn<int>(
    'range_end',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isLockedMeta = const VerificationMeta(
    'isLocked',
  );
  @override
  late final GeneratedColumn<bool> isLocked = GeneratedColumn<bool>(
    'is_locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_locked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isKidsApprovedMeta = const VerificationMeta(
    'isKidsApproved',
  );
  @override
  late final GeneratedColumn<bool> isKidsApproved = GeneratedColumn<bool>(
    'is_kids_approved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_kids_approved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    rangeStart,
    rangeEnd,
    sortOrder,
    isLocked,
    isKidsApproved,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('range_start')) {
      context.handle(
        _rangeStartMeta,
        rangeStart.isAcceptableOrUnknown(data['range_start']!, _rangeStartMeta),
      );
    } else if (isInserting) {
      context.missing(_rangeStartMeta);
    }
    if (data.containsKey('range_end')) {
      context.handle(
        _rangeEndMeta,
        rangeEnd.isAcceptableOrUnknown(data['range_end']!, _rangeEndMeta),
      );
    } else if (isInserting) {
      context.missing(_rangeEndMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('is_locked')) {
      context.handle(
        _isLockedMeta,
        isLocked.isAcceptableOrUnknown(data['is_locked']!, _isLockedMeta),
      );
    }
    if (data.containsKey('is_kids_approved')) {
      context.handle(
        _isKidsApprovedMeta,
        isKidsApproved.isAcceptableOrUnknown(
          data['is_kids_approved']!,
          _isKidsApprovedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      rangeStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}range_start'],
      )!,
      rangeEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}range_end'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isLocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_locked'],
      )!,
      isKidsApproved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_kids_approved'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String name;
  final int rangeStart;
  final int rangeEnd;
  final int sortOrder;
  final bool isLocked;
  final bool isKidsApproved;
  const Category({
    required this.id,
    required this.name,
    required this.rangeStart,
    required this.rangeEnd,
    required this.sortOrder,
    required this.isLocked,
    required this.isKidsApproved,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['range_start'] = Variable<int>(rangeStart);
    map['range_end'] = Variable<int>(rangeEnd);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_locked'] = Variable<bool>(isLocked);
    map['is_kids_approved'] = Variable<bool>(isKidsApproved);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      rangeStart: Value(rangeStart),
      rangeEnd: Value(rangeEnd),
      sortOrder: Value(sortOrder),
      isLocked: Value(isLocked),
      isKidsApproved: Value(isKidsApproved),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      rangeStart: serializer.fromJson<int>(json['rangeStart']),
      rangeEnd: serializer.fromJson<int>(json['rangeEnd']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isLocked: serializer.fromJson<bool>(json['isLocked']),
      isKidsApproved: serializer.fromJson<bool>(json['isKidsApproved']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'rangeStart': serializer.toJson<int>(rangeStart),
      'rangeEnd': serializer.toJson<int>(rangeEnd),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isLocked': serializer.toJson<bool>(isLocked),
      'isKidsApproved': serializer.toJson<bool>(isKidsApproved),
    };
  }

  Category copyWith({
    int? id,
    String? name,
    int? rangeStart,
    int? rangeEnd,
    int? sortOrder,
    bool? isLocked,
    bool? isKidsApproved,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    rangeStart: rangeStart ?? this.rangeStart,
    rangeEnd: rangeEnd ?? this.rangeEnd,
    sortOrder: sortOrder ?? this.sortOrder,
    isLocked: isLocked ?? this.isLocked,
    isKidsApproved: isKidsApproved ?? this.isKidsApproved,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      rangeStart: data.rangeStart.present
          ? data.rangeStart.value
          : this.rangeStart,
      rangeEnd: data.rangeEnd.present ? data.rangeEnd.value : this.rangeEnd,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isLocked: data.isLocked.present ? data.isLocked.value : this.isLocked,
      isKidsApproved: data.isKidsApproved.present
          ? data.isKidsApproved.value
          : this.isKidsApproved,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rangeStart: $rangeStart, ')
          ..write('rangeEnd: $rangeEnd, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isLocked: $isLocked, ')
          ..write('isKidsApproved: $isKidsApproved')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    rangeStart,
    rangeEnd,
    sortOrder,
    isLocked,
    isKidsApproved,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.rangeStart == this.rangeStart &&
          other.rangeEnd == this.rangeEnd &&
          other.sortOrder == this.sortOrder &&
          other.isLocked == this.isLocked &&
          other.isKidsApproved == this.isKidsApproved);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> rangeStart;
  final Value<int> rangeEnd;
  final Value<int> sortOrder;
  final Value<bool> isLocked;
  final Value<bool> isKidsApproved;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rangeStart = const Value.absent(),
    this.rangeEnd = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.isKidsApproved = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int rangeStart,
    required int rangeEnd,
    required int sortOrder,
    this.isLocked = const Value.absent(),
    this.isKidsApproved = const Value.absent(),
  }) : name = Value(name),
       rangeStart = Value(rangeStart),
       rangeEnd = Value(rangeEnd),
       sortOrder = Value(sortOrder);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? rangeStart,
    Expression<int>? rangeEnd,
    Expression<int>? sortOrder,
    Expression<bool>? isLocked,
    Expression<bool>? isKidsApproved,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rangeStart != null) 'range_start': rangeStart,
      if (rangeEnd != null) 'range_end': rangeEnd,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isLocked != null) 'is_locked': isLocked,
      if (isKidsApproved != null) 'is_kids_approved': isKidsApproved,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? rangeStart,
    Value<int>? rangeEnd,
    Value<int>? sortOrder,
    Value<bool>? isLocked,
    Value<bool>? isKidsApproved,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
      sortOrder: sortOrder ?? this.sortOrder,
      isLocked: isLocked ?? this.isLocked,
      isKidsApproved: isKidsApproved ?? this.isKidsApproved,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rangeStart.present) {
      map['range_start'] = Variable<int>(rangeStart.value);
    }
    if (rangeEnd.present) {
      map['range_end'] = Variable<int>(rangeEnd.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isLocked.present) {
      map['is_locked'] = Variable<bool>(isLocked.value);
    }
    if (isKidsApproved.present) {
      map['is_kids_approved'] = Variable<bool>(isKidsApproved.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rangeStart: $rangeStart, ')
          ..write('rangeEnd: $rangeEnd, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isLocked: $isLocked, ')
          ..write('isKidsApproved: $isKidsApproved')
          ..write(')'))
        .toString();
  }
}

class $PlaylistsTable extends Playlists
    with TableInfo<$PlaylistsTable, Playlist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceUrlOrPathMeta = const VerificationMeta(
    'sourceUrlOrPath',
  );
  @override
  late final GeneratedColumn<String> sourceUrlOrPath = GeneratedColumn<String>(
    'source_url_or_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _epgUrlMeta = const VerificationMeta('epgUrl');
  @override
  late final GeneratedColumn<String> epgUrl = GeneratedColumn<String>(
    'epg_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _autoRefreshHoursMeta = const VerificationMeta(
    'autoRefreshHours',
  );
  @override
  late final GeneratedColumn<int> autoRefreshHours = GeneratedColumn<int>(
    'auto_refresh_hours',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastUpdatedMeta = const VerificationMeta(
    'lastUpdated',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
    'last_updated',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    sourceUrlOrPath,
    epgUrl,
    autoRefreshHours,
    lastUpdated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<Playlist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('source_url_or_path')) {
      context.handle(
        _sourceUrlOrPathMeta,
        sourceUrlOrPath.isAcceptableOrUnknown(
          data['source_url_or_path']!,
          _sourceUrlOrPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceUrlOrPathMeta);
    }
    if (data.containsKey('epg_url')) {
      context.handle(
        _epgUrlMeta,
        epgUrl.isAcceptableOrUnknown(data['epg_url']!, _epgUrlMeta),
      );
    }
    if (data.containsKey('auto_refresh_hours')) {
      context.handle(
        _autoRefreshHoursMeta,
        autoRefreshHours.isAcceptableOrUnknown(
          data['auto_refresh_hours']!,
          _autoRefreshHoursMeta,
        ),
      );
    }
    if (data.containsKey('last_updated')) {
      context.handle(
        _lastUpdatedMeta,
        lastUpdated.isAcceptableOrUnknown(
          data['last_updated']!,
          _lastUpdatedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Playlist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Playlist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sourceUrlOrPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url_or_path'],
      )!,
      epgUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}epg_url'],
      ),
      autoRefreshHours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}auto_refresh_hours'],
      )!,
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated'],
      ),
    );
  }

  @override
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }
}

class Playlist extends DataClass implements Insertable<Playlist> {
  final int id;
  final String name;
  final String sourceUrlOrPath;
  final String? epgUrl;
  final int autoRefreshHours;
  final DateTime? lastUpdated;
  const Playlist({
    required this.id,
    required this.name,
    required this.sourceUrlOrPath,
    this.epgUrl,
    required this.autoRefreshHours,
    this.lastUpdated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['source_url_or_path'] = Variable<String>(sourceUrlOrPath);
    if (!nullToAbsent || epgUrl != null) {
      map['epg_url'] = Variable<String>(epgUrl);
    }
    map['auto_refresh_hours'] = Variable<int>(autoRefreshHours);
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    return map;
  }

  PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      sourceUrlOrPath: Value(sourceUrlOrPath),
      epgUrl: epgUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(epgUrl),
      autoRefreshHours: Value(autoRefreshHours),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
    );
  }

  factory Playlist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Playlist(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sourceUrlOrPath: serializer.fromJson<String>(json['sourceUrlOrPath']),
      epgUrl: serializer.fromJson<String?>(json['epgUrl']),
      autoRefreshHours: serializer.fromJson<int>(json['autoRefreshHours']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sourceUrlOrPath': serializer.toJson<String>(sourceUrlOrPath),
      'epgUrl': serializer.toJson<String?>(epgUrl),
      'autoRefreshHours': serializer.toJson<int>(autoRefreshHours),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
    };
  }

  Playlist copyWith({
    int? id,
    String? name,
    String? sourceUrlOrPath,
    Value<String?> epgUrl = const Value.absent(),
    int? autoRefreshHours,
    Value<DateTime?> lastUpdated = const Value.absent(),
  }) => Playlist(
    id: id ?? this.id,
    name: name ?? this.name,
    sourceUrlOrPath: sourceUrlOrPath ?? this.sourceUrlOrPath,
    epgUrl: epgUrl.present ? epgUrl.value : this.epgUrl,
    autoRefreshHours: autoRefreshHours ?? this.autoRefreshHours,
    lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
  );
  Playlist copyWithCompanion(PlaylistsCompanion data) {
    return Playlist(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sourceUrlOrPath: data.sourceUrlOrPath.present
          ? data.sourceUrlOrPath.value
          : this.sourceUrlOrPath,
      epgUrl: data.epgUrl.present ? data.epgUrl.value : this.epgUrl,
      autoRefreshHours: data.autoRefreshHours.present
          ? data.autoRefreshHours.value
          : this.autoRefreshHours,
      lastUpdated: data.lastUpdated.present
          ? data.lastUpdated.value
          : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Playlist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceUrlOrPath: $sourceUrlOrPath, ')
          ..write('epgUrl: $epgUrl, ')
          ..write('autoRefreshHours: $autoRefreshHours, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    sourceUrlOrPath,
    epgUrl,
    autoRefreshHours,
    lastUpdated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Playlist &&
          other.id == this.id &&
          other.name == this.name &&
          other.sourceUrlOrPath == this.sourceUrlOrPath &&
          other.epgUrl == this.epgUrl &&
          other.autoRefreshHours == this.autoRefreshHours &&
          other.lastUpdated == this.lastUpdated);
}

class PlaylistsCompanion extends UpdateCompanion<Playlist> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> sourceUrlOrPath;
  final Value<String?> epgUrl;
  final Value<int> autoRefreshHours;
  final Value<DateTime?> lastUpdated;
  const PlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sourceUrlOrPath = const Value.absent(),
    this.epgUrl = const Value.absent(),
    this.autoRefreshHours = const Value.absent(),
    this.lastUpdated = const Value.absent(),
  });
  PlaylistsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String sourceUrlOrPath,
    this.epgUrl = const Value.absent(),
    this.autoRefreshHours = const Value.absent(),
    this.lastUpdated = const Value.absent(),
  }) : name = Value(name),
       sourceUrlOrPath = Value(sourceUrlOrPath);
  static Insertable<Playlist> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? sourceUrlOrPath,
    Expression<String>? epgUrl,
    Expression<int>? autoRefreshHours,
    Expression<DateTime>? lastUpdated,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sourceUrlOrPath != null) 'source_url_or_path': sourceUrlOrPath,
      if (epgUrl != null) 'epg_url': epgUrl,
      if (autoRefreshHours != null) 'auto_refresh_hours': autoRefreshHours,
      if (lastUpdated != null) 'last_updated': lastUpdated,
    });
  }

  PlaylistsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? sourceUrlOrPath,
    Value<String?>? epgUrl,
    Value<int>? autoRefreshHours,
    Value<DateTime?>? lastUpdated,
  }) {
    return PlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceUrlOrPath: sourceUrlOrPath ?? this.sourceUrlOrPath,
      epgUrl: epgUrl ?? this.epgUrl,
      autoRefreshHours: autoRefreshHours ?? this.autoRefreshHours,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sourceUrlOrPath.present) {
      map['source_url_or_path'] = Variable<String>(sourceUrlOrPath.value);
    }
    if (epgUrl.present) {
      map['epg_url'] = Variable<String>(epgUrl.value);
    }
    if (autoRefreshHours.present) {
      map['auto_refresh_hours'] = Variable<int>(autoRefreshHours.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceUrlOrPath: $sourceUrlOrPath, ')
          ..write('epgUrl: $epgUrl, ')
          ..write('autoRefreshHours: $autoRefreshHours, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }
}

class $ChannelsTable extends Channels with TableInfo<$ChannelsTable, Channel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _channelNumberMeta = const VerificationMeta(
    'channelNumber',
  );
  @override
  late final GeneratedColumn<int> channelNumber = GeneratedColumn<int>(
    'channel_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<int> playlistId = GeneratedColumn<int>(
    'playlist_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES playlists (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _logoUrlMeta = const VerificationMeta(
    'logoUrl',
  );
  @override
  late final GeneratedColumn<String> logoUrl = GeneratedColumn<String>(
    'logo_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _primaryUrlMeta = const VerificationMeta(
    'primaryUrl',
  );
  @override
  late final GeneratedColumn<String> primaryUrl = GeneratedColumn<String>(
    'primary_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backupUrl1Meta = const VerificationMeta(
    'backupUrl1',
  );
  @override
  late final GeneratedColumn<String> backupUrl1 = GeneratedColumn<String>(
    'backup_url1',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _backupUrl2Meta = const VerificationMeta(
    'backupUrl2',
  );
  @override
  late final GeneratedColumn<String> backupUrl2 = GeneratedColumn<String>(
    'backup_url2',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _epgChannelIdMeta = const VerificationMeta(
    'epgChannelId',
  );
  @override
  late final GeneratedColumn<String> epgChannelId = GeneratedColumn<String>(
    'epg_channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isLockedMeta = const VerificationMeta(
    'isLocked',
  );
  @override
  late final GeneratedColumn<bool> isLocked = GeneratedColumn<bool>(
    'is_locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_locked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _favoriteOrderMeta = const VerificationMeta(
    'favoriteOrder',
  );
  @override
  late final GeneratedColumn<int> favoriteOrder = GeneratedColumn<int>(
    'favorite_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    channelNumber,
    name,
    categoryId,
    playlistId,
    logoUrl,
    primaryUrl,
    backupUrl1,
    backupUrl2,
    epgChannelId,
    isFavorite,
    isEnabled,
    isLocked,
    favoriteOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<Channel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('channel_number')) {
      context.handle(
        _channelNumberMeta,
        channelNumber.isAcceptableOrUnknown(
          data['channel_number']!,
          _channelNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_channelNumberMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    }
    if (data.containsKey('logo_url')) {
      context.handle(
        _logoUrlMeta,
        logoUrl.isAcceptableOrUnknown(data['logo_url']!, _logoUrlMeta),
      );
    }
    if (data.containsKey('primary_url')) {
      context.handle(
        _primaryUrlMeta,
        primaryUrl.isAcceptableOrUnknown(data['primary_url']!, _primaryUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_primaryUrlMeta);
    }
    if (data.containsKey('backup_url1')) {
      context.handle(
        _backupUrl1Meta,
        backupUrl1.isAcceptableOrUnknown(data['backup_url1']!, _backupUrl1Meta),
      );
    }
    if (data.containsKey('backup_url2')) {
      context.handle(
        _backupUrl2Meta,
        backupUrl2.isAcceptableOrUnknown(data['backup_url2']!, _backupUrl2Meta),
      );
    }
    if (data.containsKey('epg_channel_id')) {
      context.handle(
        _epgChannelIdMeta,
        epgChannelId.isAcceptableOrUnknown(
          data['epg_channel_id']!,
          _epgChannelIdMeta,
        ),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('is_locked')) {
      context.handle(
        _isLockedMeta,
        isLocked.isAcceptableOrUnknown(data['is_locked']!, _isLockedMeta),
      );
    }
    if (data.containsKey('favorite_order')) {
      context.handle(
        _favoriteOrderMeta,
        favoriteOrder.isAcceptableOrUnknown(
          data['favorite_order']!,
          _favoriteOrderMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Channel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Channel(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      channelNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}channel_number'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playlist_id'],
      ),
      logoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_url'],
      )!,
      primaryUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_url'],
      )!,
      backupUrl1: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backup_url1'],
      )!,
      backupUrl2: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backup_url2'],
      )!,
      epgChannelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}epg_channel_id'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      isLocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_locked'],
      )!,
      favoriteOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}favorite_order'],
      )!,
    );
  }

  @override
  $ChannelsTable createAlias(String alias) {
    return $ChannelsTable(attachedDatabase, alias);
  }
}

class Channel extends DataClass implements Insertable<Channel> {
  final int id;
  final int channelNumber;
  final String name;
  final int categoryId;
  final int? playlistId;
  final String logoUrl;
  final String primaryUrl;
  final String backupUrl1;
  final String backupUrl2;
  final String epgChannelId;
  final bool isFavorite;
  final bool isEnabled;
  final bool isLocked;
  final int favoriteOrder;
  const Channel({
    required this.id,
    required this.channelNumber,
    required this.name,
    required this.categoryId,
    this.playlistId,
    required this.logoUrl,
    required this.primaryUrl,
    required this.backupUrl1,
    required this.backupUrl2,
    required this.epgChannelId,
    required this.isFavorite,
    required this.isEnabled,
    required this.isLocked,
    required this.favoriteOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['channel_number'] = Variable<int>(channelNumber);
    map['name'] = Variable<String>(name);
    map['category_id'] = Variable<int>(categoryId);
    if (!nullToAbsent || playlistId != null) {
      map['playlist_id'] = Variable<int>(playlistId);
    }
    map['logo_url'] = Variable<String>(logoUrl);
    map['primary_url'] = Variable<String>(primaryUrl);
    map['backup_url1'] = Variable<String>(backupUrl1);
    map['backup_url2'] = Variable<String>(backupUrl2);
    map['epg_channel_id'] = Variable<String>(epgChannelId);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['is_locked'] = Variable<bool>(isLocked);
    map['favorite_order'] = Variable<int>(favoriteOrder);
    return map;
  }

  ChannelsCompanion toCompanion(bool nullToAbsent) {
    return ChannelsCompanion(
      id: Value(id),
      channelNumber: Value(channelNumber),
      name: Value(name),
      categoryId: Value(categoryId),
      playlistId: playlistId == null && nullToAbsent
          ? const Value.absent()
          : Value(playlistId),
      logoUrl: Value(logoUrl),
      primaryUrl: Value(primaryUrl),
      backupUrl1: Value(backupUrl1),
      backupUrl2: Value(backupUrl2),
      epgChannelId: Value(epgChannelId),
      isFavorite: Value(isFavorite),
      isEnabled: Value(isEnabled),
      isLocked: Value(isLocked),
      favoriteOrder: Value(favoriteOrder),
    );
  }

  factory Channel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Channel(
      id: serializer.fromJson<int>(json['id']),
      channelNumber: serializer.fromJson<int>(json['channelNumber']),
      name: serializer.fromJson<String>(json['name']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      playlistId: serializer.fromJson<int?>(json['playlistId']),
      logoUrl: serializer.fromJson<String>(json['logoUrl']),
      primaryUrl: serializer.fromJson<String>(json['primaryUrl']),
      backupUrl1: serializer.fromJson<String>(json['backupUrl1']),
      backupUrl2: serializer.fromJson<String>(json['backupUrl2']),
      epgChannelId: serializer.fromJson<String>(json['epgChannelId']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      isLocked: serializer.fromJson<bool>(json['isLocked']),
      favoriteOrder: serializer.fromJson<int>(json['favoriteOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'channelNumber': serializer.toJson<int>(channelNumber),
      'name': serializer.toJson<String>(name),
      'categoryId': serializer.toJson<int>(categoryId),
      'playlistId': serializer.toJson<int?>(playlistId),
      'logoUrl': serializer.toJson<String>(logoUrl),
      'primaryUrl': serializer.toJson<String>(primaryUrl),
      'backupUrl1': serializer.toJson<String>(backupUrl1),
      'backupUrl2': serializer.toJson<String>(backupUrl2),
      'epgChannelId': serializer.toJson<String>(epgChannelId),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'isLocked': serializer.toJson<bool>(isLocked),
      'favoriteOrder': serializer.toJson<int>(favoriteOrder),
    };
  }

  Channel copyWith({
    int? id,
    int? channelNumber,
    String? name,
    int? categoryId,
    Value<int?> playlistId = const Value.absent(),
    String? logoUrl,
    String? primaryUrl,
    String? backupUrl1,
    String? backupUrl2,
    String? epgChannelId,
    bool? isFavorite,
    bool? isEnabled,
    bool? isLocked,
    int? favoriteOrder,
  }) => Channel(
    id: id ?? this.id,
    channelNumber: channelNumber ?? this.channelNumber,
    name: name ?? this.name,
    categoryId: categoryId ?? this.categoryId,
    playlistId: playlistId.present ? playlistId.value : this.playlistId,
    logoUrl: logoUrl ?? this.logoUrl,
    primaryUrl: primaryUrl ?? this.primaryUrl,
    backupUrl1: backupUrl1 ?? this.backupUrl1,
    backupUrl2: backupUrl2 ?? this.backupUrl2,
    epgChannelId: epgChannelId ?? this.epgChannelId,
    isFavorite: isFavorite ?? this.isFavorite,
    isEnabled: isEnabled ?? this.isEnabled,
    isLocked: isLocked ?? this.isLocked,
    favoriteOrder: favoriteOrder ?? this.favoriteOrder,
  );
  Channel copyWithCompanion(ChannelsCompanion data) {
    return Channel(
      id: data.id.present ? data.id.value : this.id,
      channelNumber: data.channelNumber.present
          ? data.channelNumber.value
          : this.channelNumber,
      name: data.name.present ? data.name.value : this.name,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      logoUrl: data.logoUrl.present ? data.logoUrl.value : this.logoUrl,
      primaryUrl: data.primaryUrl.present
          ? data.primaryUrl.value
          : this.primaryUrl,
      backupUrl1: data.backupUrl1.present
          ? data.backupUrl1.value
          : this.backupUrl1,
      backupUrl2: data.backupUrl2.present
          ? data.backupUrl2.value
          : this.backupUrl2,
      epgChannelId: data.epgChannelId.present
          ? data.epgChannelId.value
          : this.epgChannelId,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      isLocked: data.isLocked.present ? data.isLocked.value : this.isLocked,
      favoriteOrder: data.favoriteOrder.present
          ? data.favoriteOrder.value
          : this.favoriteOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Channel(')
          ..write('id: $id, ')
          ..write('channelNumber: $channelNumber, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('playlistId: $playlistId, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('primaryUrl: $primaryUrl, ')
          ..write('backupUrl1: $backupUrl1, ')
          ..write('backupUrl2: $backupUrl2, ')
          ..write('epgChannelId: $epgChannelId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('isLocked: $isLocked, ')
          ..write('favoriteOrder: $favoriteOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    channelNumber,
    name,
    categoryId,
    playlistId,
    logoUrl,
    primaryUrl,
    backupUrl1,
    backupUrl2,
    epgChannelId,
    isFavorite,
    isEnabled,
    isLocked,
    favoriteOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Channel &&
          other.id == this.id &&
          other.channelNumber == this.channelNumber &&
          other.name == this.name &&
          other.categoryId == this.categoryId &&
          other.playlistId == this.playlistId &&
          other.logoUrl == this.logoUrl &&
          other.primaryUrl == this.primaryUrl &&
          other.backupUrl1 == this.backupUrl1 &&
          other.backupUrl2 == this.backupUrl2 &&
          other.epgChannelId == this.epgChannelId &&
          other.isFavorite == this.isFavorite &&
          other.isEnabled == this.isEnabled &&
          other.isLocked == this.isLocked &&
          other.favoriteOrder == this.favoriteOrder);
}

class ChannelsCompanion extends UpdateCompanion<Channel> {
  final Value<int> id;
  final Value<int> channelNumber;
  final Value<String> name;
  final Value<int> categoryId;
  final Value<int?> playlistId;
  final Value<String> logoUrl;
  final Value<String> primaryUrl;
  final Value<String> backupUrl1;
  final Value<String> backupUrl2;
  final Value<String> epgChannelId;
  final Value<bool> isFavorite;
  final Value<bool> isEnabled;
  final Value<bool> isLocked;
  final Value<int> favoriteOrder;
  const ChannelsCompanion({
    this.id = const Value.absent(),
    this.channelNumber = const Value.absent(),
    this.name = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.primaryUrl = const Value.absent(),
    this.backupUrl1 = const Value.absent(),
    this.backupUrl2 = const Value.absent(),
    this.epgChannelId = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.favoriteOrder = const Value.absent(),
  });
  ChannelsCompanion.insert({
    this.id = const Value.absent(),
    required int channelNumber,
    required String name,
    required int categoryId,
    this.playlistId = const Value.absent(),
    this.logoUrl = const Value.absent(),
    required String primaryUrl,
    this.backupUrl1 = const Value.absent(),
    this.backupUrl2 = const Value.absent(),
    this.epgChannelId = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.favoriteOrder = const Value.absent(),
  }) : channelNumber = Value(channelNumber),
       name = Value(name),
       categoryId = Value(categoryId),
       primaryUrl = Value(primaryUrl);
  static Insertable<Channel> custom({
    Expression<int>? id,
    Expression<int>? channelNumber,
    Expression<String>? name,
    Expression<int>? categoryId,
    Expression<int>? playlistId,
    Expression<String>? logoUrl,
    Expression<String>? primaryUrl,
    Expression<String>? backupUrl1,
    Expression<String>? backupUrl2,
    Expression<String>? epgChannelId,
    Expression<bool>? isFavorite,
    Expression<bool>? isEnabled,
    Expression<bool>? isLocked,
    Expression<int>? favoriteOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (channelNumber != null) 'channel_number': channelNumber,
      if (name != null) 'name': name,
      if (categoryId != null) 'category_id': categoryId,
      if (playlistId != null) 'playlist_id': playlistId,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (primaryUrl != null) 'primary_url': primaryUrl,
      if (backupUrl1 != null) 'backup_url1': backupUrl1,
      if (backupUrl2 != null) 'backup_url2': backupUrl2,
      if (epgChannelId != null) 'epg_channel_id': epgChannelId,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (isLocked != null) 'is_locked': isLocked,
      if (favoriteOrder != null) 'favorite_order': favoriteOrder,
    });
  }

  ChannelsCompanion copyWith({
    Value<int>? id,
    Value<int>? channelNumber,
    Value<String>? name,
    Value<int>? categoryId,
    Value<int?>? playlistId,
    Value<String>? logoUrl,
    Value<String>? primaryUrl,
    Value<String>? backupUrl1,
    Value<String>? backupUrl2,
    Value<String>? epgChannelId,
    Value<bool>? isFavorite,
    Value<bool>? isEnabled,
    Value<bool>? isLocked,
    Value<int>? favoriteOrder,
  }) {
    return ChannelsCompanion(
      id: id ?? this.id,
      channelNumber: channelNumber ?? this.channelNumber,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      playlistId: playlistId ?? this.playlistId,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryUrl: primaryUrl ?? this.primaryUrl,
      backupUrl1: backupUrl1 ?? this.backupUrl1,
      backupUrl2: backupUrl2 ?? this.backupUrl2,
      epgChannelId: epgChannelId ?? this.epgChannelId,
      isFavorite: isFavorite ?? this.isFavorite,
      isEnabled: isEnabled ?? this.isEnabled,
      isLocked: isLocked ?? this.isLocked,
      favoriteOrder: favoriteOrder ?? this.favoriteOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (channelNumber.present) {
      map['channel_number'] = Variable<int>(channelNumber.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (logoUrl.present) {
      map['logo_url'] = Variable<String>(logoUrl.value);
    }
    if (primaryUrl.present) {
      map['primary_url'] = Variable<String>(primaryUrl.value);
    }
    if (backupUrl1.present) {
      map['backup_url1'] = Variable<String>(backupUrl1.value);
    }
    if (backupUrl2.present) {
      map['backup_url2'] = Variable<String>(backupUrl2.value);
    }
    if (epgChannelId.present) {
      map['epg_channel_id'] = Variable<String>(epgChannelId.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (isLocked.present) {
      map['is_locked'] = Variable<bool>(isLocked.value);
    }
    if (favoriteOrder.present) {
      map['favorite_order'] = Variable<int>(favoriteOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelsCompanion(')
          ..write('id: $id, ')
          ..write('channelNumber: $channelNumber, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('playlistId: $playlistId, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('primaryUrl: $primaryUrl, ')
          ..write('backupUrl1: $backupUrl1, ')
          ..write('backupUrl2: $backupUrl2, ')
          ..write('epgChannelId: $epgChannelId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('isLocked: $isLocked, ')
          ..write('favoriteOrder: $favoriteOrder')
          ..write(')'))
        .toString();
  }
}

class $EpgProgramsTable extends EpgPrograms
    with TableInfo<$EpgProgramsTable, EpgProgram> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpgProgramsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _epgChannelIdMeta = const VerificationMeta(
    'epgChannelId',
  );
  @override
  late final GeneratedColumn<String> epgChannelId = GeneratedColumn<String>(
    'epg_channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    epgChannelId,
    title,
    description,
    startTime,
    endTime,
    category,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'epg_programs';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpgProgram> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('epg_channel_id')) {
      context.handle(
        _epgChannelIdMeta,
        epgChannelId.isAcceptableOrUnknown(
          data['epg_channel_id']!,
          _epgChannelIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_epgChannelIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
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
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EpgProgram map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpgProgram(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      epgChannelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}epg_channel_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
    );
  }

  @override
  $EpgProgramsTable createAlias(String alias) {
    return $EpgProgramsTable(attachedDatabase, alias);
  }
}

class EpgProgram extends DataClass implements Insertable<EpgProgram> {
  final int id;
  final String epgChannelId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String category;
  const EpgProgram({
    required this.id,
    required this.epgChannelId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.category,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['epg_channel_id'] = Variable<String>(epgChannelId);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['start_time'] = Variable<DateTime>(startTime);
    map['end_time'] = Variable<DateTime>(endTime);
    map['category'] = Variable<String>(category);
    return map;
  }

  EpgProgramsCompanion toCompanion(bool nullToAbsent) {
    return EpgProgramsCompanion(
      id: Value(id),
      epgChannelId: Value(epgChannelId),
      title: Value(title),
      description: Value(description),
      startTime: Value(startTime),
      endTime: Value(endTime),
      category: Value(category),
    );
  }

  factory EpgProgram.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpgProgram(
      id: serializer.fromJson<int>(json['id']),
      epgChannelId: serializer.fromJson<String>(json['epgChannelId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime>(json['endTime']),
      category: serializer.fromJson<String>(json['category']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'epgChannelId': serializer.toJson<String>(epgChannelId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime>(endTime),
      'category': serializer.toJson<String>(category),
    };
  }

  EpgProgram copyWith({
    int? id,
    String? epgChannelId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? category,
  }) => EpgProgram(
    id: id ?? this.id,
    epgChannelId: epgChannelId ?? this.epgChannelId,
    title: title ?? this.title,
    description: description ?? this.description,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    category: category ?? this.category,
  );
  EpgProgram copyWithCompanion(EpgProgramsCompanion data) {
    return EpgProgram(
      id: data.id.present ? data.id.value : this.id,
      epgChannelId: data.epgChannelId.present
          ? data.epgChannelId.value
          : this.epgChannelId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      category: data.category.present ? data.category.value : this.category,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpgProgram(')
          ..write('id: $id, ')
          ..write('epgChannelId: $epgChannelId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    epgChannelId,
    title,
    description,
    startTime,
    endTime,
    category,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpgProgram &&
          other.id == this.id &&
          other.epgChannelId == this.epgChannelId &&
          other.title == this.title &&
          other.description == this.description &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.category == this.category);
}

class EpgProgramsCompanion extends UpdateCompanion<EpgProgram> {
  final Value<int> id;
  final Value<String> epgChannelId;
  final Value<String> title;
  final Value<String> description;
  final Value<DateTime> startTime;
  final Value<DateTime> endTime;
  final Value<String> category;
  const EpgProgramsCompanion({
    this.id = const Value.absent(),
    this.epgChannelId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.category = const Value.absent(),
  });
  EpgProgramsCompanion.insert({
    this.id = const Value.absent(),
    required String epgChannelId,
    required String title,
    this.description = const Value.absent(),
    required DateTime startTime,
    required DateTime endTime,
    this.category = const Value.absent(),
  }) : epgChannelId = Value(epgChannelId),
       title = Value(title),
       startTime = Value(startTime),
       endTime = Value(endTime);
  static Insertable<EpgProgram> custom({
    Expression<int>? id,
    Expression<String>? epgChannelId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<String>? category,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (epgChannelId != null) 'epg_channel_id': epgChannelId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (category != null) 'category': category,
    });
  }

  EpgProgramsCompanion copyWith({
    Value<int>? id,
    Value<String>? epgChannelId,
    Value<String>? title,
    Value<String>? description,
    Value<DateTime>? startTime,
    Value<DateTime>? endTime,
    Value<String>? category,
  }) {
    return EpgProgramsCompanion(
      id: id ?? this.id,
      epgChannelId: epgChannelId ?? this.epgChannelId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (epgChannelId.present) {
      map['epg_channel_id'] = Variable<String>(epgChannelId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpgProgramsCompanion(')
          ..write('id: $id, ')
          ..write('epgChannelId: $epgChannelId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }
}

class $MediaFilesTable extends MediaFiles
    with TableInfo<$MediaFilesTable, MediaFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaFilesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderNameMeta = const VerificationMeta(
    'folderName',
  );
  @override
  late final GeneratedColumn<String> folderName = GeneratedColumn<String>(
    'folder_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastPositionMsMeta = const VerificationMeta(
    'lastPositionMs',
  );
  @override
  late final GeneratedColumn<int> lastPositionMs = GeneratedColumn<int>(
    'last_position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
    'last_played_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateAddedMeta = const VerificationMeta(
    'dateAdded',
  );
  @override
  late final GeneratedColumn<DateTime> dateAdded = GeneratedColumn<DateTime>(
    'date_added',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _preferredAudioTrackMeta =
      const VerificationMeta('preferredAudioTrack');
  @override
  late final GeneratedColumn<int> preferredAudioTrack = GeneratedColumn<int>(
    'preferred_audio_track',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preferredSubtitleTrackMeta =
      const VerificationMeta('preferredSubtitleTrack');
  @override
  late final GeneratedColumn<int> preferredSubtitleTrack = GeneratedColumn<int>(
    'preferred_subtitle_track',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    filePath,
    fileName,
    folderName,
    sizeBytes,
    durationMs,
    lastPositionMs,
    isFavorite,
    lastPlayedAt,
    dateAdded,
    preferredAudioTrack,
    preferredSubtitleTrack,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaFile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('folder_name')) {
      context.handle(
        _folderNameMeta,
        folderName.isAcceptableOrUnknown(data['folder_name']!, _folderNameMeta),
      );
    } else if (isInserting) {
      context.missing(_folderNameMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('last_position_ms')) {
      context.handle(
        _lastPositionMsMeta,
        lastPositionMs.isAcceptableOrUnknown(
          data['last_position_ms']!,
          _lastPositionMsMeta,
        ),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    }
    if (data.containsKey('date_added')) {
      context.handle(
        _dateAddedMeta,
        dateAdded.isAcceptableOrUnknown(data['date_added']!, _dateAddedMeta),
      );
    } else if (isInserting) {
      context.missing(_dateAddedMeta);
    }
    if (data.containsKey('preferred_audio_track')) {
      context.handle(
        _preferredAudioTrackMeta,
        preferredAudioTrack.isAcceptableOrUnknown(
          data['preferred_audio_track']!,
          _preferredAudioTrackMeta,
        ),
      );
    }
    if (data.containsKey('preferred_subtitle_track')) {
      context.handle(
        _preferredSubtitleTrackMeta,
        preferredSubtitleTrack.isAcceptableOrUnknown(
          data['preferred_subtitle_track']!,
          _preferredSubtitleTrackMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaFile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      folderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_name'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      lastPositionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_position_ms'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played_at'],
      ),
      dateAdded: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_added'],
      )!,
      preferredAudioTrack: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}preferred_audio_track'],
      ),
      preferredSubtitleTrack: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}preferred_subtitle_track'],
      ),
    );
  }

  @override
  $MediaFilesTable createAlias(String alias) {
    return $MediaFilesTable(attachedDatabase, alias);
  }
}

class MediaFile extends DataClass implements Insertable<MediaFile> {
  final int id;
  final String filePath;
  final String fileName;
  final String folderName;
  final int sizeBytes;
  final int durationMs;
  final int lastPositionMs;
  final bool isFavorite;
  final DateTime? lastPlayedAt;
  final DateTime dateAdded;
  final int? preferredAudioTrack;
  final int? preferredSubtitleTrack;
  const MediaFile({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.folderName,
    required this.sizeBytes,
    required this.durationMs,
    required this.lastPositionMs,
    required this.isFavorite,
    this.lastPlayedAt,
    required this.dateAdded,
    this.preferredAudioTrack,
    this.preferredSubtitleTrack,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['file_path'] = Variable<String>(filePath);
    map['file_name'] = Variable<String>(fileName);
    map['folder_name'] = Variable<String>(folderName);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['duration_ms'] = Variable<int>(durationMs);
    map['last_position_ms'] = Variable<int>(lastPositionMs);
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    }
    map['date_added'] = Variable<DateTime>(dateAdded);
    if (!nullToAbsent || preferredAudioTrack != null) {
      map['preferred_audio_track'] = Variable<int>(preferredAudioTrack);
    }
    if (!nullToAbsent || preferredSubtitleTrack != null) {
      map['preferred_subtitle_track'] = Variable<int>(preferredSubtitleTrack);
    }
    return map;
  }

  MediaFilesCompanion toCompanion(bool nullToAbsent) {
    return MediaFilesCompanion(
      id: Value(id),
      filePath: Value(filePath),
      fileName: Value(fileName),
      folderName: Value(folderName),
      sizeBytes: Value(sizeBytes),
      durationMs: Value(durationMs),
      lastPositionMs: Value(lastPositionMs),
      isFavorite: Value(isFavorite),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
      dateAdded: Value(dateAdded),
      preferredAudioTrack: preferredAudioTrack == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredAudioTrack),
      preferredSubtitleTrack: preferredSubtitleTrack == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredSubtitleTrack),
    );
  }

  factory MediaFile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaFile(
      id: serializer.fromJson<int>(json['id']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileName: serializer.fromJson<String>(json['fileName']),
      folderName: serializer.fromJson<String>(json['folderName']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      lastPositionMs: serializer.fromJson<int>(json['lastPositionMs']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      lastPlayedAt: serializer.fromJson<DateTime?>(json['lastPlayedAt']),
      dateAdded: serializer.fromJson<DateTime>(json['dateAdded']),
      preferredAudioTrack: serializer.fromJson<int?>(
        json['preferredAudioTrack'],
      ),
      preferredSubtitleTrack: serializer.fromJson<int?>(
        json['preferredSubtitleTrack'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'filePath': serializer.toJson<String>(filePath),
      'fileName': serializer.toJson<String>(fileName),
      'folderName': serializer.toJson<String>(folderName),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'durationMs': serializer.toJson<int>(durationMs),
      'lastPositionMs': serializer.toJson<int>(lastPositionMs),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'lastPlayedAt': serializer.toJson<DateTime?>(lastPlayedAt),
      'dateAdded': serializer.toJson<DateTime>(dateAdded),
      'preferredAudioTrack': serializer.toJson<int?>(preferredAudioTrack),
      'preferredSubtitleTrack': serializer.toJson<int?>(preferredSubtitleTrack),
    };
  }

  MediaFile copyWith({
    int? id,
    String? filePath,
    String? fileName,
    String? folderName,
    int? sizeBytes,
    int? durationMs,
    int? lastPositionMs,
    bool? isFavorite,
    Value<DateTime?> lastPlayedAt = const Value.absent(),
    DateTime? dateAdded,
    Value<int?> preferredAudioTrack = const Value.absent(),
    Value<int?> preferredSubtitleTrack = const Value.absent(),
  }) => MediaFile(
    id: id ?? this.id,
    filePath: filePath ?? this.filePath,
    fileName: fileName ?? this.fileName,
    folderName: folderName ?? this.folderName,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    durationMs: durationMs ?? this.durationMs,
    lastPositionMs: lastPositionMs ?? this.lastPositionMs,
    isFavorite: isFavorite ?? this.isFavorite,
    lastPlayedAt: lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
    dateAdded: dateAdded ?? this.dateAdded,
    preferredAudioTrack: preferredAudioTrack.present
        ? preferredAudioTrack.value
        : this.preferredAudioTrack,
    preferredSubtitleTrack: preferredSubtitleTrack.present
        ? preferredSubtitleTrack.value
        : this.preferredSubtitleTrack,
  );
  MediaFile copyWithCompanion(MediaFilesCompanion data) {
    return MediaFile(
      id: data.id.present ? data.id.value : this.id,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      folderName: data.folderName.present
          ? data.folderName.value
          : this.folderName,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      lastPositionMs: data.lastPositionMs.present
          ? data.lastPositionMs.value
          : this.lastPositionMs,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      dateAdded: data.dateAdded.present ? data.dateAdded.value : this.dateAdded,
      preferredAudioTrack: data.preferredAudioTrack.present
          ? data.preferredAudioTrack.value
          : this.preferredAudioTrack,
      preferredSubtitleTrack: data.preferredSubtitleTrack.present
          ? data.preferredSubtitleTrack.value
          : this.preferredSubtitleTrack,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaFile(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('folderName: $folderName, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('durationMs: $durationMs, ')
          ..write('lastPositionMs: $lastPositionMs, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('preferredAudioTrack: $preferredAudioTrack, ')
          ..write('preferredSubtitleTrack: $preferredSubtitleTrack')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    filePath,
    fileName,
    folderName,
    sizeBytes,
    durationMs,
    lastPositionMs,
    isFavorite,
    lastPlayedAt,
    dateAdded,
    preferredAudioTrack,
    preferredSubtitleTrack,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaFile &&
          other.id == this.id &&
          other.filePath == this.filePath &&
          other.fileName == this.fileName &&
          other.folderName == this.folderName &&
          other.sizeBytes == this.sizeBytes &&
          other.durationMs == this.durationMs &&
          other.lastPositionMs == this.lastPositionMs &&
          other.isFavorite == this.isFavorite &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.dateAdded == this.dateAdded &&
          other.preferredAudioTrack == this.preferredAudioTrack &&
          other.preferredSubtitleTrack == this.preferredSubtitleTrack);
}

class MediaFilesCompanion extends UpdateCompanion<MediaFile> {
  final Value<int> id;
  final Value<String> filePath;
  final Value<String> fileName;
  final Value<String> folderName;
  final Value<int> sizeBytes;
  final Value<int> durationMs;
  final Value<int> lastPositionMs;
  final Value<bool> isFavorite;
  final Value<DateTime?> lastPlayedAt;
  final Value<DateTime> dateAdded;
  final Value<int?> preferredAudioTrack;
  final Value<int?> preferredSubtitleTrack;
  const MediaFilesCompanion({
    this.id = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileName = const Value.absent(),
    this.folderName = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.lastPositionMs = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.dateAdded = const Value.absent(),
    this.preferredAudioTrack = const Value.absent(),
    this.preferredSubtitleTrack = const Value.absent(),
  });
  MediaFilesCompanion.insert({
    this.id = const Value.absent(),
    required String filePath,
    required String fileName,
    required String folderName,
    required int sizeBytes,
    this.durationMs = const Value.absent(),
    this.lastPositionMs = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    required DateTime dateAdded,
    this.preferredAudioTrack = const Value.absent(),
    this.preferredSubtitleTrack = const Value.absent(),
  }) : filePath = Value(filePath),
       fileName = Value(fileName),
       folderName = Value(folderName),
       sizeBytes = Value(sizeBytes),
       dateAdded = Value(dateAdded);
  static Insertable<MediaFile> custom({
    Expression<int>? id,
    Expression<String>? filePath,
    Expression<String>? fileName,
    Expression<String>? folderName,
    Expression<int>? sizeBytes,
    Expression<int>? durationMs,
    Expression<int>? lastPositionMs,
    Expression<bool>? isFavorite,
    Expression<DateTime>? lastPlayedAt,
    Expression<DateTime>? dateAdded,
    Expression<int>? preferredAudioTrack,
    Expression<int>? preferredSubtitleTrack,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filePath != null) 'file_path': filePath,
      if (fileName != null) 'file_name': fileName,
      if (folderName != null) 'folder_name': folderName,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (durationMs != null) 'duration_ms': durationMs,
      if (lastPositionMs != null) 'last_position_ms': lastPositionMs,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (dateAdded != null) 'date_added': dateAdded,
      if (preferredAudioTrack != null)
        'preferred_audio_track': preferredAudioTrack,
      if (preferredSubtitleTrack != null)
        'preferred_subtitle_track': preferredSubtitleTrack,
    });
  }

  MediaFilesCompanion copyWith({
    Value<int>? id,
    Value<String>? filePath,
    Value<String>? fileName,
    Value<String>? folderName,
    Value<int>? sizeBytes,
    Value<int>? durationMs,
    Value<int>? lastPositionMs,
    Value<bool>? isFavorite,
    Value<DateTime?>? lastPlayedAt,
    Value<DateTime>? dateAdded,
    Value<int?>? preferredAudioTrack,
    Value<int?>? preferredSubtitleTrack,
  }) {
    return MediaFilesCompanion(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      folderName: folderName ?? this.folderName,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      durationMs: durationMs ?? this.durationMs,
      lastPositionMs: lastPositionMs ?? this.lastPositionMs,
      isFavorite: isFavorite ?? this.isFavorite,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      dateAdded: dateAdded ?? this.dateAdded,
      preferredAudioTrack: preferredAudioTrack ?? this.preferredAudioTrack,
      preferredSubtitleTrack:
          preferredSubtitleTrack ?? this.preferredSubtitleTrack,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (folderName.present) {
      map['folder_name'] = Variable<String>(folderName.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (lastPositionMs.present) {
      map['last_position_ms'] = Variable<int>(lastPositionMs.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    if (dateAdded.present) {
      map['date_added'] = Variable<DateTime>(dateAdded.value);
    }
    if (preferredAudioTrack.present) {
      map['preferred_audio_track'] = Variable<int>(preferredAudioTrack.value);
    }
    if (preferredSubtitleTrack.present) {
      map['preferred_subtitle_track'] = Variable<int>(
        preferredSubtitleTrack.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaFilesCompanion(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('folderName: $folderName, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('durationMs: $durationMs, ')
          ..write('lastPositionMs: $lastPositionMs, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('preferredAudioTrack: $preferredAudioTrack, ')
          ..write('preferredSubtitleTrack: $preferredSubtitleTrack')
          ..write(')'))
        .toString();
  }
}

class $PlaybackHistoryTable extends PlaybackHistory
    with TableInfo<$PlaybackHistoryTable, PlaybackHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackHistoryTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _itemTypeMeta = const VerificationMeta(
    'itemType',
  );
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
    'item_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceIdMeta = const VerificationMeta(
    'referenceId',
  );
  @override
  late final GeneratedColumn<String> referenceId = GeneratedColumn<String>(
    'reference_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailMeta = const VerificationMeta(
    'thumbnail',
  );
  @override
  late final GeneratedColumn<String> thumbnail = GeneratedColumn<String>(
    'thumbnail',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _positionMsMeta = const VerificationMeta(
    'positionMs',
  );
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _watchedAtMeta = const VerificationMeta(
    'watchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> watchedAt = GeneratedColumn<DateTime>(
    'watched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemType,
    referenceId,
    title,
    thumbnail,
    positionMs,
    watchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaybackHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_type')) {
      context.handle(
        _itemTypeMeta,
        itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_itemTypeMeta);
    }
    if (data.containsKey('reference_id')) {
      context.handle(
        _referenceIdMeta,
        referenceId.isAcceptableOrUnknown(
          data['reference_id']!,
          _referenceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('thumbnail')) {
      context.handle(
        _thumbnailMeta,
        thumbnail.isAcceptableOrUnknown(data['thumbnail']!, _thumbnailMeta),
      );
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    }
    if (data.containsKey('watched_at')) {
      context.handle(
        _watchedAtMeta,
        watchedAt.isAcceptableOrUnknown(data['watched_at']!, _watchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_watchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaybackHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_type'],
      )!,
      referenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      thumbnail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail'],
      )!,
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
      watchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}watched_at'],
      )!,
    );
  }

  @override
  $PlaybackHistoryTable createAlias(String alias) {
    return $PlaybackHistoryTable(attachedDatabase, alias);
  }
}

class PlaybackHistoryData extends DataClass
    implements Insertable<PlaybackHistoryData> {
  final int id;
  final String itemType;
  final String referenceId;
  final String title;
  final String thumbnail;
  final int positionMs;
  final DateTime watchedAt;
  const PlaybackHistoryData({
    required this.id,
    required this.itemType,
    required this.referenceId,
    required this.title,
    required this.thumbnail,
    required this.positionMs,
    required this.watchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_type'] = Variable<String>(itemType);
    map['reference_id'] = Variable<String>(referenceId);
    map['title'] = Variable<String>(title);
    map['thumbnail'] = Variable<String>(thumbnail);
    map['position_ms'] = Variable<int>(positionMs);
    map['watched_at'] = Variable<DateTime>(watchedAt);
    return map;
  }

  PlaybackHistoryCompanion toCompanion(bool nullToAbsent) {
    return PlaybackHistoryCompanion(
      id: Value(id),
      itemType: Value(itemType),
      referenceId: Value(referenceId),
      title: Value(title),
      thumbnail: Value(thumbnail),
      positionMs: Value(positionMs),
      watchedAt: Value(watchedAt),
    );
  }

  factory PlaybackHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackHistoryData(
      id: serializer.fromJson<int>(json['id']),
      itemType: serializer.fromJson<String>(json['itemType']),
      referenceId: serializer.fromJson<String>(json['referenceId']),
      title: serializer.fromJson<String>(json['title']),
      thumbnail: serializer.fromJson<String>(json['thumbnail']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      watchedAt: serializer.fromJson<DateTime>(json['watchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemType': serializer.toJson<String>(itemType),
      'referenceId': serializer.toJson<String>(referenceId),
      'title': serializer.toJson<String>(title),
      'thumbnail': serializer.toJson<String>(thumbnail),
      'positionMs': serializer.toJson<int>(positionMs),
      'watchedAt': serializer.toJson<DateTime>(watchedAt),
    };
  }

  PlaybackHistoryData copyWith({
    int? id,
    String? itemType,
    String? referenceId,
    String? title,
    String? thumbnail,
    int? positionMs,
    DateTime? watchedAt,
  }) => PlaybackHistoryData(
    id: id ?? this.id,
    itemType: itemType ?? this.itemType,
    referenceId: referenceId ?? this.referenceId,
    title: title ?? this.title,
    thumbnail: thumbnail ?? this.thumbnail,
    positionMs: positionMs ?? this.positionMs,
    watchedAt: watchedAt ?? this.watchedAt,
  );
  PlaybackHistoryData copyWithCompanion(PlaybackHistoryCompanion data) {
    return PlaybackHistoryData(
      id: data.id.present ? data.id.value : this.id,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      referenceId: data.referenceId.present
          ? data.referenceId.value
          : this.referenceId,
      title: data.title.present ? data.title.value : this.title,
      thumbnail: data.thumbnail.present ? data.thumbnail.value : this.thumbnail,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      watchedAt: data.watchedAt.present ? data.watchedAt.value : this.watchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackHistoryData(')
          ..write('id: $id, ')
          ..write('itemType: $itemType, ')
          ..write('referenceId: $referenceId, ')
          ..write('title: $title, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('positionMs: $positionMs, ')
          ..write('watchedAt: $watchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemType,
    referenceId,
    title,
    thumbnail,
    positionMs,
    watchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackHistoryData &&
          other.id == this.id &&
          other.itemType == this.itemType &&
          other.referenceId == this.referenceId &&
          other.title == this.title &&
          other.thumbnail == this.thumbnail &&
          other.positionMs == this.positionMs &&
          other.watchedAt == this.watchedAt);
}

class PlaybackHistoryCompanion extends UpdateCompanion<PlaybackHistoryData> {
  final Value<int> id;
  final Value<String> itemType;
  final Value<String> referenceId;
  final Value<String> title;
  final Value<String> thumbnail;
  final Value<int> positionMs;
  final Value<DateTime> watchedAt;
  const PlaybackHistoryCompanion({
    this.id = const Value.absent(),
    this.itemType = const Value.absent(),
    this.referenceId = const Value.absent(),
    this.title = const Value.absent(),
    this.thumbnail = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.watchedAt = const Value.absent(),
  });
  PlaybackHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String itemType,
    required String referenceId,
    required String title,
    this.thumbnail = const Value.absent(),
    this.positionMs = const Value.absent(),
    required DateTime watchedAt,
  }) : itemType = Value(itemType),
       referenceId = Value(referenceId),
       title = Value(title),
       watchedAt = Value(watchedAt);
  static Insertable<PlaybackHistoryData> custom({
    Expression<int>? id,
    Expression<String>? itemType,
    Expression<String>? referenceId,
    Expression<String>? title,
    Expression<String>? thumbnail,
    Expression<int>? positionMs,
    Expression<DateTime>? watchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemType != null) 'item_type': itemType,
      if (referenceId != null) 'reference_id': referenceId,
      if (title != null) 'title': title,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (positionMs != null) 'position_ms': positionMs,
      if (watchedAt != null) 'watched_at': watchedAt,
    });
  }

  PlaybackHistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? itemType,
    Value<String>? referenceId,
    Value<String>? title,
    Value<String>? thumbnail,
    Value<int>? positionMs,
    Value<DateTime>? watchedAt,
  }) {
    return PlaybackHistoryCompanion(
      id: id ?? this.id,
      itemType: itemType ?? this.itemType,
      referenceId: referenceId ?? this.referenceId,
      title: title ?? this.title,
      thumbnail: thumbnail ?? this.thumbnail,
      positionMs: positionMs ?? this.positionMs,
      watchedAt: watchedAt ?? this.watchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (referenceId.present) {
      map['reference_id'] = Variable<String>(referenceId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (thumbnail.present) {
      map['thumbnail'] = Variable<String>(thumbnail.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (watchedAt.present) {
      map['watched_at'] = Variable<DateTime>(watchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackHistoryCompanion(')
          ..write('id: $id, ')
          ..write('itemType: $itemType, ')
          ..write('referenceId: $referenceId, ')
          ..write('title: $title, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('positionMs: $positionMs, ')
          ..write('watchedAt: $watchedAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, category];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  final String category;
  const AppSetting({
    required this.key,
    required this.value,
    required this.category,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['category'] = Variable<String>(category);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
      category: Value(category),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      category: serializer.fromJson<String>(json['category']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'category': serializer.toJson<String>(category),
    };
  }

  AppSetting copyWith({String? key, String? value, String? category}) =>
      AppSetting(
        key: key ?? this.key,
        value: value ?? this.value,
        category: category ?? this.category,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      category: data.category.present ? data.category.value : this.category,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, category);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value &&
          other.category == this.category);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<String> category;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.category = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    required String category,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       category = Value(category);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<String>? category,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (category != null) 'category': category,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<String>? category,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      category: category ?? this.category,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('category: $category, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemoteMappingsTable extends RemoteMappings
    with TableInfo<$RemoteMappingsTable, RemoteMapping> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemoteMappingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _actionKeyMeta = const VerificationMeta(
    'actionKey',
  );
  @override
  late final GeneratedColumn<String> actionKey = GeneratedColumn<String>(
    'action_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assignedCommandMeta = const VerificationMeta(
    'assignedCommand',
  );
  @override
  late final GeneratedColumn<String> assignedCommand = GeneratedColumn<String>(
    'assigned_command',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customParamMeta = const VerificationMeta(
    'customParam',
  );
  @override
  late final GeneratedColumn<String> customParam = GeneratedColumn<String>(
    'custom_param',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    actionKey,
    assignedCommand,
    customParam,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remote_mappings';
  @override
  VerificationContext validateIntegrity(
    Insertable<RemoteMapping> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('action_key')) {
      context.handle(
        _actionKeyMeta,
        actionKey.isAcceptableOrUnknown(data['action_key']!, _actionKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_actionKeyMeta);
    }
    if (data.containsKey('assigned_command')) {
      context.handle(
        _assignedCommandMeta,
        assignedCommand.isAcceptableOrUnknown(
          data['assigned_command']!,
          _assignedCommandMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_assignedCommandMeta);
    }
    if (data.containsKey('custom_param')) {
      context.handle(
        _customParamMeta,
        customParam.isAcceptableOrUnknown(
          data['custom_param']!,
          _customParamMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {actionKey};
  @override
  RemoteMapping map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemoteMapping(
      actionKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_key'],
      )!,
      assignedCommand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assigned_command'],
      )!,
      customParam: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_param'],
      )!,
    );
  }

  @override
  $RemoteMappingsTable createAlias(String alias) {
    return $RemoteMappingsTable(attachedDatabase, alias);
  }
}

class RemoteMapping extends DataClass implements Insertable<RemoteMapping> {
  final String actionKey;
  final String assignedCommand;
  final String customParam;
  const RemoteMapping({
    required this.actionKey,
    required this.assignedCommand,
    required this.customParam,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['action_key'] = Variable<String>(actionKey);
    map['assigned_command'] = Variable<String>(assignedCommand);
    map['custom_param'] = Variable<String>(customParam);
    return map;
  }

  RemoteMappingsCompanion toCompanion(bool nullToAbsent) {
    return RemoteMappingsCompanion(
      actionKey: Value(actionKey),
      assignedCommand: Value(assignedCommand),
      customParam: Value(customParam),
    );
  }

  factory RemoteMapping.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemoteMapping(
      actionKey: serializer.fromJson<String>(json['actionKey']),
      assignedCommand: serializer.fromJson<String>(json['assignedCommand']),
      customParam: serializer.fromJson<String>(json['customParam']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'actionKey': serializer.toJson<String>(actionKey),
      'assignedCommand': serializer.toJson<String>(assignedCommand),
      'customParam': serializer.toJson<String>(customParam),
    };
  }

  RemoteMapping copyWith({
    String? actionKey,
    String? assignedCommand,
    String? customParam,
  }) => RemoteMapping(
    actionKey: actionKey ?? this.actionKey,
    assignedCommand: assignedCommand ?? this.assignedCommand,
    customParam: customParam ?? this.customParam,
  );
  RemoteMapping copyWithCompanion(RemoteMappingsCompanion data) {
    return RemoteMapping(
      actionKey: data.actionKey.present ? data.actionKey.value : this.actionKey,
      assignedCommand: data.assignedCommand.present
          ? data.assignedCommand.value
          : this.assignedCommand,
      customParam: data.customParam.present
          ? data.customParam.value
          : this.customParam,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemoteMapping(')
          ..write('actionKey: $actionKey, ')
          ..write('assignedCommand: $assignedCommand, ')
          ..write('customParam: $customParam')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(actionKey, assignedCommand, customParam);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemoteMapping &&
          other.actionKey == this.actionKey &&
          other.assignedCommand == this.assignedCommand &&
          other.customParam == this.customParam);
}

class RemoteMappingsCompanion extends UpdateCompanion<RemoteMapping> {
  final Value<String> actionKey;
  final Value<String> assignedCommand;
  final Value<String> customParam;
  final Value<int> rowid;
  const RemoteMappingsCompanion({
    this.actionKey = const Value.absent(),
    this.assignedCommand = const Value.absent(),
    this.customParam = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemoteMappingsCompanion.insert({
    required String actionKey,
    required String assignedCommand,
    this.customParam = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : actionKey = Value(actionKey),
       assignedCommand = Value(assignedCommand);
  static Insertable<RemoteMapping> custom({
    Expression<String>? actionKey,
    Expression<String>? assignedCommand,
    Expression<String>? customParam,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (actionKey != null) 'action_key': actionKey,
      if (assignedCommand != null) 'assigned_command': assignedCommand,
      if (customParam != null) 'custom_param': customParam,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemoteMappingsCompanion copyWith({
    Value<String>? actionKey,
    Value<String>? assignedCommand,
    Value<String>? customParam,
    Value<int>? rowid,
  }) {
    return RemoteMappingsCompanion(
      actionKey: actionKey ?? this.actionKey,
      assignedCommand: assignedCommand ?? this.assignedCommand,
      customParam: customParam ?? this.customParam,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (actionKey.present) {
      map['action_key'] = Variable<String>(actionKey.value);
    }
    if (assignedCommand.present) {
      map['assigned_command'] = Variable<String>(assignedCommand.value);
    }
    if (customParam.present) {
      map['custom_param'] = Variable<String>(customParam.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemoteMappingsCompanion(')
          ..write('actionKey: $actionKey, ')
          ..write('assignedCommand: $assignedCommand, ')
          ..write('customParam: $customParam, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $PlaylistsTable playlists = $PlaylistsTable(this);
  late final $ChannelsTable channels = $ChannelsTable(this);
  late final $EpgProgramsTable epgPrograms = $EpgProgramsTable(this);
  late final $MediaFilesTable mediaFiles = $MediaFilesTable(this);
  late final $PlaybackHistoryTable playbackHistory = $PlaybackHistoryTable(
    this,
  );
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $RemoteMappingsTable remoteMappings = $RemoteMappingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    playlists,
    channels,
    epgPrograms,
    mediaFiles,
    playbackHistory,
    appSettings,
    remoteMappings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('channels', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required String name,
  required int rangeStart,
  required int rangeEnd,
  required int sortOrder,
  Value<bool> isLocked,
  Value<bool> isKidsApproved,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> rangeStart,
  Value<int> rangeEnd,
  Value<int> sortOrder,
  Value<bool> isLocked,
  Value<bool> isKidsApproved,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChannelsTable, List<Channel>> _channelsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.channels,
    aliasName: 'categories__id__channels__category_id',
  );

  $$ChannelsTableProcessedTableManager get channelsRefs {
    final manager = $$ChannelsTableTableManager(
      $_db,
      $_db.channels,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_channelsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rangeStart => $composableBuilder(
    column: $table.rangeStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rangeEnd => $composableBuilder(
    column: $table.rangeEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isKidsApproved => $composableBuilder(
    column: $table.isKidsApproved,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> channelsRefs(
    Expression<bool> Function($$ChannelsTableFilterComposer f) f,
  ) {
    final $$ChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableFilterComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rangeStart => $composableBuilder(
    column: $table.rangeStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rangeEnd => $composableBuilder(
    column: $table.rangeEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isKidsApproved => $composableBuilder(
    column: $table.isKidsApproved,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get rangeStart => $composableBuilder(
    column: $table.rangeStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rangeEnd =>
      $composableBuilder(column: $table.rangeEnd, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isLocked =>
      $composableBuilder(column: $table.isLocked, builder: (column) => column);

  GeneratedColumn<bool> get isKidsApproved => $composableBuilder(
    column: $table.isKidsApproved,
    builder: (column) => column,
  );

  Expression<T> channelsRefs<T extends Object>(
    Expression<T> Function($$ChannelsTableAnnotationComposer a) f,
  ) {
    final $$ChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({bool channelsRefs})
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rangeStart = const Value.absent(),
                Value<int> rangeEnd = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isLocked = const Value.absent(),
                Value<bool> isKidsApproved = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                rangeStart: rangeStart,
                rangeEnd: rangeEnd,
                sortOrder: sortOrder,
                isLocked: isLocked,
                isKidsApproved: isKidsApproved,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int rangeStart,
                required int rangeEnd,
                required int sortOrder,
                Value<bool> isLocked = const Value.absent(),
                Value<bool> isKidsApproved = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                rangeStart: rangeStart,
                rangeEnd: rangeEnd,
                sortOrder: sortOrder,
                isLocked: isLocked,
                isKidsApproved: isKidsApproved,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, Category>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({channelsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (channelsRefs) db.channels],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (channelsRefs)
                    await $_getPrefetchedDataByColumns<
                      Category,
                      $CategoriesTable,
                      Channel,
                      $ChannelsTable
                    >(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences
                          ._channelsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).channelsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'category_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({bool channelsRefs})
    >;
typedef $$PlaylistsTableCreateCompanionBuilder = PlaylistsCompanion Function({
  Value<int> id,
  required String name,
  required String sourceUrlOrPath,
  Value<String?> epgUrl,
  Value<int> autoRefreshHours,
  Value<DateTime?> lastUpdated,
});
typedef $$PlaylistsTableUpdateCompanionBuilder = PlaylistsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> sourceUrlOrPath,
  Value<String?> epgUrl,
  Value<int> autoRefreshHours,
  Value<DateTime?> lastUpdated,
});

final class $$PlaylistsTableReferences
    extends BaseReferences<_$AppDatabase, $PlaylistsTable, Playlist> {
  $$PlaylistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChannelsTable, List<Channel>> _channelsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.channels,
    aliasName: 'playlists__id__channels__playlist_id',
  );

  $$ChannelsTableProcessedTableManager get channelsRefs {
    final manager = $$ChannelsTableTableManager(
      $_db,
      $_db.channels,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_channelsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrlOrPath => $composableBuilder(
    column: $table.sourceUrlOrPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get epgUrl => $composableBuilder(
    column: $table.epgUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get autoRefreshHours => $composableBuilder(
    column: $table.autoRefreshHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> channelsRefs(
    Expression<bool> Function($$ChannelsTableFilterComposer f) f,
  ) {
    final $$ChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableFilterComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrlOrPath => $composableBuilder(
    column: $table.sourceUrlOrPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get epgUrl => $composableBuilder(
    column: $table.epgUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get autoRefreshHours => $composableBuilder(
    column: $table.autoRefreshHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sourceUrlOrPath => $composableBuilder(
    column: $table.sourceUrlOrPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get epgUrl =>
      $composableBuilder(column: $table.epgUrl, builder: (column) => column);

  GeneratedColumn<int> get autoRefreshHours => $composableBuilder(
    column: $table.autoRefreshHours,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => column,
  );

  Expression<T> channelsRefs<T extends Object>(
    Expression<T> Function($$ChannelsTableAnnotationComposer a) f,
  ) {
    final $$ChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistsTable,
          Playlist,
          $$PlaylistsTableFilterComposer,
          $$PlaylistsTableOrderingComposer,
          $$PlaylistsTableAnnotationComposer,
          $$PlaylistsTableCreateCompanionBuilder,
          $$PlaylistsTableUpdateCompanionBuilder,
          (Playlist, $$PlaylistsTableReferences),
          Playlist,
          PrefetchHooks Function({bool channelsRefs})
        > {
  $$PlaylistsTableTableManager(_$AppDatabase db, $PlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> sourceUrlOrPath = const Value.absent(),
                Value<String?> epgUrl = const Value.absent(),
                Value<int> autoRefreshHours = const Value.absent(),
                Value<DateTime?> lastUpdated = const Value.absent(),
              }) => PlaylistsCompanion(
                id: id,
                name: name,
                sourceUrlOrPath: sourceUrlOrPath,
                epgUrl: epgUrl,
                autoRefreshHours: autoRefreshHours,
                lastUpdated: lastUpdated,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String sourceUrlOrPath,
                Value<String?> epgUrl = const Value.absent(),
                Value<int> autoRefreshHours = const Value.absent(),
                Value<DateTime?> lastUpdated = const Value.absent(),
              }) => PlaylistsCompanion.insert(
                id: id,
                name: name,
                sourceUrlOrPath: sourceUrlOrPath,
                epgUrl: epgUrl,
                autoRefreshHours: autoRefreshHours,
                lastUpdated: lastUpdated,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistsTable, Playlist>(table),
                  $$PlaylistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({channelsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (channelsRefs) db.channels],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (channelsRefs)
                    await $_getPrefetchedDataByColumns<
                      Playlist,
                      $PlaylistsTable,
                      Channel,
                      $ChannelsTable
                    >(
                      currentTable: table,
                      referencedTable: $$PlaylistsTableReferences
                          ._channelsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PlaylistsTableReferences(
                            db,
                            table,
                            p0,
                          ).channelsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'playlist_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistsTable,
      Playlist,
      $$PlaylistsTableFilterComposer,
      $$PlaylistsTableOrderingComposer,
      $$PlaylistsTableAnnotationComposer,
      $$PlaylistsTableCreateCompanionBuilder,
      $$PlaylistsTableUpdateCompanionBuilder,
      (Playlist, $$PlaylistsTableReferences),
      Playlist,
      PrefetchHooks Function({bool channelsRefs})
    >;
typedef $$ChannelsTableCreateCompanionBuilder = ChannelsCompanion Function({
  Value<int> id,
  required int channelNumber,
  required String name,
  required int categoryId,
  Value<int?> playlistId,
  Value<String> logoUrl,
  required String primaryUrl,
  Value<String> backupUrl1,
  Value<String> backupUrl2,
  Value<String> epgChannelId,
  Value<bool> isFavorite,
  Value<bool> isEnabled,
  Value<bool> isLocked,
  Value<int> favoriteOrder,
});
typedef $$ChannelsTableUpdateCompanionBuilder = ChannelsCompanion Function({
  Value<int> id,
  Value<int> channelNumber,
  Value<String> name,
  Value<int> categoryId,
  Value<int?> playlistId,
  Value<String> logoUrl,
  Value<String> primaryUrl,
  Value<String> backupUrl1,
  Value<String> backupUrl2,
  Value<String> epgChannelId,
  Value<bool> isFavorite,
  Value<bool> isEnabled,
  Value<bool> isLocked,
  Value<int> favoriteOrder,
});

final class $$ChannelsTableReferences
    extends BaseReferences<_$AppDatabase, $ChannelsTable, Channel> {
  $$ChannelsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('channels__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias('channels__playlist_id__playlists__id');

  $$PlaylistsTableProcessedTableManager? get playlistId {
    final $_column = $_itemColumn<int>('playlist_id');
    if ($_column == null) return null;
    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChannelsTableFilterComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableFilterComposer({
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

  ColumnFilters<int> get channelNumber => $composableBuilder(
    column: $table.channelNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryUrl => $composableBuilder(
    column: $table.primaryUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backupUrl1 => $composableBuilder(
    column: $table.backupUrl1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backupUrl2 => $composableBuilder(
    column: $table.backupUrl2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get epgChannelId => $composableBuilder(
    column: $table.epgChannelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get favoriteOrder => $composableBuilder(
    column: $table.favoriteOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChannelsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableOrderingComposer({
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

  ColumnOrderings<int> get channelNumber => $composableBuilder(
    column: $table.channelNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryUrl => $composableBuilder(
    column: $table.primaryUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backupUrl1 => $composableBuilder(
    column: $table.backupUrl1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backupUrl2 => $composableBuilder(
    column: $table.backupUrl2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get epgChannelId => $composableBuilder(
    column: $table.epgChannelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get favoriteOrder => $composableBuilder(
    column: $table.favoriteOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChannelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get channelNumber => $composableBuilder(
    column: $table.channelNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => column);

  GeneratedColumn<String> get primaryUrl => $composableBuilder(
    column: $table.primaryUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backupUrl1 => $composableBuilder(
    column: $table.backupUrl1,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backupUrl2 => $composableBuilder(
    column: $table.backupUrl2,
    builder: (column) => column,
  );

  GeneratedColumn<String> get epgChannelId => $composableBuilder(
    column: $table.epgChannelId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<bool> get isLocked =>
      $composableBuilder(column: $table.isLocked, builder: (column) => column);

  GeneratedColumn<int> get favoriteOrder => $composableBuilder(
    column: $table.favoriteOrder,
    builder: (column) => column,
  );

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChannelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChannelsTable,
          Channel,
          $$ChannelsTableFilterComposer,
          $$ChannelsTableOrderingComposer,
          $$ChannelsTableAnnotationComposer,
          $$ChannelsTableCreateCompanionBuilder,
          $$ChannelsTableUpdateCompanionBuilder,
          (Channel, $$ChannelsTableReferences),
          Channel,
          PrefetchHooks Function({bool categoryId, bool playlistId})
        > {
  $$ChannelsTableTableManager(_$AppDatabase db, $ChannelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> channelNumber = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<int?> playlistId = const Value.absent(),
                Value<String> logoUrl = const Value.absent(),
                Value<String> primaryUrl = const Value.absent(),
                Value<String> backupUrl1 = const Value.absent(),
                Value<String> backupUrl2 = const Value.absent(),
                Value<String> epgChannelId = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<bool> isLocked = const Value.absent(),
                Value<int> favoriteOrder = const Value.absent(),
              }) => ChannelsCompanion(
                id: id,
                channelNumber: channelNumber,
                name: name,
                categoryId: categoryId,
                playlistId: playlistId,
                logoUrl: logoUrl,
                primaryUrl: primaryUrl,
                backupUrl1: backupUrl1,
                backupUrl2: backupUrl2,
                epgChannelId: epgChannelId,
                isFavorite: isFavorite,
                isEnabled: isEnabled,
                isLocked: isLocked,
                favoriteOrder: favoriteOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int channelNumber,
                required String name,
                required int categoryId,
                Value<int?> playlistId = const Value.absent(),
                Value<String> logoUrl = const Value.absent(),
                required String primaryUrl,
                Value<String> backupUrl1 = const Value.absent(),
                Value<String> backupUrl2 = const Value.absent(),
                Value<String> epgChannelId = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<bool> isLocked = const Value.absent(),
                Value<int> favoriteOrder = const Value.absent(),
              }) => ChannelsCompanion.insert(
                id: id,
                channelNumber: channelNumber,
                name: name,
                categoryId: categoryId,
                playlistId: playlistId,
                logoUrl: logoUrl,
                primaryUrl: primaryUrl,
                backupUrl1: backupUrl1,
                backupUrl2: backupUrl2,
                epgChannelId: epgChannelId,
                isFavorite: isFavorite,
                isEnabled: isEnabled,
                isLocked: isLocked,
                favoriteOrder: favoriteOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChannelsTable, Channel>(table),
                  $$ChannelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false, playlistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$ChannelsTableReferences
                            ._categoryIdTable(db),
                        referencedColumn: $$ChannelsTableReferences
                            ._categoryIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (playlistId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.playlistId,
                        referencedTable: $$ChannelsTableReferences
                            ._playlistIdTable(db),
                        referencedColumn: $$ChannelsTableReferences
                            ._playlistIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChannelsTable,
      Channel,
      $$ChannelsTableFilterComposer,
      $$ChannelsTableOrderingComposer,
      $$ChannelsTableAnnotationComposer,
      $$ChannelsTableCreateCompanionBuilder,
      $$ChannelsTableUpdateCompanionBuilder,
      (Channel, $$ChannelsTableReferences),
      Channel,
      PrefetchHooks Function({bool categoryId, bool playlistId})
    >;
typedef $$EpgProgramsTableCreateCompanionBuilder =
    EpgProgramsCompanion Function({
      Value<int> id,
      required String epgChannelId,
      required String title,
      Value<String> description,
      required DateTime startTime,
      required DateTime endTime,
      Value<String> category,
    });
typedef $$EpgProgramsTableUpdateCompanionBuilder =
    EpgProgramsCompanion Function({
      Value<int> id,
      Value<String> epgChannelId,
      Value<String> title,
      Value<String> description,
      Value<DateTime> startTime,
      Value<DateTime> endTime,
      Value<String> category,
    });

class $$EpgProgramsTableFilterComposer
    extends Composer<_$AppDatabase, $EpgProgramsTable> {
  $$EpgProgramsTableFilterComposer({
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

  ColumnFilters<String> get epgChannelId => $composableBuilder(
    column: $table.epgChannelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
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

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EpgProgramsTableOrderingComposer
    extends Composer<_$AppDatabase, $EpgProgramsTable> {
  $$EpgProgramsTableOrderingComposer({
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

  ColumnOrderings<String> get epgChannelId => $composableBuilder(
    column: $table.epgChannelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EpgProgramsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpgProgramsTable> {
  $$EpgProgramsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get epgChannelId => $composableBuilder(
    column: $table.epgChannelId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);
}

class $$EpgProgramsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpgProgramsTable,
          EpgProgram,
          $$EpgProgramsTableFilterComposer,
          $$EpgProgramsTableOrderingComposer,
          $$EpgProgramsTableAnnotationComposer,
          $$EpgProgramsTableCreateCompanionBuilder,
          $$EpgProgramsTableUpdateCompanionBuilder,
          (
            EpgProgram,
            BaseReferences<_$AppDatabase, $EpgProgramsTable, EpgProgram>,
          ),
          EpgProgram,
          PrefetchHooks Function()
        > {
  $$EpgProgramsTableTableManager(_$AppDatabase db, $EpgProgramsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpgProgramsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpgProgramsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpgProgramsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> epgChannelId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime> endTime = const Value.absent(),
                Value<String> category = const Value.absent(),
              }) => EpgProgramsCompanion(
                id: id,
                epgChannelId: epgChannelId,
                title: title,
                description: description,
                startTime: startTime,
                endTime: endTime,
                category: category,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String epgChannelId,
                required String title,
                Value<String> description = const Value.absent(),
                required DateTime startTime,
                required DateTime endTime,
                Value<String> category = const Value.absent(),
              }) => EpgProgramsCompanion.insert(
                id: id,
                epgChannelId: epgChannelId,
                title: title,
                description: description,
                startTime: startTime,
                endTime: endTime,
                category: category,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EpgProgramsTable, EpgProgram>(table),
                  BaseReferences<_$AppDatabase, $EpgProgramsTable, EpgProgram>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EpgProgramsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpgProgramsTable,
      EpgProgram,
      $$EpgProgramsTableFilterComposer,
      $$EpgProgramsTableOrderingComposer,
      $$EpgProgramsTableAnnotationComposer,
      $$EpgProgramsTableCreateCompanionBuilder,
      $$EpgProgramsTableUpdateCompanionBuilder,
      (
        EpgProgram,
        BaseReferences<_$AppDatabase, $EpgProgramsTable, EpgProgram>,
      ),
      EpgProgram,
      PrefetchHooks Function()
    >;
typedef $$MediaFilesTableCreateCompanionBuilder = MediaFilesCompanion Function({
  Value<int> id,
  required String filePath,
  required String fileName,
  required String folderName,
  required int sizeBytes,
  Value<int> durationMs,
  Value<int> lastPositionMs,
  Value<bool> isFavorite,
  Value<DateTime?> lastPlayedAt,
  required DateTime dateAdded,
  Value<int?> preferredAudioTrack,
  Value<int?> preferredSubtitleTrack,
});
typedef $$MediaFilesTableUpdateCompanionBuilder = MediaFilesCompanion Function({
  Value<int> id,
  Value<String> filePath,
  Value<String> fileName,
  Value<String> folderName,
  Value<int> sizeBytes,
  Value<int> durationMs,
  Value<int> lastPositionMs,
  Value<bool> isFavorite,
  Value<DateTime?> lastPlayedAt,
  Value<DateTime> dateAdded,
  Value<int?> preferredAudioTrack,
  Value<int?> preferredSubtitleTrack,
});

class $$MediaFilesTableFilterComposer
    extends Composer<_$AppDatabase, $MediaFilesTable> {
  $$MediaFilesTableFilterComposer({
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

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderName => $composableBuilder(
    column: $table.folderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPositionMs => $composableBuilder(
    column: $table.lastPositionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get preferredAudioTrack => $composableBuilder(
    column: $table.preferredAudioTrack,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get preferredSubtitleTrack => $composableBuilder(
    column: $table.preferredSubtitleTrack,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MediaFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaFilesTable> {
  $$MediaFilesTableOrderingComposer({
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

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderName => $composableBuilder(
    column: $table.folderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPositionMs => $composableBuilder(
    column: $table.lastPositionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get preferredAudioTrack => $composableBuilder(
    column: $table.preferredAudioTrack,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get preferredSubtitleTrack => $composableBuilder(
    column: $table.preferredSubtitleTrack,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaFilesTable> {
  $$MediaFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get folderName => $composableBuilder(
    column: $table.folderName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastPositionMs => $composableBuilder(
    column: $table.lastPositionMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dateAdded =>
      $composableBuilder(column: $table.dateAdded, builder: (column) => column);

  GeneratedColumn<int> get preferredAudioTrack => $composableBuilder(
    column: $table.preferredAudioTrack,
    builder: (column) => column,
  );

  GeneratedColumn<int> get preferredSubtitleTrack => $composableBuilder(
    column: $table.preferredSubtitleTrack,
    builder: (column) => column,
  );
}

class $$MediaFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaFilesTable,
          MediaFile,
          $$MediaFilesTableFilterComposer,
          $$MediaFilesTableOrderingComposer,
          $$MediaFilesTableAnnotationComposer,
          $$MediaFilesTableCreateCompanionBuilder,
          $$MediaFilesTableUpdateCompanionBuilder,
          (
            MediaFile,
            BaseReferences<_$AppDatabase, $MediaFilesTable, MediaFile>,
          ),
          MediaFile,
          PrefetchHooks Function()
        > {
  $$MediaFilesTableTableManager(_$AppDatabase db, $MediaFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> folderName = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int> lastPositionMs = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<DateTime> dateAdded = const Value.absent(),
                Value<int?> preferredAudioTrack = const Value.absent(),
                Value<int?> preferredSubtitleTrack = const Value.absent(),
              }) => MediaFilesCompanion(
                id: id,
                filePath: filePath,
                fileName: fileName,
                folderName: folderName,
                sizeBytes: sizeBytes,
                durationMs: durationMs,
                lastPositionMs: lastPositionMs,
                isFavorite: isFavorite,
                lastPlayedAt: lastPlayedAt,
                dateAdded: dateAdded,
                preferredAudioTrack: preferredAudioTrack,
                preferredSubtitleTrack: preferredSubtitleTrack,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String filePath,
                required String fileName,
                required String folderName,
                required int sizeBytes,
                Value<int> durationMs = const Value.absent(),
                Value<int> lastPositionMs = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                required DateTime dateAdded,
                Value<int?> preferredAudioTrack = const Value.absent(),
                Value<int?> preferredSubtitleTrack = const Value.absent(),
              }) => MediaFilesCompanion.insert(
                id: id,
                filePath: filePath,
                fileName: fileName,
                folderName: folderName,
                sizeBytes: sizeBytes,
                durationMs: durationMs,
                lastPositionMs: lastPositionMs,
                isFavorite: isFavorite,
                lastPlayedAt: lastPlayedAt,
                dateAdded: dateAdded,
                preferredAudioTrack: preferredAudioTrack,
                preferredSubtitleTrack: preferredSubtitleTrack,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MediaFilesTable, MediaFile>(table),
                  BaseReferences<_$AppDatabase, $MediaFilesTable, MediaFile>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MediaFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaFilesTable,
      MediaFile,
      $$MediaFilesTableFilterComposer,
      $$MediaFilesTableOrderingComposer,
      $$MediaFilesTableAnnotationComposer,
      $$MediaFilesTableCreateCompanionBuilder,
      $$MediaFilesTableUpdateCompanionBuilder,
      (MediaFile, BaseReferences<_$AppDatabase, $MediaFilesTable, MediaFile>),
      MediaFile,
      PrefetchHooks Function()
    >;
typedef $$PlaybackHistoryTableCreateCompanionBuilder =
    PlaybackHistoryCompanion Function({
      Value<int> id,
      required String itemType,
      required String referenceId,
      required String title,
      Value<String> thumbnail,
      Value<int> positionMs,
      required DateTime watchedAt,
    });
typedef $$PlaybackHistoryTableUpdateCompanionBuilder =
    PlaybackHistoryCompanion Function({
      Value<int> id,
      Value<String> itemType,
      Value<String> referenceId,
      Value<String> title,
      Value<String> thumbnail,
      Value<int> positionMs,
      Value<DateTime> watchedAt,
    });

class $$PlaybackHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $PlaybackHistoryTable> {
  $$PlaybackHistoryTableFilterComposer({
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

  ColumnFilters<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnail => $composableBuilder(
    column: $table.thumbnail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaybackHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaybackHistoryTable> {
  $$PlaybackHistoryTableOrderingComposer({
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

  ColumnOrderings<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnail => $composableBuilder(
    column: $table.thumbnail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaybackHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaybackHistoryTable> {
  $$PlaybackHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get thumbnail =>
      $composableBuilder(column: $table.thumbnail, builder: (column) => column);

  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get watchedAt =>
      $composableBuilder(column: $table.watchedAt, builder: (column) => column);
}

class $$PlaybackHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaybackHistoryTable,
          PlaybackHistoryData,
          $$PlaybackHistoryTableFilterComposer,
          $$PlaybackHistoryTableOrderingComposer,
          $$PlaybackHistoryTableAnnotationComposer,
          $$PlaybackHistoryTableCreateCompanionBuilder,
          $$PlaybackHistoryTableUpdateCompanionBuilder,
          (
            PlaybackHistoryData,
            BaseReferences<
              _$AppDatabase,
              $PlaybackHistoryTable,
              PlaybackHistoryData
            >,
          ),
          PlaybackHistoryData,
          PrefetchHooks Function()
        > {
  $$PlaybackHistoryTableTableManager(
    _$AppDatabase db,
    $PlaybackHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaybackHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaybackHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaybackHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> itemType = const Value.absent(),
                Value<String> referenceId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> thumbnail = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<DateTime> watchedAt = const Value.absent(),
              }) => PlaybackHistoryCompanion(
                id: id,
                itemType: itemType,
                referenceId: referenceId,
                title: title,
                thumbnail: thumbnail,
                positionMs: positionMs,
                watchedAt: watchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String itemType,
                required String referenceId,
                required String title,
                Value<String> thumbnail = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                required DateTime watchedAt,
              }) => PlaybackHistoryCompanion.insert(
                id: id,
                itemType: itemType,
                referenceId: referenceId,
                title: title,
                thumbnail: thumbnail,
                positionMs: positionMs,
                watchedAt: watchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaybackHistoryTable, PlaybackHistoryData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $PlaybackHistoryTable,
                    PlaybackHistoryData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaybackHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaybackHistoryTable,
      PlaybackHistoryData,
      $$PlaybackHistoryTableFilterComposer,
      $$PlaybackHistoryTableOrderingComposer,
      $$PlaybackHistoryTableAnnotationComposer,
      $$PlaybackHistoryTableCreateCompanionBuilder,
      $$PlaybackHistoryTableUpdateCompanionBuilder,
      (
        PlaybackHistoryData,
        BaseReferences<
          _$AppDatabase,
          $PlaybackHistoryTable,
          PlaybackHistoryData
        >,
      ),
      PlaybackHistoryData,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      required String category,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<String> category,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                value: value,
                category: category,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required String category,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                category: category,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$RemoteMappingsTableCreateCompanionBuilder =
    RemoteMappingsCompanion Function({
      required String actionKey,
      required String assignedCommand,
      Value<String> customParam,
      Value<int> rowid,
    });
typedef $$RemoteMappingsTableUpdateCompanionBuilder =
    RemoteMappingsCompanion Function({
      Value<String> actionKey,
      Value<String> assignedCommand,
      Value<String> customParam,
      Value<int> rowid,
    });

class $$RemoteMappingsTableFilterComposer
    extends Composer<_$AppDatabase, $RemoteMappingsTable> {
  $$RemoteMappingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get actionKey => $composableBuilder(
    column: $table.actionKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assignedCommand => $composableBuilder(
    column: $table.assignedCommand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customParam => $composableBuilder(
    column: $table.customParam,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemoteMappingsTableOrderingComposer
    extends Composer<_$AppDatabase, $RemoteMappingsTable> {
  $$RemoteMappingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get actionKey => $composableBuilder(
    column: $table.actionKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assignedCommand => $composableBuilder(
    column: $table.assignedCommand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customParam => $composableBuilder(
    column: $table.customParam,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemoteMappingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemoteMappingsTable> {
  $$RemoteMappingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get actionKey =>
      $composableBuilder(column: $table.actionKey, builder: (column) => column);

  GeneratedColumn<String> get assignedCommand => $composableBuilder(
    column: $table.assignedCommand,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customParam => $composableBuilder(
    column: $table.customParam,
    builder: (column) => column,
  );
}

class $$RemoteMappingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemoteMappingsTable,
          RemoteMapping,
          $$RemoteMappingsTableFilterComposer,
          $$RemoteMappingsTableOrderingComposer,
          $$RemoteMappingsTableAnnotationComposer,
          $$RemoteMappingsTableCreateCompanionBuilder,
          $$RemoteMappingsTableUpdateCompanionBuilder,
          (
            RemoteMapping,
            BaseReferences<_$AppDatabase, $RemoteMappingsTable, RemoteMapping>,
          ),
          RemoteMapping,
          PrefetchHooks Function()
        > {
  $$RemoteMappingsTableTableManager(
    _$AppDatabase db,
    $RemoteMappingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemoteMappingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemoteMappingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemoteMappingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> actionKey = const Value.absent(),
                Value<String> assignedCommand = const Value.absent(),
                Value<String> customParam = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemoteMappingsCompanion(
                actionKey: actionKey,
                assignedCommand: assignedCommand,
                customParam: customParam,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String actionKey,
                required String assignedCommand,
                Value<String> customParam = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemoteMappingsCompanion.insert(
                actionKey: actionKey,
                assignedCommand: assignedCommand,
                customParam: customParam,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RemoteMappingsTable, RemoteMapping>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RemoteMappingsTable,
                    RemoteMapping
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemoteMappingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemoteMappingsTable,
      RemoteMapping,
      $$RemoteMappingsTableFilterComposer,
      $$RemoteMappingsTableOrderingComposer,
      $$RemoteMappingsTableAnnotationComposer,
      $$RemoteMappingsTableCreateCompanionBuilder,
      $$RemoteMappingsTableUpdateCompanionBuilder,
      (
        RemoteMapping,
        BaseReferences<_$AppDatabase, $RemoteMappingsTable, RemoteMapping>,
      ),
      RemoteMapping,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db, _db.playlists);
  $$ChannelsTableTableManager get channels =>
      $$ChannelsTableTableManager(_db, _db.channels);
  $$EpgProgramsTableTableManager get epgPrograms =>
      $$EpgProgramsTableTableManager(_db, _db.epgPrograms);
  $$MediaFilesTableTableManager get mediaFiles =>
      $$MediaFilesTableTableManager(_db, _db.mediaFiles);
  $$PlaybackHistoryTableTableManager get playbackHistory =>
      $$PlaybackHistoryTableTableManager(_db, _db.playbackHistory);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$RemoteMappingsTableTableManager get remoteMappings =>
      $$RemoteMappingsTableTableManager(_db, _db.remoteMappings);
}
