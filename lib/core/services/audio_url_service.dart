import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song_model.dart';
import '../providers/download_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/connectivity_provider.dart';
import 'player_service.dart';
import 'audio_url_isolate.dart';

class AudioUrlService {
  AudioUrlService(DownloadProvider downloadProvider);

  static const String _cacheKeySeparator = '|';
  static const String _cacheQualityPrefix = 'q=';
  static const String _cacheProviderPrefix = 'p=';
  static const int _cacheEntryVersion = 2;
  static const int _fallbackNoExpiryTtlSeconds = 6 * 60 * 60;

  Box<String> get audioCacheBox => Hive.box<String>('audio_url_cache');

  static String normalizeProvider(String provider) {
    final normalized = provider.toLowerCase().trim();
    if (normalized.contains('saavn')) {
      return 'jiosaavn';
    }
    return 'youtube';
  }

  static String normalizeQuality(String quality) {
    return quality.toLowerCase().trim();
  }

  static String buildCacheKey({
    required String videoId,
    required String streamingQuality,
    required String provider,
  }) {
    final quality = normalizeQuality(streamingQuality);
    final source = normalizeProvider(provider);
    return [
      videoId,
      '$_cacheQualityPrefix$quality',
      '$_cacheProviderPrefix$source',
    ].join(_cacheKeySeparator);
  }

  static List<String> buildLookupCacheKeys({
    required String videoId,
    required String streamingQuality,
    required bool jioSaavnEnabled,
  }) {
    final keys = <String>[];
    if (jioSaavnEnabled) {
      keys.add(
        buildCacheKey(
          videoId: videoId,
          streamingQuality: streamingQuality,
          provider: 'jiosaavn',
        ),
      );
    }
    keys.add(
      buildCacheKey(
        videoId: videoId,
        streamingQuality: streamingQuality,
        provider: 'youtube',
      ),
    );
    return keys;
  }

  ConnectivityProvider? get connectivityProvider {
    try {
      return GetIt.I<ConnectivityProvider>();
    } catch (e) {
      return null;
    }
  }

