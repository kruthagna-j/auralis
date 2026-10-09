import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/queued_provider.dart';

class MusicSearch extends SearchDelegate<String> {
  final Color accentColor;

  MusicSearch({required this.accentColor});

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: MainScreenColors.getSurfaceColor(isDark),
        elevation: 0,
        iconTheme: IconThemeData(color: accentColor),
        toolbarTextStyle: AppTextStyles.appBarTitle(isDarkMode: isDark),
        titleTextStyle: AppTextStyles.appBarTitle(isDarkMode: isDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: AppTextStyles.finePrint(
          isDarkMode: isDark,
          color: MainScreenColors.getTextColor(
            isDark,
          ).withValues(alpha: AppDimens.opacityMid),
        ),
        border: InputBorder.none,
      ),
      textSelectionTheme: TextSelectionThemeData(cursorColor: accentColor),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          tooltip: 'Clear',
          icon: Icon(Icons.clear, color: accentColor),
          onPressed: () => query = '',
        )
      else
        IconButton(
          tooltip: 'Close',
          icon: Icon(
            Icons.close,
            color: MainScreenColors.getTextColor(
              Theme.of(context).brightness == Brightness.dark,
            ),
          ),
          onPressed: () => close(context, ''),
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: Icon(
        Icons.arrow_back,
        color: MainScreenColors.getTextColor(
          Theme.of(context).brightness == Brightness.dark,
        ),
      ),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildResults(context);

  Widget _buildResults(BuildContext context) {
    final queueProvider = Provider.of<QueueProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (queueProvider.queue.isEmpty) {
      return Center(
        child: Text(
          'Queue is empty',
          style: AppTextStyles.bodyMd(
            isDarkMode: isDarkMode,
            color: MainScreenColors.getTextColor(
              isDarkMode,
            ).withValues(alpha: AppDimens.opacityMuted),
          ),
        ),
      );
    }

    if (query.trim().isEmpty) {
      final suggestions = queueProvider.queue.take(6).toList();
      return ListView.separated(
        padding: EdgeInsets.symmetric(vertical: AppDimens.paddingSm),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => Divider(
          color: MainScreenColors.getTextColor(
            isDarkMode,
          ).withValues(alpha: AppDimens.opacitySubtle),
        ),
        itemBuilder: (context, index) {
          final song = suggestions[index];
          return _resultTile(context, song, queueProvider, isSuggestion: true);
        },
      );
    }

    final q = query.toLowerCase();
    final results = queueProvider.queue
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.artists.any((a) => a.name.toLowerCase().contains(q)),
        )
        .toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: AppDimens.iconStatus,
              color: MainScreenColors.getTextColor(
                isDarkMode,
              ).withValues(alpha: 0.4),
            ),
            SizedBox(height: AppDimens.spacingSmMd),
            Text(
              'No matches in queue',
              style: AppTextStyles.bodyMd(
                isDarkMode: isDarkMode,
                color: MainScreenColors.getTextColor(
                  isDarkMode,
                ).withValues(alpha: AppDimens.opacityMuted),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: AppDimens.paddingSm),
      itemCount: results.length,
      separatorBuilder: (_, __) => Divider(
        color: MainScreenColors.getTextColor(
          isDarkMode,
        ).withValues(alpha: AppDimens.opacitySubtle),
      ),
      itemBuilder: (context, index) {
        final song = results[index];
        return _resultTile(context, song, queueProvider);
      },
    );
  }

  Widget _resultTile(
    BuildContext context,
    dynamic song,
    QueueProvider queueProvider, {
    bool isSuggestion = false,
  }) {
    String? currentId;
    if (queueProvider.queue.isNotEmpty &&
        queueProvider.currentIndex >= 0 &&
        queueProvider.currentIndex < queueProvider.queue.length) {
      currentId = queueProvider.queue[queueProvider.currentIndex].videoId;
    }

    final isPlaying = currentId != null && song.videoId == currentId;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isPlaying
          ? accentColor.withValues(alpha: AppDimens.opacitySubtle)
          : null,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimens.paddingLg,
          vertical: AppDimens.spacingSm,
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          child: _buildThumbnail(song, queueProvider),
        ),
        title: _highlightQueryText(context, song.name),
        subtitle: Text(
          song.artists.map((artist) => artist.name).join(', '),
          style: AppTextStyles.body2(
            isDarkMode: isDarkMode,
            color: MainScreenColors.getTextColor(
              isDarkMode,
            ).withValues(alpha: AppDimens.opacityMuted),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPlaying)
              Padding(
                padding: EdgeInsets.only(right: AppDimens.paddingSm),
                child: Icon(Icons.equalizer, color: accentColor),
              ),
            IconButton(
              tooltip: 'Play',
              icon: Icon(Icons.play_arrow, color: accentColor),
              onPressed: () {
                final playerProvider = Provider.of<PlayerProvider>(
                  context,
                  listen: false,
                );
                playerProvider.playerService.playSong(song);
                close(context, song.videoId);
              },
            ),
          ],
        ),
        onTap: () {
          final playerProvider = Provider.of<PlayerProvider>(
            context,
            listen: false,
          );
          playerProvider.playerService.playSong(song);
          close(context, song.videoId);
        },
      ),
    );
  }

  Widget _highlightQueryText(BuildContext context, String text) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultStyle = AppTextStyles.bodyMd(isDarkMode: isDarkMode);

    if (query.trim().isEmpty) {
      return Text(
        text,
        style: defaultStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final q = query.toLowerCase();
    final lower = text.toLowerCase();

    final spans = <TextSpan>[];
    int start = 0;
    int index;
    while ((index = lower.indexOf(q, start)) != -1) {
      if (index > start) {
        spans.add(
          TextSpan(text: text.substring(start, index), style: defaultStyle),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + q.length),
          style: AppTextStyles.bodyMd(
            isDarkMode: isDarkMode,
            color: accentColor,
          ).copyWith(fontWeight: AppTextStyles.weightSemiBold),
        ),
      );
      start = index + q.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: defaultStyle));
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: defaultStyle, children: spans),
    );
  }

  Widget _buildThumbnail(dynamic song, QueueProvider queueProvider) {
    final playlistId = queueProvider.playlistId;
    final thumbnailUrl = song.thumbnails.first.url;

    if (playlistId == 'local_music' || playlistId == 'downloaded_music') {
      if (thumbnailUrl.isNotEmpty) {
        final file = File(thumbnailUrl.replaceFirst('file://', ''));
        return Image.file(
          file,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/default_artwork.png',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            );
          },
        );
      } else {
        return Image.asset(
          'assets/default_artwork.png',
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        );
      }
    } else {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        placeholder: (context, url) => Image.asset(
          'assets/default_artwork.png',
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
        errorWidget: (context, url, error) => Image.asset(
          'assets/default_artwork.png',
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      );
    }
  }
}
