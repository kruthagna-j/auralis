import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';

import 'home_screen_shimmer.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../playlist_album_content/presentation/screens/playlist_album_content_screen.dart';

class RecentPlaylistsSection extends StatefulWidget {
  const RecentPlaylistsSection({Key? key}) : super(key: key);

  @override
  State<RecentPlaylistsSection> createState() => _RecentPlaylistsSectionState();
}

class _RecentPlaylistsSectionState extends State<RecentPlaylistsSection> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = context.select((SettingsProvider p) => p.accentColor);
    final playerProvider = context.watch<PlayerProvider>();
    final recentPlaylists = playerProvider.recentPlaylists;

    if (playerProvider.isLoadingLastPlayedSongs) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(AppDimens.paddingLg),
            child: SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingLg),
            child: ShimmerLoading.buildSectionHeader(width: 180),
          ),
          SizedBox(
            height: AppDimens.headerImageSm + AppDimens.spacingSm + 25,
            child: ShimmerLoading.buildHorizontalListShimmer(),
          ),
        ],
      );
    }

    if (recentPlaylists.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimens.paddingLg),
          child: Text(
            'recently_played_playlist'.tr(),
            style: AppTextStyles.titleLg().copyWith(color: accentColor),
          ),
        ),
        SizedBox(
          height: AppDimens.headerImageSm + AppDimens.spacingSm + 25,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recentPlaylists.length,
            itemBuilder: (context, index) {
              final playlist = recentPlaylists[index];
              return PlaylistCard(
                playlist: playlist,
                onTap: () => _openPlaylist(context, playlist),
                isDarkMode: isDarkMode,
                accentColor: accentColor,
              );
            },
          ),
        ),
      ],
    );
  }

  void _openContentDetail(BuildContext context, Map<String, dynamic> content) {
    final bool isPlaylist = content['isPlaylist'] == null
        ? true
        : content['isPlaylist'] == true;

    final formattedContent = isPlaylist
        ? PlaylistDetailed(
            playlistId: content['playlistId'] ?? '',
            name: content['name'] ?? content['title'] ?? '',
            artist: ArtistBasic(name: ''),
            thumbnails: [
              ThumbnailFull(
                url: content['thumbnailUrl'] ?? content['thumbnail'] ?? '',
                width: 1280,
                height: 720,
              ),
            ],
            type: 'Playlist',
          )
        : AlbumDetailed(
            playlistId: content['playlistId'] ?? '',
            albumId: content['playlistId'] ?? '',
            name: content['name'] ?? content['title'] ?? '',
            artist: ArtistBasic(name: content['artist'] ?? ''),
            thumbnails: [
              ThumbnailFull(
                url: content['thumbnailUrl'] ?? content['thumbnail'] ?? '',
                width: 1280,
                height: 720,
              ),
            ],
            type: 'Album',
          );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistAlbumContent(content: formattedContent),
      ),
    );
  }

  void _openPlaylist(BuildContext context, Map<String, dynamic> playlist) {
    _openContentDetail(context, playlist);
  }
}

class PlaylistCard extends StatelessWidget {
  final Map<String, dynamic> playlist;
  final VoidCallback onTap;
  final bool isDarkMode;
  final Color accentColor;

  const PlaylistCard({
    Key? key,
    required this.playlist,
    required this.onTap,
    required this.isDarkMode,
    required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppDimens.thumbnailLarge + AppDimens.spacingXl,
        margin: const EdgeInsets.symmetric(horizontal: AppDimens.spacingSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              child: CachedNetworkImage(
                imageUrl: playlist['thumbnailUrl'] ?? '',
                height: AppDimens.headerImageSm,
                width: AppDimens.headerImageSm,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[850],
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[850],
                  child: const Icon(Icons.music_note, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.spacingSm),
            Text(
              playlist['name'] ?? 'Unknown Playlist',
              style: AppTextStyles.bodyMd(isDarkMode: isDarkMode),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
