import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'marquee_text.dart';

import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimens.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/download_provider.dart' as dp;
import '../../core/providers/settings_provider.dart';

import 'songs_options_bottomsheet.dart';

class SongListTile extends StatelessWidget {
  final dynamic song;
  final VoidCallback onPlay;
  final VoidCallback? onTap;
  final bool isPlaying;
  final bool isDarkMode;
  final EdgeInsets? contentPadding;

  final bool selectionMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;

  final VoidCallback? onLongPress;

  const SongListTile({
    Key? key,
    required this.song,
    required this.onPlay,
    this.onTap,
    this.isPlaying = false,
    required this.isDarkMode,
    this.contentPadding,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
    this.onLongPress,
  }) : super(key: key);

  String _formatDuration(Duration? duration) {
    if (duration == null || duration.inSeconds == 0) return '';

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  String _getArtistsText() {
    final artists = song.artists as List<dynamic>?;
    if (artists == null || artists.isEmpty) return 'Unknown Artist';
    return artists.map((a) => (a.name ?? a.toString()).toString()).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final textColor = MainScreenColors.getTextColor(isDarkMode);
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final accentColor = settingsProvider.accentColor;

    final double _textScale = MediaQuery.of(context).textScaleFactor;
    final double uiScale = _textScale > 1.0
        ? (1.0 / _textScale).clamp(0.85, 1.0).toDouble()
        : 1.0;
    final double marqueeSpeed = 120.0;

    final videoId = song.videoId;
    final downloadProgress = context
        .select<dp.DownloadProvider, dp.DownloadProgress?>(
          (provider) => provider.progressMap[videoId],
        );
    final isPreparing = context.select<dp.DownloadProvider, bool>(
      (provider) => provider.preparing.contains(videoId),
    );
    final isDownloaded = context.select<dp.DownloadProvider, bool>(
      (provider) => provider.downloadedSongs.any((s) => s['id'] == videoId),
    );

    void _showOptionsBottomSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SafeArea(
          top: false,
          child: SongOptionsBottomSheet(song: song, isDarkMode: isDarkMode),
        ),
      );
    }

    final EdgeInsets tilePadding = contentPadding ?? EdgeInsets.zero;

    final _mq = MediaQuery.of(context);
    final _enforcedTextScale = _mq.textScaleFactor > 1.0
        ? 1.0
        : _mq.textScaleFactor;

