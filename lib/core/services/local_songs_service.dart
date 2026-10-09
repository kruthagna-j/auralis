import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalSongsService {
  static const _channel = MethodChannel('com.auralis.app/local_songs');

  static final LocalSongsService _instance = LocalSongsService._();
  factory LocalSongsService() => _instance;
  LocalSongsService._();

  Future<Permission> _audioPermission() async {
    if (!Platform.isAndroid) return Permission.storage;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    return androidInfo.version.sdkInt >= 33
        ? Permission.audio
        : Permission.storage;
  }

  Future<List<Map<String, dynamic>>> querySongs() async {
    if (!Platform.isAndroid) return [];

    final permission = await _audioPermission();
    var status = await permission.status;
    if (!status.isGranted) {
      status = await permission.request();
      if (!status.isGranted) return [];
    }

    try {
      final result = await _channel.invokeMethod<List>('querySongs');
      if (result == null || result.isEmpty) return [];

      final songs = <Map<String, dynamic>>[];
      final seenIds = <String>{};

      for (final raw in result) {
        if (raw is! Map) continue;
        final song = Map<String, dynamic>.from(raw);
        final id = song['id']?.toString() ?? '';
        final path = song['data']?.toString() ?? '';
        final title = song['title']?.toString().trim() ?? '';
        final durationMs = (song['durationMs'] as num?)?.toInt() ?? 0;

        if (id.isEmpty || path.isEmpty || title.isEmpty || durationMs <= 0) {
          continue;
        }
        if (!seenIds.add(id)) continue;

        songs.add(song);
      }

      return songs;
    } on PlatformException catch (e) {
      debugPrint('Local music query failed: ${e.code}: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Local music query failed: $e');
      return [];
    }
  }

  Future<Uint8List?> queryArtwork(int id, {int size = 256}) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('queryArtwork', {
        'id': id,
        'size': size.clamp(128, 512),
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint('Local artwork query failed: ${e.code}: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Local artwork query failed: $e');
      return null;
    }
  }

  Future<void> scanMedia(String path) async {
    if (path.isEmpty) return;
    try {
      await _channel.invokeMethod('scanMedia', {'path': path});
    } catch (e) {
      debugPrint('Media scan failed: $e');
    }
  }
}
