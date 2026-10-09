import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:dart_ytmusic_api/yt_music.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/favorite_artist_provider.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../shared/components/app_snackbar.dart';

class ArtistSetupScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const ArtistSetupScreen({Key? key, required this.onComplete})
    : super(key: key);

  @override
  State<ArtistSetupScreen> createState() => _ArtistSetupScreenState();
}

class _ArtistSetupScreenState extends State<ArtistSetupScreen> {
  final YTMusic _ytMusic = GetIt.I<YTMusic>();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeYTMusic();
  }

  Future<void> _initializeYTMusic() async {
    final connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );
    if (connectivityProvider.hasInternet) {
      await _ytMusic.initialize();
    } else {
      if (mounted) {
        AppSnackBar.showError(
          context,
          'No internet connection. Cannot initialize music services.',
        );
      }
    }
  }

  Future<void> _searchArtists(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    final connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );

    if (!connectivityProvider.hasInternet) {
      AppSnackBar.showError(
        context,
        'No internet connection. Cannot search artists.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _ytMusic.searchArtists(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _searchResults.clear();
      });
      if (mounted) {
        AppSnackBar.showError(context, 'Error searching artists');
      }
    }
  }

  Future<void> _toggleFavorite(dynamic artist) async {
    final provider = Provider.of<FavoriteArtistProvider>(
      context,
      listen: false,
    );
    await provider.toggleFavorite(artist);
  }

  Future<void> _saveAndContinue() async {
    final provider = Provider.of<FavoriteArtistProvider>(
      context,
      listen: false,
    );

    await provider.loadFavoriteArtists();
    widget.onComplete();
  }

  void _skip() {
    widget.onComplete();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = settingsProvider.themeMode == ThemeMode.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MainScreenColors.getBackgroundColor(isDarkMode),
            MainScreenColors.getSurfaceColor(isDarkMode),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLarge = constraints.maxWidth > AppDimens.breakpointMobile;
              return Column(
                children: [
                  Expanded(
                    child: isLarge
                        ? Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    AppDimens.spacingXxxl,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'add_your_artists'.tr(),
                                        style: AppTextStyles.displayLg(
                                          isDarkMode: isDarkMode,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: AppDimens.spacingMd,
                                      ),
                                      Text(
                                        'add_your_artists_description'.tr(),
                                        style: AppTextStyles.subtitle(
                                          isDarkMode: isDarkMode,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: AppDimens.spacingXl,
                                      ),
                                      TextField(
                                        controller: _searchController,
                                        style: AppTextStyles.bodyMd(
                                          isDarkMode: isDarkMode,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'search_artists'.tr(),
                                          hintStyle:
                                              AppTextStyles.bodyMd(
                                                isDarkMode: isDarkMode,
                                              ).copyWith(
                                                color:
                                                    MainScreenColors.getTextColor(
                                                      isDarkMode,
                                                    ).withValues(alpha: 0.5),
                                              ),
                                          prefixIcon: Icon(
                                            Icons.search,
                                            color:
                                                MainScreenColors.getTextColor(
                                                  isDarkMode,
                                                ).withValues(alpha: 0.5),
                                          ),
                                          filled: true,
                                          fillColor:
                                              MainScreenColors.getSurfaceColor(
                                                isDarkMode,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppDimens.radiusLg,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppDimens.radiusLg,
                                            ),
                                            borderSide: BorderSide(
                                              color:
                                                  MainScreenColors.getPrimaryColor(
                                                    isDarkMode,
                                                  ),
                                              width: AppDimens.elevationLow,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: AppDimens.paddingLg,
                                                vertical: AppDimens.paddingLg,
                                              ),
                                        ),
                                        onChanged: _searchArtists,
                                      ),
                                      const SizedBox(
                                        height: AppDimens.spacingXl,
                                      ),
                                      Consumer<FavoriteArtistProvider>(
                                        builder: (context, provider, child) {
                                          if (provider
                                              .favoriteArtists
                                              .isNotEmpty) {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'your_favorites'.tr(),
                                                  style: AppTextStyles.titleSm(
                                                    isDarkMode: isDarkMode,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: AppDimens.spacingMd,
                                                ),
                                                ...List.generate(
                                                  provider
                                                      .favoriteArtists
                                                      .length,
                                                  (index) {
                                                    final artist = provider
                                                        .favoriteArtists[index];
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: AppDimens
                                                                .spacingMd,
                                                          ),
                                                      child: Container(
                                                        width: double.infinity,
                                                        decoration: BoxDecoration(
                                                          color:
                                                              MainScreenColors.getSurfaceColor(
                                                                isDarkMode,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                AppDimens
                                                                    .radiusXl,
                                                              ),
                                                          border: Border.all(
                                                            color:
                                                                MainScreenColors.getPrimaryColor(
                                                                  isDarkMode,
                                                                ),
                                                            width: AppDimens
                                                                .elevationLow,
                                                          ),
                                                        ),
                                                        child: ListTile(
                                                          contentPadding:
                                                              const EdgeInsets.all(
                                                                AppDimens
                                                                    .paddingSm,
                                                              ),
                                                          leading: CircleAvatar(
                                                            radius: AppDimens
                                                                .radiusAvatar,
                                                            backgroundImage:
                                                                artist['thumbnailUrl'] !=
                                                                    null
                                                                ? NetworkImage(
                                                                    artist['thumbnailUrl'],
                                                                  )
                                                                : null,
                                                            backgroundColor:
                                                                MainScreenColors.getSurfaceColor(
                                                                  isDarkMode,
                                                                ),
                                                            child:
                                                                artist['thumbnailUrl'] ==
                                                                    null
                                                                ? Icon(
                                                                    Icons
                                                                        .person,
                                                                    color: MainScreenColors.getTextColor(
                                                                      isDarkMode,
                                                                    ),
                                                                  )
                                                                : null,
                                                          ),
                                                          title: Text(
                                                            artist['name'],
                                                            style:
                                                                AppTextStyles.titleSm(
                                                                  isDarkMode:
                                                                      isDarkMode,
                                                                ),
                                                          ),
                                                          trailing: IconButton(
                                                            icon: Icon(
                                                              Icons.favorite,
                                                              color: Colors.red,
                                                              size: AppDimens
                                                                  .iconXl,
                                                            ),
                                                            onPressed: () =>
                                                                _toggleFavorite(
                                                                  artist,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    if (_isLoading)
                                      Expanded(
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  MainScreenColors.getPrimaryColor(
                                                    isDarkMode,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      )
                                    else if (_searchResults.isNotEmpty)
                                      Expanded(
                                        child: ListView.builder(
                                          itemCount: _searchResults.length,
                                          itemBuilder: (context, index) {
                                            final artist =
                                                _searchResults[index];
                                            return Consumer<
                                              FavoriteArtistProvider
                                            >(
                                              builder: (context, provider, child) {
                                                final isFavorite = provider
                                                    .favoriteArtists
                                                    .any(
                                                      (favArtist) =>
                                                          favArtist['artistId'] ==
                                                          artist.artistId,
                                                    );
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: AppDimens
                                                            .paddingXxl,
                                                        vertical:
                                                            AppDimens.spacingS,
                                                      ),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color:
                                                          MainScreenColors.getSurfaceColor(
                                                            isDarkMode,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            AppDimens.radiusLg,
                                                          ),
                                                      border: Border.all(
                                                        color: isFavorite
                                                            ? MainScreenColors.getPrimaryColor(
                                                                isDarkMode,
                                                              )
                                                            : Colors
                                                                  .transparent,
                                                        width: AppDimens
                                                            .elevationLow,
                                                      ),
                                                    ),
                                                    child: ListTile(
                                                      contentPadding:
                                                          const EdgeInsets.all(
                                                            AppDimens.paddingSm,
                                                          ),
                                                      leading: CircleAvatar(
                                                        radius: AppDimens
                                                            .radiusAvatar,
                                                        backgroundImage:
                                                            artist
                                                                    .thumbnails
                                                                    ?.isNotEmpty ==
                                                                true
                                                            ? NetworkImage(
                                                                artist
                                                                    .thumbnails!
                                                                    .last
                                                                    .url,
                                                              )
                                                            : null,
                                                        backgroundColor:
                                                            MainScreenColors.getSurfaceColor(
                                                              isDarkMode,
                                                            ),
                                                        child:
                                                            artist
                                                                    .thumbnails
                                                                    ?.isEmpty ==
                                                                true
                                                            ? Icon(
                                                                Icons.person,
                                                                color:
                                                                    MainScreenColors.getTextColor(
                                                                      isDarkMode,
                                                                    ),
                                                                size: AppDimens
                                                                    .iconMd,
                                                              )
                                                            : null,
                                                      ),
                                                      title: Text(
                                                        artist.name,
                                                        style:
                                                            AppTextStyles.subtitle(
                                                              isDarkMode:
                                                                  isDarkMode,
                                                            ),
                                                      ),
                                                      trailing: IconButton(
                                                        icon: Icon(
                                                          isFavorite
                                                              ? Icons.favorite
                                                              : Icons
                                                                    .favorite_border,
                                                          color: isFavorite
                                                              ? Colors.red
                                                              : (isDarkMode
                                                                    ? Colors
                                                                          .white70
                                                                    : Colors
                                                                          .black54),
                                                          size:
                                                              AppDimens.iconLg,
                                                        ),
                                                        onPressed: () =>
                                                            _toggleFavorite(
                                                              artist,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      )
                                    else
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            'Search for artists to get started',
                                            style: AppTextStyles.headingLg(
                                              isDarkMode: isDarkMode,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    AppDimens.paddingXl,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Add Your Artists',
                                        style: AppTextStyles.displayLg(
                                          isDarkMode: isDarkMode,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: AppDimens.spacingXl,
                                      ),
                                      Text(
                                        'Search your favorite artists to personalize your experience',
                                        style: AppTextStyles.subtitle(
                                          isDarkMode: isDarkMode,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: AppDimens.spacingXxl,
                                      ),
                                      TextField(
                                        controller: _searchController,
                                        style: AppTextStyles.bodyMd(
                                          isDarkMode: isDarkMode,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Search artists...',
                                          hintStyle:
                                              AppTextStyles.bodyMd(
                                                isDarkMode: isDarkMode,
                                              ).copyWith(
                                                color:
                                                    MainScreenColors.getTextColor(
                                                      isDarkMode,
                                                    ).withValues(alpha: 0.5),
                                              ),
                                          prefixIcon: Icon(
                                            Icons.search,
                                            color:
                                                MainScreenColors.getTextColor(
                                                  isDarkMode,
                                                ).withValues(alpha: 0.5),
                                          ),
                                          filled: true,
                                          fillColor:
                                              MainScreenColors.getSurfaceColor(
                                                isDarkMode,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppDimens.radiusXl,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppDimens.radiusXl,
                                            ),
                                            borderSide: BorderSide(
                                              color:
                                                  MainScreenColors.getPrimaryColor(
                                                    isDarkMode,
                                                  ),
                                              width: AppDimens.elevationLow,
                                            ),
                                          ),
                                        ),
                                        onChanged: _searchArtists,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_isLoading)
                                SliverFillRemaining(
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        MainScreenColors.getPrimaryColor(
                                          isDarkMode,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else if (_searchResults.isNotEmpty)
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppDimens.paddingXl,
                                  ),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      index,
                                    ) {
                                      final artist = _searchResults[index];

                                      return Consumer<FavoriteArtistProvider>(
                                        builder: (context, provider, child) {
                                          final isFavorite = provider
                                              .favoriteArtists
                                              .any(
                                                (favArtist) =>
                                                    favArtist['artistId'] ==
                                                    artist.artistId,
                                              );

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: AppDimens.spacingMd,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color:
                                                    MainScreenColors.getSurfaceColor(
                                                      isDarkMode,
                                                    ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppDimens.radiusXl,
                                                    ),
                                                border: Border.all(
                                                  color: isFavorite
                                                      ? MainScreenColors.getPrimaryColor(
                                                          isDarkMode,
                                                        )
                                                      : Colors.transparent,
                                                  width: AppDimens.elevationLow,
                                                ),
                                              ),
                                              child: ListTile(
                                                contentPadding:
                                                    const EdgeInsets.all(
                                                      AppDimens.paddingSm,
                                                    ),
                                                leading: CircleAvatar(
                                                  radius:
                                                      AppDimens.radiusAvatar,
                                                  backgroundImage:
                                                      artist
                                                              .thumbnails
                                                              ?.isNotEmpty ==
                                                          true
                                                      ? NetworkImage(
                                                          artist
                                                              .thumbnails!
                                                              .last
                                                              .url,
                                                        )
                                                      : null,
                                                  backgroundColor:
                                                      MainScreenColors.getSurfaceColor(
                                                        isDarkMode,
                                                      ),
                                                  child:
                                                      artist
                                                              .thumbnails
                                                              ?.isEmpty ==
                                                          true
                                                      ? Icon(
                                                          Icons.person,
                                                          color:
                                                              MainScreenColors.getTextColor(
                                                                isDarkMode,
                                                              ),
                                                        )
                                                      : null,
                                                ),
                                                title: Text(
                                                  artist.name,
                                                  style: AppTextStyles.titleSm(
                                                    isDarkMode: isDarkMode,
                                                  ),
                                                ),
                                                trailing: IconButton(
                                                  icon: Icon(
                                                    isFavorite
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                    color: isFavorite
                                                        ? Colors.red
                                                        : (isDarkMode
                                                              ? Colors.white70
                                                              : Colors.black54),
                                                    size: AppDimens.iconXl,
                                                  ),
                                                  onPressed: () =>
                                                      _toggleFavorite(artist),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }, childCount: _searchResults.length),
                                  ),
                                ),
                              Consumer<FavoriteArtistProvider>(
                                builder: (context, provider, child) {
                                  if (provider.favoriteArtists.isNotEmpty &&
                                      _searchResults.isEmpty) {
                                    return SliverPadding(
                                      padding: const EdgeInsets.all(
                                        AppDimens.paddingXl,
                                      ),
                                      sliver: SliverToBoxAdapter(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Your Favorites',
                                              style: AppTextStyles.titleSm(
                                                isDarkMode: isDarkMode,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: AppDimens.spacingXl,
                                            ),
                                            ...List.generate(provider.favoriteArtists.length, (
                                              index,
                                            ) {
                                              final artist = provider
                                                  .favoriteArtists[index];
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: AppDimens.spacingMd,
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color:
                                                        MainScreenColors.getSurfaceColor(
                                                          isDarkMode,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          AppDimens.radiusXl,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          MainScreenColors.getPrimaryColor(
                                                            isDarkMode,
                                                          ),
                                                      width: AppDimens
                                                          .elevationLow,
                                                    ),
                                                  ),
                                                  child: ListTile(
                                                    contentPadding:
                                                        const EdgeInsets.all(
                                                          AppDimens.paddingSm,
                                                        ),
                                                    leading: CircleAvatar(
                                                      radius: AppDimens
                                                          .radiusAvatar,
                                                      backgroundImage:
                                                          artist['thumbnailUrl'] !=
                                                              null
                                                          ? NetworkImage(
                                                              artist['thumbnailUrl'],
                                                            )
                                                          : null,
                                                      backgroundColor:
                                                          MainScreenColors.getSurfaceColor(
                                                            isDarkMode,
                                                          ),
                                                      child:
                                                          artist['thumbnailUrl'] ==
                                                              null
                                                          ? Icon(
                                                              Icons.person,
                                                              color:
                                                                  MainScreenColors.getTextColor(
                                                                    isDarkMode,
                                                                  ),
                                                            )
                                                          : null,
                                                    ),
                                                    title: Text(
                                                      artist['name'],
                                                      style:
                                                          AppTextStyles.titleSm(
                                                            isDarkMode:
                                                                isDarkMode,
                                                          ),
                                                    ),
                                                    trailing: IconButton(
                                                      icon: Icon(
                                                        Icons.favorite,
                                                        color: Colors.red,
                                                        size: AppDimens.iconXl,
                                                      ),
                                                      onPressed: () =>
                                                          _toggleFavorite(
                                                            artist,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  return const SliverToBoxAdapter(
                                    child: SizedBox.shrink(),
                                  );
                                },
                              ),
                            ],
                          ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(
                      isLarge ? AppDimens.paddingXxl : AppDimens.paddingXl,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextButton(
                            onPressed: _skip,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: AppDimens.paddingMd,
                              ),
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimens.radiusLg,
                                ),
                                side: BorderSide.none,
                              ),
                            ),
                            child: Text(
                              'Skip',
                              style: AppTextStyles.bodyMd(
                                isDarkMode: isDarkMode,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimens.spacingMd),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _saveAndContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MainScreenColors.getPrimaryColor(
                                isDarkMode,
                              ),
                              minimumSize: Size(
                                double.infinity,
                                isLarge
                                    ? AppDimens.buttonSizeLg
                                    : AppDimens.buttonSizeDefault,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimens.radiusLg,
                                ),
                              ),
                              elevation: AppDimens.elevationHigh,
                              shadowColor: MainScreenColors.getPrimaryColor(
                                isDarkMode,
                              ).withValues(alpha: 0.5),
                            ),
                            child: Text(
                              'Continue',
                              style: AppTextStyles.titleSm(
                                isDarkMode: isDarkMode,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
