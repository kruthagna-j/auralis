import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import 'home_screen_shimmer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/queued_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/stats_provider.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = context.select((SettingsProvider p) => p.accentColor);
    final iconColor = context.select((SettingsProvider p) => p.accentColor);
    final statsProvider = context.watch<StatsProvider>();
    if (statsProvider.isLoading)
      return ShimmerLoading.buildStatsShimmer(context);

    final nextSong = context.select((QueueProvider p) => p.peekNext());

    final totalSongs = context.select((StatsProvider p) => p.totalSongsPlayed);
    final totalPlaybackTime = context.select(
      (StatsProvider p) => p.totalPlaybackTime,
    );
    final totalDuration = _formatDuration(totalPlaybackTime);
    final todayTime = context.select((StatsProvider p) => p.todayPlaybackTime);
    final todayDailyEntry = context.select(
      (StatsProvider p) => p.getDailyStats(days: 1).first,
    );
    final todaySongs = todayDailyEntry.playCount;
    final thisWeekTime = context.select(
      (StatsProvider p) => p.thisWeekPlaybackTime,
    );
    final thisMonthTime = context.select(
      (StatsProvider p) => p.thisMonthPlaybackTime,
    );
    final mostPlayedArtists = context.select(
      (StatsProvider p) => p.mostPlayedArtists,
    );
    final topArtist = mostPlayedArtists.isNotEmpty
        ? mostPlayedArtists.keys.first
        : "N/A";

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        final subStatStyle = AppTextStyles.caption(isDarkMode: isDarkMode)
            .copyWith(
              color: MainScreenColors.getTextColor(
                isDarkMode,
              ).withValues(alpha: 0.7),
              fontSize: isDesktop ? 11.0 : 10.0,
            );
        final subStatValueStyle = AppTextStyles.caption(isDarkMode: isDarkMode)
            .copyWith(
              fontWeight: AppTextStyles.weightSemiBold,
              fontSize: isDesktop ? 11.0 : 10.0,
            );

        Widget subStatRow(IconData icon, String label, String value) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.5),
            child: Row(
              children: [
                Icon(icon, size: 11, color: iconColor.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: subStatStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: isDesktop ? 120 : 72,
                  child: Text(
                    value,
                    style: subStatValueStyle,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }

        Widget richStatCard(
          IconData icon,
          String value,
          String label,
          List<Widget> subStats, {
          double? minHeight,
        }) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
            ),
            color: accentColor.withValues(alpha: isDarkMode ? 0.06 : 0.36),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight ?? 0),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: isDesktop
                      ? AppDimens.spacingMd
                      : AppDimens.spacingSm,
                  horizontal: isDesktop
                      ? AppDimens.paddingMd
                      : AppDimens.paddingSm,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  value,
                                  style: isDesktop
                                      ? AppTextStyles.subtitle(
                                          isDarkMode: isDarkMode,
                                        ).copyWith(
                                          fontWeight: AppTextStyles.weightBold,
                                        )
                                      : AppTextStyles.bodyLg(
                                          isDarkMode: isDarkMode,
                                        ).copyWith(
                                          fontWeight: AppTextStyles.weightBold,
                                        ),
                                  softWrap: false,
                                ),
                              ),
                              Text(
                                label.tr(),
                                style:
                                    AppTextStyles.finePrint(
                                      isDarkMode: isDarkMode,
                                    ).copyWith(
                                      color: MainScreenColors.getTextColor(
                                        isDarkMode,
                                      ).withValues(alpha: 0.55),
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              AppDimens.radiusMd,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: iconColor,
                            size: isDesktop ? 18 : 16,
                          ),
                        ),
                      ],
                    ),
                    if (subStats.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0, bottom: 2.0),
                        child: Divider(
                          height: 1,
                          color: MainScreenColors.getTextColor(
                            isDarkMode,
                          ).withValues(alpha: 0.1),
                        ),
                      ),
                      ...subStats,
                    ],
                  ],
                ),
              ),
            ),
          );
        }

        Widget nextUpCard = GestureDetector(
          onTap: nextSong != null
              ? () {
                  final playerProvider = context.read<PlayerProvider>();
                  playerProvider.playerService.playNext();
                }
              : null,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusXl),
            ),
            color: accentColor.withValues(alpha: isDarkMode ? 0.06 : 0.36),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 0),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: isDesktop
                      ? AppDimens.spacingLg
                      : AppDimens.spacingMd,
                  horizontal: AppDimens.paddingLg,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.skip_next_rounded,
                      color: iconColor,
                      size: isDesktop ? AppDimens.iconXxl : AppDimens.iconXl,
                    ),
                    const SizedBox(width: AppDimens.spacingMd),
                    if (nextSong != null && nextSong.thumbnails.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                        child: _buildThumbnail(
                          nextSong.thumbnails.first.url,
                          isDesktop
                              ? AppDimens.thumbnailLarge
                              : AppDimens.thumbnailDefault,
                          accentColor,
                        ),
                      ),
                    if (nextSong != null)
                      const SizedBox(width: AppDimens.spacingSmMd),
                    Expanded(
                      child: nextSong != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'next_up'.tr(),
                                  style: isDesktop
                                      ? AppTextStyles.subtitle(
                                          isDarkMode: isDarkMode,
                                        )
                                      : AppTextStyles.bodyMd(
                                          isDarkMode: isDarkMode,
                                        ).copyWith(
                                          fontWeight:
                                              AppTextStyles.weightSemiBold,
                                        ),
                                ),
                                Text(
                                  nextSong.name,
                                  style: isDesktop
                                      ? AppTextStyles.titleSm(
                                          isDarkMode: isDarkMode,
                                        )
                                      : AppTextStyles.bodyLg(
                                          isDarkMode: isDarkMode,
                                        ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  nextSong.artists.isNotEmpty
                                      ? nextSong.artists
                                            .map((a) => a.name)
                                            .join(', ')
                                      : 'Unknown Artist',
                                  style:
                                      AppTextStyles.caption(
                                        isDarkMode: isDarkMode,
                                      ).copyWith(
                                        color: MainScreenColors.getTextColor(
                                          isDarkMode,
                                        ).withValues(alpha: 0.7),
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            )
                          : Text(
                              'no_next_song_in_queue'.tr(),
                              style:
                                  AppTextStyles.caption(
                                    isDarkMode: isDarkMode,
                                  ).copyWith(
                                    color: MainScreenColors.getTextColor(
                                      isDarkMode,
                                    ).withValues(alpha: 0.7),
                                  ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        return Padding(
          padding: const EdgeInsets.all(AppDimens.paddingLg),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: richStatCard(
                        Icons.library_music_rounded,
                        '$todaySongs songs',
                        'today\'s_listening'.tr(),
                        [
                          subStatRow(
                            Icons.today,
                            'total_songs_played'.tr(),
                            '$totalSongs',
                          ),
                        ],
                        minHeight: 0,
                      ),
                    ),
                    const SizedBox(width: AppDimens.spacingLg),
                    Expanded(
                      flex: 1,
                      child: richStatCard(
                        Icons.timer_rounded,

                        _formatDuration(todayTime),
                        'today\'s_listening'.tr(),
                        [
                          subStatRow(
                            Icons.today,
                            'total_playback_time'.tr(),
                            totalDuration,
                          ),
                        ],
                        minHeight: 0,
                      ),
                    ),
                    const SizedBox(width: AppDimens.spacingLg),
                    Expanded(flex: 1, child: nextUpCard),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: richStatCard(
                            Icons.library_music_rounded,
                            '$todaySongs songs',
                            'today\'s_listening'.tr(),
                            [
                              subStatRow(
                                Icons.today,
                                'total'.tr(),
                                '$totalSongs',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppDimens.spacingLg),
                        Expanded(
                          child: richStatCard(
                            Icons.timer_rounded,
                            _formatDuration(todayTime),
                            'today\'s_listening'.tr(),
                            [
                              subStatRow(
                                Icons.today,
                                'total'.tr(),
                                totalDuration,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.spacingMd),
                    nextUpCard,
                  ],
                ),
        );
      },
    );
  }
}

Widget _buildThumbnail(String url, double size, Color accentColor) {
  if (url.isEmpty) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[300],
      child: Icon(Icons.music_note, color: accentColor),
    );
  }

  if (url.startsWith('http://') || url.startsWith('https://')) {
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: size,
        height: size,
        color: Colors.grey[300],
        child: Icon(Icons.music_note, color: accentColor),
      ),
      errorWidget: (context, url, error) => Container(
        width: size,
        height: size,
        color: Colors.grey[300],
        child: Icon(Icons.broken_image, color: accentColor),
      ),
    );
  }

  try {
    final file = url.startsWith('file://')
        ? File.fromUri(Uri.parse(url))
        : File(url);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: Colors.grey[300],
          child: Icon(Icons.music_note, color: accentColor),
        ),
      );
    }
  } catch (_) {}

  return Container(
    width: size,
    height: size,
    color: Colors.grey[300],
    child: Icon(Icons.music_note, color: accentColor),
  );
}

String _formatDuration(Duration duration) {
  if (duration.inHours > 0) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    return '${h}h ${m}m';
  } else if (duration.inMinutes > 0) {
    final m = duration.inMinutes;
    final s = duration.inSeconds.remainder(60);
    return '${m}m ${s}s';
  } else {
    final s = duration.inSeconds;
    return '${s}s';
  }
}
