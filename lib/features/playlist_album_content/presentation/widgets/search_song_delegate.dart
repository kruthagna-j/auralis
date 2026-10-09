import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../shared/components/song_list_tile.dart';

class SongSearchDelegate extends SearchDelegate {
  final List<dynamic> songs;
  final Function(dynamic) onPlay;

  SongSearchDelegate({required this.songs, required this.onPlay});

  @override
  ThemeData appBarTheme(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).accentColor;
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: MainScreenColors.getSurfaceColor(isDarkMode),
        elevation: 0,
        iconTheme: IconThemeData(
          color: MainScreenColors.getTextColor(isDarkMode),
        ),
        titleTextStyle: AppTextStyles.titleLg(
          color: MainScreenColors.getTextColor(isDarkMode),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: AppTextStyles.caption(
          color: MainScreenColors.getTextColor(
            isDarkMode,
          ).withValues(alpha: 0.6),
        ),
        border: InputBorder.none,
      ),
      textSelectionTheme: TextSelectionThemeData(cursorColor: accentColor),
      textTheme: TextTheme(
        titleLarge: AppTextStyles.titleLg(
          color: MainScreenColors.getTextColor(isDarkMode),
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
          color: MainScreenColors.getTextColor(isDarkMode),
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
      color: MainScreenColors.getTextColor(isDarkMode),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final results = songs
        .where((song) => song.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: AppDimens.iconStatus,
              color: MainScreenColors.getTextColor(
                isDarkMode,
              ).withValues(alpha: 0.5),
            ),
            SizedBox(height: AppDimens.spacingLg),
            Text(
              'no_songs_found'.tr(),
              style: AppTextStyles.titleLg(
                color: MainScreenColors.getTextColor(
                  isDarkMode,
                ).withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: MainScreenColors.getBackgroundColor(isDarkMode),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.spacingSm),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final song = results[index];
          return Builder(
            builder: (context) {
              final isCurrentlyPlaying = context.select<PlayerProvider, bool>(
                (p) => p.currentSong?.videoId == song.videoId,
              );
              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spacingLg,
                  vertical: AppDimens.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: isCurrentlyPlaying
                      ? Provider.of<SettingsProvider>(
                          context,
                          listen: false,
                        ).accentColor.withValues(alpha: 0.2)
                      : MainScreenColors.getSurfaceColor(isDarkMode),
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                ),
                child: SongListTile(
                  key: ValueKey('search_${song.name}_$index'),
                  song: song,
                  isPlaying: isCurrentlyPlaying,
                  onPlay: () {
                    onPlay(song);
                    close(context, null);
                  },
                  isDarkMode: isDarkMode,
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final suggestions = query.isEmpty
        ? songs
        : songs
              .where(
                (song) => song.name.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

    if (suggestions.isEmpty && query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: AppDimens.iconStatus,
              color: MainScreenColors.getTextColor(
                isDarkMode,
              ).withValues(alpha: 0.5),
            ),
            SizedBox(height: AppDimens.spacingLg),
            Text(
              'no_songs_found'.tr(),
              style: AppTextStyles.titleLg(
                color: MainScreenColors.getTextColor(
                  isDarkMode,
                ).withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: MainScreenColors.getBackgroundColor(isDarkMode),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.spacingSm),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final song = suggestions[index];
          return Builder(
            builder: (context) {
              final isCurrentlyPlaying = context.select<PlayerProvider, bool>(
                (p) => p.currentSong?.videoId == song.videoId,
              );
              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spacingLg,
                  vertical: AppDimens.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: isCurrentlyPlaying
                      ? Provider.of<SettingsProvider>(
                          context,
                          listen: false,
                        ).accentColor.withValues(alpha: 0.2)
                      : MainScreenColors.getSurfaceColor(isDarkMode),
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                ),
                child: SongListTile(
                  key: ValueKey('suggestion_${song.name}_$index'),
                  song: song,
                  isPlaying: isCurrentlyPlaying,
                  onPlay: () {
                    onPlay(song);
                    close(context, null);
                  },
                  isDarkMode: isDarkMode,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
