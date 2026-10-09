import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'home_screen_shimmer.dart';
import '../../../../core/providers/favorite_song_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../data/services/home_screen_queue_service.dart';
import 'home_screen_helpers.dart';
import 'music_list_tile.dart';

class LikedSongsSection extends StatelessWidget {
  const LikedSongsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = context.select((SettingsProvider p) => p.accentColor);
    final favoriteSongProvider = context.watch<FavoriteSongProvider>();
    final homeScreenQueueService = HomeScreenQueueService(context);

    if (favoriteSongProvider.likedSongs.isEmpty) {
      return const SizedBox.shrink();
    }

    final itemCount = favoriteSongProvider.likedSongs.length;
    final itemHeight = AppDimens.miniPlayerHeightCompact;
    final rowsPerPage = AppDimens.isMobile(context) ? 3 : 4;
    final baseHeight = min(
      itemHeight * min(itemCount, rowsPerPage),
      AppDimens.shimmerSection,
    );

    final bottomGap = AppDimens.isMobile(context)
        ? AppDimens.spacingLg
        : AppDimens.spacing5Xl;

    final height = baseHeight + bottomGap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimens.paddingLg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'liked_songs'.tr(),
                style: AppTextStyles.titleLg().copyWith(color: accentColor),
              ),
            ],
          ),
        ),
        SizedBox(
          height: height,
          child: favoriteSongProvider.isLoadingLikedSongs
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Container(
                      width: AppDimens.maxContentWidth * 0.25,
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppDimens.spacingSm,
                      ),
                      child: ShimmerLoading.buildShimmerList(),
                    );
                  },
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount:
                      (favoriteSongProvider.likedSongs.length / rowsPerPage)
                          .ceil(),
                  itemBuilder: (context, pageIndex) {
                    final startIndex = pageIndex * rowsPerPage;
                    final endIndex = min(
                      startIndex + rowsPerPage,
                      favoriteSongProvider.likedSongs.length,
                    );
                    final pageItems = favoriteSongProvider.likedSongs.sublist(
                      startIndex,
                      endIndex,
                    );

                    return Container(
                      width: AppDimens.maxContentWidth * 0.25,
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppDimens.spacingSm,
                      ),
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: pageItems.length,
                        itemBuilder: (context, index) {
                          final song = pageItems[index];
                          final globalIndex = pageIndex * rowsPerPage + index;
                          return MusicListTile(
                            song: song,
                            onTap: () async {
                              try {
                                await homeScreenQueueService.playAll(
                                  'liked_songs',
                                  currentIndex: globalIndex,
                                );
                              } catch (e) {
                                showErrorSnackbar(
                                  context,
                                  'Failed to play song: ${e.toString()}',
                                );
                              }
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
