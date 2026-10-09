import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../features/lyrics/domain/lyrics.dart';
import 'package:path_provider/path_provider.dart';
import '../models/song_model.dart';
import '../../features/lyrics/data/services/ai_lyrics_service.dart';
import '../../features/lyrics/data/services/openai_lyrics_service.dart';
import '../../features/lyrics/data/services/lrclib_services.dart';
import '../services/yt_music_lyrics.dart';
import 'player_provider.dart';
import 'settings_provider.dart';

class LyricsProvider with ChangeNotifier {
  final PlayerProvider _playerProvider;
  final YTLyricsService _ytLyricsService = YTLyricsService();
  final LyricsService _lrclibService = LyricsService();
  final GeminiLyricsService _geminiLyricsService = GeminiLyricsService();
  final OpenAiLyricsService _openAiLyricsService = OpenAiLyricsService();

  LyricsResponse? _lyricsResponse;
  bool _isLoading = false;
  String? _error;

  SongInfo? _currentSong;
  Map<String, dynamic>? _currentLocalSong;

  final Map<String, LyricsResponse?> _providerResponses = {};
  final Map<String, String?> _providerErrors = {};
  final Set<String> _triedProvidersForCurrentSong = {};

  LyricsResponse? get lyricsResponse => _lyricsResponse;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SongInfo? get currentSong => _currentSong;

  bool hasTriedProvider(String provider) =>
      _triedProvidersForCurrentSong.contains(provider);

  LyricsProvider(this._playerProvider) {
    _playerProvider.addListener(_onSongChanged);
    _onSongChanged();
  }

  @override
  void dispose() {
    _playerProvider.removeListener(_onSongChanged);
    super.dispose();
  }

  void _onSongChanged() {
    if (_playerProvider.currentSong != _currentSong ||
        _playerProvider.currentLocalSong != _currentLocalSong) {
      _currentSong = _playerProvider.currentSong;
      _currentLocalSong = _playerProvider.currentLocalSong;
      _providerResponses.clear();
      _providerErrors.clear();
      _triedProvidersForCurrentSong.clear();

      if (_currentSong != null || _currentLocalSong != null) {
        fetchLyricsForCurrentSong();
      } else {
        _lyricsResponse = null;
        _isLoading = false;
        _error = null;
        notifyListeners();
      }
    }
  }

