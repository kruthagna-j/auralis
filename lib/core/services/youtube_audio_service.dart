import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

enum YoutubePlaybackStatus { unknown, buffering, playing, paused, ended, error }

class YoutubePlaybackSnapshot {
  final YoutubePlaybackStatus status;
  final Duration position;
  final Duration duration;
  final double buffered;
  final String? videoId;
  final int? errorCode;

  const YoutubePlaybackSnapshot({
    required this.status,
    required this.position,
    required this.duration,
    required this.buffered,
    this.videoId,
    this.errorCode,
  });
}

class YoutubeAudioService {
  InAppWebViewController? _webViewController;

  final StreamController<YoutubePlaybackSnapshot> _snapshotController =
      StreamController<YoutubePlaybackSnapshot>.broadcast();

  Stream<YoutubePlaybackSnapshot> get snapshotStream =>
      _snapshotController.stream;

  YoutubePlaybackSnapshot _snapshot = const YoutubePlaybackSnapshot(
    status: YoutubePlaybackStatus.unknown,
    position: Duration.zero,
    duration: Duration.zero,
    buffered: 0,
  );

  final Completer<void> _playerReady = Completer<void>();
  String? _pendingVideoId;
  int? _lastErrorCode;

  static const String _html = r'''
<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="referrer" content="strict-origin-when-cross-origin">
  <style>
    html, body, #player {
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      background: #000;
      overflow: hidden;
    }
  </style>
</head>
<body>
  <div id="player"></div>
  <script>
    let player = null;

    function emit(type, data) {
      try {
        window.flutter_inappwebview.callHandler(
          'youtubeEvent',
          JSON.stringify(Object.assign({type: type}, data || {}))
        );
      } catch (_) {}
    }

    function onYouTubeIframeAPIReady() {
      player = new YT.Player('player', {
        width: '100%',
        height: '100%',
        playerVars: {
          autoplay: 0,
          controls: 0,
          disablekb: 1,
          fs: 0,
          playsinline: 1,
          rel: 0,
          iv_load_policy: 3,
          origin: 'https://com.auralis.app',
          widget_referrer: 'https://com.auralis.app'
        },
        events: {
          onReady: function() {
            emit('ready', {});
          },
          onStateChange: function(event) {
            emit('state', {state: event.data});
          },
          onError: function(event) {
            emit('error', {code: event.data});
          }
        }
      });
    }

    function loadVideo(id, autoplay) {
      if (!player) return;
      if (autoplay) {
        player.loadVideoById({videoId: id, startSeconds: 0});
      } else {
        player.cueVideoById({videoId: id, startSeconds: 0});
      }
    }

    function playVideo() {
      if (player) player.playVideo();
    }

    function pauseVideo() {
      if (player) player.pauseVideo();
    }

    function stopVideo() {
      if (player) player.stopVideo();
    }

    function seekVideo(seconds) {
      if (player) player.seekTo(seconds, true);
    }

    function setVolume(value) {
      if (player) player.setVolume(value);
    }

    function setRate(value) {
      if (player) player.setPlaybackRate(value);
    }

    setInterval(function() {
      if (!player) return;
      try {
        emit('tick', {
          position: player.getCurrentTime() || 0,
          duration: player.getDuration() || 0,
          buffered: player.getVideoLoadedFraction() || 0,
          state: player.getPlayerState()
        });
      } catch (_) {}
    }, 250);
  </script>
  <script src="https://www.youtube.com/iframe_api"></script>
</body>
</html>
''';

  YoutubeAudioService();

  void _publish({
    required YoutubePlaybackStatus status,
    required Duration position,
    required Duration duration,
    required double buffered,
    required String? videoId,
    int? errorCode,
  }) {
    _snapshot = YoutubePlaybackSnapshot(
      status: status,
      position: position,
      duration: duration,
      buffered: buffered,
      videoId: videoId,
      errorCode: errorCode,
    );
    if (!_snapshotController.isClosed) {
      _snapshotController.add(_snapshot);
    }
  }

