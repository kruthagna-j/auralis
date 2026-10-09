import 'dart:async';
import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import '../models/song_model.dart';
import '../services/custom_audio_handler.dart';
import '../services/player_service.dart';
import 'queued_provider.dart';
import 'download_provider.dart';
import 'video_info_provider.dart';
import 'stats_provider.dart';
import 'favorite_song_provider.dart';

class PlayerProvider extends ChangeNotifier {
  late PlayerService _playerService;
  SongInfo? _currentSong;
  SongInfo? _lastPlayedSong;
  Map<String, dynamic>? _lastPlayedSongData;
  Map<String, dynamic>? _currentLocalSong;
  List<Map<String, dynamic>> _lastPlayedSongs = [];
  static const int maxLastPlayed = 1000;
  List<Map<String, dynamic>> _recentPlaylists = [];
  static const int maxRecentPlaylists = 30;
  CachedVideoInfo? _currentVideoDetails;

  bool _isInitialized = false;
  bool isLoadingLastPlayedSongs = true;

  final QueueProvider _queueProvider;
  final DownloadProvider _downloadProvider;
  final VideoInfoProvider _videoInfoProvider;
  final StatsProvider _statsProvider;
  final FavoriteSongProvider _favoriteSongProvider;

  PlayerProvider(
    this._queueProvider,
    this._downloadProvider,
    this._videoInfoProvider,
    this._statsProvider,
    this._favoriteSongProvider,
  ) {
    initialize();
    _queueProvider.addListener(_onQueueChanged);
  }

  ValueNotifier<Duration?> get sleepTimerRemaining =>
      _playerService.sleepTimerRemaining;
  bool get isSleepTimerActive => _playerService.isSleepTimerActive;

  Future<void> startSleepTimer(Duration duration, {bool fade = false}) async {
    await _playerService.startSleepTimer(duration, fade: fade);
    notifyListeners();
  }

  Future<void> startSleepTimerUntilEndOfTrack({bool fade = false}) async {
    await _playerService.startSleepTimerUntilEndOfTrack(fade: fade);
    notifyListeners();
  }

  Future<void> cancelSleepTimer() async {
    await _playerService.cancelSleepTimer();
    notifyListeners();
  }

  Future<void> initialize() async {
    if (!_isInitialized) {
      isLoadingLastPlayedSongs = true;
      notifyListeners();

      _playerService = PlayerService(
        this,
        _queueProvider,
        _downloadProvider,
        _statsProvider,
      );

      _queueProvider.setPlayerService(_playerService);
      await _initializeAudioService();

      await _queueProvider.loadQueue();

      if (_queueProvider.isShuffleEnabled) {
        await _playerService.setShuffleMode(true);
      }
      if (_queueProvider.isRepeatEnabled) {
        await _playerService.setLoopMode(_queueProvider.repeatMode);
      }

      if (_queueProvider.playlistId == 'local_music') {
        _queueProvider.clearQueue();
        _queueProvider.setPlaylistId('');
      }

      await _loadLastPlayed();
      await _loadRecentPlaylists();
      if (_lastPlayedSong != null && _queueProvider.queue.isEmpty) {
        _queueProvider.addToQueue(_lastPlayedSong!);
        _queueProvider.setCurrentIndex(0);
        _currentSong = _lastPlayedSong;
        await _playerService.loadSong(_lastPlayedSong!);
        await _fetchAndSetVideoDetails(_lastPlayedSong!.videoId);
      } else if (_lastPlayedSong != null && _queueProvider.queue.isNotEmpty) {
        int songIndex = _queueProvider.queue.indexWhere(
          (s) => s.videoId == _lastPlayedSong!.videoId,
        );
        if (songIndex != -1) {
          _queueProvider.setCurrentIndex(songIndex);
          _currentSong = _lastPlayedSong;
          await _playerService.loadSong(_lastPlayedSong!);
          await _fetchAndSetVideoDetails(_lastPlayedSong!.videoId);
        } else {
          _queueProvider.addToQueue(_lastPlayedSong!);
          _queueProvider.setCurrentIndex(_queueProvider.queue.length - 1);
          _currentSong = _lastPlayedSong;
          await _playerService.loadSong(_lastPlayedSong!);
          await _fetchAndSetVideoDetails(_lastPlayedSong!.videoId);
        }
      }
      _isInitialized = true;
      isLoadingLastPlayedSongs = false;
      notifyListeners();
    }
  }

  CachedVideoInfo? get currentVideoDetails => _currentVideoDetails;

