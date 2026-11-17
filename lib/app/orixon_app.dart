import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/providers/app_providers.dart';
import '../core/theme/app_theme.dart';
import '../features/os_shell/presentation/orixon_os_launcher.dart';

class OrixonApp extends StatefulWidget {
  const OrixonApp({super.key, this.enablePlayback = true}) : database = null;

  const OrixonApp.withDatabase({
    super.key,
    required this.database,
    this.enablePlayback = true,
  });

  final AppDatabase? database;
  final bool enablePlayback;

  @override
  State<OrixonApp> createState() => _OrixonAppState();
}

class _OrixonAppState extends State<OrixonApp> {
  late final AppDatabase _database;
  late final bool _ownsDatabase;

  @override
  void initState() {
    super.initState();

    _ownsDatabase = widget.database == null;
    _database = widget.database ?? AppDatabase();
  }

  @override
  void dispose() {
    if (_ownsDatabase) {
      unawaited(_database.close());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(_database)],
      child: MaterialApp(
        title: 'ORIXON',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: OrixonOsLauncher(
          database: _database,
          enablePlayback: widget.enablePlayback,
        ),
      ),
    );
  }
}
