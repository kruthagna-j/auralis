import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../../core/constants/app_dimens.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoId;
  final VoidCallback onReady;
  final bool hideAppBar;
  final VoidCallback onFullScreenChange;

  const VideoPlayerWidget({
    Key? key,
    required this.videoId,
    required this.onReady,
    required this.hideAppBar,
    required this.onFullScreenChange,
  }) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late YoutubePlayerController _controller;
  bool _isFullScreen = false;
  bool _isReadyCalled = false;
  late InAppWebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    // youtube_player_flutter 10.0+ supports Android, iOS, macOS, and Web.
    // We still fallback to InAppWebView for Windows and Linux.
    if (kIsWeb || (!Platform.isWindows && !Platform.isLinux)) {
      _initializeYoutubePlayer();
    }
  }

  void _initializeYoutubePlayer() {
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );

    // Fullscreen behavior is fully managed internally now.
    // We just listen to changes to bubble up the callback.
    _controller.setFullScreenListener((isFullScreen) {
      if (mounted) {
        setState(() {
          _isFullScreen = isFullScreen;
        });
        widget.onFullScreenChange();
      }
    });

    // Notify ready once the player transitions out of unknown state.
    _controller.listen((event) {
      if (!_isReadyCalled && event.playerState != PlayerState.unknown) {
        _isReadyCalled = true;
        widget.onReady();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      return Container(
        height: AppDimens.progressCircleLarge,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.1),
              blurRadius: AppDimens.elevationHigh,
              offset: const Offset(0, AppDimens.spacingSmMd),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
          child: InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri('https://www.yout-ube.com/watch?v=${widget.videoId}'),
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
              widget.onReady();
            },
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: _isFullScreen
            ? BorderRadius.zero
            : BorderRadius.circular(AppDimens.radiusXxl),
        boxShadow: _isFullScreen
            ? []
            : [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.1),
                  blurRadius: AppDimens.elevationHigh,
                  offset: const Offset(0, AppDimens.spacingSmMd),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: _isFullScreen
            ? BorderRadius.zero
            : BorderRadius.circular(AppDimens.radiusXxl),
        // YoutubePlayer directly renders and supports its own Overlay features for controls.
        child: YoutubePlayer(controller: _controller),
      ),
    );
  }

  @override
  void dispose() {
    if (kIsWeb || (!Platform.isWindows && !Platform.isLinux)) {
      _controller.close();
    }
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }
}