    return MediaQuery(
      data: _mq.copyWith(textScaleFactor: _enforcedTextScale),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: tilePadding,
          leading: Stack(
            alignment: Alignment.center,
            children: [
              Hero(
                tag: 'song-thumbnail-${song.name}-${song.videoId}',
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      AppDimens.radiusSm * uiScale,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4 * uiScale,
                        offset: Offset(0, 2 * uiScale),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppDimens.radiusSm * uiScale,
                    ),
                    child: CachedNetworkImage(
                      imageUrl: song.thumbnails.isNotEmpty
                          ? song.thumbnails.first.url
                          : '',
                      width: AppDimens.songTileImage * uiScale,
                      height: AppDimens.songTileImage * uiScale,
                      fit: BoxFit.cover,
                      memCacheWidth: (AppDimens.songTileImage * 2 * uiScale)
                          .toInt(),
                      memCacheHeight: (AppDimens.songTileImage * 2 * uiScale)
                          .toInt(),
                      placeholder: (context, url) => Image.asset(
                        'assets/default_artwork.png',
                        width: AppDimens.songTileImage * uiScale,
                        height: AppDimens.songTileImage * uiScale,
                        fit: BoxFit.cover,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDarkMode ? Colors.grey[850] : Colors.grey[300],
                        child: Icon(
                          Icons.error,
                          size: AppDimens.iconMd * uiScale,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (isPlaying)
                Container(
                  width: AppDimens.songTileImage * uiScale,
                  height: AppDimens.songTileImage * uiScale,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(
                      AppDimens.radiusSm * uiScale,
                    ),
                  ),
                  child: Icon(
                    Icons.equalizer,
                    color: accentColor,
                    size: AppDimens.iconLg * uiScale,
                  ),
                ),
            ],
          ),
          title: MarqueeText(
            text: song.name,
            style: AppTextStyles.bodyLg(
              isDarkMode: isDarkMode,
              color: isPlaying ? accentColor : textColor,
            ).copyWith(height: AppTextStyles.lineHeightDefault),
            speedPxPerSecond: marqueeSpeed,
            pauseDuration: const Duration(milliseconds: 300),
          ),
          subtitle: Row(
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                  ),
                  child: MarqueeText(
                    text: _getArtistsText(),
                    style: AppTextStyles.body2(
                      isDarkMode: isDarkMode,
                      color: isPlaying
                          ? accentColor.withValues(alpha: 0.7)
                          : textColor.withValues(alpha: 0.7),
                    ).copyWith(height: AppTextStyles.lineHeightDefault),
                    speedPxPerSecond: marqueeSpeed,
                    pauseDuration: const Duration(milliseconds: 300),
                  ),
                ),
              ),
              SizedBox(width: AppDimens.spacingSm),
              Text(
                _formatDuration(song.duration as Duration?),
                style: AppTextStyles.caption(
                  isDarkMode: isDarkMode,
                  color: isPlaying
                      ? accentColor.withValues(alpha: 0.6)
                      : textColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          trailing: selectionMode
              ? Checkbox(
                  value: isSelected,
                  onChanged: onSelectionChanged,
                  fillColor: MaterialStateProperty.resolveWith(
                    (states) => states.contains(MaterialState.selected)
                        ? accentColor
                        : Colors.grey,
                  ),
                  checkColor: MainScreenColors.getTextColor(isDarkMode),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDownloaded)
                      SizedBox(
                        width: AppDimens.iconMd * uiScale,
                        height: AppDimens.iconMd * uiScale,
                        child: Icon(
                          Icons.check_circle,
                          color: accentColor,
                          size: AppDimens.iconMd * uiScale,
                        ),
                      )
                    else if (isPreparing)
                      SizedBox(
                        width: AppDimens.iconMd * uiScale,
                        height: AppDimens.iconMd * uiScale,
                        child: CircularProgressIndicator(
                          strokeWidth: AppDimens.progressStroke * uiScale,
                          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        ),
                      )
                    else if (downloadProgress != null &&
                        downloadProgress.progress < 1.0)
                      SizedBox(
                        width: AppDimens.iconXxl * uiScale,
                        height: AppDimens.iconXxl * uiScale,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: downloadProgress.progress,
                              strokeWidth: AppDimens.progressStroke * uiScale,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                accentColor,
                              ),
                              backgroundColor: textColor.withValues(alpha: 0.3),
                            ),
                            Text(
                              '${(downloadProgress.progress * 100).toInt()}%',
                              style: AppTextStyles.badge(
                                isDarkMode: isDarkMode,
                                color: textColor,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        width: AppDimens.iconMd * uiScale,
                        height: AppDimens.iconMd * uiScale,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints.tightFor(
                            width: AppDimens.iconMd * uiScale,
                            height: AppDimens.iconMd * uiScale,
                          ),
                          icon: Icon(
                            Icons.download,
                            color: textColor,
                            size: AppDimens.iconMd * uiScale,
                          ),
                          onPressed: () async {
                            await context
                                .read<dp.DownloadProvider>()
                                .downloadSong(song);
                          },
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: textColor,
                        size: AppDimens.iconMd * uiScale,
                      ),
                      onPressed: _showOptionsBottomSheet,
                    ),
                  ],
                ),
          onTap: onTap ?? onPlay,
          onLongPress: onLongPress ?? _showOptionsBottomSheet,
        ),
      ),
    );
  }
}
