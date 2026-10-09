import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:smtc_windows/smtc_windows.dart';

import '../models/song_model.dart';

class SmtcService {
  SMTCWindows? _smtc;
  StreamSubscription? _buttonSubscription;

  VoidCallback? onPlay;
  VoidCallback? onPause;
  VoidCallback? onNext;
  VoidCallback? onPrevious;
  VoidCallback? onStop;

  bool _isEnabled = false;

  SmtcService();

  bool get isEnabled => _isEnabled;
  static Future<void> ensureInitialized() async {
    if (Platform.isWindows) {
      await SMTCWindows.initialize();
    }
  }

  void initialize({
    VoidCallback? onPlay,
    VoidCallback? onPause,
    VoidCallback? onNext,
    VoidCallback? onPrevious,
    VoidCallback? onStop,
  }) {
    if (!Platform.isWindows) return;

    this.onPlay = onPlay;
    this.onPause = onPause;
    this.onNext = onNext;
    this.onPrevious = onPrevious;
    this.onStop = onStop;

    _smtc = SMTCWindows(
      metadata: const MusicMetadata(
        title: '',
        album: '',
        albumArtist: '',
        artist: '',
        thumbnail: '',
      ),
      timeline: const PlaybackTimeline(
        startTimeMs: 0,
        endTimeMs: 0,
        positionMs: 0,
        minSeekTimeMs: 0,
        maxSeekTimeMs: 0,
      ),
      config: const SMTCConfig(
        fastForwardEnabled: false,
        nextEnabled: true,
        pauseEnabled: true,
        playEnabled: true,
        rewindEnabled: false,
        prevEnabled: true,
        stopEnabled: true,
      ),
    );

    _isEnabled = true;

    _buttonSubscription = _smtc!.buttonPressStream.listen((event) {
      switch (event) {
        case PressedButton.play:
          this.onPlay?.call();
          break;
        case PressedButton.pause:
          this.onPause?.call();
          break;
        case PressedButton.next:
          this.onNext?.call();
          break;
        case PressedButton.previous:
          this.onPrevious?.call();
          break;
        case PressedButton.stop:
          this.onStop?.call();
          break;
        default:
          break;
      }
    });
  }

  void updateMetadata(SongInfo song) {
    if (_smtc == null) return;
    _smtc!.updateMetadata(
      MusicMetadata(
        title: song.name,
        album: 'Auralis',
        albumArtist: song.artists.map((a) => a.name).join(', '),
        artist: song.artists.map((a) => a.name).join(', '),
        thumbnail: song.thumbnails.isNotEmpty ? song.thumbnails.last.url : '',
      ),
    );
  }

  void updateMetadataFromLocal(Map<String, dynamic> localSong) {
    if (_smtc == null) return;
    String thumb = localSong['thumbnail'] ?? '';
    if (thumb.isNotEmpty &&
        !thumb.startsWith('http') &&
        !thumb.startsWith('file://')) {
      thumb = Uri.file(thumb).toString();
    }
    _smtc!.updateMetadata(
      MusicMetadata(
        title: localSong['title'] ?? 'Unknown',
        album: localSong['album'] ?? 'Local Music',
        albumArtist: localSong['artist'] ?? 'Unknown Artist',
        artist: localSong['artist'] ?? 'Unknown Artist',
        thumbnail: thumb,
      ),
    );
  }

  void updateTimeline({
    required Duration position,
    required Duration duration,
  }) {
    if (_smtc == null) return;
    final endMs = duration.inMilliseconds;
    final posMs = position.inMilliseconds.clamp(0, endMs > 0 ? endMs : 0);
    _smtc!.updateTimeline(
      PlaybackTimeline(
        startTimeMs: 0,
        endTimeMs: endMs,
        positionMs: posMs,
        minSeekTimeMs: 0,
        maxSeekTimeMs: endMs,
      ),
    );
  }

  void setPlaybackStatus(PlaybackStatus status) {
    if (_smtc == null) return;
    _smtc!.setPlaybackStatus(status);
  }

  void setIsPlaying() => setPlaybackStatus(PlaybackStatus.playing);
  void setIsPaused() => setPlaybackStatus(PlaybackStatus.paused);
  void setIsStopped() => setPlaybackStatus(PlaybackStatus.stopped);
  void updateConfig({bool? nextEnabled, bool? prevEnabled}) {
    if (_smtc == null) return;
    _smtc!.updateConfig(
      SMTCConfig(
        fastForwardEnabled: false,
        nextEnabled: nextEnabled ?? true,
        pauseEnabled: true,
        playEnabled: true,
        rewindEnabled: false,
        prevEnabled: prevEnabled ?? true,
        stopEnabled: true,
      ),
    );
  }

  void dispose() {
    _buttonSubscription?.cancel();
    _smtc?.dispose();
    _smtc = null;
    _isEnabled = false;
  }
}
