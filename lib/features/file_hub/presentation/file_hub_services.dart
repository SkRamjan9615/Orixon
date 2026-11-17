import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

class PureDartZipEngine {
  static final List<int> _crcTable = List<int>.generate(256, (n) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? (0xedb88320 ^ (c >>> 1)) : (c >>> 1);
    }
    return c;
  });

  static int _crc32(Uint8List bytes) {
    var c = 0xffffffff;
    for (final b in bytes) {
      c = _crcTable[(c ^ b) & 0xff] ^ (c >>> 8);
    }
    return (c ^ 0xffffffff) & 0xffffffff;
  }

  static Future<int> createZip(List<String> sourcePaths, File outZip) async {
    final filesToPack = <(String, File)>[];
    for (final src in sourcePaths) {
      if (FileSystemEntity.isFileSync(src)) {
        filesToPack.add((p.basename(src), File(src)));
      } else if (FileSystemEntity.isDirectorySync(src)) {
        final baseParent = p.dirname(src);
        for (final ent in Directory(src).listSync(recursive: true)) {
          if (ent is File) {
            filesToPack.add((p.relative(ent.path, from: baseParent).replaceAll('\\', '/'), ent));
          }
        }
      }
    }

    final out = BytesBuilder(copy: false);
    final centralDir = BytesBuilder(copy: false);
    int offset = 0;
    int count = 0;
    final rawDeflate = ZLibEncoder(raw: true);

    for (final (relName, file) in filesToPack) {
      final nameBytes = utf8.encode(relName);
      final rawBytes = await file.readAsBytes();
      final crc = _crc32(rawBytes);
      final compressed = Uint8List.fromList(rawDeflate.convert(rawBytes));
      final useDeflate = compressed.length < rawBytes.length;
      final payload = useDeflate ? compressed : rawBytes;
      final method = useDeflate ? 8 : 0;

      final lfh = ByteData(30 + nameBytes.length);
      lfh.setUint32(0, 0x04034b50, Endian.little);
      lfh.setUint16(4, 20, Endian.little);
      lfh.setUint16(6, 0x0800, Endian.little);
      lfh.setUint16(8, method, Endian.little);
      lfh.setUint16(10, 0, Endian.little);
      lfh.setUint16(12, 0, Endian.little);
      lfh.setUint32(14, crc, Endian.little);
      lfh.setUint32(18, payload.length, Endian.little);
      lfh.setUint32(22, rawBytes.length, Endian.little);
      lfh.setUint16(26, nameBytes.length, Endian.little);
      lfh.setUint16(28, 0, Endian.little);
      for (var i = 0; i < nameBytes.length; i++) {
        lfh.setUint8(30 + i, nameBytes[i]);
      }

      final lfhBytes = lfh.buffer.asUint8List();
      out.add(lfhBytes);
      out.add(payload);

      final cdh = ByteData(46 + nameBytes.length);
      cdh.setUint32(0, 0x02014b50, Endian.little);
      cdh.setUint16(4, 20, Endian.little);
      cdh.setUint16(6, 20, Endian.little);
      cdh.setUint16(8, 0x0800, Endian.little);
      cdh.setUint16(10, method, Endian.little);
      cdh.setUint16(12, 0, Endian.little);
      cdh.setUint16(14, 0, Endian.little);
      cdh.setUint32(16, crc, Endian.little);
      cdh.setUint32(20, payload.length, Endian.little);
      cdh.setUint32(24, rawBytes.length, Endian.little);
      cdh.setUint16(28, nameBytes.length, Endian.little);
      cdh.setUint16(30, 0, Endian.little);
      cdh.setUint16(32, 0, Endian.little);
      cdh.setUint16(34, 0, Endian.little);
      cdh.setUint16(36, 0, Endian.little);
      cdh.setUint32(38, 0, Endian.little);
      cdh.setUint32(42, offset, Endian.little);
      for (var i = 0; i < nameBytes.length; i++) {
        cdh.setUint8(46 + i, nameBytes[i]);
      }
      centralDir.add(cdh.buffer.asUint8List());

      offset += lfhBytes.length + payload.length;
      count++;
    }

    final cdBytes = centralDir.toBytes();
    out.add(cdBytes);

    final eocd = ByteData(22);
    eocd.setUint32(0, 0x06054b50, Endian.little);
    eocd.setUint16(4, 0, Endian.little);
    eocd.setUint16(6, 0, Endian.little);
    eocd.setUint16(8, count, Endian.little);
    eocd.setUint16(10, count, Endian.little);
    eocd.setUint32(12, cdBytes.length, Endian.little);
    eocd.setUint32(16, offset, Endian.little);
    eocd.setUint16(20, 0, Endian.little);
    out.add(eocd.buffer.asUint8List());

    await outZip.writeAsBytes(out.toBytes(), flush: true);
    return count;
  }

  static Future<int> extractZip(File zipFile, Directory targetDir) async {
    final bytes = await zipFile.readAsBytes();
    final data = ByteData.sublistView(bytes);
    if (!targetDir.existsSync()) targetDir.createSync(recursive: true);

    int eocdPos = -1;
    for (int i = bytes.length - 22; i >= 0 && i >= bytes.length - 65557; i--) {
      if (data.getUint32(i, Endian.little) == 0x06054b50) {
        eocdPos = i;
        break;
      }
    }
    if (eocdPos < 0) throw const FormatException('Invalid ZIP archive.');

    final totalEntries = data.getUint16(eocdPos + 10, Endian.little);
    var cdPos = data.getUint32(eocdPos + 16, Endian.little);
    final rawInflate = ZLibDecoder(raw: true);
    int extracted = 0;

    for (var idx = 0; idx < totalEntries && cdPos + 46 <= bytes.length; idx++) {
      if (data.getUint32(cdPos, Endian.little) != 0x02014b50) break;
      final method = data.getUint16(cdPos + 10, Endian.little);
      final compSize = data.getUint32(cdPos + 20, Endian.little);
      final nameLen = data.getUint16(cdPos + 28, Endian.little);
      final extraLen = data.getUint16(cdPos + 30, Endian.little);
      final commentLen = data.getUint16(cdPos + 32, Endian.little);
      final localHeaderOffset = data.getUint32(cdPos + 42, Endian.little);

      final entryName = utf8.decode(bytes.sublist(cdPos + 46, cdPos + 46 + nameLen), allowMalformed: true);
      cdPos += 46 + nameLen + extraLen + commentLen;

      if (entryName.endsWith('/')) {
        Directory(p.join(targetDir.path, entryName)).createSync(recursive: true);
        continue;
      }

      final lfhNameLen = data.getUint16(localHeaderOffset + 26, Endian.little);
      final lfhExtraLen = data.getUint16(localHeaderOffset + 28, Endian.little);
      final dataStart = localHeaderOffset + 30 + lfhNameLen + lfhExtraLen;
      final slice = bytes.sublist(dataStart, dataStart + compSize);

      Uint8List outBytes;
      if (method == 0) {
        outBytes = slice;
      } else if (method == 8) {
        outBytes = Uint8List.fromList(rawInflate.convert(slice));
      } else {
        continue;
      }

      final outFile = File(p.join(targetDir.path, entryName));
      outFile.parent.createSync(recursive: true);
      await outFile.writeAsBytes(outBytes, flush: true);
      extracted++;
    }
    return extracted;
  }
}