  YoutubePlaybackStatus _statusFromState(int state) {
    switch (state) {
      case 1:
        return YoutubePlaybackStatus.playing;
      case 2:
        return YoutubePlaybackStatus.paused;
      case 3:
        return YoutubePlaybackStatus.buffering;
      case 0:
        return YoutubePlaybackStatus.ended;
      case -1:
      case 5:
        return YoutubePlaybackStatus.unknown;
      default:
        return YoutubePlaybackStatus.unknown;
    }
  }

  Future<void> _run(String javascript) async {
    final controller = _webViewController;
    if (controller == null) return;
    await controller.evaluateJavascript(source: javascript);
  }

  Future<void> load(String videoId, {required bool playWhenReady}) async {
    _pendingVideoId = videoId;
    _lastErrorCode = null;

    await _playerReady.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw StateError(
        'YouTube WebView player did not become ready',
      ),
    );

    final id = jsonEncode(videoId);
    await _run("loadVideo($id, ${playWhenReady ? 'true' : 'false'});");

    if (playWhenReady) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      await _run('playVideo();');
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (_snapshot.status == YoutubePlaybackStatus.error) {
        throw StateError('YouTube playback error: ${_lastErrorCode ?? 'unknown'}');
      }
    }
  }

  Future<void> play() async {
    await _playerReady.future;
    await _run('playVideo();');
  }

  Future<void> pause() => _run('pauseVideo();');

  Future<void> stop() => _run('stopVideo();');

  Future<void> seek(Duration position) =>
      _run('seekVideo(${position.inMilliseconds / 1000});');

  Future<void> setVolume(double volume) =>
      _run('setVolume(${(volume.clamp(0.0, 1.0) * 100).round()});');

  Future<void> setPlaybackRate(double rate) => _run('setRate($rate);');

  Widget buildHost() {
    return SizedBox(
      width: 200,
      height: 200,
      child: InAppWebView(
        initialData: InAppWebViewInitialData(
          data: _html,
          baseUrl: WebUri('https://com.auralis.app'),
        ),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
          useHybridComposition: true,
          transparentBackground: true,
          supportZoom: false,
          disableHorizontalScroll: true,
          disableVerticalScroll: true,
          verticalScrollBarEnabled: false,
          horizontalScrollBarEnabled: false,
        ),
        onWebViewCreated: (controller) {
          _webViewController = controller;
          controller.addJavaScriptHandler(
            handlerName: 'youtubeEvent',
            callback: (args) {
              if (args.isEmpty) return null;

              final raw = args.first;
              final map = raw is String
                  ? jsonDecode(raw) as Map<String, dynamic>
                  : Map<String, dynamic>.from(raw as Map);

              final type = map['type']?.toString();

              if (type == 'ready') {
                if (!_playerReady.isCompleted) {
                  _playerReady.complete();
                }
                return null;
              }

              if (type == 'error') {
                _lastErrorCode = (map['code'] as num?)?.toInt();
                _publish(
                  status: YoutubePlaybackStatus.error,
                  position: _snapshot.position,
                  duration: _snapshot.duration,
                  buffered: _snapshot.buffered,
                  videoId: _pendingVideoId ?? _snapshot.videoId,
                  errorCode: _lastErrorCode,
                );
                return null;
              }

              final state = (map['state'] as num?)?.toInt();
              final position = ((map['position'] as num?) ?? 0).toDouble();
              final duration = ((map['duration'] as num?) ?? 0).toDouble();
              final buffered = ((map['buffered'] as num?) ?? 0).toDouble();

              if (state != null || type == 'tick') {
                _publish(
                  status: _statusFromState(state ?? -1),
                  position: Duration(
                    milliseconds: (position * 1000).round(),
                  ),
                  duration: Duration(
                    milliseconds: (duration * 1000).round(),
                  ),
                  buffered: buffered.clamp(0.0, 1.0),
                  videoId: _pendingVideoId ?? _snapshot.videoId,
                );
              }

              return null;
            },
          );
        },
      ),
    );
  }

  Future<void> dispose() async {
    _webViewController = null;
    await _snapshotController.close();
  }
}
