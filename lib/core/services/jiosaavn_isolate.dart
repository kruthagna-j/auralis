import 'dart:async';
import 'package:flutter/foundation.dart';

import 'dart:isolate';
import 'package:get_it/get_it.dart';
import 'package:jiosaavn/jiosaavn.dart';

double _calculateArtistScore(String inputArtistStr, dynamic songArtists) {
  List<String> songArtistsList = [];
  if (songArtists is List) {
    songArtistsList = songArtists.map((e) => e.toString()).toList();
  } else if (songArtists is String) {
    songArtistsList = songArtists.split(', ').map((e) => e.trim()).toList();
  } else {
    return 0.0;
  }

  if (songArtistsList.isEmpty) return 0.0;

  final inputArtists = inputArtistStr.split(', ').map((a) => a.trim()).toList();

  double maxScore = 0.0;
  for (final inputArtist in inputArtists) {
    for (final songArtist in songArtistsList) {
      final score = _calculateSimilarity(inputArtist, songArtist);
      if (score > maxScore) maxScore = score;
    }
  }
  return maxScore;
}

Future<Map<String, dynamic>> _searchJioSaavnIsolate(
  Map<String, dynamic> params,
) async {
  try {
    final title = params['title'] as String;
    final artist = params['artist'] as String;

    JioSaavnClient jioSaavn;
    if (!GetIt.I.isRegistered<JioSaavnClient>()) {
      GetIt.I.registerSingleton<JioSaavnClient>(JioSaavnClient());
    }
    jioSaavn = GetIt.I<JioSaavnClient>();

    final inputArtists = artist.split(', ');
    final firstArtist = inputArtists.isNotEmpty
        ? inputArtists.first.trim()
        : '';
    final searchQuery = '$title $firstArtist';
    final response = await jioSaavn.search.songs(searchQuery, limit: 10);

    if (response.results == null || response.results!.isEmpty) {
      return {'success': false, 'error': 'No songs found'};
    }

    SongResponse? bestMatch;
    double bestScore = 0.0;

    for (final song in response.results!) {
      final titleScore = _calculateSimilarity(title, song.name ?? '');
      final artistScore = _calculateArtistScore(artist, song.primaryArtists);
      final score = (titleScore + artistScore) / 2.0;

      final primaryArtists = song.primaryArtists;
      String artistsDisplay;
      if (primaryArtists is List) {
        final list = primaryArtists as List;
        artistsDisplay = list.join(', ');
      } else {
        artistsDisplay = primaryArtists?.toString() ?? 'Unknown';
      }
      debugPrint(
        'JioSaavn match attempt - Song: ${song.name} by $artistsDisplay - TitleScore: ${titleScore.toStringAsFixed(2)}, ArtistScore: ${artistScore.toStringAsFixed(2)}, Total: ${score.toStringAsFixed(2)}',
      );

      if (score > bestScore && score >= 0.7) {
        bestMatch = song;
        bestScore = score;
      }
    }

    if (bestMatch == null) {
      return {'success': false, 'error': 'No suitable match found'};
    }

    final downloadUrl = _getBestDownloadUrl(bestMatch);
    if (downloadUrl == null) {
      return {'success': false, 'error': 'No download URL available'};
    }

    int? durationMs;
    try {
      final durationSec = int.tryParse(bestMatch.duration);
      if (durationSec != null && durationSec > 0) {
        durationMs = durationSec * 1000;
      }
    } catch (_) {}

    return {
      'success': true,
      'url': downloadUrl,
      'song': bestMatch.toJson(),
      'similarity_score': bestScore,
      'duration': durationMs,
    };
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

double _calculateSimilarity(String title1, String title2) {
  final normalized1 = _normalizeTitle(title1);
  final normalized2 = _normalizeTitle(title2);

  if (normalized1.isEmpty || normalized2.isEmpty) return 0.0;

  final distance = _levenshteinDistance(normalized1, normalized2);
  final maxLength = normalized1.length > normalized2.length
      ? normalized1.length
      : normalized2.length;

  return 1.0 - (distance / maxLength);
}

String _normalizeTitle(String title) {
  return title
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .replaceAll(
        RegExp(
          r'\b(official|video|audio|music|song|track|remix|cover|live|feat|ft|with)\b',
        ),
        '',
      )
      .trim();
}

int _levenshteinDistance(String s1, String s2) {
  if (s1 == s2) return 0;
  if (s1.isEmpty) return s2.length;
  if (s2.isEmpty) return s1.length;

  final matrix = List.generate(
    s1.length + 1,
    (i) => List.filled(s2.length + 1, 0),
  );

  for (var i = 0; i <= s1.length; i++) {
    matrix[i][0] = i;
  }
  for (var j = 0; j <= s2.length; j++) {
    matrix[0][j] = j;
  }

  for (var i = 1; i <= s1.length; i++) {
    for (var j = 1; j <= s2.length; j++) {
      final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
      matrix[i][j] = [
        matrix[i - 1][j] + 1,
        matrix[i][j - 1] + 1,
        matrix[i - 1][j - 1] + cost,
      ].reduce((a, b) => a < b ? a : b);
    }
  }

  return matrix[s1.length][s2.length];
}

String? _getBestDownloadUrl(SongResponse song) {
  if (song.downloadUrl == null || song.downloadUrl!.isEmpty) {
    return null;
  }

  final qualityOrder = ['320kbps', '160kbps', '96kbps', '48kbps'];

  for (final quality in qualityOrder) {
    try {
      final url = song.downloadUrl!.firstWhere((e) => e.quality == quality);
      return url.link;
    } catch (_) {
      continue;
    }
  }

  return song.downloadUrl!.first.link;
}

class JioSaavnIsolate {
  static final Map<String, Completer<Map<String, dynamic>>> _activeRequests =
      {};

  static Future<Map<String, dynamic>> searchSong({
    required String title,
    required String artist,
    required Duration timeout,
    bool allowCancellation = true,
  }) async {
    final requestKey = '${title}_${artist}';

    if (_activeRequests.containsKey(requestKey)) {
      if (allowCancellation) {
        _activeRequests[requestKey]?.completeError(
          Exception('Request cancelled for new request'),
        );
        _activeRequests.remove(requestKey);
      } else {
        try {
          return await _activeRequests[requestKey]!.future;
        } catch (e) {}
      }
    }

    final completer = Completer<Map<String, dynamic>>();
    _activeRequests[requestKey] = completer;

    try {
      final result = await Isolate.run(
        () => _searchJioSaavnIsolate({'title': title, 'artist': artist}),
      ).timeout(timeout);

      completer.complete(result);
      return result;
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      rethrow;
    } finally {
      _activeRequests.remove(requestKey);
    }
  }

  static Future<void> cancelRequest(String title, String artist) async {
    final requestKey = '${title}_${artist}';
    final completer = _activeRequests[requestKey];
    if (completer != null && !completer.isCompleted) {
      completer.completeError(Exception('Request cancelled'));
    }
    _activeRequests.remove(requestKey);
  }

  static Future<void> cancelAllRequests() async {
    for (final requestKey in _activeRequests.keys.toList()) {
      final completer = _activeRequests[requestKey];
      if (completer != null && !completer.isCompleted) {
        completer.completeError(Exception('All requests cancelled'));
      }
    }
    _activeRequests.clear();
  }

  static int get activeRequestCount => _activeRequests.length;

  static bool isRequestActive(String title, String artist) =>
      _activeRequests.containsKey('${title}_${artist}');
}
