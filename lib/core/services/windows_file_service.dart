import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:path_provider/path_provider.dart';

import '../providers/player_provider.dart';

class WindowsFileService {
  static const _channel = MethodChannel('com.auralis.app/file_open');

  final PlayerProvider _playerProvider;

  WindowsFileService(this._playerProvider);

  Future<void> init() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openFiles') {
        final args = call.arguments;
        if (args is List) {
          final paths = args.whereType<String>().toList();
          if (paths.isNotEmpty) {
            await _handleAudioFiles(paths);
          }
        }
      } else if (call.method == 'openFile') {
        final path = call.arguments as String?;
        if (path != null && path.isNotEmpty) {
          await _handleAudioFiles([path]);
        }
      }
    });

    try {
      final initialFiles = await _channel.invokeMethod<List<Object?>?>(
        'getInitialFiles',
      );
      if (initialFiles != null && initialFiles.isNotEmpty) {
        final paths = initialFiles.whereType<String>().toList();
        if (paths.isNotEmpty) {
          await _handleAudioFiles(paths);
        }
      }
    } catch (e) {
      if (kDebugMode)
        debugPrint('WindowsFileService: getInitialFiles error: $e');
    }
  }

  Future<void> _handleAudioFiles(List<String> paths) async {
    final List<Map<String, dynamic>> queue = [];

    for (final path in paths) {
      Map<String, dynamic> songData;
      try {
        final metadata = await MetadataGod.readMetadata(file: path);

        Uint8List? artwork;
        final picData = metadata.picture?.data;
        if (picData != null) {
          artwork = picData;
        }

        String? thumbnailUri;
        if (artwork != null) {
          try {
            final tempDir = await getTemporaryDirectory();
            final hash = path.hashCode.toRadixString(16);
            final artFile = File('${tempDir.path}/artwork_$hash.jpg');
            if (!await artFile.exists()) {
              await artFile.writeAsBytes(artwork);
            }
            thumbnailUri = artFile.path;
          } catch (e) {
            if (kDebugMode) debugPrint('Failed to write artwork file: $e');
          }
        }

        final rawDuration =
            metadata.durationMs ??
            (metadata.duration != null
                ? metadata.duration!.inMilliseconds
                : null);
        int? durationMsInt = rawDuration?.toInt();

        songData = {
          'id': path,
          'title': metadata.title ?? _fileNameWithoutExtension(path),
          'artist': metadata.artist ?? 'Unknown Artist',
          'album': metadata.album ?? 'Unknown Album',
          'duration': durationMsInt,
          'thumbnail': thumbnailUri,
          'localPath': path,
          'isLocal': true,
        };
      } on Exception catch (e) {
        if (kDebugMode) debugPrint('Metadata read error for $path: $e');
        songData = _fallbackSongData(path);
      } catch (e) {
        if (kDebugMode) debugPrint('Error reading metadata for $path: $e');
        songData = _fallbackSongData(path);
      }
      queue.add(songData);
    }

    if (queue.isEmpty) return;

    try {
      await _playerProvider.playerService.playLocalAudioWithQueue(
        queue.first['localPath'],
        queue.first,
        queue,
        0,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to play local songs from intent: $e');
    }
  }

  Map<String, dynamic> _fallbackSongData(String path) => {
    'id': path,
    'title': _fileNameWithoutExtension(path),
    'artist': 'Unknown Artist',
    'album': 'Unknown Album',
    'duration': null,
    'thumbnail': null,
    'localPath': path,
    'isLocal': true,
  };

  String _fileNameWithoutExtension(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
  }
}
