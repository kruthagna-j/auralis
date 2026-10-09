import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'home_screen_shimmer.dart';
import '../../../../shared/components/songs_options_bottomsheet.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/song_model.dart';

class MusicListTile extends StatelessWidget {
  final Map<String, dynamic> song;
  final VoidCallback onTap;

  const MusicListTile({Key? key, required this.song, required this.onTap})
    : super(key: key);

  void _showOptionsBottomSheet(BuildContext context, bool isDarkMode) {
    final artists =
        (song['artists'] as List<dynamic>?)
            ?.map(
              (a) => Artist(
                name: a['name'] ?? 'unknown_artist'.tr(),
                id: a['id'] ?? '',
              ),
            )
            .toList() ??
        [
          Artist(
            name: song['artist'] ?? 'unknown_artist'.tr(),
            id: song['artistId'] ?? '',
          ),
        ];

    final songInfo = SongInfo(
      videoId: song['id'] ?? '',
      name: song['title'] ?? 'unknown_title'.tr(),
      artists: artists,
      thumbnails: [
        Thumbnail(
          url: song['thumbnail'] ?? 'assets/default_artwork.png',
          width: 1280,
          height: 720,
        ),
      ],
      duration: Duration(seconds: song['duration'] ?? 0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: SongOptionsBottomSheet(song: songInfo, isDarkMode: isDarkMode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      onLongPress: () => _showOptionsBottomSheet(context, isDarkMode),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusXs),
        child: CachedNetworkImage(
          imageUrl: song['thumbnail'] ?? 'assets/default_artwork.png',
          height: AppDimens.thumbnailDefault,
          width: AppDimens.thumbnailDefault,
          fit: BoxFit.cover,
          placeholder: (context, url) => ShimmerLoading.buildShimmerRect(
            width: AppDimens.thumbnailDefault,
            height: AppDimens.thumbnailDefault,
            borderRadius: AppDimens.radiusXs,
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[850],
            child: const Icon(Icons.error, color: Colors.white),
          ),
        ),
      ),
      title: Text(
        song['title'] ?? 'unknown_title'.tr(),
        style: AppTextStyles.bodyMd(isDarkMode: isDarkMode),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        (song['artists'] as List<dynamic>?)
                ?.map((a) => a['name'] as String)
                .join(', ') ??
            song['artist'] ??
            'unknown_artist'.tr(),
        style: AppTextStyles.settingsSubtitle(isDarkMode: isDarkMode),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.more_vert,
          color: MainScreenColors.getTextColor(isDarkMode),
        ),
        onPressed: () => _showOptionsBottomSheet(context, isDarkMode),
      ),
    );
  }
}
