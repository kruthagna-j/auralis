import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../shared/components/marquee_text.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/queued_provider.dart';
import '../../../../core/services/player_service.dart';
import 'youtube_video_player.dart';
import 'player_controls.dart';

class PlayerComponents {
  static const double _toggleScale = 0.85;

  static String _cleanPlaylistName(String name) {
    if (name.isEmpty) return name;
    final cleaned = name.replaceAll('_', ' ');
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  static Widget buildThumbnail({
    bool isMini = false,
    required bool isDarkMode,
    required PlayerProvider playerProvider,
    required PlayerService playerService,
    double? thumbnailSize,
  }) {
    return StreamBuilder<bool>(
      stream: playerService.playingStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        final thumbnail = playerProvider.currentThumbnail;
        final videoId = playerProvider.currentSong?.videoId;

        if (isMini) {
          final miniSize = thumbnailSize ?? AppDimens.thumbnailDefault;
          return Container(
            width: miniSize,
            height: miniSize,
            margin: EdgeInsets.all(AppDimens.paddingXs),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              child: Stack(
                children: [
                  thumbnail.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: thumbnail,
                          width: miniSize,
                          height: miniSize,
                          fit: BoxFit.cover,
                          placeholder: buildImagePlaceholder,
                          errorWidget: (context, url, error) => CachedNetworkImage(
                            imageUrl:
                                'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
                            width: miniSize,
                            height: miniSize,
                            fit: BoxFit.cover,
                            placeholder: buildImagePlaceholder,
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/default_artwork.png',
                              width: miniSize,
                              height: miniSize,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : () {
                          String path = thumbnail;
                          if (thumbnail.startsWith('file://')) {
                            try {
                              path = Uri.parse(thumbnail).toFilePath();
                            } catch (_) {
                              path = thumbnail.replaceFirst('file://', '');
                            }
                          }
                          return Image.file(
                            File(path),
                            width: miniSize,
                            height: miniSize,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                                  'assets/default_artwork.png',
                                  width: miniSize,
                                  height: miniSize,
                                  fit: BoxFit.cover,
                                ),
                          );
                        }(),
                ],
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isPortrait = constraints.maxHeight > constraints.maxWidth;
            final containerWidth = constraints.maxWidth.clamp(
              AppDimens.shimmerSection,
              constraints.maxWidth,
            );
            final containerHeight = isPortrait
                ? (constraints.maxHeight * 0.58).clamp(
                    AppDimens.shimmerSection,
                    constraints.maxHeight,
                  )
                : containerWidth;

            final _mq = MediaQuery.of(context);
            final _enforcedScale = _mq.textScaleFactor > 1.0
                ? 1.0
                : _mq.textScaleFactor;

            return Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (playerProvider.playlistName != null &&
                    playerProvider.playlistName!.isNotEmpty &&
                    playerProvider.currentLocalSong == null)
                  Padding(
                    padding: EdgeInsets.only(bottom: AppDimens.spacingSm),
                    child: MediaQuery(
                      data: _mq.copyWith(textScaleFactor: _enforcedScale),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Now playing',
                            style:
                                AppTextStyles.finePrint(
                                  isDarkMode: isDarkMode,
                                ).copyWith(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: AppDimens.spacingXs),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: Text(
                              _cleanPlaylistName(playerProvider.playlistName!),
                              style: AppTextStyles.subtitleBase().copyWith(
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: containerWidth,
                        maxHeight: containerHeight,
                        minHeight: AppDimens.shimmerSection,
                      ),
                      child: Container(
                        width: containerWidth,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusXxl,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusXxl,
                          ),
                          child: SizedBox.expand(
                            child: CachedNetworkImage(
                              imageUrl:
                                  'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
                              fit: BoxFit.cover,
                              placeholder: buildImagePlaceholder,
                              errorWidget: (context, url, error) =>
                                  CachedNetworkImage(
                                    imageUrl:
                                        'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                                    fit: BoxFit.cover,
                                    placeholder: buildImagePlaceholder,
                                    errorWidget: (context, url, error) =>
                                        thumbnail.startsWith('http')
                                        ? CachedNetworkImage(
                                            imageUrl: thumbnail,
                                            fit: BoxFit.cover,
                                            placeholder: buildImagePlaceholder,
                                            errorWidget:
                                                (
                                                  context,
                                                  url,
                                                  error,
                                                ) => Image.asset(
                                                  'assets/default_artwork.png',
                                                  fit: BoxFit.cover,
                                                ),
                                          )
                                        : () {
                                            String path = thumbnail;
                                            if (thumbnail.startsWith(
                                              'file://',
                                            )) {
                                              try {
                                                path = Uri.parse(
                                                  thumbnail,
                                                ).toFilePath();
                                              } catch (_) {
                                                path = thumbnail.replaceFirst(
                                                  'file://',
                                                  '',
                                                );
                                              }
                                            }
                                            return Image.file(
                                              File(path),
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Image.asset(
                                                    'assets/default_artwork.png',
                                                    fit: BoxFit.cover,
                                                  ),
                                            );
                                          }(),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ).animate().slide().fadeIn(),
              ],
            );
          },
        );
      },
    );
  }

  static Widget buildSongInfo({
    bool isMini = false,
    required bool isDarkMode,
    required BuildContext context,
    required PlayerProvider playerProvider,

    Color? accentColor,
    bool? isDownloading,
    bool? isLiked,
    VoidCallback? toggleLike,

    bool isLocalSong = false,
    VoidCallback? onMorePressed,
    VoidCallback? onArtistTap,
    VoidCallback? onVolumePressed,
    VoidCallback? onEqualizerPressed,
    GlobalKey? artistKey,
    bool expand = true,
  }) {
    final title = playerProvider.currentTitle;
    final artist = playerProvider.currentArtist;

    if (isMini) {
      final screenWidth = MediaQuery.of(context).size.width;
      final isCompact = screenWidth < AppDimens.breakpointSmallMobile;
      final content = Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimens.paddingSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MarqueeText(
              text: title,
              style:
                  (isCompact
                          ? AppTextStyles.caption(isDarkMode: isDarkMode)
                          : AppTextStyles.bodyMd(isDarkMode: isDarkMode))
                      .copyWith(fontWeight: AppTextStyles.weightSemiBold),
            ),
            MarqueeText(
              text: artist,
              style:
                  (isCompact
                          ? AppTextStyles.finePrint(isDarkMode: isDarkMode)
                          : AppTextStyles.caption(isDarkMode: isDarkMode))
                      .copyWith(
                        color: MainScreenColors.getTextColor(
                          isDarkMode,
                        ).withValues(alpha: 0.7),
                      ),
              maxLines: 1,
            ),
          ],
        ),
      );
      final mq = MediaQuery.of(context);
      final enforcedScale = mq.textScaleFactor > 1.0 ? 1.0 : mq.textScaleFactor;
      final scaledContent = MediaQuery(
        data: mq.copyWith(textScaleFactor: enforcedScale),
        child: content,
      );
      return expand ? Expanded(child: scaledContent) : scaledContent;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final isTablet = shortestSide >= AppDimens.breakpointTabletShort;
    final isDesktop =
        Platform.isWindows || Platform.isMacOS || Platform.isLinux;

    final compactScale = isTablet ? 0.85 : 0.95;
    final isCompact = screenWidth < AppDimens.breakpointSmallMobile;
    final uiScale = isCompact ? 0.75 : compactScale;

    final titleFontSize =
        (screenWidth * (isDesktop ? 0.035 : (isTablet ? 0.04 : 0.06)) * uiScale)
            .clamp(
              AppTextStyles.fontSizeBody2,
              AppTextStyles.fontSizeHeadingLg,
            );
    final artistFontSize =
        (screenWidth * (isDesktop ? 0.025 : (isTablet ? 0.03 : 0.04)) * uiScale)
            .clamp(AppTextStyles.fontSizeXs, AppTextStyles.fontSizeTitle);
    final spacingBetween = AppDimens.spacingXxs * (isCompact ? 0.5 : 0.7);

    final _mq = MediaQuery.of(context);
    final _enforcedScale = _mq.textScaleFactor > 1.0
        ? 1.0
        : _mq.textScaleFactor;

    return MediaQuery(
      data: _mq.copyWith(textScaleFactor: _enforcedScale),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MarqueeText(
            text: title,
            style: AppTextStyles.playerTitle().copyWith(
              fontSize: titleFontSize,
            ),
          ),
          SizedBox(height: spacingBetween),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: onArtistTap != null
                    ? GestureDetector(
                        key: artistKey,
                        onTap: onArtistTap,
                        child: MarqueeText(
                          text: artist,
                          style: TextStyle(
                            fontSize: artistFontSize,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                        ),
                      )
                    : MarqueeText(
                        text: artist,
                        style: AppTextStyles.subtitleBase().copyWith(
                          fontSize: artistFontSize,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: AppTextStyles.weightMedium,
                        ),
                        maxLines: 1,
                      ),
              ),
              if (!isMini &&
                  !isLocalSong &&
                  accentColor != null &&
                  isLiked != null &&
                  toggleLike != null)
                Padding(
                  padding: EdgeInsets.only(
                    left: isCompact ? AppDimens.spacingSm : AppDimens.paddingSm,
                  ),
                  child: PlayerControls.buildFavoriteButton(
                    isMini: true,
                    isDarkMode: isDarkMode,
                    accentColor: accentColor,
                    isLiked: isLiked,
                    toggleLike: toggleLike,
                  ),
                ),
              if (!isMini)
                Padding(
                  padding: EdgeInsets.only(
                    left: isCompact ? AppDimens.spacingSm : AppDimens.paddingSm,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.equalizer,
                      color: MainScreenColors.getTextColor(
                        isDarkMode,
                      ).withValues(alpha: 0.8),
                      size: AppDimens.iconLg,
                    ),
                    onPressed: onEqualizerPressed ?? onVolumePressed,
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, duration: AppDimens.animSmooth);
  }

  static Widget buildFullPlayerAppBar(
    BuildContext context,
    bool isDarkMode,
    bool isVideoMode,
    VoidCallback onMinimize,
    VoidCallback toggleVideoMode,
    Widget Function(bool) buildOptionsMenu,
    Color accentColor, {
    bool isLocalSong = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < AppDimens.breakpointSmallMobile;
    final leadingPadding = isCompact
        ? AppDimens.spacingSm
        : AppDimens.paddingSm;
    final leadingSize = isCompact
        ? AppDimens.buttonSizeCompact
        : AppDimens.buttonSizeDefault;
    final leadingIconSize = isCompact ? AppDimens.iconMd : AppDimens.iconLg;
    final localToggleScale = _toggleScale * (isCompact ? 0.8 : 1.0);
    final leadingWidth =
        (leadingSize + (leadingPadding * 2) + AppDimens.spacingXs) *
        (isCompact ? 0.85 : 1.0);
    final toolbarHeight = isCompact
        ? AppDimens.buttonSizeDefault
        : kToolbarHeight;

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      toolbarHeight: toolbarHeight,
      leadingWidth: leadingWidth,
      leading: Padding(
        padding: EdgeInsets.only(left: leadingPadding),
        child: InkWell(
          onTap: onMinimize,
          borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
          child: SizedBox(
            width: leadingSize,
            height: leadingSize,
            child: Center(
              child: Container(
                width: leadingSize * 0.90,
                height: leadingSize * 0.90,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: leadingIconSize * 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
      title: (isLocalSong)
          ? null
          : Transform.scale(
              scale: localToggleScale,
              child: _buildVideoAudioToggle(
                isVideoMode,
                toggleVideoMode,
                isDarkMode,
                accentColor,
              ),
            ),
      centerTitle: true,
      actions: [buildOptionsMenu(isDarkMode)],
    );
  }

  static Widget _buildVideoAudioToggle(
    bool isVideoMode,
    VoidCallback toggleVideoMode,
    bool isDarkMode,
    Color accentColor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.spacingXs * _toggleScale,
        vertical: AppDimens.spacingXs * _toggleScale,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDimens.radiusXxl * _toggleScale),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption(
            text: 'SONG',
            isSelected: !isVideoMode,
            onTap: isVideoMode ? toggleVideoMode : null,
            isDarkMode: isDarkMode,
            accentColor: accentColor,
          ),
          SizedBox(width: AppDimens.spacingSm * _toggleScale),
          _buildToggleOption(
            text: 'VIDEO',
            isSelected: isVideoMode,
            onTap: !isVideoMode ? toggleVideoMode : null,
            isDarkMode: isDarkMode,
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  static Widget _buildToggleOption({
    required String text,
    required bool isSelected,
    required VoidCallback? onTap,
    required bool isDarkMode,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.spacingLg * _toggleScale,
          vertical: AppDimens.paddingSm * _toggleScale,
        ),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(
            AppDimens.radiusXl * _toggleScale,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: AppTextStyles.fontSizeBody * _toggleScale,
          ),
        ),
      ),
    );
  }

  static Widget buildMediaPlayer(
    bool isDarkMode,
    bool isVideoMode,
    PlayerProvider playerProvider,
    PlayerService playerService,
    BuildContext context,
  ) {
    if (isVideoMode) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final videoSize =
              (constraints.maxHeight < constraints.maxWidth
                      ? constraints.maxHeight
                      : constraints.maxWidth)
                  .clamp(AppDimens.shimmerSection, constraints.maxWidth);

          return SizedBox(
            width: videoSize,
            height: videoSize,
            child: VideoPlayerWidget(
              key: ValueKey(playerProvider.currentSong!.videoId),
              videoId: playerProvider.currentSong!.videoId,
              onReady: () {},
              hideAppBar: false,
              onFullScreenChange: () {},
            ).animate().fadeIn().scale(),
          );
        },
      );
    }
    return buildThumbnail(
      isDarkMode: isDarkMode,
      playerProvider: playerProvider,
      playerService: playerService,
    );
  }

  static Widget buildPlayerActionRow({
    required BuildContext context,
    required bool isDarkMode,
    required Color accentColor,
    required VoidCallback onShowSleepTimer,
    required VoidCallback onShowLyrics,
    required VoidCallback onShowQueue,
    VoidCallback? onDownload,
    VoidCallback? onToggleShuffle,
    VoidCallback? onToggleRepeat,
    double? downloadProgress,
    bool isDownloaded = false,
    bool isShuffleActive = false,
    RepeatMode repeatMode = RepeatMode.off,
    bool isPreparing = false,
  }) {
    final scale = AppDimens.scaleFactor(context);
    Widget _actionButton({
      required IconData icon,
      required String tooltip,
      required VoidCallback? onPressed,
      bool active = false,
      Widget? centerWidget,
    }) {
      final bool disabled = onPressed == null;
      final bgColor = disabled
          ? Colors.black.withValues(alpha: 0.08)
          : (active ? accentColor : Colors.black.withValues(alpha: 0.35));
      final iconColor = disabled
          ? Colors.white.withValues(alpha: 0.45)
          : (active
                ? (isDarkMode ? Colors.black : Colors.white)
                : Colors.white.withValues(alpha: 0.95));

      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: AppDimens.buttonSizeLg,
            height: AppDimens.buttonSizeLg,
            margin: EdgeInsets.symmetric(
              horizontal: AppDimens.spacingXl * scale * 0.6,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (!disabled)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Center(
              child:
                  centerWidget ??
                  Icon(icon, color: iconColor, size: AppDimens.iconMd),
            ),
          ),
        ),
      );
    }

    Widget _downloadWidget(double size, Color iconColor) {
      if (isDownloaded) {
        return Icon(
          Icons.check_circle,
          color: iconColor,
          size: AppDimens.iconMd,
        );
      }
      if (isPreparing) {
        return SizedBox(
          width: AppDimens.iconMd * 1.6,
          height: AppDimens.iconMd * 1.6,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(),
              SizedBox(
                width: AppDimens.iconMd * 1.1,
                height: AppDimens.iconMd * 1.1,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  backgroundColor: Colors.white.withValues(alpha: 0.04),
                ),
              ),
              Icon(
                Icons.hourglass_top,
                color: iconColor,
                size: AppDimens.iconSm,
              ),
            ],
          ),
        );
      }

