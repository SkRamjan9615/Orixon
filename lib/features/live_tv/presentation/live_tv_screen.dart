import 'services/media_kit_playback.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/constants/live_tv_categories.dart';
import 'widgets/live_tv_player.dart';

class LiveTvScreen extends ConsumerStatefulWidget {
  const LiveTvScreen({
    super.key,
    required this.database,
    this.enablePlayback = true,
    this.initialChannelId,
  });

  final AppDatabase database;
  final bool enablePlayback;
  final int? initialChannelId;

  @override
  ConsumerState<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends ConsumerState<LiveTvScreen> {
  int? selectedCategoryId;
  int? selectedChannelId;
  int _lastZapDirection = 1;
  bool _showFavoritesOnly = false;
  bool _isSearchVisible = false;
  BoxFit _videoFit = BoxFit.contain;
  bool _panelsVisible = true;
  int _controlsRevision = 0;
  bool _showZappingBanner = false;
  Timer? _panelAutoHideTimer;
  Timer? _zappingBannerTimer;
  final TextEditingController _searchController = TextEditingController();

  Timer? _channelNumberTimer;
  String _channelNumberInput = '';
  String? _channelNumberMessage;
  DateTime? _lastRemoteOkAt;

  @override
  void initState() {
    super.initState();
    selectedChannelId = widget.initialChannelId;
    _schedulePanelAutoHide();
    _syncPlaybackSettings();
  }

  Future<void> _syncPlaybackSettings() async {
    try {
      final rows = await widget.database.select(widget.database.appSettings).get();
      var skipFound = false;
      for (final r in rows) {
        if (r.key.endsWith('Auto-skip dead TV channels')) {
          MediaKitPlayback.autoSkipDeadChannels = r.value != 'false';
          skipFound = true;
        } else if (r.key.endsWith('HTTP user agent')) {
          MediaKitPlayback.customUserAgent = r.value;
        } else if (r.key.endsWith('Hardware Acceleration')) {
          MediaKitPlayback.hwDecMode = r.value.startsWith('Soft')
              ? 'no'
              : r.value.startsWith('Full')
              ? 'mediacodec-copy'
              : 'auto';
        }
      }
      if (!skipFound) MediaKitPlayback.autoSkipDeadChannels = true;
    } catch (_) {}
  }

  void _schedulePanelAutoHide() {
    _panelAutoHideTimer?.cancel();
    _panelAutoHideTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted || !_panelsVisible) return;
      setState(() => _panelsVisible = false);
    });
  }

  void _registerActivity() {
    if (!mounted) return;
    setState(() {
      _panelsVisible = true;
      _controlsRevision++;
    });
    _schedulePanelAutoHide();
  }

  void _toggleVideoFit() {
    if (!mounted) return;
    _registerActivity();
    setState(() {
      _videoFit = _videoFit == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
    });
  }

  void _showChannelZappingBanner() {
    _zappingBannerTimer?.cancel();
    setState(() => _showZappingBanner = true);
    _zappingBannerTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showZappingBanner = false);
    });
  }

  @override
  void dispose() {
    _channelNumberTimer?.cancel();
    _panelAutoHideTimer?.cancel();
    _zappingBannerTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final channelsAsync = ref.watch(channelsProvider);

    return categoriesAsync.when(
      data: (categories) => channelsAsync.when(
        data: (channels) => Focus(
          autofocus: true,
          onKeyEvent: (node, event) => _handleRemoteKey(event, channels),
          child: _buildScreen(categories, channels),
        ),
        loading: () => _loadingScreen(),
        error: (error, stackTrace) => _errorScreen(error),
      ),
      loading: () => _loadingScreen(),
      error: (error, stackTrace) => _errorScreen(error),
    );
  }

  Widget _loadingScreen() {
    return const Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
    );
  }

  Widget _errorScreen(Object error) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Unable to load TV data.\\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.muted),
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(List<Category> categories, List<Channel> channels) {
    final activeCategoryId =
        categories.any((category) => category.id == selectedCategoryId)
        ? selectedCategoryId
        : null;

    final categoryChannels = activeCategoryId == null
        ? channels
        : channels
              .where((channel) => channel.categoryId == activeCategoryId)
              .toList();

    final favoriteChannels = _showFavoritesOnly
        ? categoryChannels.where((channel) => channel.isFavorite).toList()
        : categoryChannels;

    final query = _searchController.text.trim().toLowerCase();
    final visibleChannels = query.isEmpty
        ? favoriteChannels
        : favoriteChannels.where((channel) {
            return channel.name.toLowerCase().contains(query) ||
                channel.channelNumber.toString().contains(query);
          }).toList();

    Channel? currentChannel;
    for (final channel in channels) {
      if (channel.id == selectedChannelId) {
        currentChannel = channel;
        break;
      }
    }

    // Resume the most recently watched Live TV channel when opening Live TV.
    if (currentChannel == null &&
        selectedChannelId == null &&
        activeCategoryId == null &&
        !_showFavoritesOnly &&
        query.isEmpty) {
      final recent =
          ref.watch(recentLiveTvChannelsProvider).asData?.value ?? const [];
      for (final entry in recent) {
        final resumed = entry.channel;
        if (resumed != null &&
            favoriteChannels.any((channel) => channel.id == resumed.id)) {
          currentChannel = resumed;
          break;
        }
      }
    }

    if (query.isEmpty) {
      currentChannel ??= favoriteChannels.isNotEmpty
          ? favoriteChannels.first
          : null;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final panels = _panelsVisible;

          return Listener(
            onPointerDown: (_) => _registerActivity(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Keep this exact player subtree mounted while its bounds animate.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  left: panels ? width * 0.25 : 0,
                  top: 0,
                  width: panels ? width * 0.75 : width,
                  height: height,
                  child: KeyedSubtree(
                    key: const ValueKey('orixon-live-tv-player'),
                    child: _player(
                      currentChannel,
                      channels: visibleChannels.isNotEmpty ? visibleChannels : channels,
                      fullscreen: !panels,
                    ),
                  ),
                ),
                if (panels) ...[
                  Positioned(
                    left: 0,
                    top: 0,
                    width: width * 0.25,
                    height: height * 0.10,
                    child: _searchPanel(),
                  ),
                  Positioned(
                    left: 0,
                    top: height * 0.10,
                    width: width * 0.10,
                    height: height * 0.90,
                    child: _categoryRail(categories, activeCategoryId),
                  ),
                  Positioned(
                    left: width * 0.10,
                    top: height * 0.10,
                    width: width * 0.15,
                    height: height * 0.90,
                    child: _compactChannelPanel(
                      visibleChannels,
                      currentChannel,
                    ),
                  ),
                ],
                if (false && _showZappingBanner && currentChannel != null)
                  Positioned(
                    top: 58,
                    left: panels ? width * 0.25 : 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xE6000000),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.accent.withValues(alpha: 0.7),
                            ),
                          ),
                          child: Text(
                            '${currentChannel.channelNumber}  •  ${currentChannel.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_channelNumberInput.isNotEmpty ||
                    _channelNumberMessage != null)
                  Positioned(
                    bottom: panels ? height * 0.10 + 12 : 20,
                    right: 16,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xE6000000),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          _channelNumberMessage ?? _channelNumberInput,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _searchPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      color: const Color(0xFF101A2A),
      alignment: Alignment.center,
      child: TextField(
        key: const ValueKey('channel-search-field'),
        controller: _searchController,
        onTap: _registerActivity,
        onChanged: (_) {
          _registerActivity();
          setState(() {});
        },
        style: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Search channels...',
          hintStyle: const TextStyle(color: AppTheme.muted, fontSize: 11),
          prefixIcon: const Icon(Icons.search, size: 17),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    _registerActivity();
                    _searchController.clear();
                    setState(() {});
                  },
                ),
          isDense: true,
          filled: true,
          fillColor: const Color(0xFF172235),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _categoryRail(List<Category> categories, int? activeCategoryId) {
    final canonicalCategories = [
      for (final name in LiveTvCategories.names)
        for (final category in categories)
          if (category.name == name) category,
    ];

    return Container(
      color: const Color(0xFF0D1422),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
        children: [
          _categoryRailItem(
            icon: Icons.grid_view_rounded,
            label: 'All',
            active: activeCategoryId == null && !_showFavoritesOnly,
            onTap: () {
              _registerActivity();
              setState(() {
                selectedCategoryId = null;
                _showFavoritesOnly = false;
              });
            },
          ),
          _categoryRailItem(
            icon: Icons.favorite_rounded,
            label: 'Favourite',
            active: _showFavoritesOnly,
            onTap: () {
              _registerActivity();
              setState(() => _showFavoritesOnly = !_showFavoritesOnly);
            },
          ),
          for (final category in canonicalCategories)
            _categoryRailItem(
              icon: switch (category.name) {
                'Movies' => Icons.movie_rounded,
                'Sports' => Icons.sports_soccer_rounded,
                'News' => Icons.newspaper_rounded,
                'Kids' => Icons.child_care_rounded,
                'Music' => Icons.music_note_rounded,
                'Entertainment' => Icons.theaters_rounded,
                'General' => Icons.tv_rounded,
                'Others' => Icons.apps_rounded,
                _ => Icons.live_tv_rounded,
              },
              label: category.name,
              active: !_showFavoritesOnly && category.id == activeCategoryId,
              onTap: () {
                _registerActivity();
                setState(() {
                  selectedCategoryId = category.id;
                  _showFavoritesOnly = false;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _categoryRailItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minHeight: 60),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
              decoration: BoxDecoration(
                color: active
                    ? AppTheme.accent.withValues(alpha: 0.17)
                    : const Color(0xFF121E30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active
                      ? AppTheme.accent.withValues(alpha: 0.75)
                      : const Color(0xFF26344A),
                  width: active ? 1.2 : 0.7,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 26,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active
                          ? AppTheme.accent.withValues(alpha: 0.16)
                          : Colors.white.withValues(alpha: 0.045),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      icon,
                      size: 17,
                      color: active ? AppTheme.accent : AppTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? AppTheme.accent : AppTheme.muted,
                      fontSize: 8.5,
                      height: 1.15,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryBar(List<Category> categories, int? activeCategoryId) {
    final sorted = [...categories]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return SizedBox(
      height: 53,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        itemCount: sorted.length + 2,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final isFavourite = index == 1;
          final category = index < 2 ? null : sorted[index - 2];
          final active = isAll
              ? activeCategoryId == null && !_showFavoritesOnly
              : isFavourite
              ? _showFavoritesOnly
              : !_showFavoritesOnly && category!.id == activeCategoryId;
          final label = isAll
              ? 'All'
              : isFavourite
              ? 'Favourite'
              : category!.name;

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _registerActivity();
              setState(() {
                if (isFavourite) {
                  _showFavoritesOnly = !_showFavoritesOnly;
                } else {
                  selectedCategoryId = isAll ? null : category!.id;
                  _showFavoritesOnly = false;
                }
              });
            },
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: active
                    ? AppTheme.accent.withValues(alpha: 0.16)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? AppTheme.accent : const Color(0xFF26344A),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: active ? AppTheme.accent : AppTheme.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _channelPanel(List<Channel> channels, Channel? currentChannel) {
    return Container(
      color: const Color(0xFF0D1422),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'CHANNELS',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '${channels.length} CHANNELS',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 9),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF243149)),
          Expanded(
            child: channels.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.trim().isNotEmpty
                          ? 'No matching channels'
                          : _showFavoritesOnly
                          ? 'No favorite channels yet'
                          : 'No channels available',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: channels.length,
                    itemBuilder: (context, index) {
                      final channel = channels[index];
                      final active = channel.id == currentChannel?.id;

                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          dense: true,
                          selected: active,
                          selectedTileColor: AppTheme.accent.withValues(
                            alpha: 0.12,
                          ),
                          leading: Text(
                            channel.channelNumber.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 11,
                            ),
                          ),
                          title: Text(
                            channel.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: active
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            channel.isFavorite ? 'FAVORITE' : 'IPTV CHANNEL',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppTheme.muted,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (active && !channel.isFavorite)
                                const Icon(
                                  Icons.equalizer,
                                  color: AppTheme.accent,
                                ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: channel.isFavorite
                                    ? 'Remove from favorites'
                                    : 'Add to favorites',
                                icon: Icon(
                                  channel.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 17,
                                  color: channel.isFavorite
                                      ? AppTheme.accent
                                      : AppTheme.muted,
                                ),
                                onPressed: () => _toggleFavorite(channel),
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() => selectedChannelId = channel.id);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _compactChannelPanel(List<Channel> channels, Channel? currentChannel) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF101A2A),
        border: Border(right: BorderSide(color: Color(0xFF26344A))),
      ),
      child: channels.isEmpty
          ? Center(
              child: Text(
                _searchController.text.trim().isNotEmpty
                    ? 'No match'
                    : 'No channels',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.muted, fontSize: 8),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final channel = channels[index];
                final active = channel.id == currentChannel?.id;

                return Material(
                  color: active
                      ? AppTheme.accent.withValues(alpha: 0.16)
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _registerActivity();
                      _selectChannel(channel);
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 42,
                            height: 36,
                            child: channel.logoUrl.trim().isNotEmpty
                                ? Image.network(
                                    channel.logoUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.live_tv_rounded,
                                      color: AppTheme.accent,
                                      size: 26,
                                    ),
                                  )
                                : const Icon(
                                    Icons.live_tv_rounded,
                                    color: AppTheme.accent,
                                    size: 24,
                                  ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  channel.channelNumber.toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: active
                                        ? AppTheme.accent
                                        : Colors.white70,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  _registerActivity();
                                  _toggleFavorite(channel);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    channel.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 13,
                                    color: channel.isFavorite
                                        ? AppTheme.accent
                                        : AppTheme.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            channel.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  KeyEventResult _handleRemoteKey(KeyEvent event, List<Channel> channels) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    _registerActivity();
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      final now = DateTime.now();
      final previous = _lastRemoteOkAt;
      _lastRemoteOkAt = now;
      if (previous != null &&
          now.difference(previous) <= const Duration(seconds: 2)) {
        _lastRemoteOkAt = null;
        _toggleVideoFit();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.channelUp ||
        key == LogicalKeyboardKey.channelDown) {
      final currentIndex = channels.indexWhere(
        (channel) => channel.id == selectedChannelId,
      );
      final currentChannel = currentIndex >= 0
          ? channels[currentIndex]
          : (channels.isEmpty ? null : channels.first);

      _changeChannel(
        channels,
        currentChannel,
        key == LogicalKeyboardKey.channelUp ? 1 : -1,
      );
      return KeyEventResult.handled;
    }

    const digitKeys = <LogicalKeyboardKey>[
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
      LogicalKeyboardKey.numpad0,
      LogicalKeyboardKey.numpad1,
      LogicalKeyboardKey.numpad2,
      LogicalKeyboardKey.numpad3,
      LogicalKeyboardKey.numpad4,
      LogicalKeyboardKey.numpad5,
      LogicalKeyboardKey.numpad6,
      LogicalKeyboardKey.numpad7,
      LogicalKeyboardKey.numpad8,
      LogicalKeyboardKey.numpad9,
    ];

    final keyIndex = digitKeys.indexOf(key);
    if (keyIndex >= 0) {
      _handleChannelDigit(keyIndex % 10, channels);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _handleChannelDigit(int digit, List<Channel> channels) {
    if (digit < 0 || digit > 9) return;
    _registerActivity();

    setState(() {
      _channelNumberInput += digit.toString();
      _channelNumberMessage = null;
    });

    _channelNumberTimer?.cancel();
    _channelNumberTimer = Timer(
      const Duration(milliseconds: 1800),
      () => _commitChannelNumber(channels),
    );
  }

  void _commitChannelNumber(List<Channel> channels) {
    final input = _channelNumberInput;
    _channelNumberTimer = null;

    if (input.isEmpty || !mounted) return;

    final number = int.tryParse(input);
    Channel? match;

    if (number != null) {
      for (final channel in channels) {
        if (channel.channelNumber == number) {
          match = channel;
          break;
        }
      }
    }

    if (match == null) {
      setState(() {
        _channelNumberInput = '';
        _channelNumberMessage = 'Channel $input not found';
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Channel $input not found')));
      return;
    }

    _selectChannel(match, clearFilters: true);
  }

  void _changeChannel(
    List<Channel> channels,
    Channel? currentChannel,
    int direction,
  ) {
    if (channels.isEmpty || direction == 0) return;
    _lastZapDirection = direction >= 0 ? 1 : -1;

    final currentIndex = channels.indexWhere(
      (channel) => channel.id == currentChannel?.id,
    );

    final nextIndex = currentIndex == -1
        ? (direction > 0 ? 0 : channels.length - 1)
        : (currentIndex + direction) % channels.length < 0 ? channels.length - 1 : (currentIndex + direction) % channels.length;

    if (nextIndex == currentIndex) return;

    _channelNumberTimer?.cancel();
    _selectChannel(channels[nextIndex], clearFilters: true);
  }

  void _selectChannel(Channel channel, {bool clearFilters = false}) {
    _registerActivity();
    _showChannelZappingBanner();
    if (!mounted) return;

    setState(() {
      selectedChannelId = channel.id;
      _channelNumberInput = '';
      _channelNumberMessage = null;

      if (clearFilters) {
        selectedCategoryId = null;
        _showFavoritesOnly = false;
        _searchController.clear();
        _isSearchVisible = false;
      }
    });
  }

  Future<void> _toggleFavorite(Channel channel) async {
    try {
      final updated = await ref
          .read(channelRepositoryProvider)
          .setFavorite(channelId: channel.id, isFavorite: !channel.isFavorite);

      if (!mounted) return;

      if (!updated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Channel could not be updated.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update favorite status.')),
      );
    }
  }

  Future<void> _recordLiveTvPlayback(Channel channel) async {
    try {
      await ref
          .read(channelRepositoryProvider)
          .recordLiveTvPlayback(
            channelId: channel.id,
            channelName: channel.name,
          );
    } catch (error, stackTrace) {
      debugPrint('Could not save TV playback history: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  List<Widget> _playerCenterControls(
    List<Channel> channels,
    Channel? currentChannel,
  ) {
    return [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Previous channel (CH−)',
            onPressed: channels.length > 1
                ? () {
                    _registerActivity();
                    _changeChannel(channels, currentChannel, -1);
                  }
                : null,
            icon: const Icon(Icons.skip_previous_rounded, size: 36),
          ),
          const SizedBox(width: 28),
          IconButton(
            tooltip: 'Next channel (CH+)',
            onPressed: channels.length > 1
                ? () {
                    _registerActivity();
                    _changeChannel(channels, currentChannel, 1);
                  }
                : null,
            icon: const Icon(Icons.skip_next_rounded, size: 36),
          ),
        ],
      ),
    ];
  }

  Widget _player(
    Channel? currentChannel, {
    required List<Channel> channels,
    bool fullscreen = false,
  }) {
    if (!widget.enablePlayback) return const SizedBox.expand();
    return LiveTvPlayer(
      onChannelFailed: () => _changeChannel(channels, currentChannel, _lastZapDirection),
      channel: currentChannel,
      fullscreen: fullscreen,
      controlsTopBar: const [],
      controlsCenterBar: _panelsVisible
          ? _playerCenterControls(channels, currentChannel)
          : const [],
      videoFit: _videoFit,
      controlsRevision: _controlsRevision,
      onFitFillToggle: _toggleVideoFit,
      onPlaybackThresholdReached: (channel) {
        unawaited(_recordLiveTvPlayback(channel));
      },
    );
  }

  Widget _programInfo(Channel? currentChannel, List<Channel> channels) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.tv, color: AppTheme.accent, size: 27),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentChannel == null
                      ? 'No channel selected'
                      : '${currentChannel.channelNumber}. ${currentChannel.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _channelNumberInput.isNotEmpty
                      ? 'Tuning: $_channelNumberInput'
                      : _channelNumberMessage ??
                            'Program information will appear here',
                  style: TextStyle(
                    color: _channelNumberInput.isNotEmpty
                        ? AppTheme.accent
                        : AppTheme.muted,
                    fontSize: 10,
                    fontWeight: _channelNumberInput.isNotEmpty
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            currentChannel?.isFavorite == true
                ? Icons.favorite
                : Icons.favorite_border,
            color: currentChannel?.isFavorite == true
                ? AppTheme.accent
                : AppTheme.muted,
          ),
        ],
      ),
    );
  }
}
