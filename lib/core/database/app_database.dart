import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'dart:io';

part 'app_database.g.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  IntColumn get rangeStart => integer()();
  IntColumn get rangeEnd => integer()();
  IntColumn get sortOrder => integer()();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  BoolColumn get isKidsApproved =>
      boolean().withDefault(const Constant(false))();
}

class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get sourceUrlOrPath => text()();
  TextColumn get epgUrl => text().nullable()();
  IntColumn get autoRefreshHours => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUpdated => dateTime().nullable()();
}

class Channels extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get channelNumber => integer().unique()();
  TextColumn get name => text()();

  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.restrict)();

  IntColumn get playlistId => integer().nullable().references(
    Playlists,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get logoUrl => text().withDefault(const Constant(''))();
  TextColumn get primaryUrl => text()();
  TextColumn get backupUrl1 => text().withDefault(const Constant(''))();
  TextColumn get backupUrl2 => text().withDefault(const Constant(''))();
  TextColumn get epgChannelId => text().withDefault(const Constant(''))();

  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();

  IntColumn get favoriteOrder => integer().withDefault(const Constant(0))();
}

class EpgPrograms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get epgChannelId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  TextColumn get category => text().withDefault(const Constant(''))();

  List<Index> get customIndexes => [
    Index(
      'epg_channel_time_idx',
      'CREATE INDEX epg_channel_time_idx '
          'ON epg_programs (epg_channel_id, start_time, end_time)',
    ),
  ];
}

class MediaFiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filePath => text().unique()();
  TextColumn get fileName => text()();
  TextColumn get folderName => text()();
  IntColumn get sizeBytes => integer()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  IntColumn get lastPositionMs => integer().withDefault(const Constant(0))();

  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  DateTimeColumn get dateAdded => dateTime()();

  IntColumn get preferredAudioTrack => integer().nullable()();

  IntColumn get preferredSubtitleTrack => integer().nullable()();
}

class PlaybackHistory extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get itemType => text()();

  TextColumn get referenceId => text()();

  TextColumn get title => text()();

  TextColumn get thumbnail => text().withDefault(const Constant(''))();

  IntColumn get positionMs => integer().withDefault(const Constant(0))();

  DateTimeColumn get watchedAt => dateTime()();
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  TextColumn get category => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class RemoteMappings extends Table {
  TextColumn get actionKey => text()();
  TextColumn get assignedCommand => text()();
  TextColumn get customParam => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {actionKey};
}

@DriftDatabase(
  tables: [
    Categories,
    Playlists,
    Channels,
    EpgPrograms,
    MediaFiles,
    PlaybackHistory,
    AppSettings,
    RemoteMappings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'orixon.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
