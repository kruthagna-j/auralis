import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';

import '../../../favorite_artist/presentation/screens/favorite_artist_screen.dart';
import 'home_screen_helpers.dart';
import 'home_screen_shimmer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/providers/favorite_artist_provider.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../artist/presentation/screens/artist_content.dart';
import '../../data/services/home_screen_queue_service.dart';

class FavoriteArtistsSection extends StatelessWidget {
  const FavoriteArtistsSection({Key? key}) : super(key: key);

  void _openArtistDetail(BuildContext context, Map<String, dynamic> artist) {
    final artistDetailed = ArtistDetailed(
      artistId: artist['artistId'],
      name: artist['name'],
      thumbnails: [
        ThumbnailFull(url: artist['thumbnailUrl'], width: 0, height: 0),
      ],
      type: '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArtistContent(artist: artistDetailed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = context.select((SettingsProvider p) => p.accentColor);
    final provider = context.watch<FavoriteArtistProvider>();

    if (provider.favoriteArtists.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimens.paddingLg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'favorite_artists'.tr(),
                style: AppTextStyles.titleLg().copyWith(color: accentColor),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoriteArtistsScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? Colors.transparent
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
                    side: BorderSide(color: accentColor),
                  ),
                  fixedSize: Size(
                    AppDimens.buttonSizeCompact,
                    AppDimens.iconSm + 6,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spacingXs,
                    vertical: AppDimens.spacingXs,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'manage'.tr(),
                  style: AppTextStyles.finePrint().copyWith(color: accentColor),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: AppDimens.paddingLg),
            Expanded(
              child: SizedBox(
                height: AppDimens.headerImageSm + AppDimens.spacingSm + 40,
                child: provider.isFavoriteArtistsLoading
                    ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          return Container(
                            width:
                                AppDimens.headerImageSm + AppDimens.spacingXl,
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppDimens.spacingSm,
                            ),
                            child: ShimmerLoading.buildShimmerCard(),
                          );
                        },
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: provider.favoriteArtists.length,
                        itemBuilder: (context, index) {
                          final artist = provider.favoriteArtists[index];
                          return GestureDetector(
                            onTap: () => _openArtistDetail(context, artist),
                            child: Container(
                              width:
                                  AppDimens.headerImageSm + AppDimens.spacingXl,
                              margin: const EdgeInsets.symmetric(
                                horizontal: AppDimens.spacingSm,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ArtistAvatarWithPlayButton(
                                    artist: artist,
                                    isDarkMode: isDarkMode,
                                    accentColor: accentColor,
                                  ),
                                  const SizedBox(height: AppDimens.spacingSm),
                                  Text(
                                    artist['name'] ?? 'unknown_artist'.tr(),
                                    style: AppTextStyles.bodyMd(
                                      isDarkMode: isDarkMode,
                                    ),
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(width: AppDimens.paddingLg),
          ],
        ),
      ],
    );
  }
}

class ArtistAvatarWithPlayButton extends StatefulWidget {
  final Map<String, dynamic> artist;
  final bool isDarkMode;
  final Color accentColor;

  const ArtistAvatarWithPlayButton({
    Key? key,
    required this.artist,
    required this.isDarkMode,
    required this.accentColor,
  }) : super(key: key);

  @override
  State<ArtistAvatarWithPlayButton> createState() =>
      _ArtistAvatarWithPlayButtonState();
}

class _ArtistAvatarWithPlayButtonState
    extends State<ArtistAvatarWithPlayButton> {
  bool _isLoading = false;

  Future<void> _playArtistSongs() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final homeScreenQueueService = HomeScreenQueueService(context);
      await homeScreenQueueService.playArtistSongs(widget.artist['artistId']);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, 'Failed to play artist songs');
      debugPrint('Error playing artist songs: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      color: widget.accentColor.withValues(
        alpha: widget.isDarkMode ? 0.06 : 0.36,
      ),
      child: SizedBox(
        width: AppDimens.headerImageSm,
        height: AppDimens.headerImageSm,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusAvatar),

                child: CachedNetworkImage(
                  imageUrl: widget.artist['thumbnailUrl'] ?? '',
                  height: AppDimens.thumbnailLarge + AppDimens.spacingSm,
                  width: AppDimens.thumbnailLarge + AppDimens.spacingSm,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      ShimmerLoading.buildShimmerRect(
                        width: AppDimens.thumbnailLarge + AppDimens.spacingSm,
                        height: AppDimens.thumbnailLarge + AppDimens.spacingSm,
                        borderRadius: AppDimens.radiusAvatar,
                      ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[850],
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.spacingXs),
                child: Container(
                  width: AppDimens.iconStatus / 2,
                  height: AppDimens.iconStatus / 2,
                  decoration: BoxDecoration(
                    color: widget.accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Builder(
                    builder: (context) {
                      final playerProvider = context.watch<PlayerProvider>();
                      final isPlayingWithArtist =
                          playerProvider.isPlaying &&
                          playerProvider.currentSong?.artists.any(
                                (a) => a.id == widget.artist['artistId'],
                              ) ==
                              true;
                      final showLoading = _isLoading && !isPlayingWithArtist;
                      if (showLoading) {
                        return const Center(
                          child: SizedBox(
                            width: AppDimens.iconMd,
                            height: AppDimens.iconMd,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          ),
                        );
                      }
                      return IconButton(
                        icon: Icon(
                          isPlayingWithArtist ? Icons.pause : Icons.play_arrow,
                          color: MainScreenColors.getTextColor(
                            !widget.isDarkMode,
                          ),
                          size: AppDimens.iconSm,
                        ),
                        onPressed: isPlayingWithArtist
                            ? null
                            : _playArtistSongs,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
