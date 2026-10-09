import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/providers/download_provider.dart';
import '../../../../core/providers/queued_provider.dart';
import '../../../../core/services/player_service.dart';

class PlayerControls {
  static Widget buildPlayPauseButton({
    bool isMini = false,
    BuildContext? context,
    required bool isDarkMode,
    required Color accentColor,
    required VoidCallback handlePlayPause,
    required PlayerService playerService,
    double outerSize = AppDimens.buttonHeightLarge,
    double iconSize = AppDimens.iconHero,
  }) {
    return StreamBuilder<PlayerState>(
      stream: playerService.playerStateStream,
      builder: (context2, snapshot) {
        final playerState = snapshot.data;
        final isPlaying = playerState?.playing ?? false;

        return ValueListenableBuilder<bool>(
          valueListenable: playerService.isFetchingStreamUrlNotifier,
          builder: (context3, isFetchingStreamUrl, child) {
            final screenWidth = context != null
                ? MediaQuery.of(context).size.width
                : MediaQuery.of(context3).size.width;
            final isCompact = screenWidth < AppDimens.breakpointSmallMobile;

            final _outer = isMini
                ? (isCompact
                      ? AppDimens.buttonSizeCompact
                      : AppDimens.buttonSizeDefault)
                : outerSize;
            final _icon = isMini
                ? (isCompact ? AppDimens.iconXl : AppDimens.iconXxl)
                : iconSize;

            if (!isMini &&
                (playerState?.processingState == ProcessingState.loading ||
                    playerState?.processingState == ProcessingState.buffering ||
                    isFetchingStreamUrl)) {
              return Container(
                width: _outer,
                height: _outer,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: AppDimens.opacityLight)
                      : Colors.black.withValues(alpha: AppDimens.opacityLight),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: _icon,
                    height: _icon,
                    child: CircularProgressIndicator(
                      strokeWidth: AppDimens.progressStroke,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isFetchingStreamUrl
                            ? accentColor
                            : MainScreenColors.darkTirtiaryColor,
                      ),
                      year2023: false,
                    ),
                  ),
                ),
              );
            }

            if (isMini) {
              return SizedBox(
                width: _outer,
                height: _outer,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: accentColor,
                    size: _icon,
                  ),
                  onPressed: handlePlayPause,
                ),
              );
            }

            if (isPlaying) {
              return Container(
                width: _outer,
                height: _outer,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white : Colors.black,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: _outer,
                      minHeight: _outer,
                      maxWidth: _outer,
                      maxHeight: _outer,
                    ),
                    icon: Icon(
                      Icons.pause_rounded,
                      size: _icon,
                      color: isDarkMode ? Colors.black : Colors.white,
                    ),
                    onPressed: handlePlayPause,
                  ),
                ),
              );
            } else {
              return Container(
                width: _outer,
                height: _outer,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white : Colors.black,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: _outer,
                      minHeight: _outer,
                      maxWidth: _outer,
                      maxHeight: _outer,
                    ),
                    icon: Icon(
                      Icons.play_arrow_rounded,
                      size: _icon,
                      color: isDarkMode ? Colors.black : Colors.white,
                    ),
                    onPressed: handlePlayPause,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  static Widget buildProgressBar({
    required BuildContext context,
    bool isMini = false,
    required bool isDarkMode,
    required Color accentColor,
    required PlayerService playerService,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < AppDimens.breakpointSmallMobile;

    return ValueListenableBuilder<bool>(
      valueListenable: playerService.isFetchingStreamUrlNotifier,
      builder: (context, isFetching, child) {
        return StreamBuilder<Duration>(
          stream: playerService.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            return StreamBuilder<Duration?>(
              stream: playerService.durationStream,
              builder: (context, snapshot) {
                final duration = snapshot.data ?? Duration.zero;

                return StreamBuilder<Duration>(
                  stream: playerService.bufferedPositionStream,
                  builder: (context, snapshot) {
                    final bufferedPosition = snapshot.data ?? Duration.zero;

                    if (isMini) {
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapDown: (details) {
                            try {
                              final renderBox =
                                  context.findRenderObject() as RenderBox;
                              final local = renderBox.globalToLocal(
                                details.globalPosition,
                              );
                              final dx = local.dx.clamp(
                                0.0,
                                renderBox.size.width,
                              );
                              final relative = dx / renderBox.size.width;
                              final target = Duration(
                                milliseconds:
                                    (duration.inMilliseconds * relative)
                                        .round(),
                              );
                              playerService.seek(target);
                            } catch (_) {}
                          },
                          child: LinearProgressIndicator(
                            value: duration.inMilliseconds > 0
                                ? position.inMilliseconds /
                                      duration.inMilliseconds
                                : 0.0,
                            backgroundColor: isDarkMode
                                ? Colors.grey[800]
                                : accentColor.withValues(
                                    alpha: AppDimens.opacityMedium,
                                  ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              accentColor,
                            ),
                            year2023: false,
                            minHeight: AppDimens.sliderTrackHeight * 1,
                          ),
                        ),
                      );
                    }

                    return IgnorePointer(
                      ignoring: isFetching,
                      child: MouseRegion(
                        cursor: isFetching
                            ? SystemMouseCursors.basic
                            : SystemMouseCursors.click,
                        child: ProgressBar(
                          progress: position,
                          total: duration,
                          buffered: bufferedPosition,
                          onSeek: (duration) {
                            playerService.seek(duration);
                          },
                          baseBarColor: isDarkMode
                              ? Colors.grey[800]
                              : Colors.grey[300],
                          progressBarColor: isFetching
                              ? Colors.grey
                              : accentColor,
                          bufferedBarColor: isDarkMode
                              ? Colors.grey[600]
                              : Colors.grey[400],
                          thumbColor: isFetching ? Colors.grey : accentColor,
                          barHeight: isCompact
                              ? AppDimens.sliderTrackHeight * 1.8
                              : AppDimens.sliderTrackHeight * 2.4,
                          timeLabelTextStyle: TextStyle(
                            color: MainScreenColors.getTextColor(
                              isDarkMode,
                            ).withValues(alpha: 0.75),
                            fontWeight: AppTextStyles.weightRegular,
                            fontSize: isCompact
                                ? AppTextStyles.fontSizeXs
                                : AppTextStyles.fontSizeSm,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  static Widget buildMiniControls({
    required bool isDarkMode,
    required Color accentColor,
    required QueueProvider queueProvider,
    required PlayerService playerService,
    required VoidCallback handlePrevious,
    required VoidCallback handlePlayPause,
    required VoidCallback handleNext,
  }) {
    return StreamBuilder<PlayerState>(
      stream: playerService.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;

        return ValueListenableBuilder<bool>(
          valueListenable: playerService.isFetchingStreamUrlNotifier,
          builder: (context, isFetchingStreamUrl, child) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isCompact = screenWidth < AppDimens.breakpointSmallMobile;

            if (playerState?.processingState == ProcessingState.loading ||
                playerState?.processingState == ProcessingState.buffering ||
                isFetchingStreamUrl) {
              final size = isCompact
                  ? AppDimens.iconHero
                  : AppDimens.thumbnailLarge;
              final padding = isCompact
                  ? AppDimens.spacingSmMd
                  : AppDimens.paddingMd;
              final stroke = isCompact
                  ? AppDimens.progressStroke * 2
                  : AppDimens.progressStroke * 2.5;

              return SizedBox(
                width: size,
                height: size,
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: CircularProgressIndicator(
                    strokeWidth: stroke,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isFetchingStreamUrl
                          ? accentColor
                          : MainScreenColors.darkTirtiaryColor,
                    ),
                    year2023: false,
                  ),
                ),
              );
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: isCompact ? AppDimens.iconXl : AppDimens.iconXxl,
                  height: isCompact ? AppDimens.iconXl : AppDimens.iconXxl,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      size: isCompact ? AppDimens.iconMdLg : AppDimens.iconXxl,
                      color: queueProvider.hasPrevious
                          ? MainScreenColors.getTextColor(isDarkMode)
                          : MainScreenColors.getTextColor(
                              isDarkMode,
                            ).withValues(alpha: 0.3),
                    ),
                    onPressed: queueProvider.hasPrevious
                        ? handlePrevious
                        : null,
                  ),
                ),
                buildPlayPauseButton(
                  context: context,
                  isMini: true,
                  isDarkMode: isDarkMode,
                  accentColor: accentColor,
                  handlePlayPause: handlePlayPause,
                  playerService: playerService,
                ),
                SizedBox(
                  width: isCompact ? AppDimens.iconXl : AppDimens.iconXxl,
                  height: isCompact ? AppDimens.iconXl : AppDimens.iconXxl,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.skip_next_rounded,
                      size: isCompact ? AppDimens.iconMdLg : AppDimens.iconXxl,
                      color: queueProvider.hasNext
                          ? MainScreenColors.getTextColor(isDarkMode)
                          : MainScreenColors.getTextColor(
                              isDarkMode,
                            ).withValues(alpha: 0.3),
                    ),
                    onPressed: queueProvider.hasNext ? handleNext : null,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget buildFavoriteButton({
    bool isMini = false,
    required bool isDarkMode,
    required Color accentColor,
    required bool isLiked,
    required VoidCallback toggleLike,
  }) {
    const double buttonSize = AppDimens.iconMdLg;

    return IconButton(
      icon: Icon(
        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isMini
            ? accentColor
            : (isLiked
                  ? Colors.red
                  : MainScreenColors.getTextColor(isDarkMode)),
        size: isMini ? AppDimens.iconMdLg : AppDimens.iconXl,
      ),
      onPressed: toggleLike,
    );
  }

  static Widget buildFullPlayerControls({
    required bool isDarkMode,
    required Color accentColor,
    required QueueProvider queueProvider,
    required PlayerService playerService,
    required VoidCallback handlePrevious,
    required VoidCallback handlePlayPause,
    required VoidCallback handleNext,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < AppDimens.breakpointSmallMobile;
        final isWideScreen = screenWidth > AppDimens.breakpointWideScreen;
        final mobileScale = isSmallScreen ? 0.92 : 1.0;

        final skipSize =
            (isSmallScreen ? AppDimens.iconXl : AppDimens.iconXxl) *
            mobileScale;
        final replayForwardSize =
            (isSmallScreen ? AppDimens.iconXl : AppDimens.iconHero) *
            mobileScale;
        final playOuterSize =
            (isSmallScreen
                ? AppDimens.buttonHeightLarge
                : AppDimens.miniPlayerHeight) *
            mobileScale;
        final playIconSize =
            (isSmallScreen ? AppDimens.iconXxl : AppDimens.iconHero) *
            mobileScale;

        final spacingSmall =
            (isSmallScreen ? AppDimens.spacingSm : AppDimens.spacingMd) *
            mobileScale;
        final spacingMedium =
            (isSmallScreen ? AppDimens.spacingMd : AppDimens.spacingLg) *
            mobileScale;
        final maxControlsWidth = isWideScreen
            ? AppDimens.breakpointWideScreen
            : double.infinity;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxControlsWidth),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Container(
                    width:
                        (isSmallScreen
                            ? AppDimens.buttonSizeDefault
                            : AppDimens.buttonSizeLg) *
                        mobileScale,
                    height:
                        (isSmallScreen
                            ? AppDimens.buttonSizeDefault
                            : AppDimens.buttonSizeLg) *
                        mobileScale,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: AppDimens.opacityOverlay,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.skip_previous_rounded,
                        size: skipSize,
                        color: queueProvider.hasPrevious
                            ? MainScreenColors.getTextColor(isDarkMode)
                            : MainScreenColors.getTextColor(
                                isDarkMode,
                              ).withValues(alpha: 0.3),
                      ),
                      onPressed: queueProvider.hasPrevious
                          ? handlePrevious
                          : null,
                    ),
                  ),
                ),
                SizedBox(width: spacingSmall),
                Flexible(
                  child: Container(
                    width:
                        (isSmallScreen
                            ? AppDimens.buttonSizeDefault
                            : AppDimens.buttonSizeLg) *
                        mobileScale,
                    height:
                        (isSmallScreen
                            ? AppDimens.buttonSizeDefault
                            : AppDimens.buttonSizeLg) *
                        mobileScale,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: AppDimens.opacityOverlay,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Transform.translate(
                      offset: const Offset(-3, 0),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.fast_rewind_rounded,
                          size: replayForwardSize,
                          color: MainScreenColors.getTextColor(isDarkMode),
                        ),
                        onPressed: () async {
                          final pos = await playerService.getCurrentPosition();
                          final newPos = pos - const Duration(seconds: 10);
                          await playerService.seek(
                            newPos.isNegative ? Duration.zero : newPos,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: spacingMedium),
                Flexible(
                  child: buildPlayPauseButton(
                    isDarkMode: isDarkMode,
                    accentColor: accentColor,
                    handlePlayPause: handlePlayPause,
                    playerService: playerService,
                    outerSize: playOuterSize,
                    iconSize: playIconSize,
                  ),
                ),
                SizedBox(width: spacingMedium),
                Flexible(
                  child: Container(
                    width:
                        (isSmallScreen
                            ? AppDimens.buttonSizeDefault
                            : AppDimens.buttonSizeLg) *
                        mobileScale,
                    height:
                        (isSmallScreen
                            ? AppDimens.buttonSizeDefault
                            : AppDimens.buttonSizeLg) *
                        mobileScale,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: AppDimens.opacityOverlay,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.fast_forward_rounded,
                        size: replayForwardSize,
                        color: MainScreenColors.getTextColor(isDarkMode),
                      ),
                      onPressed: () async {
                        final pos = await playerService.getCurrentPosition();
                        final duration =
                            await playerService.durationStream.first;
                        final newPos = pos + const Duration(seconds: 10);
                        final clamped = (duration != null && newPos > duration)
                            ? duration
                            : newPos;
                        await playerService.seek(clamped);
                      },
                    ),
                  ),
                ),
                SizedBox(width: spacingSmall),
                Flexible(
                  child: Container(
                    width:
                        (isSmallScreen
                            ? AppDimens.buttonSizeDefault
                            : AppDimens.buttonSizeLg) *
                        mobileScale,
                    height:
                        (isSmallScreen
                            ? AppDimens.buttonSizeDefault
                            : AppDimens.buttonSizeLg) *
                        mobileScale,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: AppDimens.opacityOverlay,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.skip_next_rounded,
                        size: skipSize,
                        color: queueProvider.hasNext
                            ? MainScreenColors.getTextColor(isDarkMode)
                            : MainScreenColors.getTextColor(
                                isDarkMode,
                              ).withValues(alpha: 0.3),
                      ),
                      onPressed: queueProvider.hasNext ? handleNext : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget buildActionButtons({
    required bool isDarkMode,
    required Color accentColor,
    required bool isDownloading,
    required bool isLiked,
    required VoidCallback toggleLike,
    required VoidCallback downloadSong,
    required DownloadProvider downloadProvider,
    required String videoId,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildFavoriteButton(
          isDarkMode: isDarkMode,
          accentColor: accentColor,
          isLiked: isLiked,
          toggleLike: toggleLike,
        ),
      ],
    ).animate().fadeIn();
  }
}
