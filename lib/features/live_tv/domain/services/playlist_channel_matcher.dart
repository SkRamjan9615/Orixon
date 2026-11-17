import 'package:orixon/features/live_tv/data/models/m3u_channel.dart';

class ExistingPlaylistChannel {
  final int id;
  final String tvgId;
  final String streamUrl;

  const ExistingPlaylistChannel({
    required this.id,
    required this.tvgId,
    required this.streamUrl,
  });
}

class PlaylistChannelMatchException implements Exception {
  final String message;

  const PlaylistChannelMatchException(this.message);

  @override
  String toString() => 'PlaylistChannelMatchException: $message';
}

class PlaylistChannelMatcher {
  const PlaylistChannelMatcher();

  /// Returns incoming index -> existing database channel ID.
  ///
  /// Matching is restricted to the existing channels supplied by the caller.
  /// The caller must supply channels belonging to the target playlist only.
  Map<int, int> match({
    required List<M3uChannel> incoming,
    required List<ExistingPlaylistChannel> existing,
  }) {
    final incomingById = <String, List<int>>{};
    final existingById = <String, List<ExistingPlaylistChannel>>{};

    final incomingByUrl = <String, List<int>>{};
    final existingByUrl = <String, List<ExistingPlaylistChannel>>{};

    for (var i = 0; i < incoming.length; i++) {
      final channel = incoming[i];

      if (channel.tvgId.isNotEmpty) {
        incomingById.putIfAbsent(channel.tvgId, () => []).add(i);
      }

      incomingByUrl.putIfAbsent(channel.streamUrl, () => []).add(i);
    }

    for (final channel in existing) {
      if (channel.tvgId.isNotEmpty) {
        existingById.putIfAbsent(channel.tvgId, () => []).add(channel);
      }

      existingByUrl.putIfAbsent(channel.streamUrl, () => []).add(channel);
    }

    final matches = <int, int>{};
    final usedExistingIds = <int>{};

    for (final entry in incomingById.entries) {
      final incomingIndexes = entry.value;
      final existingChannels = existingById[entry.key];

      final existingCount = existingChannels?.length ?? 0;

      // A unique incoming ID with no existing counterpart is a new channel.
      // URL fallback is reserved for duplicate-ID situations.
      if (incomingIndexes.length == 1 && existingCount == 0) {
        continue;
      }

      // A unique ID on both sides is the highest-priority match.
      if (incomingIndexes.length == 1 && existingCount == 1) {
        final existingChannel = existingChannels!.single;

        matches[incomingIndexes.single] = existingChannel.id;
        usedExistingIds.add(existingChannel.id);
        continue;
      }

      // Duplicate ID on either side: fall back to exact stream URL.
      for (final incomingIndex in incomingIndexes) {
        final url = incoming[incomingIndex].streamUrl;
        final incomingUrlMatches = incomingByUrl[url] ?? [];
        final existingUrlMatches = existingByUrl[url] ?? [];

        // No existing row has this exact URL: this incoming channel
        // is new and will be inserted by the repository.
        if (existingUrlMatches.isEmpty) {
          continue;
        }

        // URL fallback is allowed only when unique on both sides.
        if (incomingUrlMatches.length != 1 || existingUrlMatches.length != 1) {
          throw PlaylistChannelMatchException(
            'Ambiguous exact stream URL during duplicate tvg-id '
            'fallback: $url',
          );
        }

        final existingChannel = existingUrlMatches.single;

        if (!usedExistingIds.add(existingChannel.id)) {
          throw PlaylistChannelMatchException(
            'One existing channel would be matched more than once: '
            '${existingChannel.id}',
          );
        }

        matches[incomingIndex] = existingChannel.id;
      }
    }

    // A blank incoming tvg-id may use URL fallback only when the
    // existing row belongs to a duplicated existing tvg-id group.
    for (var i = 0; i < incoming.length; i++) {
      if (incoming[i].tvgId.isNotEmpty || matches.containsKey(i)) {
        continue;
      }

      final url = incoming[i].streamUrl;
      final incomingUrlMatches = incomingByUrl[url] ?? [];
      final existingUrlMatches = existingByUrl[url] ?? [];

      final hasDuplicateExistingId = existingUrlMatches.any((channel) {
        if (channel.tvgId.isEmpty) return false;
        return (existingById[channel.tvgId]?.length ?? 0) > 1;
      });

      if (!hasDuplicateExistingId) {
        continue;
      }

      if (incomingUrlMatches.length != 1 || existingUrlMatches.length != 1) {
        throw PlaylistChannelMatchException(
          'Ambiguous exact stream URL during duplicate tvg-id '
          'fallback: $url',
        );
      }

      final existingChannel = existingUrlMatches.single;

      if (!usedExistingIds.add(existingChannel.id)) {
        throw PlaylistChannelMatchException(
          'One existing channel would be matched more than once: '
          '${existingChannel.id}',
        );
      }

      matches[i] = existingChannel.id;
    }

    return Map.unmodifiable(matches);
  }
}
