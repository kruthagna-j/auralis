import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

class MediaKitPlayerAdapter {
  Player _player;
  Player? _nextPlayer;
  bool _nextPlayerReady = false;

  final StreamController<bool> _playingSC = StreamController<bool>.broadcast();
  final StreamController<Duration> _positionSC = StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationSC = StreamController<Duration>.broadcast();
  final StreamController<Duration> _bufferSC = StreamController<Duration>.broadcast();
  final StreamController<bool> _completedSC = StreamController<bool>.broadcast();
  final StreamController<bool> _bufferingSC = StreamController<bool>.broadcast();

  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _bufferSub;
  StreamSubscription<bool>? _completedSub;
  StreamSubscription<bool>? _bufferingSub;

  MediaKitPlayerAdapter({Player? player})
      : _player = player ?? Player(configuration: const PlayerConfiguration(bufferSize: 16 * 1024 * 1024)) {
    _bindPlayerStreams(_player);
  }

  Player get rawPlayer => _player;
  bool get isNextTrackReady => _nextPlayerReady;

  Future<void> openUri(String uri, {bool play = false, Map<String, String>? httpHeaders}) async {
    _cancelPrebuffer();
    final media = httpHeaders == null ? Media(uri) : Media(uri, httpHeaders: httpHeaders);
    await _player.open(media, play: play);
  }

  Future<void> openPath(String path, {bool play = false}) async {
    _cancelPrebuffer();
    await _player.open(Media(path), play: play);
  }

  Future<void> play() async => _player.play();
  Future<void> pause() async => _player.pause();
  Future<void> stop() async => _player.stop();
  Future<void> seek(Duration position) async => _player.seek(position);
  Future<void> setSpeed(double speed) async => _player.setRate(speed);

  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.5);
    await _player.setVolume(clamped * 100.0);
    if (_nextPlayer != null) {
      try { await _nextPlayer!.setVolume(clamped * 100.0); } catch (_) {}
    }
  }

  Future<void> setAudioFilterGraph(String graph) async {
    await _applyFilterGraphToPlayer(_player, graph);
  }

  Future<void> applyFilterGraphToNextPlayer(String graph) async {
    final next = _nextPlayer;
    if (next != null) await _applyFilterGraphToPlayer(next, graph);
  }

  Future<void> prebufferUri(String uri, {double? volume}) async {
    await _initNextPlayer(volume: volume);
    try {
      await _nextPlayer!.open(Media(uri), play: false);
      _nextPlayerReady = true;
      debugPrint('[Prebuffer] URI ready');
    } catch (e) {
      debugPrint('[Prebuffer] Failed to prebuffer URI: $e');
      _cancelPrebuffer();
    }
  }

  Future<void> prebufferPath(String path, {double? volume}) async {
    await _initNextPlayer(volume: volume);
    try {
      await _nextPlayer!.open(Media(path), play: false);
      _nextPlayerReady = true;
      debugPrint('[Prebuffer] Path ready');
    } catch (e) {
      debugPrint('[Prebuffer] Failed to prebuffer path: $e');
      _cancelPrebuffer();
    }
  }

  Future<bool> swapToPrebuffered() async {
    if (!_nextPlayerReady || _nextPlayer == null) return false;
    final oldPlayer = _player;
    _player = _nextPlayer!;
    _nextPlayer = null;
    _nextPlayerReady = false;
    _bindPlayerStreams(_player);
    await _player.play();
    unawaited(Future.delayed(const Duration(milliseconds: 200), () async {
      try { await oldPlayer.stop(); await oldPlayer.dispose(); } catch (_) {}
    }));
    return true;
  }

  void _cancelPrebuffer() {
    _nextPlayerReady = false;
    final old = _nextPlayer;
    _nextPlayer = null;
    if (old != null) {
      unawaited(Future(() async {
        try { await old.stop(); await old.dispose(); } catch (_) {}
      }));
    }
  }

  Future<void> _initNextPlayer({double? volume}) async {
    _cancelPrebuffer();
    _nextPlayer = Player(configuration: const PlayerConfiguration(bufferSize: 16 * 1024 * 1024));
    if (volume != null) {
      final clamped = volume.clamp(0.0, 1.5);
      await _nextPlayer!.setVolume(clamped * 100.0);
    }
  }

  void _bindPlayerStreams(Player player) {
    _playingSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _bufferSub?.cancel();
    _completedSub?.cancel();
    _bufferingSub?.cancel();
    _playingSub = player.stream.playing.listen(_playingSC.add);
    _positionSub = player.stream.position.listen(_positionSC.add);
    _durationSub = player.stream.duration.listen(_durationSC.add);
    _bufferSub = player.stream.buffer.listen(_bufferSC.add);
    _completedSub = player.stream.completed.listen(_completedSC.add);
    _bufferingSub = player.stream.buffering.listen(_bufferingSC.add);
  }

  Stream<bool> get playingStream => _playingSC.stream;
  Stream<Duration> get positionStream => _positionSC.stream;
  Stream<Duration> get durationStream => _durationSC.stream;
  Stream<Duration> get bufferedPositionStream => _bufferSC.stream;
  Stream<bool> get completedStream => _completedSC.stream;
  Stream<bool> get bufferingStream => _bufferingSC.stream;

  bool get currentPlaying => _player.state.playing;
  Duration get currentPosition => _player.state.position;
  Duration get currentBuffered => _player.state.buffer;
  Duration? get currentDuration => _player.state.duration;

  Future<void> dispose() async {
    _playingSub?.cancel(); _positionSub?.cancel(); _durationSub?.cancel();
    _bufferSub?.cancel(); _completedSub?.cancel(); _bufferingSub?.cancel();
    _cancelPrebuffer();
    await _player.dispose();
    await _playingSC.close(); await _positionSC.close(); await _durationSC.close();
    await _bufferSC.close(); await _completedSC.close(); await _bufferingSC.close();
  }

  Future<void> _applyFilterGraphToPlayer(Player player, String graph) async {
    Future<void> apply(String value) async {
      final platform = (player as dynamic).platform;
      await platform.setProperty('af', value).timeout(const Duration(milliseconds: 800));
    }
    try {
      await apply(graph);
      return;
    } catch (_) {}
    if (graph.isNotEmpty) {
      try { await apply('lavfi=[$graph]'); } catch (_) {}
    }
  }
}
