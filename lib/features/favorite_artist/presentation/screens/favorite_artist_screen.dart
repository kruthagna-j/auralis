import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:provider/provider.dart';
import 'package:dart_ytmusic_api/yt_music.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/providers/favorite_artist_provider.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../shared/components/app_snackbar.dart';

class FavoriteArtistsScreen extends StatefulWidget {
  const FavoriteArtistsScreen({Key? key}) : super(key: key);

  @override
  _FavoriteArtistsScreenState createState() => _FavoriteArtistsScreenState();
}

class _FavoriteArtistsScreenState extends State<FavoriteArtistsScreen>
    with SingleTickerProviderStateMixin {
  final YTMusic _ytMusic = GetIt.I<YTMusic>();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initializeYTMusic();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FavoriteArtistProvider>(
        context,
        listen: false,
      ).loadFavoriteArtists();
    });
  }

  Future<void> _initializeYTMusic() async {
    await _ytMusic.initialize();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchArtists(query.trim());
    });
  }

  Future<void> _searchArtists(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _ytMusic.searchArtists(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'error_searching_artists'.tr());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite(dynamic artist) async {
    await Provider.of<FavoriteArtistProvider>(
      context,
      listen: false,
    ).toggleFavorite(artist);
    await Provider.of<FavoriteArtistProvider>(
      context,
      listen: false,
    ).loadFavoriteArtists();
  }

  Future<void> _removeFavoriteById(Map<String, dynamic> artist) async {
    await Provider.of<FavoriteArtistProvider>(
      context,
      listen: false,
    ).removeFavorite(artist['artistId'] as String);
  }

  Future<void> _editFavoriteName(String artistId, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        final accent = settings.accentColor;
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isWide = screenWidth >= 700;
            final maxDialogWidth = min(
              AppDimens.breakpointWideScreen,
              screenWidth * 0.8,
            );
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusXl),
              ),
              backgroundColor: MainScreenColors.getSurfaceColor(isDark),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? maxDialogWidth : double.infinity,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingXl,
                      vertical: AppDimens.paddingLg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'rename_artist'.tr(),
                                style: AppTextStyles.titleSm(isDarkMode: isDark)
                                    .copyWith(
                                      fontWeight: AppTextStyles.weightBold,
                                      color: MainScreenColors.getTextColor(
                                        isDark,
                                      ),
                                    ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: MainScreenColors.getTextColor(isDark),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        SizedBox(height: AppDimens.spacingSm),
                        TextField(
                          controller: controller,
                          cursorColor: accent,
                          decoration: InputDecoration(
                            hintText: 'artist_name'.tr(),
                            filled: true,
                            fillColor: MainScreenColors.getBackgroundColor(
                              isDark,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppDimens.paddingMd,
                              vertical: AppDimens.paddingSm,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          autofocus: true,
                        ),
                        SizedBox(height: AppDimens.spacingMdLg),
                        isWide
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: accent.withValues(alpha: 0.9),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppDimens.radiusMd,
                                        ),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: AppDimens.paddingMd,
                                        horizontal: AppDimens.paddingXl,
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: AppTextStyles.button(
                                        color: accent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(
                                      context,
                                      controller.text.trim(),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppDimens.radiusMd,
                                        ),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: AppDimens.paddingMd,
                                        horizontal: AppDimens.paddingXxl,
                                      ),
                                    ),
                                    child: Text(
                                      'Save',
                                      style: AppTextStyles.button(),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: accent.withValues(alpha: 0.9),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppDimens.radiusMd,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: AppDimens.paddingMd,
                                        ),
                                      ),
                                      child: Text(
                                        'Cancel',
                                        style: AppTextStyles.button(
                                          color: accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(
                                        context,
                                        controller.text.trim(),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: accent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppDimens.radiusMd,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: AppDimens.paddingMd,
                                        ),
                                      ),
                                      child: Text(
                                        'Save',
                                        style: AppTextStyles.button(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null && result.isNotEmpty && result != currentName) {
      await Provider.of<FavoriteArtistProvider>(
        context,
        listen: false,
      ).editFavorite(artistId, result);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildSearchTab(
    bool isDarkMode,
    Color accentColor,
    bool isDesktopLayout,
  ) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(AppDimens.spacingMdLg),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            cursorColor: accentColor,
            style: AppTextStyles.bodyMd(isDarkMode: isDarkMode),
            decoration: InputDecoration(
              hintText: 'search_artists'.tr(),
              hintStyle: AppTextStyles.caption(isDarkMode: isDarkMode).copyWith(
                color: MainScreenColors.getTextColor(
                  isDarkMode,
                ).withValues(alpha: 0.7),
              ),
              prefixIcon: Icon(Icons.search, color: accentColor),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: MainScreenColors.getTextColor(isDarkMode),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults.clear();
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: MainScreenColors.getSurfaceColor(isDarkMode),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : _searchResults.isEmpty
              ? Center(
                  child: Text(
                    _searchController.text.isEmpty
                        ? 'search_for_favorite_artists'.tr()
                        : 'no_artists_found'.tr(),
                    style: AppTextStyles.bodyMd(isDarkMode: isDarkMode),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: AppDimens.paddingSm),
                  itemBuilder: (context, index) {
                    final artist = _searchResults[index];
                    return Consumer<FavoriteArtistProvider>(
                      builder: (context, provider, child) {
                        final isFavorite = provider.favoriteArtists.any(
                          (favArtist) =>
                              favArtist['artistId'] == artist.artistId,
                        );
                        return ListTile(
                          leading: CircleAvatar(
                            radius: AppDimens.radiusAvatar,
                            backgroundImage:
                                artist.thumbnails?.isNotEmpty == true
                                ? NetworkImage(artist.thumbnails!.last.url)
                                : null,
                            child: artist.thumbnails?.isEmpty == true
                                ? Icon(
                                    Icons.person,
                                    color: MainScreenColors.getTextColor(
                                      isDarkMode,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            artist.name,
                            style:
                                AppTextStyles.subtitle(
                                  isDarkMode: isDarkMode,
                                ).copyWith(
                                  fontWeight: AppTextStyles.weightSemiBold,
                                ),
                          ),

                          subtitle: null,
                          trailing: IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite
                                  ? accentColor
                                  : MainScreenColors.getTextColor(isDarkMode),
                            ),
                            onPressed: () => _toggleFavorite(artist),
                            tooltip: isFavorite
                                ? 'Remove favorite'
                                : 'Add favorite',
                          ),
                          onTap: () {
                            if (isFavorite) {
                              if (!isDesktopLayout) _tabController.animateTo(1);
                            }
                          },
                        );
                      },
                    );
                  },
                  separatorBuilder: (_, __) =>
                      Divider(height: AppDimens.dividerHeight),
                  itemCount: _searchResults.length,
                ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab(
    bool isDarkMode,
    Color accentColor,
    bool isDesktopLayout,
  ) {
    return Consumer<FavoriteArtistProvider>(
      builder: (context, provider, child) {
        if (provider.isFavoriteArtistsLoading) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }

        final favorites = provider.favoriteArtists;
        if (favorites.isEmpty) {
          return Center(
            child: Text(
              'no_favorite_artists_yet'.tr(),
              style: AppTextStyles.bodyMd(isDarkMode: isDarkMode),
              textAlign: TextAlign.center,
            ),
          );
        }

        return RefreshIndicator(
          color: accentColor,
          onRefresh: () => provider.loadFavoriteArtists(),
          child: ListView.separated(
            padding: EdgeInsets.symmetric(vertical: AppDimens.paddingSm),
            itemCount: favorites.length,
            separatorBuilder: (_, __) =>
                Divider(height: AppDimens.dividerHeight),
            itemBuilder: (context, index) {
              final artist = favorites[index];
              return Dismissible(
                key: ValueKey(artist['artistId']),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingXl,
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  final confirmed =
                      await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Remove favorite'),
                          content: Text(
                            'Remove "${artist['name']}" from favorites?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                  return confirmed;
                },
                onDismissed: (_) async {
                  final removed = Map<String, dynamic>.from(artist);
                  await _removeFavoriteById(artist);
                  AppSnackBar.showInfo(
                    context,
                    'Removed ${removed['name']}',
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () async {
                        final favoritesBox = Hive.box<String>(
                          'favorite_artists',
                        );
                        final key = removed['artistId']?.toString();
                        if (key != null && key.isNotEmpty) {
                          await favoritesBox.put(key, jsonEncode(removed));
                        }
                        await Provider.of<FavoriteArtistProvider>(
                          context,
                          listen: false,
                        ).loadFavoriteArtists();
                      },
                    ),
                  );
                },
                child: ListTile(
                  leading: CircleAvatar(
                    radius: AppDimens.radiusAvatar,
                    backgroundImage: artist['thumbnailUrl'] != null
                        ? NetworkImage(artist['thumbnailUrl'])
                        : null,
                    child: artist['thumbnailUrl'] == null
                        ? Icon(
                            Icons.person,
                            color: MainScreenColors.getTextColor(isDarkMode),
                          )
                        : null,
                  ),
                  title: Text(
                    artist['name'] ?? 'Unknown',
                    style: AppTextStyles.subtitle(
                      isDarkMode: isDarkMode,
                    ).copyWith(fontWeight: AppTextStyles.weightSemiBold),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: MainScreenColors.getTextColor(isDarkMode),
                        ),
                        onPressed: () => _editFavoriteName(
                          artist['artistId'],
                          artist['name'],
                        ),
                        tooltip: 'Edit name',
                      ),
                      IconButton(
                        icon: Icon(Icons.favorite, color: accentColor),
                        onPressed: () => _removeFavoriteById(artist),
                        tooltip: 'Remove favorite',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = settingsProvider.accentColor;
    final isDesktopLayout =
        MediaQuery.of(context).size.width >= AppDimens.breakpointDesktopLarge;
    final playerProvider = Provider.of<PlayerProvider>(context);
    final hasPlayer =
        playerProvider.currentSong != null ||
        playerProvider.lastPlayedSong != null ||
        playerProvider.currentLocalSong != null;

    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'favorite_artists'.tr(),
            style: AppTextStyles.appBarTitle(isDarkMode: isDarkMode),
          ),
          backgroundColor: MainScreenColors.getSurfaceColor(isDarkMode),
          elevation: 0,
          bottom: isDesktopLayout
              ? null
              : TabBar(
                  controller: _tabController,
                  indicatorColor: accentColor,
                  labelColor: accentColor,
                  unselectedLabelColor: MainScreenColors.getTextColor(
                    isDarkMode,
                  ).withValues(alpha: 0.6),
                  tabs: [
                    Tab(icon: Icon(Icons.search), text: 'search'.tr()),
                    Tab(icon: Icon(Icons.favorite), text: 'favorites'.tr()),
                  ],
                ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              bottom: hasPlayer ? AppDimens.miniPlayerHeight : 0,
              child: Container(
                color: MainScreenColors.getBackgroundColor(isDarkMode),
                child: isDesktopLayout
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimens.paddingSm,
                          vertical: AppDimens.spacingS,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppDimens.paddingMd,
                                      vertical: AppDimens.paddingSm,
                                    ),
                                    child: Text(
                                      'search'.tr(),
                                      style: AppTextStyles.titleSm(
                                        isDarkMode: isDarkMode,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildSearchTab(
                                      isDarkMode,
                                      accentColor,
                                      isDesktopLayout,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            VerticalDivider(
                              width: 1,
                              color: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[300],
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppDimens.paddingMd,
                                      vertical: AppDimens.paddingSm,
                                    ),
                                    child: Text(
                                      'favorites'.tr(),
                                      style: AppTextStyles.titleSm(
                                        isDarkMode: isDarkMode,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildFavoritesTab(
                                      isDarkMode,
                                      accentColor,
                                      isDesktopLayout,
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
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDimens.paddingSm,
                              vertical: AppDimens.spacingS,
                            ),
                            child: _buildSearchTab(
                              isDarkMode,
                              accentColor,
                              isDesktopLayout,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDimens.paddingSm,
                              vertical: AppDimens.spacingS,
                            ),
                            child: _buildFavoritesTab(
                              isDarkMode,
                              accentColor,
                              isDesktopLayout,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
        backgroundColor: MainScreenColors.getBackgroundColor(isDarkMode),
      ),
    );
  }
}
