import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:get_it/get_it.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../features/equalizer/presentation/data/services/equalizer_services.dart';
import '../models/song_model.dart';
import '../providers/download_provider.dart';
import '../providers/player_provider.dart';
import '../providers/queued_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/stats_provider.dart';
import '../utils/palette_generator.dart';
import 'audio_url_isolate.dart';
import 'audio_url_service.dart';
import 'media_kit_player_adapter.dart';
import 'settings_storage_service.dart';
import 'smtc_service.dart';
import 'temp_audio_cache_service.dart';
import 'youtube_audio_service.dart';

class CanceledException implements Exception {
  final String message;
  CanceledException([this.message = 'Operation cancelled']);

  @override
  String toString() => 'CanceledException: $message';
}

enum ProcessingState { idle, loading, buffering, ready, completed }

class PlayerState {
  final bool playing;
  final ProcessingState processingState;

  const PlayerState(this.playing, this.processingState);
}

class PlayerService {
  final MediaKitPlayerAdapter _mediaKitAdapter;
  final AudioUrlService _audioUrlService;
  final TempAudioCacheService _tempAudioCacheService = TempAudioCacheService();
  final YoutubeAudioService _youtubeAudioService = GetIt.I<YoutubeAudioService>();

  final PlayerProvider playerProvider;
  final QueueProvider queueProvider;
  final DownloadProvider downloadProvider;
  final StatsProvider statsProvider;

  final YoutubeExplode _yt = GetIt.I<YoutubeExplode>();

  final ValueNotifier<Color> backgroundColorNotifier = ValueNotifier<Color>(
    Colors.black,
  );

  final ValueNotifier<bool> isFetchingStreamUrlNotifier = ValueNotifier<bool>(
    false,
  );

  Timer? _bufferingTimeoutTimer;

  Timer? sleepTimer;
  DateTime? sleepTimerEnd;
  final ValueNotifier<Duration?> sleepTimerRemaining = ValueNotifier(null);

  bool get isSleepTimerActive => sleepTimerEnd != null;

  bool isExplicitlySettingSong = false;

  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();
  final StreamController<Duration> _bufferedController =
      StreamController<Duration>.broadcast();
  final StreamController<bool> _playingController =
      StreamController<bool>.broadcast();

  Stream<PlayerState> get playerStateStream async* {
    yield PlayerState(_isPlaying, _processingState);
    yield* _playerStateController.stream;
  }

  Stream<Duration> get positionStream async* {
    yield _position;
    yield* _positionController.stream;
  }

  Stream<Duration?> get durationStream async* {
    yield _duration;
    yield* _durationController.stream;
  }

  Stream<Duration> get bufferedPositionStream async* {
    yield _mediaKitAdapter.currentBuffered;
    yield* _bufferedController.stream;
  }

  Stream<bool> get playingStream async* {
    yield _isPlaying;
    yield* _playingController.stream;
  }

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration? _duration;
  Duration _bufferedPosition = Duration.zero;
  double _playbackSpeed = 1.0;
  double _volume = 1.0;
  ProcessingState _processingState = ProcessingState.idle;

  bool _wasPlayingBeforeInterruption = false;
  bool _wasDucked = false;
  bool _isHandlingCompletion = false;

  // True only while the YouTube IFrame (WebView) owns playback. Downloaded and
  // local files are always played by media_kit, even when currentSong != null.
  bool _usingYoutube = false;

  static const int _prebufferThresholdSeconds = 15;

  bool _prebufferStarted = false;

  SongInfo? _prebufferedSong;

  SmtcService? _smtcService;
  Timer? _smtcPositionTimer;
  AudioSession? _audioSession;
  Timer? _progressSyncTimer;

  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _bufferSubscription;
  StreamSubscription<bool>? _completedSubscription;
  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<YoutubePlaybackSnapshot>? _youtubeSnapshotSubscription;

  String? _currentStatsSongId;
  String? _currentStatsSongTitle;
  String? _currentStatsSongArtist;
  int? _currentStatsSessionStartPosition;

  RepeatMode _loopMode = RepeatMode.off;

