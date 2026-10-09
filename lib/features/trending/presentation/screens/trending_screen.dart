import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../data/provider/trending_provider.dart';
import '../../../../shared/components/song_list_tile.dart';
import '../../../../core/providers/player_provider.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({Key? key}) : super(key: key);

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final trendingProvider = Provider.of<TrendingProvider>(
        context,
        listen: false,
      );
      if (trendingProvider.selectedCountry != null &&
          trendingProvider
              .getTrendingSongs(trendingProvider.selectedCountry!.playlistId)
              .isEmpty) {
        trendingProvider.loadTrendingSongs(
          trendingProvider.selectedCountry!.playlistId,
        );
      }
      if (trendingProvider
          .getTrendingSongs(TrendingProvider.top100GlobalPlaylistId)
          .isEmpty) {
        trendingProvider.loadTrendingSongs(
          TrendingProvider.top100GlobalPlaylistId,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      final trendingProvider = Provider.of<TrendingProvider>(
        context,
        listen: false,
      );
      if (_tabController.index == 0) {
        if (trendingProvider.selectedCountry != null &&
            trendingProvider
                .getTrendingSongs(trendingProvider.selectedCountry!.playlistId)
                .isEmpty) {
          trendingProvider.loadTrendingSongs(
            trendingProvider.selectedCountry!.playlistId,
          );
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
  }

  void _showCountrySelectionDialog(
    BuildContext context,
    TrendingProvider trendingProvider,
  ) {
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
                                              : (isDarkMode
                                                    ? Colors.white
                                                    : Colors.black87),
                                        ).copyWith(
                                          fontWeight: isSelected
                                              ? AppTextStyles.weightSemiBold
                                              : AppTextStyles.weightMedium,
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

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: true,
    );
    final accentColor = settingsProvider.accentColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final isDesktopLayout =
        MediaQuery.of(context).size.width >= AppDimens.breakpointDesktopLarge;

    return Scaffold(
      body: Consumer<TrendingProvider>(
        builder: (context, trendingProvider, child) {
          return Column(
            children: [
              if (!isDesktopLayout)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingLg,
                    vertical: AppDimens.spacingMd,
                  ),
                  child: Container(
                    height: AppDimens.buttonSizeDefault,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(
                          AppDimens.radiusFull,
                        ),
                      ),
                      labelColor: accentColor,
                      unselectedLabelColor: isDarkMode
                          ? Colors.white70
                          : Colors.black87,
                      tabs: [
                        Tab(
                          child: GestureDetector(
                            onTap: () {
                              _showCountrySelectionDialog(
                                context,
                                trendingProvider,
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (trendingProvider.selectedCountry !=
                                    null) ...[
                                  Text(trendingProvider.selectedCountry!.flag),
                                  SizedBox(width: AppDimens.spacingS),
                                  Text(trendingProvider.selectedCountry!.name),
                                  SizedBox(width: AppDimens.spacingXs),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    size: AppDimens.iconXs,
                                  ),
                                ] else ...[
                                  Icon(Icons.flag),
                                  SizedBox(width: AppDimens.spacingS),
                                  Text('By Country'.tr()),
                                ],
                              ],
                            ),
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.public),
                              SizedBox(width: AppDimens.spacingS),
                              Text('100 Global'.tr()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: isDesktopLayout
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.spacingSm,
                          vertical: AppDimens.spacingS,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppDimens.paddingMd,
                                      vertical: AppDimens.paddingSm,
                                    ),
                                    child: GestureDetector(
                                      onTap: () => _showCountrySelectionDialog(
                                        context,
                                        trendingProvider,
                                      ),
                                      child: Row(
                                        children: [
                                          if (trendingProvider
                                                  .selectedCountry !=
                                              null) ...[
                                            Text(
                                              trendingProvider
                                                  .selectedCountry!
                                                  .flag,
                                            ),
                                            const SizedBox(
                                              width: AppDimens.spacingS,
                                            ),
                                            Text(
                                              trendingProvider
                                                  .selectedCountry!
                                                  .name,
                                            ),
                                            const SizedBox(
                                              width: AppDimens.spacingXs,
                                            ),
                                            Icon(
                                              Icons.arrow_drop_down,
                                              size: AppDimens.iconXs,
                                            ),
                                          ] else ...[
                                            const Icon(Icons.flag),
                                            const SizedBox(
                                              width: AppDimens.spacingS,
                                            ),
                                            Text('By Country'.tr()),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildCountryTab(
                                      context,
                                      trendingProvider,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            VerticalDivider(
                              width: AppDimens.dividerHeight,
                              color: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[300],
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppDimens.paddingMd,
                                      vertical: AppDimens.paddingSm,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.public),
                                        const SizedBox(
                                          width: AppDimens.spacingS,
                                        ),
                                        Text('100 Global'.tr()),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildSongList(
                                      context,
                                      trendingProvider,
                                      TrendingProvider.top100GlobalPlaylistId,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildCountryTab(context, trendingProvider),
                          _buildSongList(
                            context,
                            trendingProvider,
                            TrendingProvider.top100GlobalPlaylistId,
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCountryTab(
    BuildContext context,
    TrendingProvider trendingProvider,
  ) {
    final selectedCountry = trendingProvider.selectedCountry;
    if (selectedCountry == null) {
      return Center(child: Text('No country selected'.tr()));
    }
    final currentPlaylistId = selectedCountry.playlistId;
    final currentTrendingSongs = trendingProvider.getTrendingSongs(
      currentPlaylistId,
    );
    final isLoading = trendingProvider.isLoading(currentPlaylistId);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: true,
    );
    final accentColor = settingsProvider.accentColor;

    return isLoading && currentTrendingSongs.isEmpty
        ? Center(child: CircularProgressIndicator(color: accentColor))
        : _buildSongList(context, trendingProvider, currentPlaylistId);
  }

  Widget _buildSongList(
    BuildContext context,
    TrendingProvider trendingProvider,
    String playlistId,
  ) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: true,
    );
    final accentColor = settingsProvider.accentColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final songs = trendingProvider.getTrendingSongs(playlistId);
    final isLoading = trendingProvider.isLoading(playlistId);

    if (isLoading && songs.isEmpty) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    return RefreshIndicator(
      color: accentColor,
      onRefresh: () async {
        await trendingProvider.refreshTrendingSongs(playlistId);
      },
      child: songs.isEmpty
          ? LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Text(
                        'No trending songs found for this category.'.tr(),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                );
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppDimens.paddingLg),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return Builder(
                  builder: (context) {
                    final isPlayingSong = context.select<PlayerProvider, bool>(
                      (p) => p.currentSong?.videoId == song.videoId,
                    );
                    return Container(
                      decoration: BoxDecoration(
                        color: isPlayingSong
                            ? accentColor.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SongListTile(
                        song: song,
                        onPlay: () {
                          String playlistName;
                          if (playlistId ==
                              TrendingProvider.top100GlobalPlaylistId) {
                            playlistName = 'Global Trending';
                          } else {
                            try {
                              final country = trendingProvider.countries
                                  .firstWhere(
                                    (c) => c.playlistId == playlistId,
                                  );
                              playlistName = '${country.name} Trending';
                            } catch (_) {
                              playlistName = 'Trending';
                            }
                          }

                          trendingProvider.playSong(
                            song,
                            context,
                            playlistId,
                            playlistName: playlistName,
                          );
                        },
                        isDarkMode: isDarkMode,
                        isPlaying: isPlayingSong,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