  int? parseExpiryFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final expireParam = uri.queryParameters['expire'];
      if (expireParam != null) {
        return int.tryParse(expireParam);
      }
    } catch (_) {}
    return null;
  }

  int _computeCacheExpiry({required String url, required int? explicitExpiry}) {
    if (explicitExpiry != null) {
      return explicitExpiry;
    }

    final parsedExpiry = parseExpiryFromUrl(url);
    if (parsedExpiry != null) {
      return parsedExpiry;
    }

    final nowEpoch = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return nowEpoch + _fallbackNoExpiryTtlSeconds;
  }

  bool isCachedUrlValid(String cacheKey, {int bufferSeconds = 30}) {
    final jsonStr = audioCacheBox.get(cacheKey);
    if (jsonStr == null) return false;
    try {
      final Map<String, dynamic> data =
          json.decode(jsonStr) as Map<String, dynamic>;
      final url = data['url'] as String?;
      final expiry = data['expiry'] as int?;
      if (url == null) return false;
      if (expiry == null) return true;
      final nowEpoch = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      return (expiry - bufferSeconds) > nowEpoch;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getAudioUrl(
    SongInfo song, {
    bool isPreloading = false,
    bool forceRefresh = false,
    int maxRetries = 1,
    Duration initialDelay = const Duration(seconds: 1),
    Completer<bool>? completer,
  }) async {
    if (completer != null && completer.isCompleted) {
      throw CanceledException('Audio URL fetch cancelled before start');
    }

    final settingsProvider = GetIt.I<SettingsProvider>();
    final streamingQuality = settingsProvider.streamingQuality;
    final lookupKeys = buildLookupCacheKeys(
      videoId: song.videoId,
      streamingQuality: streamingQuality,
      jioSaavnEnabled: settingsProvider.jioSaavnEnabled,
    );

    // YouTube CDN URLs are signed and short-lived. Never reuse a previously
    // resolved YouTube URL for playback; always resolve a fresh URL.
    // Cached audio files are handled separately by TempAudioCacheService.
    if (forceRefresh) {
      for (final cacheKey in lookupKeys) {
        await audioCacheBox.delete(cacheKey);
      }
    } else if (settingsProvider.jioSaavnEnabled) {
      for (final cacheKey in lookupKeys) {
        final cachedJson = audioCacheBox.get(cacheKey);
        if (cachedJson == null) {
          continue;
        }
        try {
          final Map<String, dynamic> data =
              json.decode(cachedJson) as Map<String, dynamic>;
          final cachedUrl = data['url'] as String?;
          final expiry = data['expiry'] as int?;
          final cachedDuration = data['duration'] as int?;
          final cachedProvider = normalizeProvider(
            data['source'] as String? ?? 'youtube',
          );
          if (cachedProvider == 'jiosaavn' &&
              cachedUrl != null &&
              (expiry == null || isCachedUrlValid(cacheKey))) {
            debugPrint('Using cached URL for ${song.name} - $cacheKey');
            return {'url': cachedUrl, 'duration': cachedDuration};
          }
          await audioCacheBox.delete(cacheKey);
        } catch (_) {
          await audioCacheBox.delete(cacheKey);
        }
      }
    } else {
      // Remove any old signed YouTube URL left by previous app versions.
      for (final cacheKey in lookupKeys) {
        await audioCacheBox.delete(cacheKey);
      }
    }

    if (!(connectivityProvider?.canPerformNetworkOperations() ?? false)) {
      debugPrint(
        'No internet connection - cannot fetch audio URL for ${song.videoId}',
      );
      return null;
    }

    debugPrint(
      'Fetching stream URL in isolate for ${song.name} - ${song.videoId} (preloading: $isPreloading)',
    );

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      if (completer != null && completer.isCompleted) {
        throw CanceledException('Audio URL fetch cancelled during retry');
      }

      try {
        final result = await AudioUrlIsolate.fetchStreamUrl(
          videoId: song.videoId,
          streamingQuality: streamingQuality,
          timeout: Duration(seconds: isPreloading ? 20 : 20),
          allowCancellation: true,
          title: song.name,
          artist: song.artists.map((a) => a.name).join(', '),
          jioSaavnEnabled: settingsProvider.jioSaavnEnabled,
        );

        if (result['success'] == true) {
          final audioUrl = result['url'] as String;
          final explicitExpiry = result['expiry'] as int?;
          final duration = result['duration'] as int?;
          final source = normalizeProvider(
            result['source'] as String? ??
                (audioUrl.contains('saavn') ? 'jiosaavn' : 'youtube'),
          );
          final expiry = _computeCacheExpiry(
            url: audioUrl,
            explicitExpiry: explicitExpiry,
          );
          final cacheKey = buildCacheKey(
            videoId: song.videoId,
            streamingQuality: streamingQuality,
            provider: source,
          );

          final Map<String, dynamic> storeData = {
            'url': audioUrl,
            'source': source,
            'keyVersion': _cacheEntryVersion,
            'expiry': expiry,
          };
          if (duration != null) storeData['duration'] = duration;

          // Do not persist signed YouTube CDN URLs. They can become stale even
          // when their expire parameter has not yet been reached.
          if (source == 'jiosaavn') {
            await audioCacheBox.put(cacheKey, json.encode(storeData));
          } else {
            await audioCacheBox.delete(cacheKey);
          }

          debugPrint(
            'Successfully fetched stream URL for ${song.name} - ${song.videoId}',
          );
          return {'url': audioUrl, 'duration': duration};
        } else {
          final error = result['error'] as String?;
          throw Exception(error ?? 'Unknown error from isolate');
        }
      } catch (e) {
        debugPrint(
          'Error getting audio URL for ${song.videoId} (attempt ${attempt + 1}): $e',
        );

        if (e is! CanceledException) {
          AudioUrlIsolate.cancelRequest(song.videoId).catchError((_) {});
        }

        if (attempt < maxRetries - 1) {
          final delay = initialDelay * (1 << attempt);
          await Future.delayed(delay);
        }
      }
    }

    debugPrint('All retries failed for ${song.videoId}');
    return null;
  }

  AudioOnlyStreamInfo getStreamQuality(StreamManifest manifest) {
    final settingsProvider = GetIt.I<SettingsProvider>();
    final streamInfos = manifest.audioOnly
        .where((stream) => stream.container == StreamContainer.mp4)
        .sortByBitrate()
        .reversed
        .toList();

    switch (settingsProvider.streamingQuality.toLowerCase()) {
      case 'low':
        return streamInfos.first;
      case 'medium':
        return streamInfos[streamInfos.length ~/ 2];
      case 'high':
      default:
        return streamInfos.last;
    }
  }
}
