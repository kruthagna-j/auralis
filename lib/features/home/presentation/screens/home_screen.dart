import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/stat_section.dart';
import '../widgets/favorite_artists_section.dart';
import '../widgets/home_sections.dart';
import '../widgets/last_played_section.dart';
import '../widgets/liked_songs_section.dart';
import '../widgets/recent_playlists_section.dart';
import '../../../../core/providers/favorite_song_provider.dart';
import '../../data/providers/home_screen_provider.dart';
import '../../../../shared/components/song_list_tile.dart';
import '../../../../core/models/song_model.dart';
import '../../data/services/home_screen_queue_service.dart';
import '../../../trending/data/provider/trending_provider.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/components/app_snackbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FavoriteSongProvider>(
        context,
        listen: false,
      ).loadLikedSongs();
    });
  }

  Future<void> _onRefresh(BuildContext context) async {
    final homeScreenProvider = Provider.of<HomeScreenProvider>(
      context,
      listen: false,
    );

    await homeScreenProvider.refreshData();
  }

  int _selectedIndex = 0;
  int _trendingSubIndex = 0;

  void _showCountrySelectionDialog(BuildContext context) {
    final trendingProvider = Provider.of<TrendingProvider>(
      context,
      listen: false,
    );
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final accentColor = settingsProvider.accentColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    int selectedIndex = -1;
    if (trendingProvider.selectedCountry != null) {
      selectedIndex = trendingProvider.countries.indexWhere(
        (country) => country.name == trendingProvider.selectedCountry!.name,
      );
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final ScrollController scrollController = ScrollController();

        if (selectedIndex != -1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scrollController.hasClients) {
              const double itemHeight = AppDimens.shimmerListTile;
              final double targetPosition = selectedIndex * itemHeight;
              final double maxScrollExtent =
                  scrollController.position.maxScrollExtent;
              final double viewportHeight =
                  scrollController.position.viewportDimension;

              double scrollToPosition =
                  targetPosition - (viewportHeight / 2) + (itemHeight / 2);

              scrollToPosition = scrollToPosition.clamp(0.0, maxScrollExtent);

              scrollController.animateTo(
                scrollToPosition,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;
            final maxDialogWidth = min(
              AppDimens.breakpointWideScreen,
              screenWidth * 0.85,
            );
            final maxDialogHeight = screenHeight * 0.7;

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxDialogWidth,
                  maxHeight: maxDialogHeight,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDimens.paddingXl),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppDimens.radiusXxl),
                            topRight: Radius.circular(AppDimens.radiusXxl),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.public,
                              color: accentColor,
                              size: AppDimens.iconLg,
                            ),
                            const SizedBox(width: AppDimens.spacingMd),
                            Expanded(
                              child: Text(
                                'Select Country'.tr(),
                                style: AppTextStyles.titleSm(
                                  isDarkMode: isDarkMode,
                                  color: accentColor,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                padding: const EdgeInsets.all(
                                  AppDimens.paddingXs,
                                ),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(
                                    AppDimens.radiusSm,
                                  ),
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                  size: AppDimens.iconMd,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SizedBox(
                          height: maxDialogHeight - 80,
                          child: ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppDimens.spacingSm,
                            ),
                            itemCount: trendingProvider.countries.length,
                            itemBuilder: (BuildContext context, int index) {
                              final country = trendingProvider.countries[index];
                              final isSelected =
                                  trendingProvider.selectedCountry?.name ==
                                  country.name;

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: AppDimens.paddingMd,
                                  vertical: AppDimens.spacingXxs,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? accentColor.withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    AppDimens.radiusLg,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppDimens.paddingLg,
                                    vertical: AppDimens.paddingXs,
                                  ),
                                  leading: Container(
                                    width: AppDimens.thumbnailMini,
                                    height: AppDimens.thumbnailMini,
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.radiusMd,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        country.flag,
                                        style: const TextStyle(
                                          fontSize: AppTextStyles.fontSizeBody,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    country.name,
                                    style:
                                        AppTextStyles.subtitle(
                                          isDarkMode: isDarkMode,
                                          color: isSelected
                                              ? accentColor
                                              : isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ).copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                  ),
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check_circle,
                                          color: accentColor,
                                          size: AppDimens.iconLg,
                                        )
                                      : null,
                                  onTap: () {
                                    trendingProvider.setSelectedCountry(
                                      country,
                                    );
                                    Navigator.of(context).pop();
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimens.spacingSm),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabs(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = context.select((SettingsProvider p) => p.accentColor);

    Widget tab(String title, int index) {
      final selected = _selectedIndex == index;
      return GestureDetector(
        onTap: () async {
          setState(() => _selectedIndex = index);

          if (index == 1) {
            final trendingProvider = Provider.of<TrendingProvider>(
              context,
              listen: false,
            );

            if (_trendingSubIndex == 0) {
              if (trendingProvider.selectedCountry != null) {
                final pid = trendingProvider.selectedCountry!.playlistId;
                if (trendingProvider.getTrendingSongs(pid).isEmpty) {
                  trendingProvider.loadTrendingSongs(pid);
                }
              } else {
                if (trendingProvider
                    .getTrendingSongs(TrendingProvider.top100GlobalPlaylistId)
                    .isEmpty) {
                  trendingProvider.loadTrendingSongs(
                    TrendingProvider.top100GlobalPlaylistId,
                  );
                }
              }
            } else {
              if (trendingProvider
                  .getTrendingSongs(TrendingProvider.top100GlobalPlaylistId)
                  .isEmpty) {
                trendingProvider.loadTrendingSongs(
                  TrendingProvider.top100GlobalPlaylistId,
                );
              }
            }
          }

          if (index == 2) {
            final favoriteProvider = Provider.of<FavoriteSongProvider>(
              context,
              listen: false,
            );
            if (favoriteProvider.likedSongs.isEmpty) {
              favoriteProvider.loadLikedSongs();
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingMd,
            vertical: AppDimens.paddingXs,
          ),
          margin: const EdgeInsets.only(right: AppDimens.spacingSm),
          decoration: BoxDecoration(
            color: selected
                ? accentColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
            border: Border.all(
              color: selected
                  ? accentColor.withValues(alpha: 0.25)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            title,
            style:
                AppTextStyles.bodyMd(
                  isDarkMode: isDarkMode,
                  color: selected ? accentColor : null,
                ).copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingLg),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            tab('all'.tr(), 0),
            tab('trending'.tr(), 1),
            tab('favorites'.tr(), 2),
            tab('recently_played'.tr(), 3),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTrendingSlivers(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = context.select((SettingsProvider p) => p.accentColor);
    final trendingProvider = Provider.of<TrendingProvider>(context);

    Widget subTab(String title, int index, {VoidCallback? onLongPress}) {
      final selected = _trendingSubIndex == index;
      return GestureDetector(
        onTap: () {
          setState(() => _trendingSubIndex = index);

          if (index == 0) {
            if (trendingProvider.selectedCountry == null ||
                (selected && index == 0)) {
              _showCountrySelectionDialog(context);
            } else {
              if (trendingProvider
                  .getTrendingSongs(
                    trendingProvider.selectedCountry!.playlistId,
                  )
                  .isEmpty) {
                trendingProvider.loadTrendingSongs(
                  trendingProvider.selectedCountry!.playlistId,
                );
              }
            }
          } else if (index == 1) {
            if (trendingProvider
                .getTrendingSongs(TrendingProvider.top100GlobalPlaylistId)
                .isEmpty) {
              trendingProvider.loadTrendingSongs(
                TrendingProvider.top100GlobalPlaylistId,
              );
            }
          }
        },
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingMd,
            vertical: AppDimens.paddingXs,
          ),
          margin: const EdgeInsets.only(right: AppDimens.spacingSm),
          decoration: BoxDecoration(
            color: selected
                ? accentColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(
              color: selected
                  ? accentColor.withValues(alpha: 0.25)
                  : (isDarkMode ? Colors.white10 : Colors.black12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style:
                    AppTextStyles.bodyMd(
                      isDarkMode: isDarkMode,
                      color: selected ? accentColor : null,
                    ).copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
              if (index == 0) ...[
                const SizedBox(width: AppDimens.spacingXs),
                Icon(
                  Icons.arrow_drop_down,
                  color: selected
                      ? accentColor
                      : (isDarkMode ? Colors.white70 : Colors.black54),
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      );
    }

    String countryTitle = 'Country';
    if (trendingProvider.selectedCountry != null) {
      countryTitle =
          '${trendingProvider.selectedCountry!.flag} ${trendingProvider.selectedCountry!.name}';
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingLg,
            vertical: AppDimens.paddingSm,
          ),
          child: Row(children: [subTab(countryTitle, 0), subTab('Global', 1)]),
        ),
      ),
      _buildTrendingSliverList(context),
    ];
  }

  Widget _buildTrendingSliverList(BuildContext context) {
    final trendingProvider = Provider.of<TrendingProvider>(context);

    String playlistId;
    if (_trendingSubIndex == 0) {
      if (trendingProvider.selectedCountry == null) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingLg),
            child: Center(
              child: Column(
                children: [
                  Text('No country selected.'),
                  TextButton(
                    onPressed: () => _showCountrySelectionDialog(context),
                    child: Text('Select Country'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      playlistId = trendingProvider.selectedCountry!.playlistId;
    } else {
      playlistId = TrendingProvider.top100GlobalPlaylistId;
    }

    final songs = trendingProvider.getTrendingSongs(playlistId);
    final isLoading = trendingProvider.isLoading(playlistId);

    if (isLoading && songs.isEmpty) {
      final accentColor = context.select((SettingsProvider p) => p.accentColor);
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingLg),
          child: Center(child: CircularProgressIndicator(color: accentColor)),
        ),
      );
    }

    if (songs.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingLg),
          child: Center(child: Text('No trending songs found.')),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final song = songs[index];

        return Builder(
          builder: (itemContext) {
            final isPlaying = itemContext.select<PlayerProvider, bool>(
              (p) => p.currentSong?.videoId == song.videoId,
            );
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final accentColor = itemContext.select(
              (SettingsProvider p) => p.accentColor,
            );

            return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingLg,
                vertical: AppDimens.spacingXxs,
              ),
              decoration: BoxDecoration(
                color: isPlaying
                    ? accentColor.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: SongListTile(
                song: song,
                onPlay: () {
                  final playlistName = _trendingSubIndex == 0
                      ? (trendingProvider.selectedCountry != null
                            ? '${trendingProvider.selectedCountry!.name} Trending'
                            : 'Country Trending')
                      : 'Global Trending';

                  trendingProvider.playSong(
                    song,
                    context,
                    playlistId,
                    playlistName: playlistName,
                  );
                },
                isDarkMode: isDark,
                isPlaying: isPlaying,
              ),
            );
          },
        );
      }, childCount: songs.length),
    );
  }

  Widget _buildMapSliverList(
    BuildContext context,
    List<Map<String, dynamic>> list,
    String playlistType,
  ) {
    if (list.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingLg),
          child: Center(child: Text('no_songs_found'.tr())),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final songMap = list[index];

        final songInfo = SongInfo(
          videoId: songMap['id'] ?? songMap['videoId'] ?? '',
          name: songMap['title'] ?? songMap['name'] ?? '',
          artists:
              (songMap['artists'] as List<dynamic>?)
                  ?.map(
                    (a) => Artist(
                      name: (a is Map)
                          ? (a['name'] ?? '') as String
                          : a.toString(),
                      id: (a is Map) ? (a['id'] ?? '') as String : '',
                    ),
                  )
                  .toList() ??
              [
                Artist(
                  name: songMap['artist'] ?? '',
                  id: songMap['artistId'] ?? '',
                ),
              ],
          thumbnails: [
            Thumbnail(url: songMap['thumbnail'] ?? '', width: 480, height: 360),
          ],
          duration: Duration(seconds: songMap['duration'] ?? 0),
        );

        return Builder(
          builder: (itemContext) {
            final isPlaying = itemContext.select<PlayerProvider, bool>(
              (p) => p.currentSong?.videoId == songInfo.videoId,
            );
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final accentColor = itemContext.select(
              (SettingsProvider p) => p.accentColor,
            );

            return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingLg,
                vertical: AppDimens.spacingXxs,
              ),
              decoration: BoxDecoration(
                color: isPlaying
                    ? accentColor.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: SongListTile(
                song: songInfo,
                onPlay: () async {
                  try {
                    await HomeScreenQueueService(
                      context,
                    ).playAll(playlistType, currentIndex: index);
                  } catch (e) {
                    print('Error playing song: $e');
                    AppSnackBar.showError(
                      context,
                      'failed_to_play_song_error'.tr(),
                    );
                  }
                },
                isDarkMode: isDark,
                isPlaying: isPlaying,
              ),
            );
          },
        );
      }, childCount: list.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = context.select((SettingsProvider p) => p.accentColor);

    return RefreshIndicator(
      color: accentColor,
      onRefresh: () => _onRefresh(context),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: _buildTabs(context)),
          if (_selectedIndex == 0) ...[
            SliverToBoxAdapter(child: RecentPlaylistsSection()),
            SliverToBoxAdapter(child: StatsSection()),
            SliverToBoxAdapter(child: LastPlayedSection()),
            SliverToBoxAdapter(child: LikedSongsSection()),
            SliverToBoxAdapter(child: FavoriteArtistsSection()),
            SliverToBoxAdapter(child: HomeSections()),
          ] else if (_selectedIndex == 1) ...[
            ..._buildTrendingSlivers(context),
          ] else if (_selectedIndex == 2) ...[
            _buildMapSliverList(
              context,
              Provider.of<FavoriteSongProvider>(context).likedSongs,
              'liked_songs',
            ),
          ] else ...[
            _buildMapSliverList(
              context,
              Provider.of<PlayerProvider>(context).lastPlayedSongs,
              'recently_played',
            ),
          ],
          SliverToBoxAdapter(child: SizedBox(height: AppDimens.paddingXl)),
        ],
      ),
    );
  }
}