  Future<void> _initializeAudioService() async {
    try {
      await AudioService.init(
        builder: () => CustomAudioHandler(
          _playerService,
          _queueProvider,
          this,
          _favoriteSongProvider,
        ),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.auralis.app',
          androidNotificationChannelName: 'Auralis Playback',
          androidStopForegroundOnPause: true,
          androidShowNotificationBadge: true,
          androidNotificationOngoing: false,
          androidNotificationIcon: 'mipmap/ic_launcher_monochrome',
        ),
      );
      debugPrint('AudioService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AudioService: $e');
    }
  }

  void _onQueueChanged() {
    if (_queueProvider.queue.isNotEmpty &&
        _queueProvider.currentIndex >= 0 &&
        _queueProvider.currentIndex < _queueProvider.queue.length) {
      final queueCurrentSong =
          _queueProvider.queue[_queueProvider.currentIndex];

      if (_currentSong?.videoId != queueCurrentSong.videoId) {
        if (_queueProvider.playlistId == 'local_music' ||
            _currentLocalSong != null) {
          notifyListeners();
          return;
        }

        _currentSong = queueCurrentSong;
        _lastPlayedSong = queueCurrentSong;
        _favoriteSongProvider.setCurrentSong(queueCurrentSong);

        if (_currentLocalSong == null) {
          final songData = {
            'id': queueCurrentSong.videoId,
            'title': queueCurrentSong.name,
            'thumbnail': queueCurrentSong.thumbnails.isNotEmpty
                ? queueCurrentSong.thumbnails.last.url
                : '',
            'artists': queueCurrentSong.artists
                .map((a) => {'name': a.name, 'id': a.id})
                .toList(),
            'duration': queueCurrentSong.duration.inSeconds,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'isLocal': false,
            'playlistId': _queueProvider.playlistId,
            'playlistName': _queueProvider.playlistName,
          };
          _updateLastPlayed(songData);
          _fetchAndSetVideoDetails(queueCurrentSong.videoId);
        } else {
          notifyListeners();
        }
      }
    }
  }

  Future<void> setCurrentSong(SongInfo song) async {
    debugPrint(
      'Setting current song: ${song.name} by ${song.artists.map((a) => a.name).join(", ")}',
    );
    final cleanedArtists = song.artists.map((artist) {
      final cleanedName = artist.name.endsWith(' - Topic')
          ? artist.name.substring(0, artist.name.length - ' - Topic'.length)
          : artist.name;
      return Artist(name: cleanedName, id: artist.id);
    }).toList();
    final cleanedSong = SongInfo(
      videoId: song.videoId,
      name: song.name,
      artists: cleanedArtists,
      thumbnails: song.thumbnails,
      duration: song.duration,
    );

    _currentSong = cleanedSong;
    _lastPlayedSong = cleanedSong;
    _favoriteSongProvider.setCurrentSong(cleanedSong);
    _currentLocalSong = null;

    int songIndex = _queueProvider.queue.indexWhere(
      (s) => s.videoId == cleanedSong.videoId,
    );
    if (songIndex == -1) {
      _queueProvider.addToQueue(cleanedSong);
      songIndex = _queueProvider.queue.length - 1;
    }
    _queueProvider.setCurrentIndex(songIndex);

    final songData = {
      'id': cleanedSong.videoId,
      'title': cleanedSong.name,
      'thumbnail': cleanedSong.thumbnails.isNotEmpty
          ? cleanedSong.thumbnails.last.url
          : '',
      'artists': cleanedSong.artists
          .map((a) => {'name': a.name, 'id': a.id})
          .toList(),
      'duration': cleanedSong.duration.inSeconds,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'isLocal': false,
      'playlistId': _queueProvider.playlistId,
      'playlistName': _queueProvider.playlistName,
    };

    _updateLastPlayed(songData, notify: false);
    notifyListeners();
    _fetchAndSetVideoDetails(cleanedSong.videoId);
  }

  Future<void> _fetchAndSetVideoDetails(String videoId) async {
    try {
      final videoInfo = await _videoInfoProvider.getVideoInfo(videoId);
      _currentVideoDetails = videoInfo;

      if (videoInfo?.duration != null &&
          _currentSong != null &&
          _currentSong!.duration.inSeconds == 0) {
        final updatedSong = SongInfo(
          videoId: _currentSong!.videoId,
          name: _currentSong!.name,
          artists: _currentSong!.artists,
          thumbnails: _currentSong!.thumbnails,
          duration: videoInfo!.duration!,
        );
        _currentSong = updatedSong;
        _lastPlayedSong = updatedSong;

        final queueIndex = _queueProvider.queue.indexWhere(
          (s) => s.videoId == updatedSong.videoId,
        );
        if (queueIndex != -1) {
          _queueProvider.updateSongInQueue(queueIndex, updatedSong);
        }

        final songData = {
          'id': updatedSong.videoId,
          'title': updatedSong.name,
          'thumbnail': updatedSong.thumbnails.isNotEmpty
              ? updatedSong.thumbnails.first.url
              : '',
          'artists': updatedSong.artists
              .map((a) => {'name': a.name, 'id': a.id})
              .toList(),
          'duration': updatedSong.duration.inSeconds,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'isLocal': false,
          'playlistId': _queueProvider.playlistId,
          'playlistName': _queueProvider.playlistName,
        };
        _updateLastPlayed(songData);
      }

      notifyListeners();
    } catch (e) {
      _currentVideoDetails = null;
      notifyListeners();
    }
  }

  void setCurrentLocalSong(Map<String, dynamic> song) async {
    debugPrint(
      'Setting current local song: ${song['title']} by ${song['artist']}',
    );
    _currentLocalSong = song;
    _currentSong = null;
    _lastPlayedSong = null;
    _favoriteSongProvider.setCurrentSong(null);
    _currentVideoDetails = null;

    _queueProvider.clearQueue();

    notifyListeners();
  }

  Future<void> setCurrentLocalSongWithQueue(
    Map<String, dynamic> song,
    List<Map<String, dynamic>> songQueue,
    int currentIndex,
  ) async {
    final songWithQueue = Map<String, dynamic>.from(song);
    songWithQueue['queue'] = songQueue;
    _currentLocalSong = songWithQueue;
    _currentSong = null;
    _lastPlayedSong = null;
    _favoriteSongProvider.setCurrentSong(null);
    _currentVideoDetails = null;

    _queueProvider.clearQueue();
    _queueProvider.setPlaylistId('local_music');

    for (final localSong in songQueue) {
      final dummySongInfo = SongInfo(
        videoId: localSong['id'] ?? '',
        name: localSong['title'] ?? 'Unknown',
        artists: [Artist(name: localSong['artist'] ?? 'Unknown', id: '')],
        thumbnails: [
          Thumbnail(url: localSong['thumbnail'] ?? '', width: 0, height: 0),
        ],
        duration: Duration(milliseconds: localSong['duration'] ?? 0),
      );
      _queueProvider.addToQueue(dummySongInfo);
    }

    _queueProvider.setCurrentIndex(currentIndex);

    notifyListeners();
  }

  Future<void> updateCurrentLocalSongWithQueue(
    Map<String, dynamic> song,
    List<Map<String, dynamic>> songQueue,
    int currentIndex,
  ) async {
    final songWithQueue = Map<String, dynamic>.from(song);
    songWithQueue['queue'] = songQueue;
    _currentLocalSong = songWithQueue;
    _currentSong = null;
    _lastPlayedSong = null;
    _favoriteSongProvider.setCurrentSong(null);
    _currentVideoDetails = null;

    _queueProvider.setCurrentIndex(currentIndex);

    notifyListeners();
  }

  void updateCurrentLocalSong(Map<String, dynamic> song) {
    debugPrint(
      'Updating current local song: ${song['title']} by ${song['artist']}',
    );
    final queue = _currentLocalSong?['queue'];
    _currentLocalSong = song;
    if (queue != null) {
      _currentLocalSong!['queue'] = queue;
    }
    _currentSong = null;
    _lastPlayedSong = null;
    _favoriteSongProvider.setCurrentSong(null);
    _currentVideoDetails = null;
    notifyListeners();
  }

  void _updateLastPlayed(Map<String, dynamic> songData, {bool notify = true}) {
    _lastPlayedSongs.removeWhere(
      (song) => song['id'].toString() == songData['id'].toString(),
    );
    _lastPlayedSongs.insert(0, songData);

    if (_lastPlayedSongs.length > maxLastPlayed) {
      _lastPlayedSongs = _lastPlayedSongs.sublist(0, maxLastPlayed);
    }

    _lastPlayedSongData = songData;
    unawaited(_saveLastPlayed());
    if (notify) {
      notifyListeners();
    }
  }

  PlayerService get playerService => _playerService;
  QueueProvider get queueProvider => _queueProvider;
  String? get playlistName => _queueProvider.playlistName;
  SongInfo? get currentSong => _currentSong;
  Map<String, dynamic>? get lastPlayedSongData => _lastPlayedSongData;
  Map<String, dynamic>? get currentLocalSong => _currentLocalSong;
  List<Map<String, dynamic>> get lastPlayedSongs => _lastPlayedSongs;
  List<Map<String, dynamic>> get recentPlaylists => _recentPlaylists;
  bool get isPlaying => _currentSong != null || _currentLocalSong != null;
  SongInfo? get lastPlayedSong => _lastPlayedSong;

  Map<String, dynamic>? get currentDownloadedSong {
    final currentId = _currentSong?.videoId;
    if (currentId == null) return null;
    return _downloadProvider.downloadedSongs.firstWhere(
      (song) => song['id'] == currentId,
      orElse: () => {},
    );
  }

  String get currentTitle =>
      _currentLocalSong?['title'] ?? _currentSong?.name ?? '';
  String get currentArtist =>
      _currentLocalSong?['artist'] ??
      _currentSong?.artists.map((a) => a.name).join(', ') ??
      '';
  String get currentThumbnail =>
      _currentLocalSong?['thumbnail'] ??
      (_currentSong?.thumbnails.isNotEmpty == true
          ? _currentSong!.thumbnails.last.url
          : 'assets/default_artwork.png');
  Duration get currentDuration => Duration(
    seconds:
        _currentLocalSong?['duration'] ?? _currentSong?.duration.inSeconds ?? 0,
  );

  Future<void> _loadLastPlayed() async {
    try {
      final box = Hive.box<String>('last_played');
      final values = box.values.cast<String>().toList();

      final List<Map<String, dynamic>> jsonList = values
          .map((v) {
            try {
              return json.decode(v) as Map<String, dynamic>;
            } catch (e) {
              return <String, dynamic>{};
            }
          })
          .where(
            (m) =>
                m.isNotEmpty &&
                m['id'] != null &&
                m['title'] != null &&
                !RegExp(r'^[0-9]+$').hasMatch(m['id'].toString()),
          )
          .toList();

      jsonList.sort((a, b) {
        final ta = a['timestamp'] ?? 0;
        final tb = b['timestamp'] ?? 0;

        final num taNum = ta is String ? (int.tryParse(ta) ?? 0) : ta;
        final num tbNum = tb is String ? (int.tryParse(tb) ?? 0) : tb;

        return tbNum.compareTo(taNum);
      });

      _lastPlayedSongs = jsonList;

      if (jsonList.length > maxLastPlayed) {
        final keysToDelete = box.keys
            .cast<String>()
            .where((key) => !jsonList.any((song) => song['id'] == key))
            .toList();
        if (keysToDelete.isNotEmpty) {
          Future.microtask(() async {
            try {
              await box.deleteAll(keysToDelete);
              debugPrint(
                'Cleaned up ${keysToDelete.length} old last played entries',
              );
            } catch (e) {
              debugPrint('Error cleaning up old last played entries: $e');
            }
          });
        }
      }

      if (_lastPlayedSongs.isNotEmpty) {
        _lastPlayedSongData = _lastPlayedSongs.first;

        if (_lastPlayedSongData!['isLocal'] == true) {
          _currentLocalSong = _lastPlayedSongData;
        } else {
          try {
            final videoId = _lastPlayedSongData!['id'];
            final video = await _videoInfoProvider.getVideoInfo(videoId);
            if (video == null) return;
            if (_lastPlayedSongData!['artists'] != null) {
              final artists = (_lastPlayedSongData!['artists'] as List<dynamic>)
                  .map((a) => Artist(name: a['name'], id: a['id']))
                  .toList();
              _lastPlayedSong = SongInfo(
                videoId: video.videoId,
                name: video.title,
                artists: artists,
                thumbnails: [
                  Thumbnail(url: video.thumbnailUrl, width: 1280, height: 720),
                ],
                duration: video.duration ?? Duration.zero,
              );
            } else {
              final artistName = _lastPlayedSongData!['artist'] ?? video.author;
              final artistId =
                  _lastPlayedSongData!['artistId'] ?? video.channelId;
              final cleanedName = artistName.endsWith(' - Topic')
                  ? artistName.substring(
                      0,
                      artistName.length - ' - Topic'.length,
                    )
                  : artistName;
              _lastPlayedSong = SongInfo(
                videoId: video.videoId,
                name: video.title,
                artists: [Artist(name: cleanedName, id: artistId)],
                thumbnails: [
                  Thumbnail(url: video.thumbnailUrl, width: 1280, height: 720),
                ],
                duration: video.duration ?? Duration.zero,
              );
            }
            _currentSong = _lastPlayedSong;
          } catch (e) {
            debugPrint('Error fetching video: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading last played from Hive: $e');
      _lastPlayedSongs = [];
    } finally {
      isLoadingLastPlayedSongs = false;
      notifyListeners();
    }
  }

  Future<void> _saveLastPlayed() async {
    try {
      final box = Hive.box<String>('last_played');
      final songsToSave = <String, String>{};
      for (final song in _lastPlayedSongs) {
        final id =
            song['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString();
        songsToSave[id] = json.encode(song);
      }
      await box.putAll(songsToSave);
    } catch (e) {
      debugPrint('Error saving last played to Hive: $e');
    }
  }

  Future<void> removeLastPlayed(String songId) async {
    _lastPlayedSongs.removeWhere((song) => song['id'].toString() == songId);
    await _saveLastPlayed();
    notifyListeners();
  }

  Future<void> clearLastPlayed() async {
    _lastPlayedSongs.clear();
    _lastPlayedSongData = null;
    _currentLocalSong = null;
    try {
      final box = Hive.box<String>('last_played');
      await box.clear();
    } catch (e) {
      debugPrint('Error clearing last played Hive box: $e');
    }
    notifyListeners();
  }

  Future<void> _loadRecentPlaylists() async {
    try {
      final box = Hive.box<String>('recent_playlists');
      final values = box.values.cast<String>().toList();

      final List<Map<String, dynamic>> jsonList = values
          .map((v) {
            try {
              return json.decode(v) as Map<String, dynamic>;
            } catch (e) {
              return <String, dynamic>{};
            }
          })
          .where(
            (m) => m.isNotEmpty && m['playlistId'] != null && m['name'] != null,
          )
          .toList();

      jsonList.sort((a, b) {
        final ta = a['timestamp'] ?? 0;
        final tb = b['timestamp'] ?? 0;

        final num taNum = ta is String ? (int.tryParse(ta) ?? 0) : ta;
        final num tbNum = tb is String ? (int.tryParse(tb) ?? 0) : tb;

        return tbNum.compareTo(taNum);
      });

      _recentPlaylists = jsonList
          .map((m) {
            if (!m.containsKey('isPlaylist')) {
              m['isPlaylist'] = true;
            }
            return m;
          })
          .take(maxRecentPlaylists)
          .toList();

      if (jsonList.length > maxRecentPlaylists) {
        final keysToDelete = box.keys
            .cast<String>()
            .where(
              (key) =>
                  !jsonList.any((playlist) => playlist['playlistId'] == key),
            )
            .toList();
        if (keysToDelete.isNotEmpty) {
          Future.microtask(() async {
            try {
              await box.deleteAll(keysToDelete);
              debugPrint(
                'Cleaned up ${keysToDelete.length} old recent playlist entries',
              );
            } catch (e) {
              debugPrint('Error cleaning up old recent playlist entries: $e');
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading recent playlists from Hive: $e');
      _recentPlaylists = [];
    }
  }

  Future<void> _saveRecentPlaylists() async {
    try {
      final box = Hive.box<String>('recent_playlists');
      final playlistsToSave = <String, String>{};
      for (final playlist in _recentPlaylists) {
        final id = playlist['playlistId']?.toString() ?? '';
        if (id.isNotEmpty) {
          playlistsToSave[id] = json.encode(playlist);
        }
      }
      await box.putAll(playlistsToSave);
    } catch (e) {
      debugPrint('Error saving recent playlists to Hive: $e');
    }
  }

  void addRecentPlaylist(
    String playlistId,
    String name,
    String thumbnailUrl, {
    bool isPlaylist = true,
  }) {
    final playlistData = {
      'playlistId': playlistId,
      'name': name,
      'thumbnailUrl': thumbnailUrl,
      'isPlaylist': isPlaylist,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    _recentPlaylists.removeWhere(
      (playlist) => playlist['playlistId'] == playlistId,
    );

    _recentPlaylists.insert(0, playlistData);

    if (_recentPlaylists.length > maxRecentPlaylists) {
      _recentPlaylists = _recentPlaylists.sublist(0, maxRecentPlaylists);
    }

    _saveRecentPlaylists();
    notifyListeners();
  }

  Future<void> removeRecentPlaylist(String playlistId) async {
    _recentPlaylists.removeWhere(
      (playlist) => playlist['playlistId'] == playlistId,
    );
    await _saveRecentPlaylists();
    notifyListeners();
  }

  Future<void> clearRecentPlaylists() async {
    _recentPlaylists.clear();
    try {
      final box = Hive.box<String>('recent_playlists');
      await box.clear();
    } catch (e) {
      debugPrint('Error clearing recent playlists Hive box: $e');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _queueProvider.removeListener(_onQueueChanged);
    super.dispose();
  }
}
