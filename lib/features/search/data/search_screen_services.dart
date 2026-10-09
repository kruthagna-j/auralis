import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:get_it/get_it.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Thumbnail;

import '../../../core/models/song_model.dart';
import '../../../core/services/related_song_service.dart';
import '../../../core/services/settings_storage_service.dart';
import '../../../core/services/yt-music-api.dart' as ytApi;

enum SearchMode { youtubeMusic, youtube }

class YouTubeApiVideoId {
  final String value;
  const YouTubeApiVideoId(this.value);
}

class YouTubeApiThumbnail {
  final String lowResUrl;
  final String highResUrl;
  const YouTubeApiThumbnail(this.lowResUrl, this.highResUrl);
}

class YouTubeApiVideo {
  final YouTubeApiVideoId id;
  final String title;
  final String author;
  final YouTubeApiVideoId channelId;
  final List<YouTubeApiThumbnail> thumbnails;

  const YouTubeApiVideo({
    required this.id,
    required this.title,
    required this.author,
    required this.channelId,
    required this.thumbnails,
  });
}

class SearchScreenServices {
  final YTMusic _ytMusic = GetIt.I<YTMusic>();
  final YoutubeExplode _yt = GetIt.I<YoutubeExplode>();
  final RelatedSongService _relatedSongService = RelatedSongService();

  final ValueNotifier<bool> isLoadingRelatedSongsNotifier = ValueNotifier(
    false,
  );

  static const String SEARCH_HISTORY_KEY = 'search_history';
  static const String SEARCH_HISTORY_ENABLED_KEY = 'searchHistoryEnabled';
  static const int _maxSearchQueueSize = 250;
  static const int _initialRadioBatchLimit = 50;
  static const int _extraRadioFetchCount = 6;
  static const int _maxExpandedSearchQueries = 5;

  Future<List<String>> loadSearchHistory() async {
    final box = await SettingsStorageService.getBox();
    final isEnabled = (box.get(SEARCH_HISTORY_ENABLED_KEY) as bool?) ?? true;
    if (!isEnabled) return [];
    return (box.get(SEARCH_HISTORY_KEY) as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
  }

  Future<void> saveSearchHistory(List<String> history) async {
    final box = await SettingsStorageService.getBox();
    final isEnabled = (box.get(SEARCH_HISTORY_ENABLED_KEY) as bool?) ?? true;
    if (isEnabled) {
      await box.put(SEARCH_HISTORY_KEY, history);
    }
  }

  Future<List<String>> addToSearchHistory(
    List<String> history,
    String query,
  ) async {
    if (query.trim().isEmpty) return history;

    final updatedHistory = List<String>.from(history)
      ..remove(query)
      ..insert(0, query);

    if (updatedHistory.length > 10) {
      updatedHistory.removeRange(10, updatedHistory.length);
    }

    await saveSearchHistory(updatedHistory);
    return updatedHistory;
  }

  Future<List<String>> removeFromSearchHistory(
    List<String> history,
    String query,
  ) async {
    final updatedHistory = List<String>.from(history)..remove(query);
    await saveSearchHistory(updatedHistory);
    return updatedHistory;
  }

  Future<List<dynamic>> fetchQuickSongs(String query) async {
    try {
      final songs = await _ytMusic.searchSongs(query);
      return songs.take(5).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> fetchSearchSuggestions(
    String query,
    SearchMode mode,
  ) async {
    if (query.trim().isEmpty) return [];

    try {
      if (mode == SearchMode.youtube) {
        if (query.length < 3) return [];
        final suggestions = await _yt.search.getQuerySuggestions(query);
        return suggestions.take(5).toList();
      } else {
        final suggestions = await _ytMusic.getSearchSuggestions(query);
        return suggestions.take(5).toList();
      }
    } catch (e) {
      return [];
    }
  }

  static const String _youtubeDataApiKey = String.fromEnvironment(
    'YOUTUBE_DATA_API_KEY',
    defaultValue: 'AIzaSyDinkyCxfLI-K4RtXnDck-PG9Ivi2jDdQY',
  );

  Future<List<dynamic>> fetchYouTubeVideos(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await Dio().get(
        'https://www.googleapis.com/youtube/v3/search',
        queryParameters: {
          'part': 'snippet',
          'q': query.trim(),
          'type': 'video',
          'maxResults': 25,
          'regionCode': 'IN',
          'videoEmbeddable': 'true',
          'videoSyndicated': 'true',
          'key': _youtubeDataApiKey,
        },
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) return [];

      final items = data['items'];
      if (items is! List) return [];

      return items.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final idMap = Map<String, dynamic>.from(
          (map['id'] as Map?) ?? const <String, dynamic>{},
        );
        final snippet = Map<String, dynamic>.from(
          (map['snippet'] as Map?) ?? const <String, dynamic>{},
        );
        final thumbnails = Map<String, dynamic>.from(
          (snippet['thumbnails'] as Map?) ?? const <String, dynamic>{},
        );

        String thumbUrl(String key) {
          final thumb = thumbnails[key];
          if (thumb is Map && thumb['url'] != null) {
            return thumb['url'].toString();
          }
          return '';
        }

        final videoId = idMap['videoId']?.toString() ?? '';
        final channelId = snippet['channelId']?.toString() ?? '';

        return YouTubeApiVideo(
          id: YouTubeApiVideoId(videoId),
          title: snippet['title']?.toString() ?? 'Unknown title',
          author: snippet['channelTitle']?.toString() ?? 'YouTube',
          channelId: YouTubeApiVideoId(channelId),
          thumbnails: [
            YouTubeApiThumbnail(
              thumbUrl('default').isNotEmpty
                  ? thumbUrl('default')
                  : thumbUrl('medium'),
              thumbUrl('high').isNotEmpty
                  ? thumbUrl('high')
                  : thumbUrl('medium'),
            ),
          ],
        );
      }).where((video) => video.id.value.isNotEmpty).toList();
    } catch (e) {
      debugPrint('YouTube Data API search failed: $e');
      return [];
    }
  }