  MediaKitPlayerAdapter get mediaKitAdapter => _mediaKitAdapter;
  dynamic get audioPlayerInstance => null;
  YoutubeExplode get yt => _yt;

  double get volume => _volume;
  bool get isPlaying => _isPlaying;
  PlayerState get playerStateSnapshot =>
      PlayerState(_isPlaying, _processingState);

  PlayerService(
    this.playerProvider,
    this.queueProvider,
    this.downloadProvider,
    this.statsProvider,
  ) : _mediaKitAdapter = MediaKitPlayerAdapter(),
      _audioUrlService = AudioUrlService(downloadProvider) {
    _bindMediaKitStreams();
    _bindYoutubeStreams();
    _setupCompletionHandling();
    _restoreSleepTimerIfNeeded();
    _initializeAudioSession();
    _restoreSavedVolume();
    unawaited(_tempAudioCacheService.cleanupExpiredCache());
    _initSmtc();

    if (!GetIt.I.isRegistered<EqualizerService>()) {
      GetIt.I.registerSingleton<EqualizerService>(EqualizerService());
    }
    unawaited(() async {
      await GetIt.I<EqualizerService>().bindPlayer(_mediaKitAdapter);
    }());
  }

  void _bindMediaKitStreams() {
    _playingSubscription = _mediaKitAdapter.playingStream.listen((playing) {
      _isPlaying = playing;
      if (playing && _processingState == ProcessingState.loading) {
        _processingState = ProcessingState.ready;
      }
      _emitState();
      _updateSmtcPlaybackStatus();
      _setupStatsOnPlayStateChange();
    });

    _positionSubscription = _mediaKitAdapter.positionStream.listen((position) {
      _position = position;
      _positionController.add(position);
    });

    _durationSubscription = _mediaKitAdapter.durationStream.listen((duration) {
      _duration = duration;
      _durationController.add(duration);
    });

    _bufferSubscription = _mediaKitAdapter.bufferedPositionStream.listen((b) {
      if (b != _bufferedPosition) {
        _bufferedPosition = b;
        _bufferedController.add(b);
      }
    });

    _completedSubscription = _mediaKitAdapter.completedStream.listen((done) {
      if (done) {
        _processingState = ProcessingState.completed;
        _emitState();
        _handlePlaybackCompletion();
      }
    });

    _bufferingSubscription = _mediaKitAdapter.bufferingStream.listen((
      buffering,
    ) {
      if (buffering) {
        if (_processingState != ProcessingState.loading) {
          _processingState = ProcessingState.buffering;
          _emitState();
        }
        _bufferingTimeoutTimer?.cancel();
        _bufferingTimeoutTimer = Timer(const Duration(seconds: 15), () {
          _handleBufferingTimeout();
        });
      } else {
        _bufferingTimeoutTimer?.cancel();
        if (_processingState == ProcessingState.buffering) {
          _processingState = ProcessingState.ready;
          _emitState();
        }
      }
    });

    _progressSyncTimer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      // media_kit owns local-file playback. Online YouTube playback is owned
      // by YoutubeAudioService, so never let the media_kit idle player reset
      // YouTube position/duration/playing state back to zero.
      if (_usingYoutube) {
        return;
      }

      final currentPos = _mediaKitAdapter.currentPosition;
      final currentDur = _mediaKitAdapter.currentDuration;
      final currentBuf = _mediaKitAdapter.currentBuffered;
      final currentPlay = _mediaKitAdapter.currentPlaying;

      if (currentPos != _position) {
        _position = currentPos;
        _positionController.add(currentPos);
      }
      if (currentDur != _duration) {
        _duration = currentDur;
        _durationController.add(currentDur);
      }
      if (currentBuf != _bufferedPosition) {
        _bufferedPosition = currentBuf;
        _bufferedController.add(currentBuf);
      }
      if (currentPlay != _isPlaying) {
        _isPlaying = currentPlay;
        _emitState();
      }

      _checkAndTriggerPrebuffer(currentPos, currentDur);
    });
  }

  void _bindYoutubeStreams() {
    _youtubeSnapshotSubscription =
        _youtubeAudioService.snapshotStream.listen((snapshot) {
      final currentSong = playerProvider.currentSong;
      if (!_usingYoutube ||
          currentSong == null ||
          playerProvider.currentLocalSong != null) {
        return;
      }
      if (snapshot.videoId != null &&
          snapshot.videoId!.isNotEmpty &&
          snapshot.videoId != currentSong.videoId) {
        return;
      }

      _position = snapshot.position;
      _positionController.add(_position);
      if (snapshot.duration > Duration.zero) {
        _duration = snapshot.duration;
        _durationController.add(_duration);
      }
      _bufferedPosition = snapshot.duration > Duration.zero
          ? Duration(
              milliseconds:
                  (snapshot.duration.inMilliseconds * snapshot.buffered).round(),
            )
          : Duration.zero;
      _bufferedController.add(_bufferedPosition);

      switch (snapshot.status) {
        case YoutubePlaybackStatus.playing:
          _isPlaying = true;
          _processingState = ProcessingState.ready;
          break;
        case YoutubePlaybackStatus.buffering:
          _isPlaying = true;
          _processingState = ProcessingState.buffering;
          break;
        case YoutubePlaybackStatus.paused:
          _isPlaying = false;
          if (_processingState != ProcessingState.loading) {
            _processingState = ProcessingState.ready;
          }
          break;
        case YoutubePlaybackStatus.ended:
          _isPlaying = false;
          _processingState = ProcessingState.completed;
          _emitState();
          unawaited(_handlePlaybackCompletion());
          return;
        case YoutubePlaybackStatus.error:
          _isPlaying = false;
          _processingState = ProcessingState.idle;
          break;
        case YoutubePlaybackStatus.unknown:
          break;
      }

      _emitState();
      _updateSmtcPlaybackStatus();
    });
  }

  void _setupCompletionHandling() {}

  Future<void> _handleBufferingTimeout() async {
    if (_processingState != ProcessingState.buffering) return;

    final currentSong = playerProvider.currentSong;
    if (currentSong == null || playerProvider.currentLocalSong != null) return;

    final wasPlaying = _isPlaying;
    final currentPos = _position;

    debugPrint(
      'Buffering timeout, retrying to fetch stream for ${currentSong.name}',
    );

    try {
      await _openSong(currentSong, playWhenReady: false, forceRefresh: true);

      await Future.delayed(const Duration(milliseconds: 300));

      if (currentPos > Duration.zero) {
        await seek(currentPos);
      }

      if (wasPlaying) {
        await play();
      }
    } catch (e) {
      debugPrint('Buffering retry failed: $e');
    }
  }

  void _emitState() {
    final state = PlayerState(_isPlaying, _processingState);
    _playerStateController.add(state);
    _playingController.add(_isPlaying);
  }

  Future<void> _restoreSavedVolume() async {
    final box = await SettingsStorageService.getBox();
    _volume = ((box.get('volumeLevel') as num?)?.toDouble() ?? 1.0).clamp(
      0.0,
      1.5,
    );
    await _mediaKitAdapter.setVolume(_volume);
  }

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.5);
    if (_usingYoutube) {
      await _youtubeAudioService.setVolume(_volume);
    } else {
      await _mediaKitAdapter.setVolume(_volume);
    }
    final box = await SettingsStorageService.getBox();
    await box.put('volumeLevel', _volume);
  }

  Future<Duration> getCurrentPosition() async => _position;

  double getPlaybackSpeed() => _playbackSpeed;

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    if (_usingYoutube) {
      await _youtubeAudioService.setPlaybackRate(speed);
    } else {
      await _mediaKitAdapter.setSpeed(speed);
    }
  }

  Future<void> seek(Duration position) async {
    if (_usingYoutube) {
      await _youtubeAudioService.seek(position);
    } else {
      await _mediaKitAdapter.seek(position);
    }
    _position = position;
    _positionController.add(position);
  }

  Future<void> play() async {
    unawaited(_setAudioSessionActive(true));
    if (_usingYoutube) {
      await _youtubeAudioService.play();
    } else {
      await _mediaKitAdapter.play();
    }
    _processingState = ProcessingState.ready;
    _emitState();
  }

  Future<void> pause() async {
    unawaited(_recordCurrentPlaybackEnd());
    if (_usingYoutube) {
      await _youtubeAudioService.pause();
    } else {
      await _mediaKitAdapter.pause();
    }
    unawaited(_setAudioSessionActive(false));
    _processingState = ProcessingState.ready;
    _emitState();
  }

  Future<void> stop() async {
    await _recordCurrentPlaybackEnd();
    if (_usingYoutube) {
      await _youtubeAudioService.stop();
    } else {
      await _mediaKitAdapter.stop();
    }
    await _setAudioSessionActive(false);
    _processingState = ProcessingState.idle;
    _position = Duration.zero;
    _emitState();
  }

  Future<void> loadSong(SongInfo song) async {
    try {
      _updateSmtcMetadata(song);
      await _openSong(song, playWhenReady: false);
      updateBackgroundColor(
        song.thumbnails.isNotEmpty ? song.thumbnails.first.url : null,
      );
    } catch (e, stack) {
      debugPrint('Error loading song: $e');
      debugPrint('$stack');
    }
  }

  Future<void> _openSong(
    SongInfo song, {
    required bool playWhenReady,
    bool forceRefresh = false,
  }) async {
    _prebufferStarted = false;
    _prebufferedSong = null;

    isFetchingStreamUrlNotifier.value = true;
    _processingState = ProcessingState.loading;
    _emitState();

    if (playWhenReady) {
      unawaited(_setAudioSessionActive(true));
    }

    try {
      final downloadedPath = await downloadProvider.getDownloadedSongPath(
        song.videoId,
      );
      if (downloadedPath != null) {
        _usingYoutube = false;
        await _mediaKitAdapter.openPath(downloadedPath, play: playWhenReady);
      } else {
        _usingYoutube = true;
        debugPrint(
          'YouTube: using official IFrame playback for ' +
              song.videoId +
              '; skipping CDN extraction/cache',
        );
        await _youtubeAudioService.load(
          song.videoId,
          playWhenReady: playWhenReady,
        );
      }
      if (GetIt.I.isRegistered<EqualizerService>()) {
        unawaited(GetIt.I<EqualizerService>().applyToBoundPlayer());
      }
      // For YouTube, duration comes from the IFrame metadata. Do not
      // overwrite it with the search-result duration before the player reports
      // its actual state.
      if (playerProvider.currentLocalSong != null) {
        _duration = song.duration;
        _durationController.add(_duration);
      }
      _processingState = ProcessingState.ready;
      _emitState();
    } catch (e) {
      _processingState = ProcessingState.idle;
      _emitState();
      rethrow;
    } finally {
      isFetchingStreamUrlNotifier.value = false;
    }
  }

  Future<bool> playSong(SongInfo song, {int maxRetries = 1}) async {
    isExplicitlySettingSong = true;

    if (_isPlaying) {
      if (_usingYoutube) {
        await _youtubeAudioService.pause();
      } else {
        await _mediaKitAdapter.pause();
      }
      _isPlaying = false;
      _emitState();
    }

    playerProvider.setCurrentSong(song);
    _updateSmtcMetadata(song);
    unawaited(_recordCurrentPlaybackEnd());

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await _openSong(song, playWhenReady: true);

        _currentStatsSongId = song.videoId;
        _currentStatsSongTitle = song.name;
        _currentStatsSongArtist = song.artists.map((a) => a.name).join(', ');
        _currentStatsSessionStartPosition =
            (await getCurrentPosition()).inSeconds;
        statsProvider.recordPlayStart(
          _currentStatsSongId!,
          _currentStatsSongTitle!,
          _currentStatsSongArtist!,
          _currentStatsSessionStartPosition!,
        );

        isExplicitlySettingSong = false;
        return true;
      } catch (e) {
        if (attempt == maxRetries - 1) {
          isExplicitlySettingSong = false;
          return false;
        }
      }
    }

    isExplicitlySettingSong = false;
    return false;
  }

  Future<void> playLocalAudioWithQueue(
    String filePath,
    Map<String, dynamic> songData,
    List<Map<String, dynamic>> songQueue,
    int currentIndex,
  ) async {
    isExplicitlySettingSong = true;

    await _recordCurrentPlaybackEnd();
    await stop();

    await playerProvider.setCurrentLocalSongWithQueue(
      songData,
      songQueue,
      currentIndex,
    );

    _usingYoutube = false;
    await _mediaKitAdapter.openPath(filePath, play: true);
    _processingState = ProcessingState.ready;
    _emitState();

    _updateSmtcMetadataFromLocal(songData);
    updateBackgroundColor(songData['thumbnail']?.toString());

    isExplicitlySettingSong = false;
  }

  void playNext({int retryCount = 0}) async {
    if (playerProvider.currentLocalSong != null) {
      final nextSong = queueProvider.getNextSong();
      if (nextSong == null) {
        await seek(Duration.zero);
        await pause();
        return;
      }

      final nextIndex = queueProvider.currentIndex;
      final localSongs =
          playerProvider.currentLocalSong!['queue']
              as List<Map<String, dynamic>>?;
      if (localSongs != null &&
          nextIndex >= 0 &&
          nextIndex < localSongs.length) {
        final nextLocalSong = localSongs[nextIndex];
        final localPath = nextLocalSong['localPath']?.toString();
        if (localPath != null && localPath.isNotEmpty) {
          await playLocalAudioWithQueue(
            localPath,
            nextLocalSong,
            localSongs,
            nextIndex,
          );
        }
      }
      return;
    }

    final nextSong = queueProvider.getNextSong();
    if (nextSong != null) {
      await playSong(nextSong);
    }
  }

  void playPrevious({int retryCount = 0}) async {
    if (playerProvider.currentLocalSong != null) {
      final previousSong = queueProvider.getPreviousSong();
      if (previousSong == null) {
        await seek(Duration.zero);
        await pause();
        return;
      }

      final previousIndex = queueProvider.currentIndex;
      final localSongs =
          playerProvider.currentLocalSong!['queue']
              as List<Map<String, dynamic>>?;
      if (localSongs != null &&
          previousIndex >= 0 &&
          previousIndex < localSongs.length) {
        final previousLocalSong = localSongs[previousIndex];
        final localPath = previousLocalSong['localPath']?.toString();
        if (localPath != null && localPath.isNotEmpty) {
          await playLocalAudioWithQueue(
            localPath,
            previousLocalSong,
            localSongs,
            previousIndex,
          );
        }
      }
      return;
    }

    final previousSong = queueProvider.getPreviousSong();
    if (previousSong != null) {
      await playSong(previousSong);
    }
  }

  Future<void> setShuffleMode(bool enabled) async {}

  Future<void> setLoopMode(RepeatMode repeatMode) async {
    _loopMode = repeatMode;
  }

  Future<void> insertSongIntoPlaylist(int queueIndex, SongInfo song) async {}

  Future<void> moveSongInPlaylist(int fromQueueIndex, int toQueueIndex) async {}

  Future<void> removeFromPlaylist(int queueIndex) async {}

  Future<void> startSleepTimer(Duration duration, {bool fade = false}) async {
    await cancelSleepTimer();
    sleepTimerEnd = DateTime.now().add(duration);
    sleepTimerRemaining.value = duration;

    final box = await SettingsStorageService.getBox();
    await box.put('sleep_timer_end', sleepTimerEnd!.millisecondsSinceEpoch);
    await box.put('sleep_timer_fade', fade);

    sleepTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      final remaining = sleepTimerEnd!.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        t.cancel();
        sleepTimer = null;
        sleepTimerRemaining.value = null;
        sleepTimerEnd = null;
        await box.delete('sleep_timer_end');
        await box.delete('sleep_timer_fade');

        if (fade) {
          await fadeAndStop();
        } else {
          await pause();
        }
      } else {
        sleepTimerRemaining.value = remaining;
      }
    });
  }

  Future<void> startSleepTimerUntilEndOfTrack({bool fade = false}) async {
    final duration = _duration;
    final position = _position;

    if (duration != null) {
      final remaining = duration - position;
      if (remaining > Duration.zero) {
        await startSleepTimer(remaining, fade: fade);
      } else {
        if (fade) {
          await fadeAndStop();
        } else {
          await pause();
        }
      }
    }
  }

  Future<void> cancelSleepTimer() async {
    sleepTimer?.cancel();
    sleepTimer = null;
    sleepTimerEnd = null;
    sleepTimerRemaining.value = null;
    final box = await SettingsStorageService.getBox();
    await box.delete('sleep_timer_end');
    await box.delete('sleep_timer_fade');
  }

  Future<void> _restoreSleepTimerIfNeeded() async {
    final box = await SettingsStorageService.getBox();
    final endMillis = box.get('sleep_timer_end') as int?;
    final fade = (box.get('sleep_timer_fade') as bool?) ?? false;
    if (endMillis != null) {
      final end = DateTime.fromMillisecondsSinceEpoch(endMillis);
      final remaining = end.difference(DateTime.now());
      if (remaining > Duration.zero) {
        await startSleepTimer(remaining, fade: fade);
      } else {
        await box.delete('sleep_timer_end');
        await box.delete('sleep_timer_fade');
      }
    }
  }

  Future<void> fadeAndStop({
    int steps = 8,
    Duration stepDelay = const Duration(milliseconds: 200),
  }) async {
    final original = _volume;
    try {
      for (int i = 0; i < steps; i++) {
        final v = (original * (steps - i - 1) / steps).clamp(0.0, 1.5);
        await _mediaKitAdapter.setVolume(v);
        await Future.delayed(stepDelay);
      }
    } catch (_) {}
    await pause();
    await _mediaKitAdapter.setVolume(original);
  }

  Future<void> _recordCurrentPlaybackEnd() async {
    if (_currentStatsSongId != null &&
        _currentStatsSessionStartPosition != null) {
      final currentPosition = await getCurrentPosition();
      await statsProvider.recordPlayEnd(
        _currentStatsSongId,
        _currentStatsSongTitle,
        _currentStatsSongArtist,
        currentPosition.inSeconds,
      );
      _currentStatsSongId = null;
      _currentStatsSongTitle = null;
      _currentStatsSongArtist = null;
      _currentStatsSessionStartPosition = null;
    }
  }

  void _setupStatsOnPlayStateChange() {
    if (_isPlaying) {
      final currentSong = playerProvider.currentSong;
      if (currentSong != null && playerProvider.currentLocalSong == null) {
        _currentStatsSongId = currentSong.videoId;
        _currentStatsSongTitle = currentSong.name;
        _currentStatsSongArtist = currentSong.artists
            .map((a) => a.name)
            .join(', ');
      }
    }
  }

  Future<void> _initializeAudioSession() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      _audioSession = await AudioSession.instance;
      await _audioSession!.configure(const AudioSessionConfiguration.music());

      _audioSession!.interruptionEventStream.listen((event) async {
        debugPrint(
          '[AudioSession] interruption begin=${event.begin} type=${event.type} '
          'usingYoutube=$_usingYoutube',
        );
        // The YouTube IFrame plays inside a WebView that requests its own
        // Android audio focus. That request makes this app's own audio_session
        // lose focus and report an "interruption", which used to call pause()
        // about one second after playback started. The WebView handles real
        // interruptions (calls, other apps) itself and reports them through
        // the player state, so ignore session interruptions for YouTube.
        if (_usingYoutube) return;

        if (event.begin) {
          _wasPlayingBeforeInterruption = _isPlaying;
          switch (event.type) {
            case AudioInterruptionType.duck:
              // Ducking means "play quieter", not "stop".
              _wasDucked = true;
              await _mediaKitAdapter.setVolume(_volume * 0.3);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              await pause();
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              if (_wasDucked) {
                _wasDucked = false;
                await _mediaKitAdapter.setVolume(_volume);
              }
              break;
            case AudioInterruptionType.pause:
              if (_wasPlayingBeforeInterruption) {
                await play();
              }
              break;
            case AudioInterruptionType.unknown:
              break;
          }
        }
      });

      _audioSession!.becomingNoisyEventStream.listen((_) async {
        await pause();
      });
    } catch (_) {}
  }

  Future<void> _setAudioSessionActive(bool active) async {
    if (_audioSession == null) return;
    // Never compete with the WebView for audio focus (see interruption handler).
    if (active && _usingYoutube) return;
    try {
      await _audioSession!.setActive(active);
    } catch (_) {}
  }

  void _initSmtc() {
    if (!Platform.isWindows) return;

    _smtcService = SmtcService();
    _smtcService!.initialize(
      onPlay: () => play(),
      onPause: () => pause(),
      onNext: () => playNext(),
      onPrevious: () => playPrevious(),
      onStop: () => stop(),
    );

    _smtcPositionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_duration != null && _duration! > Duration.zero) {
        _smtcService!.updateTimeline(position: _position, duration: _duration!);
      }
    });

    queueProvider.addListener(() {
      _smtcService?.updateConfig(
        nextEnabled: queueProvider.hasNext,
        prevEnabled: queueProvider.hasPrevious,
      );
    });
  }

  void _updateSmtcPlaybackStatus() {
    if (_smtcService == null) return;
    if (_isPlaying) {
      _smtcService!.setIsPlaying();
      return;
    }

    if (_processingState == ProcessingState.completed ||
        _processingState == ProcessingState.idle) {
      _smtcService!.setIsStopped();
      return;
    }

    _smtcService!.setIsPaused();
  }

  void _updateSmtcMetadata(SongInfo song) {
    _smtcService?.updateMetadata(song);
  }

  void _updateSmtcMetadataFromLocal(Map<String, dynamic> localSong) {
    _smtcService?.updateMetadataFromLocal(localSong);
  }

  Future<void> _handlePlaybackCompletion() async {
    if (_isHandlingCompletion) return;
    _isHandlingCompletion = true;

    try {
      await _recordCurrentPlaybackEnd();

      if (_loopMode == RepeatMode.one) {
        await seek(Duration.zero);
        await play();
        return;
      }

      if (queueProvider.hasNext || queueProvider.isRepeatEnabled) {
        final nextSong = queueProvider.peekNext();
        if (nextSong != null &&
            _prebufferedSong != null &&
            _prebufferedSong!.videoId == nextSong.videoId &&
            _mediaKitAdapter.isNextTrackReady) {
          queueProvider.getNextSong();

          isExplicitlySettingSong = true;
          playerProvider.setCurrentSong(nextSong);
          _updateSmtcMetadata(nextSong);

          final swapped = await _mediaKitAdapter.swapToPrebuffered();
          if (swapped) {
            if (GetIt.I.isRegistered<EqualizerService>()) {
              unawaited(
                GetIt.I<EqualizerService>().bindPlayer(_mediaKitAdapter),
              );
            }

            _processingState = ProcessingState.ready;
            _duration = nextSong.duration;
            _durationController.add(_duration);
            _emitState();

            _currentStatsSongId = nextSong.videoId;
            _currentStatsSongTitle = nextSong.name;
            _currentStatsSongArtist = nextSong.artists
                .map((a) => a.name)
                .join(', ');
            _currentStatsSessionStartPosition = 0;
            statsProvider.recordPlayStart(
              _currentStatsSongId!,
              _currentStatsSongTitle!,
              _currentStatsSongArtist!,
              _currentStatsSessionStartPosition!,
            );

            updateBackgroundColor(
              nextSong.thumbnails.isNotEmpty
                  ? nextSong.thumbnails.first.url
                  : null,
            );

            _prebufferStarted = false;
            _prebufferedSong = null;
            isExplicitlySettingSong = false;
            return;
          }
          isExplicitlySettingSong = false;
        }
        _prebufferStarted = false;
        _prebufferedSong = null;
        playNext();
      } else {
        await seek(Duration.zero);
        await pause();
      }
    } finally {
      _isHandlingCompletion = false;
    }
  }

  void _checkAndTriggerPrebuffer(Duration position, Duration? duration) {
    if (_prebufferStarted) return;
    if (duration == null || duration == Duration.zero) return;
    if (!_isPlaying) return;
    try {
      final settings = GetIt.I<SettingsProvider>();
      if (!settings.gaplessPlaybackEnabled) return;
    } catch (_) {
      return;
    }

    if (_loopMode == RepeatMode.one) return;

    final remaining = duration - position;
    if (remaining.inSeconds <= _prebufferThresholdSeconds &&
        remaining.inSeconds > 0) {
      final nextSong = queueProvider.peekNext();
      if (nextSong == null) return;

      if (playerProvider.currentLocalSong != null) return;

      _prebufferStarted = true;
      _prebufferNextTrack(nextSong);
    }
  }

  Future<void> _prebufferNextTrack(SongInfo song) async {
    try {
      debugPrint('[Prebuffer] Starting prebuffer for: ${song.name}');
      _prebufferedSong = song;

      final settingsProvider = GetIt.I<SettingsProvider>();
      final isTempCacheEnabled = settingsProvider.audioCacheEnabled;
      final downloadedPath = await downloadProvider.getDownloadedSongPath(
        song.videoId,
      );

      if (downloadedPath != null) {
        await _mediaKitAdapter.prebufferPath(downloadedPath, volume: _volume);
      } else {
        final cachedFile = isTempCacheEnabled
            ? await _tempAudioCacheService.getCachedFile(song)
            : null;
        if (cachedFile != null) {
          await _mediaKitAdapter.prebufferPath(
            cachedFile.path,
            volume: _volume,
          );
        } else {
          final audioData = await _audioUrlService.getAudioUrl(
            song,
            isPreloading: true,
          );
          final audioUrl = audioData?['url'] as String?;
          if (audioUrl == null) {
            debugPrint('[Prebuffer] Could not resolve URL for ${song.name}');
            _prebufferedSong = null;
            return;
          }
          await _mediaKitAdapter.prebufferUri(audioUrl, volume: _volume);
          if (isTempCacheEnabled) {
            unawaited(
              _tempAudioCacheService
                  .downloadAndCacheFile(audioUrl, song)
                  .catchError((_) {}),
            );
          }
        }
      }

      if (GetIt.I.isRegistered<EqualizerService>()) {
        try {
          final eqService = GetIt.I<EqualizerService>();
          final graph = eqService.equalizerEnabled
              ? eqService.buildFilterGraph()
              : '';
          await _mediaKitAdapter.applyFilterGraphToNextPlayer(graph);
        } catch (_) {}
      }

      debugPrint('[Prebuffer] Ready: ${song.name}');
    } catch (e) {
      debugPrint('[Prebuffer] Error: $e');
      _prebufferedSong = null;
    }
  }

  Future<void> updateBackgroundColor(String? thumbnailUrl) async {
    final color = await ColorPaletteService.generatePalette(thumbnailUrl ?? '');
    backgroundColorNotifier.value = color;
  }

  Future<Uri> getDefaultArtworkUri() async {
    try {
      final dir = Directory.systemTemp;
      return Uri.file('${dir.path}/default_artwork.png');
    } catch (_) {
      return Uri.parse(
        'https://dummyimage.com/600x400/ff0000/ffffff&text=Artwork',
      );
    }
  }

  Future<void> dispose() async {
    await _recordCurrentPlaybackEnd();
    await _setAudioSessionActive(false);
    sleepTimer?.cancel();
    _bufferingTimeoutTimer?.cancel();
    _smtcPositionTimer?.cancel();
    _progressSyncTimer?.cancel();
    _smtcService?.dispose();

    _playingSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _bufferSubscription?.cancel();
    _completedSubscription?.cancel();
    _youtubeSnapshotSubscription?.cancel();

    await _playerStateController.close();
    await _positionController.close();
    await _durationController.close();
    await _bufferedController.close();
    await _playingController.close();

    _prebufferStarted = false;
    _prebufferedSong = null;
    await _mediaKitAdapter.dispose();

    AudioUrlIsolate.cancelAllRequests().catchError((_) {});
  }
}