      if (downloadProgress != null &&
          downloadProgress >= 0 &&
          downloadProgress < 1.0) {
        return SizedBox(
          width: AppDimens.iconMd * 1.6,
          height: AppDimens.iconMd * 1.6,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: downloadProgress,
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
              ),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${(downloadProgress * 100).toInt()}%',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: AppDimens.iconSm * 0.6,
                      height: 1.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Icon(
        Icons.download_rounded,
        color: iconColor,
        size: AppDimens.iconMd,
      );
    }

    final downloadIconColor = onDownload == null
        ? Colors.white.withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.95);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.paddingSm,
        vertical: AppDimens.spacingSm,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionButton(
              icon: Icons.lyrics_rounded,
              tooltip: 'lyrics'.tr(),
              onPressed: onShowLyrics,
            ),

            _actionButton(
              icon: Icons.timer_rounded,
              tooltip: 'sleep_timer'.tr(),
              onPressed: onShowSleepTimer,
            ),

            _actionButton(
              icon: Icons.shuffle_rounded,
              tooltip: 'shuffle'.tr(),
              onPressed: onToggleShuffle,
              active: isShuffleActive,
            ),
            _actionButton(
              icon: Icons.download_rounded,
              tooltip: isPreparing
                  ? 'preparing'.tr()
                  : (downloadProgress != null
                        ? '${(downloadProgress * 100).toInt()}%'.tr()
                        : (isDownloaded ? 'downloaded'.tr() : 'download'.tr())),
              onPressed: onDownload,
              centerWidget: _downloadWidget(
                AppDimens.buttonSizeLg,
                downloadIconColor,
              ),
              active: false,
            ),

            _actionButton(
              icon: repeatMode == RepeatMode.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              tooltip: repeatMode == RepeatMode.one
                  ? 'repeat_one'.tr()
                  : repeatMode == RepeatMode.all
                  ? 'repeat_all'.tr()
                  : 'repeat'.tr(),
              onPressed: onToggleRepeat,
              active: repeatMode != RepeatMode.off,
            ),

            _actionButton(
              icon: Icons.queue_music_rounded,
              tooltip: 'queue'.tr(),
              onPressed: onShowQueue,
            ),
          ],
        ),
      ),
    );
  }

  static PopupMenuEntry<String> buildPopupMenuItem(
    String value,
    String text,
    IconData icon,
    bool isDarkMode,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: ListTile(
          leading: Icon(icon, color: MainScreenColors.getTextColor(isDarkMode)),
          title: Text(
            text,
            style: TextStyle(color: MainScreenColors.getTextColor(isDarkMode)),
          ),
        ),
      ),
    );
  }

  static Widget buildImagePlaceholder(BuildContext context, String url) {
    return Image.asset('assets/default_artwork.png', fit: BoxFit.cover);
  }

  static Widget buildImageError(
    BuildContext context,
    String url,
    dynamic error,
  ) {
    return Container(
      color: MainScreenColors.getSurfaceColor(
        Theme.of(context).brightness == Brightness.dark,
      ),
      child: const Icon(Icons.error, color: Colors.red),
    );
  }
}