  List<String> _buildExpandedSearchQueries(String query) {
    final normalized = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return [];

    final words = normalized
        .split(' ')
        .map((word) => word.trim())
        .where((word) => word.length >= 2)
        .toList();

    final queries = <String>[normalized];

    if (words.length >= 2) {
      queries.add(words.take(2).join(' '));
      queries.add(words.reversed.take(2).toList().reversed.join(' '));
    }

    for (final word in words) {
      if (queries.length >= _maxExpandedSearchQueries) break;
      if (!queries.contains(word)) queries.add(word);
    }

    return queries.take(_maxExpandedSearchQueries).toList();
  }

  List<dynamic> _mergeUniqueResults(Iterable<List<dynamic>> resultLists) {
    final merged = <dynamic>[];
    final seen = <String>{};

    for (final results in resultLists) {
      for (final result in results) {
        String? key;
        try {
          key = result.videoId?.toString();
        } catch (_) {}
        if (key == null || key.isEmpty) {
          try {
            key = result.albumId?.toString();
          } catch (_) {}
        }
        if (key == null || key.isEmpty) {
          try {
            key = result.artistId?.toString();
          } catch (_) {}
        }
        if (key == null || key.isEmpty) {
          try {
            key = result.playlistId?.toString();
          } catch (_) {}
        }
        key ??= result.toString();

        if (seen.add(key)) merged.add(result);
      }
    }

    return merged;
  }

  Future<Map<String, List<dynamic>>> performSearch(
    String query,
    SearchMode mode,
  ) async {
    if (query.trim().isEmpty) {
      if (mode == SearchMode.youtube) {
        return {'Videos': []};
      } else {
        return {'Songs': [], 'Albums': [], 'Artists': [], 'Playlists': []};
      }
    }

    if (mode == SearchMode.youtube) {
      final videos = await fetchYouTubeVideos(query);
      return {'Videos': videos};
    }

    final expandedQueries = _buildExpandedSearchQueries(query);

    final songResults = await Future.wait(
      expandedQueries.map((q) async {
        try {
          return await _ytMusic.searchSongs(q);
        } catch (_) {
          return <dynamic>[];
        }
      }),
    );

    final albumResults = await Future.wait(
      expandedQueries.take(3).map((q) async {
        try {
          return await _ytMusic.searchAlbums(q);
        } catch (_) {
          return <dynamic>[];
        }
      }),
    );

    final artistResults = await Future.wait(
      expandedQueries.take(3).map((q) async {
        try {
          return await _ytMusic.searchArtists(q);
        } catch (_) {
          return <dynamic>[];
        }
      }),
    );

    final playlistResults = await Future.wait(
      expandedQueries.take(3).map((q) async {
        try {
          return await _ytMusic.searchPlaylists(q);
        } catch (_) {
          return <dynamic>[];
        }
      }),
    );

    return {
      'Songs': _mergeUniqueResults(songResults),
      'Albums': _mergeUniqueResults(albumResults),
      'Artists': _mergeUniqueResults(artistResults),
      'Playlists': _mergeUniqueResults(playlistResults),
    };
  }

