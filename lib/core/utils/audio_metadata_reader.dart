import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';

/// 音訊檔案內嵌標籤資訊（支援 Ogg Vorbis / Ogg Opus / MP3 ID3v2）
class AudioMetadata {
  final String? title;
  final String? artist;
  final String? album;

  const AudioMetadata({
    this.title,
    this.artist,
    this.album,
  });

  bool get isEmpty =>
      (title == null || title!.isEmpty) &&
      (artist == null || artist!.isEmpty) &&
      (album == null || album!.isEmpty);
}

/// 純 Dart 音訊檔頭 Metadata 解析器（零原生外部套件依賴，跨 Android/iOS/Web/Desktop/Test 通用）
class AudioMetadataReader {
  /// 從 Flutter Asset 讀取音訊標籤（例如 assetPath 為 `audio/bb01-xxx.ogg`）
  static Future<AudioMetadata?> readFromAsset(
    String assetPath, {
    AssetBundle? bundle,
  }) async {
    final effectiveBundle = bundle ?? rootBundle;
    final fullKey =
        assetPath.startsWith('assets/') ? assetPath : 'assets/$assetPath';
    try {
      final byteData = await effectiveBundle.load(fullKey);
      // 僅取前 128 KB 視圖即可涵蓋絕大多數 Vorbis Comment / ID3v2 標籤區，避免大檔複製開銷
      final maxLen =
          byteData.lengthInBytes < 131072 ? byteData.lengthInBytes : 131072;
      final headerBytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        maxLen,
      );
      return parseBytes(headerBytes);
    } catch (_) {
      return null;
    }
  }

  /// 直接解析音訊位元組陣列中的 Metadata 標籤
  static AudioMetadata? parseBytes(Uint8List bytes) {
    if (bytes.length < 10) return null;

    // 1. Ogg 容器 (Ogg Vorbis / Ogg Opus)：以 'OggS' (0x4F 0x67 0x67 0x53) 開頭
    if (bytes[0] == 0x4F &&
        bytes[1] == 0x67 &&
        bytes[2] == 0x67 &&
        bytes[3] == 0x53) {
      return _parseOggMetadata(bytes);
    }

    // 2. MP3 ID3v2 標籤：以 'ID3' (0x49 0x44 0x33) 開頭
    if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
      return _parseId3v2Metadata(bytes);
    }

    return null;
  }

  /// 解析 Ogg Page 分段封包並提取 Vorbis Comment (`0x03 + "vorbis"`) 或 OpusTags (`"OpusTags"`)
  static AudioMetadata? _parseOggMetadata(Uint8List bytes) {
    var offset = 0;
    final packetBuilder = BytesBuilder(copy: false);
    var pagesScanned = 0;

    while (offset + 27 <= bytes.length && pagesScanned < 16) {
      if (bytes[offset] != 0x4F ||
          bytes[offset + 1] != 0x67 ||
          bytes[offset + 2] != 0x67 ||
          bytes[offset + 3] != 0x53) {
        break;
      }
      pagesScanned++;

      final headerType = bytes[offset + 5];
      final numSegments = bytes[offset + 26];
      if (offset + 27 + numSegments > bytes.length) break;

      // 若非延續上一頁未完封包 (continued packet flag = 0x01)，先清空殘留緩衝
      if ((headerType & 0x01) == 0 && packetBuilder.isNotEmpty) {
        packetBuilder.clear();
      }

      var dataOffset = offset + 27 + numSegments;
      for (var i = 0; i < numSegments; i++) {
        final lacing = bytes[offset + 27 + i];
        if (dataOffset + lacing > bytes.length) {
          return null;
        }
        if (lacing > 0) {
          packetBuilder.add(
            Uint8List.sublistView(bytes, dataOffset, dataOffset + lacing),
          );
        }
        dataOffset += lacing;

        // lacing < 255 代表一個完整 Ogg Packet 結束
        if (lacing < 255) {
          final packet = packetBuilder.takeBytes();
          // Vorbis Comment Header: [0x03, 'v', 'o', 'r', 'b', 'i', 's']
          if (packet.length >= 7 &&
              packet[0] == 0x03 &&
              packet[1] == 0x76 &&
              packet[2] == 0x6F &&
              packet[3] == 0x72 &&
              packet[4] == 0x62 &&
              packet[5] == 0x69 &&
              packet[6] == 0x73) {
            return _parseVorbisCommentBody(packet, 7);
          }
          // OpusTags Header: ['O', 'p', 'u', 's', 'T', 'a', 'g', 's']
          if (packet.length >= 8 &&
              packet[0] == 0x4F &&
              packet[1] == 0x70 &&
              packet[2] == 0x75 &&
              packet[3] == 0x73 &&
              packet[4] == 0x54 &&
              packet[5] == 0x61 &&
              packet[6] == 0x67 &&
              packet[7] == 0x73) {
            return _parseVorbisCommentBody(packet, 8);
          }
        }
      }

      offset = dataOffset;
    }

    return null;
  }

  /// 解析 Vorbis Comment 結構（Little-Endian uint32 長度 + UTF-8 KEY=VALUE 字串）
  static AudioMetadata? _parseVorbisCommentBody(
    Uint8List packet,
    int startPos,
  ) {
    final bd = ByteData.sublistView(packet);
    var pos = startPos;

    if (pos + 4 > packet.length) return null;
    final vendorLen = bd.getUint32(pos, Endian.little);
    pos += 4 + vendorLen;

    if (pos + 4 > packet.length) return null;
    final commentCount = bd.getUint32(pos, Endian.little);
    pos += 4;

    final tags = <String, String>{};
    for (var i = 0; i < commentCount; i++) {
      if (pos + 4 > packet.length) break;
      final itemLen = bd.getUint32(pos, Endian.little);
      pos += 4;
      if (pos + itemLen > packet.length) break;

      final entry = utf8.decode(
        Uint8List.sublistView(packet, pos, pos + itemLen),
        allowMalformed: true,
      );
      pos += itemLen;

      final eqIdx = entry.indexOf('=');
      if (eqIdx > 0) {
        final key = entry.substring(0, eqIdx).trim().toUpperCase();
        final value = entry.substring(eqIdx + 1).trim();
        if (value.isNotEmpty && !tags.containsKey(key)) {
          tags[key] = value;
        }
      }
    }

    return AudioMetadata(
      title: tags['TITLE'],
      artist: tags['ARTIST'] ?? tags['PERFORMER'] ?? tags['ALBUMARTIST'],
      album: tags['ALBUM'],
    );
  }

  /// 解析 MP3 ID3v2.3 / ID3v2.4 標籤 (TIT2 / TPE1 / TALB)
  static AudioMetadata? _parseId3v2Metadata(Uint8List bytes) {
    if (bytes.length < 10) return null;
    final versionMajor = bytes[3];
    if (versionMajor < 3 || versionMajor > 4) return null;

    final flags = bytes[5];
    final tagSize = ((bytes[6] & 0x7F) << 21) |
        ((bytes[7] & 0x7F) << 14) |
        ((bytes[8] & 0x7F) << 7) |
        (bytes[9] & 0x7F);

    final endOffset =
        (10 + tagSize < bytes.length) ? (10 + tagSize) : bytes.length;
    var pos = 10;

    // 若含有 Extended Header (flag 0x40)，略過之
    if ((flags & 0x40) != 0 && pos + 4 <= endOffset) {
      final extSize = (versionMajor == 4)
          ? (((bytes[pos] & 0x7F) << 21) |
              ((bytes[pos + 1] & 0x7F) << 14) |
              ((bytes[pos + 2] & 0x7F) << 7) |
              (bytes[pos + 3] & 0x7F))
          : ((bytes[pos] << 24) |
              (bytes[pos + 1] << 16) |
              (bytes[pos + 2] << 8) |
              bytes[pos + 3]);
      pos += (versionMajor == 4) ? extSize : (4 + extSize);
    }

    String? title;
    String? artist;
    String? album;

    while (pos + 10 <= endOffset) {
      if (bytes[pos] == 0) break; // Padding
      final frameId = String.fromCharCodes(bytes.sublist(pos, pos + 4));
      final frameSize = (versionMajor == 4)
          ? (((bytes[pos + 4] & 0x7F) << 21) |
              ((bytes[pos + 5] & 0x7F) << 14) |
              ((bytes[pos + 6] & 0x7F) << 7) |
              (bytes[pos + 7] & 0x7F))
          : ((bytes[pos + 4] << 24) |
              (bytes[pos + 5] << 16) |
              (bytes[pos + 6] << 8) |
              bytes[pos + 7]);
      pos += 10;
      if (frameSize <= 0 || pos + frameSize > endOffset) break;

      if (frameId == 'TIT2' || frameId == 'TPE1' || frameId == 'TALB') {
        final text = _decodeId3TextFrame(
          Uint8List.sublistView(bytes, pos, pos + frameSize),
        );
        if (text != null && text.isNotEmpty) {
          if (frameId == 'TIT2') title ??= text;
          if (frameId == 'TPE1') artist ??= text;
          if (frameId == 'TALB') album ??= text;
        }
      }
      pos += frameSize;
    }

    return AudioMetadata(title: title, artist: artist, album: album);
  }

  static String? _decodeId3TextFrame(Uint8List frameBytes) {
    if (frameBytes.isEmpty) return null;
    final encoding = frameBytes[0];
    final body = Uint8List.sublistView(frameBytes, 1);
    if (body.isEmpty) return null;

    String raw;
    if (encoding == 3) {
      // UTF-8
      raw = utf8.decode(body, allowMalformed: true);
    } else if (encoding == 1 || encoding == 2) {
      // UTF-16 with BOM or UTF-16BE
      raw = _decodeUtf16(body, bigEndianDefault: encoding == 2);
    } else {
      // ISO-8859-1 fallback
      raw = latin1.decode(body, allowInvalid: true);
    }
    return raw.replaceAll('\x00', '').trim();
  }

  static String _decodeUtf16(Uint8List bytes, {required bool bigEndianDefault}) {
    if (bytes.length < 2) return '';
    var offset = 0;
    var isBigEndian = bigEndianDefault;
    if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
      isBigEndian = true;
      offset = 2;
    } else if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
      isBigEndian = false;
      offset = 2;
    }
    final codeUnits = <int>[];
    for (var i = offset; i + 1 < bytes.length; i += 2) {
      final unit = isBigEndian
          ? ((bytes[i] << 8) | bytes[i + 1])
          : (bytes[i] | (bytes[i + 1] << 8));
      if (unit == 0) break;
      codeUnits.add(unit);
    }
    return String.fromCharCodes(codeUnits);
  }
}

