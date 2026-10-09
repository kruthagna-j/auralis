import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'yt-stream.dart' as stream_provider;

Future<Map<String, dynamic>> _fetchYoutubeUrl(
  String videoId,
  String streamingQuality,
  bool forDownloading,
) async {
  debugPrint(
    'Fetching from YouTube for videoId: $videoId - current time: ${DateTime.now()}',
  );

  final streamProvider = await stream_provider.StreamProvider.fetch(videoId);

  if (!streamProvider.playable) {
    return {'success': false, 'error': streamProvider.statusMSG};
  }

  if (streamProvider.audioFormats == null ||
      streamProvider.audioFormats!.isEmpty) {
    return {'success': false, 'error': 'No audio streams found'};
  }

  debugPrint(
    'Audio streams found: ${streamProvider.audioFormats!.length} - current time: ${DateTime.now()}',
  );

  stream_provider.Audio? selectedAudio;
  switch (streamingQuality.toLowerCase()) {
    case 'low':
      selectedAudio = streamProvider.lowQualityAudio;
      break;
    case 'medium':
      selectedAudio = streamProvider.highestBitrateMp4aAudio;
      break;
    case 'high':
      selectedAudio = forDownloading
          ? streamProvider.highestBitrateMp4aAudio
          : streamProvider.highestQualityAudio;
      break;
    default:
      selectedAudio = forDownloading
          ? streamProvider.highestBitrateMp4aAudio
          : streamProvider.highestQualityAudio;
      break;
  }

  if (selectedAudio == null) {
    selectedAudio = streamProvider.audioFormats!.first;
  }

  final extension = selectedAudio.audioCodec == stream_provider.Codec.mp4a
      ? 'm4a'
      : 'opus';

  int? expiry;
  try {
    final uri = Uri.parse(selectedAudio.url);
    final expireParam = uri.queryParameters['expire'];
    if (expireParam != null) {
      expiry = int.tryParse(expireParam);
    }
  } catch (_) {}

  return {
    'success': true,
    'url': selectedAudio.url,
    'expiry': expiry,
    'bitrate': selectedAudio.bitrate,
    'size': selectedAudio.size,
    'source': 'youtube',
    'extension': extension,
    'duration': selectedAudio.duration,
  };
}

Future<Map<String, dynamic>> _fetchManifestDirect(
  Map<String, dynamic> params,
) async {
  final token = params['rootIsolateToken'] as RootIsolateToken?;
  if (token != null) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  }

  try {
    final videoId = params['videoId'] as String;
    final streamingQuality = params['streamingQuality'] as String? ?? 'high';
    final forDownloading = params['forDownloading'] as bool? ?? false;

    return await _fetchYoutubeUrl(
      videoId,
      streamingQuality,
      forDownloading,
    );
  } catch (e) {
    debugPrint('Error fetching YouTube manifest: $e');
    return {'success': false, 'error': e.toString()};
  }
}

class AudioUrlIsolate {
  static final Map<String, Completer<Map<String, dynamic>>> _activeRequests =
      {};

  static Future<Map<String, dynamic>> fetchStreamUrl({
    required String videoId,
    required String streamingQuality,
    required Duration timeout,
    bool allowCancellation = true,
    String? title,
    String? artist,
    bool forDownloading = false,
    bool jioSaavnEnabled = true,
  }) async {
    if (_activeRequests.containsKey(videoId)) {
      if (allowCancellation) {
        _activeRequests[videoId]?.completeError(
          Exception('Request cancelled for new request'),
        );
        _activeRequests.remove(videoId);
      } else {
        try {
          return await _activeRequests[videoId]!.future;
        } catch (e) {}
      }
    }

    final completer = Completer<Map<String, dynamic>>();
    _activeRequests[videoId] = completer;

    try {
      final result = await compute(_fetchManifestDirect, {
        'videoId': videoId,
        'streamingQuality': streamingQuality,
        'forDownloading': forDownloading,
        'rootIsolateToken': RootIsolateToken.instance,
      }).timeout(timeout);

      if (!completer.isCompleted) {
        completer.complete(result);
      }
      return result;
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      rethrow;
    } finally {
      _activeRequests.remove(videoId);
    }
  }

  static Future<void> cancelRequest(String videoId) async {
    final completer = _activeRequests[videoId];
    if (completer != null && !completer.isCompleted) {
      completer.completeError(Exception('Request cancelled'));
    }
    _activeRequests.remove(videoId);
  }

  static Future<void> cancelAllRequests() async {
    for (final videoId in _activeRequests.keys.toList()) {
      final completer = _activeRequests[videoId];
      if (completer != null && !completer.isCompleted) {
        completer.completeError(Exception('All requests cancelled'));
      }
    }
    _activeRequests.clear();
  }

  static int get activeRequestCount => _activeRequests.length;

  static bool isRequestActive(String videoId) =>
      _activeRequests.containsKey(videoId);
}