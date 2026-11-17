import 'dart:convert';
import 'package:orixon/features/live_tv/data/models/m3u_channel.dart';

class M3uParser {
  static final RegExp _attributePattern = RegExp(
    r'''([A-Za-z0-9_-]+)=("([^"]*)"|'([^']*)'|([^\s,]+))''',
  );

  static List<M3uChannel> parse(String content) {
    final lines = content
        .replaceFirst('\uFEFF', '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');

    final channels = <M3uChannel>[];
    final seenNameAndLink = <String>{};

    Map<String, String>? pendingAttributes;
    String pendingName = '';
    String pendingGroup = '';
    final Map<String, String> pendingHeaders = {};

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line == '#EXTM3U') continue;

      if (line.startsWith('#EXTINF:')) {
        final commaIndex = line.lastIndexOf(',');
        final header = commaIndex >= 0 ? line.substring(0, commaIndex) : line;
        final title = commaIndex >= 0 ? line.substring(commaIndex + 1).trim() : '';

        final attributes = <String, String>{};
        for (final match in _attributePattern.allMatches(header)) {
          final key = match.group(1)!.toLowerCase();
          final value = match.group(3) ?? match.group(4) ?? match.group(5) ?? '';
          attributes[key] = value;
        }

        pendingAttributes = attributes;
        pendingName = title.isNotEmpty ? title : attributes['tvg-name'] ?? '';
        final grp = attributes['group-title'] ?? attributes['group'] ?? '';
        if (grp.isNotEmpty) pendingGroup = grp;

        // Note: Do NOT clear pendingHeaders here because #KODIPROP / #EXTVLCOPT
        // often appear immediately ABOVE #EXTINF in M3U files!
        if (attributes['http-user-agent']?.isNotEmpty == true) {
          pendingHeaders['User-Agent'] = attributes['http-user-agent']!;
        }
        if (attributes['http-referrer']?.isNotEmpty == true) {
          pendingHeaders['Referer'] = attributes['http-referrer']!;
        }
        if (attributes['key']?.isNotEmpty == true) {
          pendingHeaders['Orixon-Drm-Key'] = attributes['key']!;
        }
        continue;
      }

      if (line.startsWith('#EXTGRP:')) {
        pendingGroup = line.substring(8).trim();
        continue;
      }

      // Support #KODIPROP both before and after #EXTINF
      if (line.startsWith('#KODIPROP:')) {
        final prop = line.substring(10).trim();
        final eqIdx = prop.indexOf('=');
        if (eqIdx > 0) {
          final k = prop.substring(0, eqIdx).trim().toLowerCase();
          final v = prop.substring(eqIdx + 1).trim();
          if (k.endsWith('license_type')) {
            pendingHeaders['Orixon-Drm-Type'] = v;
          } else if (k.endsWith('license_key')) {
            pendingHeaders['Orixon-Drm-Key'] = v;
          } else if (k.endsWith('stream_headers')) {
            for (final part in v.split('&')) {
              final pEq = part.indexOf('=');
              if (pEq > 0) {
                pendingHeaders[part.substring(0, pEq).trim()] =
                    Uri.decodeComponent(part.substring(pEq + 1).trim());
              }
            }
          }
        }
        continue;
      }

      // Support #EXTVLCOPT both before and after #EXTINF
      if (line.startsWith('#EXTVLCOPT:')) {
        final opt = line.substring(11).trim();
        final lower = opt.toLowerCase();
        if (lower.startsWith('http-user-agent=')) {
          pendingHeaders['User-Agent'] = opt.substring(16).trim();
        } else if (lower.startsWith('http-referrer=')) {
          pendingHeaders['Referer'] = opt.substring(14).trim();
        } else if (lower.startsWith('http-referer=')) {
          pendingHeaders['Referer'] = opt.substring(13).trim();
        } else if (lower.startsWith('http-origin=')) {
          pendingHeaders['Origin'] = opt.substring(12).trim();
        } else if (lower.startsWith('http-cookie=')) {
          pendingHeaders['Cookie'] = opt.substring(12).trim();
        }
        continue;
      }

      if (line.startsWith('#EXTHTTP:')) {
        try {
          final map = jsonDecode(line.substring(9).trim());
          if (map is Map) {
            map.forEach((k, v) {
              if (v != null) pendingHeaders[k.toString()] = v.toString();
            });
          }
        } catch (_) {}
        continue;
      }

      if (line.startsWith('#')) continue;
      if (pendingAttributes == null) continue;

      final pipeIdx = line.indexOf('|');
      final baseUrl = (pipeIdx >= 0 ? line.substring(0, pipeIdx) : line).trim();
      if (pipeIdx >= 0) {
        final tail = line.substring(pipeIdx + 1).trim();
        for (final part in tail.split('&')) {
          final eq = part.indexOf('=');
          if (eq > 0) {
            final hk = part.substring(0, eq).trim();
            final hv = Uri.decodeComponent(part.substring(eq + 1).trim());
            pendingHeaders[hk] = hv;
          }
        }
      }

      final uri = Uri.tryParse(baseUrl);
      if (uri == null || !uri.hasScheme) {
        pendingAttributes = null;
        pendingName = '';
        pendingGroup = '';
        pendingHeaders.clear();
        continue;
      }

      final attributes = Map<String, String>.unmodifiable(pendingAttributes);
      final name = pendingName.isNotEmpty
          ? pendingName
          : attributes['tvg-name'] ?? baseUrl;

      // Deduplicate ONLY if BOTH channel name AND base stream link are identical!
      final dedupKey = '${name.toLowerCase().trim()}||${baseUrl.toLowerCase()}';
      if (seenNameAndLink.add(dedupKey)) {
        var finalStreamUrl = baseUrl;
        if (pendingHeaders.isNotEmpty) {
          final encoded = pendingHeaders.entries
              .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
              .join('&');
          finalStreamUrl = '$baseUrl|$encoded';
        }

        final logo = attributes['tvg-logo']?.trim().isNotEmpty == true
            ? attributes['tvg-logo']!.trim()
            : (attributes['logo']?.trim() ?? '');

        channels.add(
          M3uChannel(
            name: name,
            streamUrl: finalStreamUrl,
            tvgId: attributes['tvg-id'] ?? '',
            tvgName: attributes['tvg-name'] ?? '',
            groupTitle: pendingGroup,
            logoUrl: logo,
            attributes: attributes,
          ),
        );
      }

      pendingAttributes = null;
      pendingName = '';
      pendingGroup = '';
      pendingHeaders.clear();
    }

    return channels;
  }
}
