import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/live_tv/data/parsers/m3u_parser.dart';
import '../../../../features/live_tv/data/repositories/playlist_repository.dart';
import '../../../../features/live_tv/data/services/m3u_source_service.dart';

class PlaylistManagementPanel extends ConsumerStatefulWidget {
  const PlaylistManagementPanel({super.key});

  @override
  ConsumerState<PlaylistManagementPanel> createState() =>
      _PlaylistManagementPanelState();
}

class _PlaylistManagementPanelState
    extends ConsumerState<PlaylistManagementPanel> {
  bool _isImportingPlaylist = false;
  int _activeTab = 0; // 0 = Playlists, 1 = Channels (Search, Filter & Custom Builder)
  String _channelSearchQuery = '';
  int? _selectedCategoryFilter;
  int? _selectedPlaylistFilter;
  final Set<int> _selectedCustomChannelIds = <int>{};

  static const _accent = Color(0xFF26E7FF);
  static const _surface = Color(0xFF0D1628);

  Future<Directory> _resolveOrixonM3uDir() async {
    if (Platform.isAndroid) {
      final dl = Directory('/storage/emulated/0/Download/Orixon');
      try {
        if (!dl.existsSync()) await dl.create(recursive: true);
        return dl;
      } catch (_) {}
      final ext = Directory('/storage/emulated/0/Orixon');
      try {
        if (!ext.existsSync()) await ext.create(recursive: true);
        return ext;
      } catch (_) {}
    }
    final local = Directory('${Directory.current.path}/Orixon');
    if (!local.existsSync()) await local.create(recursive: true);
    return local;
  }

  Future<String> _exportChannelsToM3uFile({
    required String playlistName,
    required List<Channel> channels,
    required Map<int, String> categoryNames,
  }) async {
    final dir = await _resolveOrixonM3uDir();
    final safeName = playlistName
        .replaceAll(RegExp(r'[\/:*?"<>|]'), '_')
        .trim();
    final fileName = safeName.isEmpty ? 'orixon_playlist.m3u' : '$safeName.m3u';
    final file = File('${dir.path}/$fileName');
    final buf = StringBuffer()..writeln('#EXTM3U');
    for (final ch in channels) {
      final group = categoryNames[ch.categoryId] ?? 'General';
      final logoAttr = ch.logoUrl.trim().isNotEmpty ? ' tvg-logo="${ch.logoUrl.trim()}"' : '';
      buf.writeln('#EXTINF:-1 tvg-chno="${ch.channelNumber}"$logoAttr group-title="$group",${ch.name}');
      buf.writeln(ch.primaryUrl);
    }
    await file.writeAsString(buf.toString(), flush: true);
    return file.path;
  }

  Future<void> _promptCreateCustomPlaylist(
    AppDatabase database,
    List<Channel> allChannels,
    Map<int, String> categoryNames,
  ) async {
    final chosen = allChannels
        .where((c) => _selectedCustomChannelIds.contains(c.id))
        .toList();
    if (chosen.isEmpty) return;

    final nameCtrl = TextEditingController(text: 'My Custom Playlist');
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A1324),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: _accent.withValues(alpha: 0.45)),
        ),
        title: const Text(
          'Create Custom Playlist',
          style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected ${chosen.length} channel(s). This will create a new playlist in Orixon and save the .m3u file in your Orixon storage folder.',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'New Playlist Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
            label: const Text('CREATE & SAVE .M3U'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty) return;
    try {
      final savedPath = await _exportChannelsToM3uFile(
        playlistName: newName,
        channels: chosen,
        categoryNames: categoryNames,
      );
      await _importPlaylist(name: newName, sourceUrl: savedPath);
      setState(() {
        _selectedCustomChannelIds.clear();
        _activeTab = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created "$newName" & saved to $savedPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create playlist: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(playlistRepositoryProvider);
    final database = ref.watch(appDatabaseProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      children: [
        // Action Header Bar: Add & Import
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F2648), Color(0xFF091426)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.playlist_add_rounded,
                  color: _accent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IPTV PLAYLIST & CHANNEL STUDIO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    
                  ],
                ),
              ),
              _isImportingPlaylist
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: _accent,
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: _showAddPlaylistDialog,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'ADD PLAYLIST',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2-Tab Switcher: PLAYLISTS vs CHANNELS (Custom Playlist Builder)
        Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _activeTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: _activeTab == 0
                        ? _accent.withValues(alpha: 0.18)
                        : _surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _activeTab == 0 ? _accent : Colors.white12,
                      width: _activeTab == 0 ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.queue_music_rounded,
                        size: 18,
                        color: _activeTab == 0 ? _accent : Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PLAYLISTS',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: _activeTab == 0 ? _accent : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _activeTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: _activeTab == 1
                        ? _accent.withValues(alpha: 0.18)
                        : _surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _activeTab == 1 ? _accent : Colors.white12,
                      width: _activeTab == 1 ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.live_tv_rounded,
                        size: 18,
                        color: _activeTab == 1 ? _accent : Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CHANNELS (${_selectedCustomChannelIds.isEmpty ? "ALL" : "${_selectedCustomChannelIds.length} SELECTED"})',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: _activeTab == 1 ? _accent : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_activeTab == 0)
          _buildPlaylistsTab(repository, database)
        else
          _buildAllChannelsBuilderTab(repository, database),
      ],
    );
  }

  Widget _buildPlaylistsTab(
    PlaylistRepository repository,
    AppDatabase database,
  ) {
    return FutureBuilder<List<Playlist>>(
      future: repository.getAllPlaylists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: _accent),
            ),
          );
        }

        final playlists = snapshot.data ?? [];
        if (playlists.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: const Center(
              child: Text(
                'No IPTV Playlists Configured. Tap "+ ADD PLAYLIST" above.',
                style: TextStyle(color: AppTheme.muted, fontSize: 12.5),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: playlists.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            final isRemote = playlist.sourceUrlOrPath.startsWith('http://') ||
                playlist.sourceUrlOrPath.startsWith('https://');
            final channelCountFuture = (database.select(database.channels)
                  ..where((t) => t.playlistId.equals(playlist.id)))
                .get()
                .then((ch) => ch.length);

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openPlaylistChannelsModal(database, playlist),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isRemote ? _accent : const Color(0xFFD552FF))
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isRemote ? Icons.cloud_download_rounded : Icons.folder_rounded,
                        color: isRemote ? _accent : const Color(0xFFD552FF),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist.name,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            playlist.sourceUrlOrPath,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: AppTheme.muted),
                          ),
                          const SizedBox(height: 4),
                          FutureBuilder<int>(
                            future: channelCountFuture,
                            builder: (context, countSnap) {
                              final count = countSnap.data ?? 0;
                              return Text(
                                countSnap.hasData ? '$count CHANNELS' : 'COUNTING...',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _accent,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Save Playlist (.m3u) to Storage',
                      onPressed: () async {
                        final chs = await (database.select(database.channels)
                              ..where((t) => t.playlistId.equals(playlist.id)))
                            .get();
                        final cats = await database.select(database.categories).get();
                        final catMap = {for (final c in cats) c.id: c.name};
                        final path = await _exportChannelsToM3uFile(
                          playlistName: playlist.name,
                          channels: chs,
                          categoryNames: catMap,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Saved to $path')),
                          );
                        }
                      },
                      icon: const Icon(Icons.save_alt_rounded, color: Color(0xFF38BDF8), size: 21),
                    ),
                    IconButton(
                      tooltip: 'View & Delete Channels',
                      onPressed: () => _openPlaylistChannelsModal(database, playlist),
                      icon: const Icon(Icons.list_alt_rounded, color: Color(0xFF34D399), size: 22),
                    ),
                    IconButton(
                      tooltip: 'Sync / Reload Playlist',
                      onPressed: _isImportingPlaylist
                          ? null
                          : () => _importPlaylist(
                                name: playlist.name,
                                sourceUrl: playlist.sourceUrlOrPath,
                              ),
                      icon: const Icon(Icons.sync_rounded, color: _accent, size: 22),
                    ),
                    IconButton(
                      tooltip: 'Delete Playlist',
                      onPressed: _isImportingPlaylist
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Playlist?'),
                                  content: Text('Remove "${playlist.name}" and its channels?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('CANCEL'),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('DELETE'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await repository.deletePlaylist(playlist.id);
                                setState(() {});
                              }
                            },
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAllChannelsBuilderTab(
    PlaylistRepository repository,
    AppDatabase database,
  ) {
    return FutureBuilder(
      future: Future.wait([
        database.select(database.channels).get(),
        database.select(database.categories).get(),
        repository.getAllPlaylists(),
      ]),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: _accent),
            ),
          );
        }
        final allChannels = (snap.data![0] as List<Channel>)
          ..sort((a, b) => a.channelNumber.compareTo(b.channelNumber));
        final categories = snap.data![1] as List<Category>;
        final playlists = snap.data![2] as List<Playlist>;
        final catMap = {for (final c in categories) c.id: c.name};
        final plMap = {for (final p in playlists) p.id: p.name};

        final filtered = allChannels.where((ch) {
          if (_selectedCategoryFilter != null &&
              ch.categoryId != _selectedCategoryFilter) {
            return false;
          }
          if (_selectedPlaylistFilter != null &&
              ch.playlistId != _selectedPlaylistFilter) {
            return false;
          }
          if (_channelSearchQuery.isNotEmpty) {
            final q = _channelSearchQuery.toLowerCase();
            final catName = (catMap[ch.categoryId] ?? '').toLowerCase();
            return ch.name.toLowerCase().contains(q) ||
                ch.channelNumber.toString().contains(q) ||
                catName.contains(q);
          }
          return true;
        }).toList();

        final allFilteredSelected = filtered.isNotEmpty &&
            filtered.every((c) => _selectedCustomChannelIds.contains(c.id));

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar & Select All Filtered Button
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        onChanged: (v) =>
                            setState(() => _channelSearchQuery = v.trim()),
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText:
                              'Search channels by name, number or category...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: _accent,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          filled: true,
                          fillColor: const Color(0xFF132038),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      setState(() {
                        if (allFilteredSelected) {
                          for (final c in filtered) {
                            _selectedCustomChannelIds.remove(c.id);
                          }
                        } else {
                          for (final c in filtered) {
                            _selectedCustomChannelIds.add(c.id);
                          }
                        }
                      });
                    },
                    icon: Icon(
                      allFilteredSelected
                          ? Icons.deselect_rounded
                          : Icons.select_all_rounded,
                      size: 16,
                    ),
                    label: Text(
                      allFilteredSelected ? 'UNSELECT' : 'SELECT ALL',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Category Filter Chips with 1-Tap Category Select-All Icon
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          'All (${allChannels.length})',
                          style: const TextStyle(fontSize: 11),
                        ),
                        selected: _selectedCategoryFilter == null,
                        onSelected: (_) =>
                            setState(() => _selectedCategoryFilter = null),
                      ),
                    ),
                    ...categories.map((cat) {
                      final catChannels = allChannels
                          .where((c) => c.categoryId == cat.id)
                          .toList();
                      if (catChannels.isEmpty) return const SizedBox.shrink();
                      final allCatSelected = catChannels.every(
                        (c) => _selectedCustomChannelIds.contains(c.id),
                      );
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InputChip(
                          label: Text(
                            '${cat.name} (${catChannels.length})',
                            style: const TextStyle(fontSize: 11),
                          ),
                          selected: _selectedCategoryFilter == cat.id,
                          onSelected: (_) => setState(() {
                            _selectedCategoryFilter =
                                _selectedCategoryFilter == cat.id
                                    ? null
                                    : cat.id;
                          }),
                          avatar: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (allCatSelected) {
                                  for (final c in catChannels) {
                                    _selectedCustomChannelIds.remove(c.id);
                                  }
                                } else {
                                  for (final c in catChannels) {
                                    _selectedCustomChannelIds.add(c.id);
                                  }
                                }
                              });
                            },
                            child: Icon(
                              allCatSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.add_circle_outline_rounded,
                              size: 16,
                              color: allCatSelected ? _accent : Colors.white70,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              if (playlists.length > 1) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: const Text(
                            'All Playlists',
                            style: TextStyle(fontSize: 11),
                          ),
                          selected: _selectedPlaylistFilter == null,
                          onSelected: (_) =>
                              setState(() => _selectedPlaylistFilter = null),
                        ),
                      ),
                      ...playlists.map(
                        (pl) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              pl.name,
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: _selectedPlaylistFilter == pl.id,
                            onSelected: (_) => setState(() {
                              _selectedPlaylistFilter =
                                  _selectedPlaylistFilter == pl.id
                                      ? null
                                      : pl.id;
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_selectedCustomChannelIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF122845),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accent.withValues(alpha: 0.6)),
                  ),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${_selectedCustomChannelIds.length} Channel(s) Selected',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _accent,
                          fontSize: 13,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton.icon(
                            onPressed: () => _promptCreateCustomPlaylist(
                              database,
                              allChannels,
                              catMap,
                            ),
                            icon: const Icon(
                              Icons.playlist_add_check_rounded,
                              size: 17,
                            ),
                            label: const Text(
                              'CREATE NEW PLAYLIST & SAVE .M3U',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Delete Selected Channels',
                            onPressed: () async {
                              await (database.delete(database.channels)
                                    ..where(
                                      (t) => t.id.isIn(
                                        _selectedCustomChannelIds.toList(),
                                      ),
                                    ))
                                  .go();
                              setState(() => _selectedCustomChannelIds.clear());
                            },
                            icon: const Icon(
                              Icons.delete_sweep_rounded,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 10),
              Text(
                'Showing ${filtered.length} of ${allChannels.length} channels',
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 390,
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No channels match your filter.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (_, idx) {
                          final ch = filtered[idx];
                          final checked =
                              _selectedCustomChannelIds.contains(ch.id);
                          final catLabel = catMap[ch.categoryId] ?? 'General';
                          final plLabel = plMap[ch.playlistId] ?? 'Playlist';
                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onLongPress: () => setState(() {
                              if (checked) {
                                _selectedCustomChannelIds.remove(ch.id);
                              } else {
                                _selectedCustomChannelIds.add(ch.id);
                              }
                            }),
                            onTap: () {
                              if (_selectedCustomChannelIds.isNotEmpty) {
                                setState(() {
                                  if (checked) {
                                    _selectedCustomChannelIds.remove(ch.id);
                                  } else {
                                    _selectedCustomChannelIds.add(ch.id);
                                  }
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: checked
                                    ? const Color(0xFF17314F)
                                    : const Color(0xFF101C30),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: checked ? _accent : Colors.white10,
                                  width: checked ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0A1426),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: ch.logoUrl.trim().isNotEmpty
                                        ? Image.network(
                                            ch.logoUrl.trim(),
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                                  Icons.live_tv_rounded,
                                                  size: 18,
                                                  color: _accent,
                                                ),
                                          )
                                        : const Icon(
                                            Icons.live_tv_rounded,
                                            size: 18,
                                            color: _accent,
                                          ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _accent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'CH ${ch.channelNumber}',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                        color: _accent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ch.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          '$catLabel  •  $plLabel',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPlaylistChannelsModal(
    AppDatabase database,
    Playlist playlist,
  ) async {
    String filterQuery = '';
    final selectedChannelIds = <int>{};

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final channelsFuture = (database.select(database.channels)
                ..where((t) => t.playlistId.equals(playlist.id)))
              .get();

          return AlertDialog(
            backgroundColor: const Color(0xFF0A1324),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: _accent.withValues(alpha: 0.45)),
            ),
            title: Row(
              children: [
                const Icon(Icons.live_tv_rounded, color: _accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${playlist.name} • Channels',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (selectedChannelIds.isNotEmpty)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () async {
                      await (database.delete(database.channels)
                            ..where(
                              (t) => t.id.isIn(selectedChannelIds.toList()),
                            ))
                          .go();
                      selectedChannelIds.clear();
                      setModal(() {});
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                    label: Text('Delete (${selectedChannelIds.length})'),
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            content: SizedBox(
              width: 560,
              height: 340,
              child: Column(
                children: [
                  SizedBox(
                    height: 38,
                    child: TextField(
                      onChanged: (v) =>
                          setModal(() => filterQuery = v.trim().toLowerCase()),
                      style: const TextStyle(fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText:
                            'Search channel name or number (Tap & Hold to select)...',
                        prefixIcon: const Icon(Icons.search, size: 17),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        filled: true,
                        fillColor: const Color(0xFF121F36),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: FutureBuilder<List<Channel>>(
                      future: channelsFuture,
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final all = snap.data!
                          ..sort(
                            (a, b) =>
                                a.channelNumber.compareTo(b.channelNumber),
                          );
                        final list = all.where((c) {
                          if (filterQuery.isEmpty) return true;
                          return c.name.toLowerCase().contains(filterQuery) ||
                              c.channelNumber.toString().contains(filterQuery);
                        }).toList();

                        if (list.isEmpty) {
                          return const Center(
                            child: Text(
                              'No channels match your filter.',
                              style: TextStyle(color: Colors.white54),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (_, i) {
                            final ch = list[i];
                            final checked = selectedChannelIds.contains(ch.id);
                            return InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onLongPress: () => setModal(() {
                                if (checked) {
                                  selectedChannelIds.remove(ch.id);
                                } else {
                                  selectedChannelIds.add(ch.id);
                                }
                              }),
                              onTap: () {
                                if (selectedChannelIds.isNotEmpty) {
                                  setModal(() {
                                    if (checked) {
                                      selectedChannelIds.remove(ch.id);
                                    } else {
                                      selectedChannelIds.add(ch.id);
                                    }
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: checked
                                      ? const Color(0xFF17314F)
                                      : const Color(0xFF101C30),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: checked ? _accent : Colors.white10,
                                    width: checked ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0A1426),
                                        borderRadius: BorderRadius.circular(8),
                                        border:
                                            Border.all(color: Colors.white12),
                                      ),
                                      child: ch.logoUrl.trim().isNotEmpty
                                          ? Image.network(
                                              ch.logoUrl.trim(),
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                    Icons.live_tv_rounded,
                                                    size: 18,
                                                    color: _accent,
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.live_tv_rounded,
                                              size: 18,
                                              color: _accent,
                                            ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'CH ${ch.channelNumber}',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900,
                                          color: _accent,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ch.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            ch.primaryUrl,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete Channel',
                                      onPressed: () async {
                                        await (database.delete(database.channels)
                                              ..where(
                                                (t) => t.id.equals(ch.id),
                                              ))
                                            .go();
                                        selectedChannelIds.remove(ch.id);
                                        setModal(() {});
                                        if (mounted) setState(() {});
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                        size: 19,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddPlaylistDialog() async {
    final request = await showDialog<_PlaylistImportRequest>(
      context: context,
      builder: (_) => const _AddPlaylistDialog(),
    );

    if (request == null || !mounted) return;

    await _importPlaylist(
      name: request.name,
      sourceUrl: request.sourceUrlOrPath,
      loadContent: (service) {
        if (request.pickedFile != null) {
          return service.loadFromPickedFile(request.pickedFile!);
        }
        if (request.isLocalPath) {
          return service.loadFromPath(request.sourceUrlOrPath);
        }
        return service.loadFromUrl(request.sourceUrlOrPath);
      },
    );
  }

  Future<void> _importPlaylist({
    required String name,
    required String sourceUrl,
    Future<String> Function(M3uSourceService service)? loadContent,
  }) async {
    setState(() => _isImportingPlaylist = true);

    final repository = ref.read(playlistRepositoryProvider);
    final sourceService = ref.read(m3uSourceServiceProvider);

    try {
      var content =
          await (loadContent?.call(sourceService) ??
              (sourceUrl.startsWith('/')
                  ? sourceService.loadFromPath(sourceUrl)
                  : sourceUrl.startsWith('http://') ||
                        sourceUrl.startsWith('https://')
                  ? sourceService.loadFromUrl(sourceUrl)
                  : throw const M3uSourceException(
                      'Please select this local playlist again using Browse Storage.',
                    )));

      if (M3uParser.parse(content).isEmpty &&
          (content.contains('#EXTM3U') ||
           content.contains('#EXT-X-') ||
           sourceUrl.toLowerCase().contains('.m3u8'))) {
        content = '#EXTM3U\n#EXTINF:-1 group-title="Live TV",$name\n$sourceUrl\n';
      }
      if (M3uParser.parse(content).isEmpty) {
        throw const PlaylistImportException(
          'The selected source contains no valid M3U channels.',
        );
      }

      Playlist? existingPlaylist;
      final playlists = await repository.getAllPlaylists();
      for (final playlist in playlists) {
        if (playlist.sourceUrlOrPath == sourceUrl) {
          existingPlaylist = playlist;
          break;
        }
      }

      if (existingPlaylist != null) {
        if (!mounted) return;

        final shouldUpdate = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            scrollable: true,
            title: const Text('Playlist already exists'),
            content: Text(
              '"${existingPlaylist!.name}" already uses this source. '
              'Do you want to update its channels?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Update'),
              ),
            ],
          ),
        );

        if (!mounted || shouldUpdate != true) return;

        final result = await repository.importM3u(
          playlistId: existingPlaylist.id,
          content: content,
        );

        if (mounted) {
          _showPlaylistImportResult(result, updated: true);
          setState(() {});
        }
        return;
      }

      final createdPlaylist = await repository.createPlaylist(
        name: name,
        sourceUrlOrPath: sourceUrl,
      );

      late final PlaylistImportResult result;
      try {
        result = await repository.importM3u(
          playlistId: createdPlaylist.id,
          content: content,
        );
      } catch (_) {
        await repository.deletePlaylist(createdPlaylist.id);
        rethrow;
      }

      if (mounted) {
        _showPlaylistImportResult(result, updated: false);
        setState(() {});
      }
    } catch (error) {
      if (mounted) {
        final message = switch (error) {
          M3uSourceException() => error.message,
          PlaylistManagementException() => error.message,
          PlaylistImportException() => error.message,
          _ => 'Playlist import failed: $error',
        };

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() => _isImportingPlaylist = false);
      }
    }
  }

  void _showPlaylistImportResult(
    PlaylistImportResult result, {
    required bool updated,
  }) {
    final action = updated ? 'updated' : 'imported';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F2648),
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Playlist $action: ${result.inserted} added, ${result.updated} updated, ${result.removed} removed.',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

enum _PlaylistSourceMode { url, localFile, localPath }

class _PlaylistImportRequest {
  const _PlaylistImportRequest({
    required this.name,
    required this.sourceUrlOrPath,
    this.pickedFile,
    this.isLocalPath = false,
  });

  final String name;
  final String sourceUrlOrPath;
  final PlatformFile? pickedFile;
  final bool isLocalPath;
}

class _AddPlaylistDialog extends StatefulWidget {
  const _AddPlaylistDialog();

  @override
  State<_AddPlaylistDialog> createState() => _AddPlaylistDialogState();
}

class _AddPlaylistDialogState extends State<_AddPlaylistDialog> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _pathController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  _PlaylistSourceMode _mode = _PlaylistSourceMode.url;
  PlatformFile? _pickedFile;
  bool _isPickingFile = false;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) {
      setState(() {
        if (_mode == _PlaylistSourceMode.url) {
          _urlController.text = text;
        } else if (_mode == _PlaylistSourceMode.localPath) {
          _pathController.text = text;
        }
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = 'IPTV Playlist';
        }
      });
    }
  }

  Future<void> _browseFile() async {
    setState(() => _isPickingFile = true);
    try {
      final file = await FilePicker.pickFiles(
        dialogTitle: 'Select M3U playlist',
        type: FileType.custom,
        allowedExtensions: const ['m3u', 'm3u8'],
      );

      if (!mounted || file.isEmpty) return;
      final selectedFile = file.first;

      final extension = selectedFile.extension?.toLowerCase();
      if (extension != 'm3u' && extension != 'm3u8') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an M3U or M3U8 file.')),
        );
        return;
      }

      setState(() {
        _pickedFile = selectedFile;
        _mode = _PlaylistSourceMode.localFile;
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = selectedFile.name.replaceAll(
            RegExp(r'\.m3u8?$'),
            '',
          );
        }
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to select file: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingFile = false);
      }
    }
  }

  String? _validateUrl(String? value) {
    final input = value?.trim() ?? '';
    final uri = Uri.tryParse(input);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'Enter a valid HTTP or HTTPS URL';
    }
    return null;
  }

  String? _validatePath(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty || !input.startsWith('/')) {
      return 'Enter an absolute file path';
    }
    final lower = input.toLowerCase();
    if (!lower.endsWith('.m3u') && !lower.endsWith('.m3u8')) {
      return 'Use an .m3u or .m3u8 file';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();

    switch (_mode) {
      case _PlaylistSourceMode.url:
        Navigator.pop(
          context,
          _PlaylistImportRequest(
            name: name,
            sourceUrlOrPath: _urlController.text.trim(),
          ),
        );
      case _PlaylistSourceMode.localFile:
        final file = _pickedFile;
        if (file == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please browse and select a file.')),
          );
          return;
        }
        Navigator.pop(
          context,
          _PlaylistImportRequest(
            name: name,
            sourceUrlOrPath: file.path ?? file.name,
            pickedFile: file,
          ),
        );
      case _PlaylistSourceMode.localPath:
        Navigator.pop(
          context,
          _PlaylistImportRequest(
            name: name,
            sourceUrlOrPath: _pathController.text.trim(),
            isLocalPath: true,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      backgroundColor: const Color(0xFF0D172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF26E7FF), width: 1.2),
      ),
      title: const Row(
        children: [
          Icon(Icons.playlist_add_rounded, color: Color(0xFF26E7FF)),
          SizedBox(width: 10),
          Text(
            'Add IPTV Playlist',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Playlist name',
                  hintText: 'e.g. My Cable TV',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a playlist name'
                    : null,
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: SegmentedButton<_PlaylistSourceMode>(
                  segments: const [
                    ButtonSegment(
                      value: _PlaylistSourceMode.url,
                      label: Text('URL'),
                      icon: Icon(Icons.link_rounded),
                    ),
                    ButtonSegment(
                      value: _PlaylistSourceMode.localFile,
                      label: Text('Browse'),
                      icon: Icon(Icons.folder_open_rounded),
                    ),
                    ButtonSegment(
                      value: _PlaylistSourceMode.localPath,
                      label: Text('Path'),
                      icon: Icon(Icons.drive_file_move_rounded),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) {
                    setState(() => _mode = selection.first);
                  },
                ),
              ),
              const SizedBox(height: 14),
              if (_mode == _PlaylistSourceMode.url) ...[
                TextFormField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'M3U URL',
                    hintText: 'https://example.com/playlist.m3u',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'Paste from clipboard',
                      onPressed: _pasteFromClipboard,
                      icon: const Icon(
                        Icons.content_paste_rounded,
                        color: Color(0xFF26E7FF),
                      ),
                    ),
                  ),
                  validator: _validateUrl,
                ),
              ],
              if (_mode == _PlaylistSourceMode.localFile) ...[
                OutlinedButton.icon(
                  onPressed: _isPickingFile ? null : _browseFile,
                  icon: _isPickingFile
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.folder_open_rounded),
                  label: const Text('BROWSE STORAGE'),
                ),
                if (_pickedFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.insert_drive_file_rounded,
                            color: Color(0xFF26E7FF),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _pickedFile!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() => _pickedFile = null),
                            icon: const Icon(Icons.close_rounded, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              if (_mode == _PlaylistSourceMode.localPath) ...[
                TextFormField(
                  controller: _pathController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Absolute File Path',
                    hintText: '/sdcard/Download/playlist.m3u',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'Paste from clipboard',
                      onPressed: _pasteFromClipboard,
                      icon: const Icon(
                        Icons.content_paste_rounded,
                        color: Color(0xFF26E7FF),
                      ),
                    ),
                  ),
                  validator: _validatePath,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        FilledButton(onPressed: _submit, child: const Text('IMPORT & SYNC')),
      ],
    );
  }
}
