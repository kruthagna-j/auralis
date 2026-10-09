import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:hive_ce/hive.dart';
import '../models/song_model.dart';

class QueueStorage {
  static const String _boxName = 'queue_storage';

  static Future<Map<String, dynamic>> songToMap(SongInfo song) async {
    return {
      'videoId': song.videoId,
      'name': song.name,
      'artists': song.artists.map((a) => {'name': a.name, 'id': a.id}).toList(),
      'thumbnails': song.thumbnails
          .map((t) => {'url': t.url, 'width': t.width, 'height': t.height})
          .toList(),
      'duration': song.duration.inMilliseconds,
    };
  }

  static SongInfo mapToSong(Map<String, dynamic> map) {
    return SongInfo(
      videoId: map['videoId'],
      name: map['name'],
      artists: (map['artists'] as List)
          .map((a) => Artist(name: a['name'], id: a['id']))
          .toList(),
      thumbnails: (map['thumbnails'] as List)
          .map(
            (t) => Thumbnail(
              url: t['url'],
              width: t['width'],
              height: t['height'],
            ),
          )
          .toList(),
      duration: Duration(milliseconds: map['duration']),
    );
  }

  static Future<void> saveQueue(
    List<SongInfo> queue,
    int currentIndex,
    bool isShuffle,
    String repeatMode,
    List<int> shuffleIndices,
    String? playlistId,
    String? playlistName,
  ) async {
    try {
      final box = Hive.box<String>(_boxName);

      final meta = {
        'currentIndex': currentIndex,
        'isShuffle': isShuffle,
        'repeatMode': repeatMode,
        'shuffleIndices': shuffleIndices,
        'playlistId': playlistId,
        'playlistName': playlistName,
      };
      await box.put('_meta', jsonEncode(meta));

      final Map<String, String> newQueueEntries = {};
      for (int i = 0; i < queue.length; i++) {
        final item = await songToMap(queue[i]);
        newQueueEntries['q_$i'] = jsonEncode(item);
      }

      final existingQueueKeys = box.keys
          .where((k) => k is String && (k).startsWith('q_'))
          .toList();

      for (final key in existingQueueKeys) {
        if (!newQueueEntries.containsKey(key)) {
          await box.delete(key);
        }
      }

      if (newQueueEntries.isNotEmpty) {
        await box.putAll(newQueueEntries);
      } else {
        for (final key in existingQueueKeys) {
          await box.delete(key);
        }
      }
    } catch (e) {
      debugPrint('Error saving queue to Hive: $e');
    }
  }

  static Future<Map<String, dynamic>?> loadQueue() async {
    try {
      final box = Hive.box<String>(_boxName);
      if (box.isEmpty) return null;

      final metaString = box.get('_meta');
      Map<String, dynamic> meta = {};
      if (metaString != null) {
        meta = jsonDecode(metaString) as Map<String, dynamic>;
      }

      final entries = <Map<String, dynamic>>[];
      final keys =
          box.keys.where((k) => k is String && (k).startsWith('q_')).toList()
            ..sort((a, b) {
              final ai = int.tryParse((a as String).substring(2)) ?? 0;
              final bi = int.tryParse((b as String).substring(2)) ?? 0;
              return ai.compareTo(bi);
            });

      for (final key in keys) {
        final v = box.get(key as String);
        if (v == null) continue;
        try {
          final map = jsonDecode(v) as Map<String, dynamic>;
          entries.add(map);
        } catch (_) {}
      }

      return {
        'queue': entries,
        'currentIndex': meta['currentIndex'] ?? 0,
        'isShuffle': meta['isShuffle'] ?? false,
        'repeatMode':
            meta['repeatMode'] as String? ??
            (meta['isRepeat'] == true ? 'all' : 'off'),
        'shuffleIndices':
            (meta['shuffleIndices'] as List?)?.cast<int>() ?? <int>[],
        'playlistId': meta['playlistId'],
        'playlistName': meta['playlistName'],
      };
    } catch (e) {
      debugPrint('Error loading queue from Hive: $e');
    }
    return null;
  }
}
