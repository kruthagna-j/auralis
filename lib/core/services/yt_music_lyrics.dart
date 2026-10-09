import 'package:dart_ytmusic_api/yt_music.dart';
import 'package:get_it/get_it.dart';
import '../../../../features/lyrics/domain/lyrics.dart';
import 'package:flutter/foundation.dart';

class YTLyricsService {
  final YTMusic _ytmusic = GetIt.I<YTMusic>();

  Future<LyricsResponse?> getLyrics(String videoId) async {
    try {
      final lyrics = await _ytmusic.getLyrics(videoId);
      debugPrint('Plain lyrics: $lyrics');

      if (lyrics != null) {
        return LyricsResponse(lyrics: lyrics, isSynced: false);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching lyrics: $e');
      return null;
    }
  }

  Future<LyricsResponse?> getTimedLyrics(String videoId) async {
    try {
      final timedLyrics = await _ytmusic.getTimedLyrics(videoId);

      if (timedLyrics != null && timedLyrics.timedLyricsData.isNotEmpty) {
        final lrcLines = <String>[];

        for (final lyricData in timedLyrics.timedLyricsData) {
          final startTimeMs = lyricData.cueRange?.startTimeMilliseconds ?? 0;
          final lyricLine = lyricData.lyricLine ?? '';

          final minutes = (startTimeMs / 60000).floor();
          final seconds = ((startTimeMs % 60000) / 1000).floor();
          final centiseconds = ((startTimeMs % 1000) / 10).floor();

          final timeTag =
              '[${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}]';
          lrcLines.add('$timeTag$lyricLine');
        }

        return LyricsResponse(lyrics: lrcLines.join('\n'), isSynced: true);
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching timed lyrics: $e');
      return null;
    }
  }

  Future<LyricsResponse?> getBestLyrics(String videoId) async {
    final timedLyrics = await getTimedLyrics(videoId);
    if (timedLyrics != null) {
      return timedLyrics;
    }

    return await getLyrics(videoId);
  }
}
