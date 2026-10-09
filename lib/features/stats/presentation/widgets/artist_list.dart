import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';

class ArtistList extends StatelessWidget {
  final Map<String, Duration> artists;
  final Map<String, int>? artistSongCounts;
  final Color color;
  final bool isDarkMode;
  final String Function(Duration) formatDuration;

  const ArtistList({
    required this.artists,
    this.artistSongCounts,
    required this.color,
    required this.isDarkMode,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final topArtists = artists.entries.take(10).toList();
    if (topArtists.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimens.paddingLg),
        child: Center(
          child: Text(
            'no_artist_data_yet'.tr(),
            style: AppTextStyles.bodyMd(isDarkMode: isDarkMode).copyWith(
              color: MainScreenColors.getTextColor(
                isDarkMode,
              ).withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }
    return Column(
      children: topArtists.asMap().entries.map((mapEntry) {
        final index = mapEntry.key;
        final entry = mapEntry.value;
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: AppDimens.radiusMdLg,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              '${index + 1}',
              style: AppTextStyles.caption(
                isDarkMode: isDarkMode,
              ).copyWith(fontWeight: AppTextStyles.weightBold, color: color),
            ),
          ),
          title: Text(
            entry.key,
            style: AppTextStyles.bodyMd(
              isDarkMode: isDarkMode,
            ).copyWith(color: MainScreenColors.getTextColor(isDarkMode)),
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatDuration(entry.value),
                style: AppTextStyles.body2(isDarkMode: isDarkMode).copyWith(
                  color: MainScreenColors.getTextColor(
                    isDarkMode,
                  ).withValues(alpha: 0.7),
                ),
              ),
              if (artistSongCounts != null &&
                  artistSongCounts!.containsKey(entry.key))
                Text(
                  '${artistSongCounts![entry.key]} song${artistSongCounts![entry.key] == 1 ? '' : 's'}',
                  style: AppTextStyles.finePrint(isDarkMode: isDarkMode)
                      .copyWith(
                        color: MainScreenColors.getTextColor(
                          isDarkMode,
                        ).withValues(alpha: 0.5),
                      ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