class FtpClientSession {
  FtpClientSession({required this.socket, required this.localIp, required this.rootPath}) : currentDir = rootPath;
  final Socket socket;
  final String localIp;
  final String rootPath;
  String currentDir;
  ServerSocket? _pasvServer;

  void start() {
    _send('220 ORIXON FTP Server Ready');
    socket.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen(
      _handleCommand,
      onDone: _cleanup,
      onError: (_) => _cleanup(),
    );
  }

  void _send(String line) {
    try { socket.write('$line\r\n'); } catch (_) {}
  }

  Future<void> _handleCommand(String rawLine) async {
    final line = rawLine.trim();
    if (line.isEmpty) return;
    final sp = line.indexOf(' ');
    final cmd = (sp < 0 ? line : line.substring(0, sp)).toUpperCase();
    final arg = sp < 0 ? '' : line.substring(sp + 1).trim();

    switch (cmd) {
      case 'USER': _send('331 User OK, password not required');
      case 'PASS': _send('230 Logged into ORIXON File Hub');
      case 'SYST': _send('215 UNIX Type: L8');
      case 'FEAT': _send('211-Features:\r\n PASV\r\n UTF8\r\n SIZE\r\n211 End');
      case 'OPTS': _send('200 UTF8 mode enabled');
      case 'PWD':
      case 'XPWD': _send('257 "$currentDir" is current directory');
      case 'TYPE': _send('200 Type set to $arg');
      case 'CDUP':
        currentDir = p.dirname(currentDir);
        _send('250 Directory changed to $currentDir');
      case 'CWD':
        final next = arg.startsWith('/') ? arg : p.join(currentDir, arg);
        if (Directory(next).existsSync()) {
          currentDir = p.normalize(next);
          _send('250 Directory changed to $currentDir');
        } else {
          _send('550 Directory not found');
        }
      case 'PASV':
        await _pasvServer?.close();
        _pasvServer = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
        final port = _pasvServer!.port;
        final ipParts = localIp.split('.').join(',');
        _send('227 Entering Passive Mode ($ipParts,${port ~/ 256},${port % 256})');
      case 'LIST':
      case 'NLST':
        if (_pasvServer == null) { _send('425 Use PASV first'); return; }
        _send('150 Opening directory list');
        final ds = await _pasvServer!.first;
        final dir = Directory(currentDir);
        if (dir.existsSync()) {
          for (final ent in dir.listSync(followLinks: false)) {
            final name = p.basename(ent.path);
            if (cmd == 'NLST') {
              ds.write('$name\r\n');
            } else {
              final isDir = ent is Directory;
              final sz = ent is File ? (tryLen(ent)) : 4096;
              ds.write('${isDir ? "drwxr-xr-x" : "-rw-r--r--"} 1 orixon orixon $sz Jan 01 12:00 $name\r\n');
            }
          }
        }
        await ds.flush(); await ds.close(); await _pasvServer?.close(); _pasvServer = null;
        _send('226 Directory send OK');
      case 'RETR':
        if (_pasvServer == null) { _send('425 Use PASV first'); return; }
        final target = File(arg.startsWith('/') ? arg : p.join(currentDir, arg));
        if (!target.existsSync()) { _send('550 File not found'); return; }
        _send('150 Opening binary connection');
        final ds = await _pasvServer!.first;
        await ds.addStream(target.openRead());
        await ds.flush(); await ds.close(); await _pasvServer?.close(); _pasvServer = null;
        _send('226 Transfer complete');
      case 'STOR':
        if (_pasvServer == null) { _send('425 Use PASV first'); return; }
        final target = File(arg.startsWith('/') ? arg : p.join(currentDir, p.basename(arg)));
        _send('150 Ready to receive file');
        final ds = await _pasvServer!.first;
        final sink = target.openWrite();
        await ds.forEach(sink.add);
        await sink.close(); await ds.close(); await _pasvServer?.close(); _pasvServer = null;
        _send('226 Upload complete');
      case 'NOOP': _send('200 OK');
      case 'QUIT': _send('221 Goodbye'); _cleanup();
      default: _send('502 Command not implemented');
    }
  }

  int tryLen(File f) { try { return f.lengthSync(); } catch (_) { return 0; } }
  void _cleanup() { _pasvServer?.close(); socket.destroy(); }
}