  Future<void> playSong(
    dynamic song,
    dynamic playerProvider,
    dynamic queueProvider,
  ) async {
    try {
      isLoadingRelatedSongsNotifier.value = false;

      final songInfo = SongInfo(
        videoId: song.videoId,
        name: song.name,
        artists: [
          Artist(name: song.artist.name, id: song.artist.artistId ?? ''),
        ],
        thumbnails: (song.thumbnails as List)
            .map((t) => Thumbnail(url: t.url, width: t.width, height: t.height))
            .toList(),
        duration: Duration(seconds: song.duration ?? 0),
      );

      await playerProvider.playerService.playSong(songInfo);

      List<SongInfo> songsList;
      dynamic isYouTube;
      try {
        isYouTube = song.isYouTube;
      } catch (e) {
        isYouTube = false;
      }
      if (isYouTube) {
        // YouTube
        songsList = await _relatedSongService.createSongListWithRelated(
          songInfo,
          song.videoId,
        );
        final songIndex = songsList.indexWhere(
          (s) => s.videoId == song.videoId,
        );
        queueProvider.setQueue(
          songsList,
          currentIndex: songIndex,
          playlistId: 'search_results',
          playlistName: 'Search Results',
        );
      } else {
        // YouTube Music
        songsList = await _buildExpandedRadioQueueIncremental(
          currentSong: songInfo,
          seedVideoId: song.videoId,
          queueProvider: queueProvider,
        );
      }
      isLoadingRelatedSongsNotifier.value = false;
    } catch (e) {
      throw Exception('Failed to play song: $e');
    }
  }

  Future<List<SongInfo>> _buildExpandedRadioQueueIncremental({
    required SongInfo currentSong,
    required String seedVideoId,
    required dynamic queueProvider,
  }) async {
    final random = Random();
    final seenVideoIds = <String>{};
    var songs = <SongInfo>[];

    List<SongInfo> getUniqueSongs(Iterable<SongInfo> incoming) {
      final unique = <SongInfo>[];
      for (final item in incoming) {
        if (item.videoId.isEmpty || seenVideoIds.contains(item.videoId)) {
          continue;
        }
        seenVideoIds.add(item.videoId);
        unique.add(item);
        if (seenVideoIds.length >= _maxSearchQueueSize) {
          break;
        }
      }
      return unique;
    }

    seenVideoIds.add(currentSong.videoId);
    queueProvider.setQueue(
      [currentSong],
      currentIndex: 0,
      playlistId: 'search_results',
      playlistName: 'Search Results',
    );
    songs = List<SongInfo>.from(queueProvider.queue);

    final initialRadioData = await ytApi.getRadioSongs(
      seedVideoId,
      limit: _initialRadioBatchLimit,
    );
    final initialUniqueSongs = getUniqueSongs(
      _mapRadioTracksToSongInfo(initialRadioData['tracks'] as List),
    );
    if (initialUniqueSongs.isNotEmpty) {
      queueProvider.addAllToQueue(initialUniqueSongs);
      songs = List<SongInfo>.from(queueProvider.queue);
    }

    for (
      var i = 0;
      i < _extraRadioFetchCount && songs.length < _maxSearchQueueSize;
      i++
    ) {
      if (songs.isEmpty) break;

      final randomSeedSong = songs[random.nextInt(songs.length)];
      try {
        final extraRadioData = await ytApi.getRadioSongs(
          randomSeedSong.videoId,
          limit: _initialRadioBatchLimit,
        );
        final extraUniqueSongs = getUniqueSongs(
          _mapRadioTracksToSongInfo(extraRadioData['tracks'] as List),
        );
        if (extraUniqueSongs.isNotEmpty) {
          queueProvider.addAllToQueue(extraUniqueSongs);
          songs = List<SongInfo>.from(queueProvider.queue);
        }
      } catch (e) {
        debugPrint(
          'Extra radio fetch failed for ${randomSeedSong.videoId}: $e',
        );
      }
    }

    return songs.take(_maxSearchQueueSize).toList();
  }

  List<SongInfo> _mapRadioTracksToSongInfo(List tracks) {
    return tracks.map((track) {
      final trackArtists = track['artists'] as List?;
      final thumbnails = track['thumbnails'] as List?;
      return SongInfo(
        videoId: track['videoId'] ?? '',
        name: track['title'] ?? 'Unknown Title',
        artists:
            trackArtists
                ?.map(
                  (a) => Artist(
                    name: a['name'] ?? 'Unknown Artist',
                    id: a['id'] ?? '',
                  ),
                )
                ?.toList() ??
            [Artist(name: 'Unknown Artist', id: '')],
        thumbnails: [
          Thumbnail(
            url: (thumbnails?.isNotEmpty ?? false)
                ? (thumbnails!.last['url'] ?? '')
                : '',
            width: 1280,
            height: 720,
          ),
        ],
        duration: Duration(seconds: track['duration_seconds'] ?? 0),
      );
    }).toList();
  }
}
