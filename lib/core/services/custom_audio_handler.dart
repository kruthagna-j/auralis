import 'dart:async';

import 'package:audio_service/audio_service.dart';

import '../models/song_model.dart';
import '../providers/favorite_song_provider.dart';
import '../providers/player_provider.dart';
import '../providers/queued_provider.dart';
import 'player_service.dart';

class CustomAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final PlayerService _playerService;
  final QueueProvider _queueProvider;
  final PlayerProvider _playerProvider;
  final FavoriteSongProvider _favoriteSongProvider;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<Duration>? _bufferedSubscription;
  // ignore: unused_field
  Timer? _throttleTimer;
  bool _stateDirty = false;

  Duration _position = Duration.zero;
  Duration _buffered = Duration.zero;
  Duration _duration = Duration.zero;

  CustomAudioHandler(
    this._playerService,
    this._queueProvider,
    this._playerProvider,
    this._favoriteSongProvider,
  ) {
    _init();
  }

  void _init() {
    _playerStateSubscription = _playerService.playerStateStream.listen((_) {
      _markStateDirty();
    });

    _positionSubscription = _playerService.positionStream.listen((position) {
      _position = position;
      _markStateDirty();
    });

    _durationSubscription = _playerService.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      if (mediaItem.value != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: _duration));
      }
      _markStateDirty();
    });

    _bufferedSubscription = _playerService.bufferedPositionStream.listen((b) {
      _buffered = b;
      _markStateDirty();
    });

    _queueProvider.addListener(_updateQueue);
    _playerProvider.addListener(_updateMediaItem);
    _favoriteSongProvider.addListener(_markStateDirty);

    _throttleTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_stateDirty) {
        _stateDirty = false;
        _broadcastState();
      }
    });

    _updateQueue();
    _updateMediaItem();
    _broadcastState();
  }

  void _markStateDirty() {
    _stateDirty = true;
  }

  void _updateQueue() {
    final items = _queueProvider.queue.map(_songToMediaItem).toList();
    queue.add(items);
  }

  void _updateMediaItem() {
    final currentSong = _playerProvider.currentSong;
    if (currentSong != null) {
      final item = _songToMediaItem(currentSong);
      mediaItem.add(item.copyWith(duration: _duration));
      _favoriteSongProvider.setCurrentSong(currentSong);
      return;
    }

    final localSong = _playerProvider.currentLocalSong;
    if (localSong != null) {
      mediaItem.add(_localToMediaItem(localSong).copyWith(duration: _duration));
      _favoriteSongProvider.setCurrentSong(null);
      return;
    }

    mediaItem.add(null);
    _favoriteSongProvider.setCurrentSong(null);
  }

  MediaItem _songToMediaItem(SongInfo song) {
    final thumb = song.thumbnails.isNotEmpty
        ? song.thumbnails.last.url
        : 'https://img.youtube.com/vi/${song.videoId}/hqdefault.jpg';
    return MediaItem(
      id: song.videoId,
      album: 'Auralis',
      title: song.name,
      artist: song.artists.map((a) => a.name).join(', '),
      artUri: Uri.parse(thumb),
      duration: song.duration,
    );
  }

  MediaItem _localToMediaItem(Map<String, dynamic> localSong) {
    final thumb = localSong['thumbnail']?.toString();
    final artUri = thumb == null || thumb.isEmpty
        ? null
        : (thumb.startsWith('http') || thumb.startsWith('file://')
              ? Uri.parse(thumb)
              : Uri.file(thumb));

    return MediaItem(
      id: localSong['id']?.toString() ?? 'local',
      album: localSong['album']?.toString() ?? 'Local Music',
      title: localSong['title']?.toString() ?? 'Unknown',
      artist: localSong['artist']?.toString() ?? 'Unknown Artist',
      artUri: artUri,
      duration: Duration(milliseconds: localSong['duration'] ?? 0),
    );
  }

  void _broadcastState() {
    final processingState =
        switch (_playerService.playerStateSnapshot.processingState) {
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
          ProcessingState.idle => AudioProcessingState.idle,
        };

    final isOnlineSong = _playerProvider.currentSong != null;
    final controls = <MediaControl>[
      if (_queueProvider.hasPrevious) MediaControl.skipToPrevious,
      if (isOnlineSong)
        MediaControl.custom(
          androidIcon: _favoriteSongProvider.isCurrentSongLiked
              ? 'drawable/ic_like'
              : 'drawable/ic_like_outline',
          label: _favoriteSongProvider.isCurrentSongLiked ? 'Unlike' : 'Like',
          name: 'toggleLike',
        ),
      _playerService.isPlaying ? MediaControl.pause : MediaControl.play,
      MediaControl.custom(
        androidIcon: _queueProvider.repeatMode == RepeatMode.one
            ? 'drawable/ic_repeat_one'
            : 'drawable/ic_repeat',
        label: 'Repeat',
        name: 'toggleRepeat',
      ),
      if (_queueProvider.hasNext || _queueProvider.isRepeatEnabled)
        MediaControl.skipToNext,
    ];

    final prevIndex = controls.indexOf(MediaControl.skipToPrevious);
    final playIndex = controls.indexWhere(
      (c) => c == MediaControl.pause || c == MediaControl.play,
    );
    final nextIndex = controls.indexOf(MediaControl.skipToNext);

    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.custom,
        },
        androidCompactActionIndices: [
          if (prevIndex != -1) prevIndex,
          if (playIndex != -1) playIndex,
          if (nextIndex != -1) nextIndex,
        ],
        processingState: processingState,
        playing: _playerService.isPlaying,
        updatePosition: _position,
        bufferedPosition: _buffered,
        speed: _playerService.getPlaybackSpeed(),
        queueIndex: _queueProvider.currentIndex,
      ),
    );
  }

  @override
  Future<void> play() => _playerService.play();

  @override
  Future<void> pause() => _playerService.pause();

  @override
  Future<void> seek(Duration position) => _playerService.seek(position);

  @override
  Future<void> stop() => _playerService.stop();

  @override
  Future<void> skipToNext() async => _playerService.playNext();

  @override
  Future<void> skipToPrevious() async => _playerService.playPrevious();

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _queueProvider.queue.length) return;
    await _playerService.playSong(_queueProvider.queue[index]);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final mode = switch (repeatMode) {
      AudioServiceRepeatMode.one => RepeatMode.one,
      AudioServiceRepeatMode.all ||
      AudioServiceRepeatMode.group => RepeatMode.all,
      _ => RepeatMode.off,
    };
    _queueProvider.setRepeatMode(mode);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode != AudioServiceShuffleMode.none;
    if (_queueProvider.isShuffleEnabled != enabled) {
      _queueProvider.toggleShuffle();
    }
  }

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    switch (name) {
      case 'toggleLike':
        if (_playerProvider.currentSong != null) {
          await _favoriteSongProvider.toggleLike();
          _broadcastState();
        }
        break;
      case 'toggleRepeat':
        _queueProvider.toggleRepeat();
        _broadcastState();
        break;
      default:
        break;
    }
    return null;
  }
}