  Future<void> fetchLyricsForCurrentSong({bool forceRefresh = false}) async {
    if (_currentSong == null && _currentLocalSong == null) return;

    _isLoading = true;
    _error = null;
    _lyricsResponse = null;
    notifyListeners();

    try {
      final bool isLocal = _currentLocalSong != null;
      String artist;
      String title;
      String videoId = '';
      Duration songDuration = Duration.zero;

      if (isLocal) {
        artist = (_currentLocalSong!['artist'] ?? '').toString();
        title = (_currentLocalSong!['title'] ?? '').toString();
        songDuration = Duration(
          milliseconds: (_currentLocalSong!['duration'] ?? 0) as int,
        );
      } else {
        artist = _currentSong!.artists
            .map((a) => a.name)
            .join(' & ')
            .replaceAll(' - Topic', '');
        title = _currentSong!.name;
        videoId = _currentSong!.videoId;
        songDuration = _currentSong!.duration;
      }

      final settingsProvider = GetIt.I<SettingsProvider>();
      if (isLocal && settingsProvider.lyricsProvider == 'YT Music') {
        _error = 'YouTube Music lyrics are not available for local songs.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      if (settingsProvider.lyricsProvider == 'AI') {
        if (settingsProvider.aiProvider == 'Gemini' &&
            (settingsProvider.geminiApiKeyValue == null ||
                settingsProvider.geminiApiKeyValue!.isEmpty)) {
          _error = 'Gemini API Key is not set. Please set it in settings.';
          _isLoading = false;
          notifyListeners();
          return;
        }
        if (settingsProvider.aiProvider == 'OpenAI' &&
            (settingsProvider.openAiApiKeyValue == null ||
                settingsProvider.openAiApiKeyValue!.isEmpty)) {
          _error = 'OpenAI API Key is not set. Please set it in settings.';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      final cacheKey =
          '${settingsProvider.lyricsProvider}-${isLocal ? 'local' : 'remote'}-$artist-$title.json';

      final cachedLyrics = await _readCachedLyrics(cacheKey);
      if (cachedLyrics != null && !forceRefresh) {
        _lyricsResponse = cachedLyrics;
      } else {
        if (settingsProvider.lyricsProvider == 'LRCLib') {
          _lyricsResponse = await _lrclibService.searchLyrics(artist, title);
        } else if (settingsProvider.lyricsProvider == 'AI') {
          if (settingsProvider.aiProvider == 'Gemini') {
            _lyricsResponse = await _geminiLyricsService.getLyrics(
              artist,
              title,
              songDuration,
              settingsProvider,
            );
          } else if (settingsProvider.aiProvider == 'OpenAI') {
            _lyricsResponse = await _openAiLyricsService.getLyrics(
              artist,
              title,
              songDuration,
              settingsProvider,
            );
          } else {
            _error = 'Unsupported AI provider: ${settingsProvider.aiProvider}';
          }
        } else {
          _lyricsResponse = await _ytLyricsService.getBestLyrics(videoId);
        }

        if (_lyricsResponse != null) {
          await _cacheLyrics(cacheKey, _lyricsResponse!);
        }
      }
    } catch (e) {
      _error = 'Failed to load lyrics: $e';
    } finally {
      try {
        final settingsProvider = GetIt.I<SettingsProvider>();
        _triedProvidersForCurrentSong.add(settingsProvider.lyricsProvider);
        _providerResponses[settingsProvider.lyricsProvider] = _lyricsResponse;
        _providerErrors[settingsProvider.lyricsProvider] = _error;
      } catch (_) {}

      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCachedLyricsForProvider(String provider) async {
    if (_currentSong == null && _currentLocalSong == null) return;

    _isLoading = true;
    _error = null;
    _lyricsResponse = null;
    notifyListeners();

    try {
      if (_providerResponses.containsKey(provider)) {
        _lyricsResponse = _providerResponses[provider];
        _error = _providerErrors[provider];
      } else {
        final bool isLocal = _currentLocalSong != null;
        String artist;
        String title;

        if (isLocal) {
          artist = (_currentLocalSong!['artist'] ?? '').toString();
          title = (_currentLocalSong!['title'] ?? '').toString();
        } else {
          artist = _currentSong!.artists
              .map((a) => a.name)
              .join(' & ')
              .replaceAll(' - Topic', '');
          title = _currentSong!.name;
        }

        final cacheKey =
            '$provider-${isLocal ? 'local' : 'remote'}-$artist-$title.json';

        final cached = await _readCachedLyrics(cacheKey);
        if (cached != null) {
          _lyricsResponse = cached;
          _providerResponses[provider] = cached;
          _providerErrors[provider] = null;
        } else {
          _lyricsResponse = null;
          _error = _providerErrors[provider];
        }
      }

      _triedProvidersForCurrentSong.add(provider);
    } catch (e) {
      _error = 'Failed to load cached lyrics: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<LyricsResponse?> _readCachedLyrics(String cacheKey) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/auralis/$cacheKey');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = json.decode(content);
        return LyricsResponse(
          lyrics: data['lyrics'],
          isSynced: data['isSynced'],
        );
      }
    } catch (e) {
      debugPrint('Error reading cached lyrics: $e');
    }
    return null;
  }

  Future<void> _cacheLyrics(
    String cacheKey,
    LyricsResponse lyricsResponse,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$cacheKey');
      final content = json.encode({
        'lyrics': lyricsResponse.lyrics,
        'isSynced': lyricsResponse.isSynced,
      });
      await file.writeAsString(content);
    } catch (e) {
      debugPrint('Error caching lyrics: $e');
    }
  }
}
