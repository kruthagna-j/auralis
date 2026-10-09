import 'dart:math';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';

import '../widgets/create_playlist_bottomsheet.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../data/providers/playlist_album_library_provider.dart';
import '../../../../core/services/content_details_service.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/queued_provider.dart';
import '../../../../core/models/song_model.dart';
import '../../../playlist_album_content/presentation/screens/playlist_album_content_screen.dart';
import 'playlists_detail_screen.dart';
import '../../../../shared/components/app_snackbar.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({Key? key}) : super(key: key);

  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _savedContentFilter = 'Playlists';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<PlaylistAlbumLibraryProvider>(
        context,
        listen: false,
      );

      await provider.loadAll();
      await provider.loadCreatedPlaylistsWithThumbnails();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {}

  void _createNewPlaylist() async {
    final result = await showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return CreatePlaylistBottomSheet();
      },
    );
    if (result == true) {
      final provider = Provider.of<PlaylistAlbumLibraryProvider>(
        context,
        listen: false,
      );
      await provider.loadCreatedPlaylistsWithThumbnails();
    }
  }

  void _deletePlaylist(Map<String, dynamic> playlist) async {
    final provider = Provider.of<PlaylistAlbumLibraryProvider>(
      context,
      listen: false,
    );
    await provider.deleteCreatedPlaylist(playlist['name']);
    await provider.loadCreatedPlaylistsWithThumbnails();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: true,
    );
    final accentColor = settingsProvider.accentColor;
    final isDesktopLayout = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: MainScreenColors.getBackgroundColor(isDarkMode),

      body: Column(
        children: [
          if (!isDesktopLayout)
            TabBar(
              controller: _tabController,
              indicatorColor: accentColor,
              labelColor: accentColor,
              unselectedLabelColor: MainScreenColors.getTextColor(
                isDarkMode,
              ).withValues(alpha: 0.7),
              tabs: [
                Tab(text: 'created_tab'.tr()),
                Tab(text: 'saved_tab'.tr()),
              ],
            ),
          Expanded(
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
                                  vertical: AppDimens.spacingSm,
                                ),
                                child: Text(
                                  'created_tab'.tr(),
                                  style: AppTextStyles.titleLg(
                                    color: accentColor,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _buildCreatedTab(
                                  isDarkMode,
                                  accentColor,
                                  settingsProvider,
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
                                  vertical: AppDimens.spacingSm,
                                ),
                                child: Text(
                                  'saved_tab'.tr(),
                                  style: AppTextStyles.titleLg(
                                    color: accentColor,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _buildSavedTab(
                                  isDarkMode,
                                  accentColor,
                                  settingsProvider,
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
                      _buildCreatedTab(
                        isDarkMode,
                        accentColor,
                        settingsProvider,
                      ),
                      _buildSavedTab(isDarkMode, accentColor, settingsProvider),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'toggleView',
            onPressed: () {
              settingsProvider.isGridView = !settingsProvider.isGridView;
            },
            backgroundColor: accentColor,
            child: Icon(
              settingsProvider.isGridView ? Icons.list : Icons.grid_on,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'createNewPlaylist',
            onPressed: _createNewPlaylist,
            backgroundColor: accentColor,
            child: Icon(Icons.add, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatedTab(
    bool isDarkMode,
    Color accentColor,
    SettingsProvider settingsProvider,
  ) {
    return Consumer<PlaylistAlbumLibraryProvider>(
      builder: (context, provider, _) {
        final playlists = provider.createdPlaylists
            .map((p) => {...p, 'thumbnail': p['thumbnail']})
            .toList();
        return RefreshIndicator(
          onRefresh: () async =>
              await provider.loadCreatedPlaylistsWithThumbnails(),
          color: accentColor,
          backgroundColor: MainScreenColors.getSurfaceColor(isDarkMode),
          child: playlists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.playlist_add,
                        size: AppDimens.iconStatus,
                        color: MainScreenColors.getTextColor(
                          isDarkMode,
                        ).withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'no_playlists_created_yet'.tr(),
                        style: AppTextStyles.subtitle(
                          isDarkMode: isDarkMode,
                          color: MainScreenColors.getTextColor(
                            isDarkMode,
                          ).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : settingsProvider.isGridView
              ? ListView(
                  children: [
                    const SizedBox(height: AppDimens.spacingSm),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimens.paddingLg,
                        vertical: AppDimens.spacingSmMd,
                      ),
                      child: Text(
                        'my_playlists'.tr(),
                        style: AppTextStyles.titleLg(color: accentColor),
                      ),
                    ),
                    _buildPlaylistsGrid(playlists, isDarkMode, accentColor),
                  ],
                )
              : _buildPlaylistsList(playlists, isDarkMode, accentColor),
        );
      },
    );
  }

  Widget _buildSavedTab(
    bool isDarkMode,
    Color accentColor,
    SettingsProvider settingsProvider,
  ) {
    return Consumer<PlaylistAlbumLibraryProvider>(
      builder: (context, provider, _) {
        final savedPlaylists = provider.savedPlaylists;
        final savedAlbums = provider.savedAlbums;
        return RefreshIndicator(
          onRefresh: () async => await provider.loadAll(),
          color: accentColor,
          backgroundColor: MainScreenColors.getSurfaceColor(isDarkMode),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingLg,
                  vertical: AppDimens.spacingSmMd,
                ),
                child: Row(
                  children: [
                    _buildFilterButton(
                      label: 'playlists_filter',
                      isSelected: _savedContentFilter == 'Playlists',
                      onPressed: () {
                        setState(() {
                          _savedContentFilter = 'Playlists';
                        });
                      },
                      isDarkMode: isDarkMode,
                      accentColor: accentColor,
                    ),
                    const SizedBox(width: AppDimens.spacingSmMd),
                    _buildFilterButton(
                      label: 'albums_filter',
                      isSelected: _savedContentFilter == 'Albums',
                      onPressed: () {
                        setState(() {
                          _savedContentFilter = 'Albums';
                        });
                      },
                      isDarkMode: isDarkMode,
                      accentColor: accentColor,
                    ),
                  ],
                ),
              ),

              Expanded(
                child:
                    _savedContentFilter == 'Playlists' &&
                            savedPlaylists.isEmpty ||
                        _savedContentFilter == 'Albums' && savedAlbums.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _savedContentFilter == 'Playlists'
                                  ? Icons.playlist_add
                                  : Icons.album,
                              size: AppDimens.iconStatus,
                              color: MainScreenColors.getTextColor(
                                isDarkMode,
                              ).withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: AppDimens.spacingLg),
                            Text(
                              _savedContentFilter == 'Playlists'
                                  ? 'no_saved_playlists_found'.tr()
                                  : 'no_saved_albums_found'.tr(),
                              style: AppTextStyles.subtitle(
                                isDarkMode: isDarkMode,
                                color: MainScreenColors.getTextColor(
                                  isDarkMode,
                                ).withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        children: [
                          if (_savedContentFilter == 'Playlists' &&
                              savedPlaylists.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.all(
                                AppDimens.paddingLg,
                              ),
                              child: Text(
                                'saved_playlists_title'.tr(),
                                style: AppTextStyles.titleLg(
                                  color: accentColor,
                                ),
                              ),
                            ),
                            settingsProvider.isGridView
                                ? _buildSavedContentGrid(
                                    savedPlaylists,
                                    isDarkMode,
                                    accentColor,
                                  )
                                : _buildSavedContentList(
                                    savedPlaylists,
                                    isDarkMode,
                                    accentColor,
                                  ),
                          ],
                          if (_savedContentFilter == 'Albums' &&
                              savedAlbums.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.all(
                                AppDimens.paddingLg,
                              ),
                              child: Text(
                                'saved_albums_title'.tr(),
                                style: AppTextStyles.titleLg(
                                  color: accentColor,
                                ),
                              ),
                            ),
                            settingsProvider.isGridView
                                ? _buildSavedContentGrid(
                                    savedAlbums,
                                    isDarkMode,
                                    accentColor,
                                  )
                                : _buildSavedContentList(
                                    savedAlbums,
                                    isDarkMode,
                                    accentColor,
                                  ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterButton({
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
    required bool isDarkMode,
    required Color accentColor,
  }) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? accentColor
              : MainScreenColors.getSurfaceColor(isDarkMode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          padding: EdgeInsets.symmetric(vertical: AppDimens.paddingMd),
        ),
        child: Text(
          label.tr(),
          style: AppTextStyles.button(
            color: isSelected
                ? MainScreenColors.getTextColor(!isDarkMode)
                : MainScreenColors.getTextColor(isDarkMode),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistsGrid(
    List<Map<String, dynamic>> playlists,
    bool isDarkMode,
    Color accentColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 32;
        final crossAxisCount = max(2, (availableWidth / 200).floor());
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return FutureBuilder<int>(
              future: _getSongCountForPlaylist(playlist['name']),
              builder: (context, snapshot) {
                final int songCount = snapshot.hasData ? snapshot.data! : 0;
                return GestureDetector(
                  onTap: () => _showPlaylistDetails(playlist),
                  child: Container(
                    decoration: BoxDecoration(
                      color: MainScreenColors.getSurfaceColor(isDarkMode),
                      borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: playlist['thumbnail'] == null
                                      ? MainScreenColors.getSurfaceColor(
                                          isDarkMode,
                                        ).withValues(alpha: 0.5)
                                      : null,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(AppDimens.radiusXl),
                                  ),
                                ),
                                child: playlist['thumbnail'] != null
                                    ? ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(
                                                AppDimens.radiusXl,
                                              ),
                                            ),
                                        child: CachedNetworkImage(
                                          imageUrl: playlist['thumbnail'],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorWidget: (context, url, error) =>
                                              Icon(
                                                Icons.library_music,
                                                color: accentColor,
                                                size: AppDimens.iconHero,
                                              ),
                                        ),
                                      )
                                    : Center(
                                        child: Icon(
                                          Icons.library_music,
                                          color: accentColor,
                                          size: AppDimens.iconHero,
                                        ),
                                      ),
                              ),

                              if (songCount > 0)
                                Positioned(
                                  bottom: AppDimens.spacingSm,
                                  right: AppDimens.spacingSm,
                                  child: GestureDetector(
                                    onTap: () => _playPlaylist(playlist),
                                    child: Container(
                                      padding: const EdgeInsets.all(
                                        AppDimens.paddingSm,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accentColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.black,
                                        size: AppDimens.iconHero,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: AppDimens.spacingSm,
                                right: AppDimens.spacingSm,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppDimens.spacingSm,
                                    vertical: AppDimens.spacingXs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.radiusLg,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.music_note,
                                        size: AppDimens.iconXxs,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(
                                        width: AppDimens.spacingXs,
                                      ),
                                      Text(
                                        '$songCount',
                                        style: AppTextStyles.caption(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppDimens.paddingMd),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      playlist['name'],
                                      style: AppTextStyles.titleSm(
                                        isDarkMode: isDarkMode,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Created ${_formatDate(playlist['created'])}',
                                      style: AppTextStyles.caption(
                                        isDarkMode: isDarkMode,
                                        color: MainScreenColors.getTextColor(
                                          isDarkMode,
                                        ).withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: MainScreenColors.getTextColor(
                                    isDarkMode,
                                  ),
                                ),
                                color: MainScreenColors.getSurfaceColor(
                                  isDarkMode,
                                ),
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _deletePlaylist(playlist);
                                  }
                                },
                                itemBuilder: (BuildContext context) => [
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text(
                                      'delete_playlist'.tr(),
                                      style: AppTextStyles.bodyMd(
                                        isDarkMode: isDarkMode,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPlaylistsList(
    List<Map<String, dynamic>> playlists,
    bool isDarkMode,
    Color accentColor,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.paddingLg,
        AppDimens.spacingSm,
        AppDimens.paddingLg,
        0,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return FutureBuilder<int>(
          future: _getSongCountForPlaylist(playlist['name']),
          builder: (context, snapshot) {
            final int songCount = snapshot.hasData ? snapshot.data! : 0;
            return GestureDetector(
              onTap: () => _showPlaylistDetails(playlist),
              child: Container(
                margin: const EdgeInsets.only(bottom: AppDimens.spacingLg),
                decoration: BoxDecoration(
                  color: MainScreenColors.getSurfaceColor(isDarkMode),
                  borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(AppDimens.radiusXl),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: playlist['thumbnail'] ?? '',
                        fit: BoxFit.cover,
                        width: AppDimens.thumbnailLarge,
                        height: AppDimens.thumbnailLarge,
                        errorWidget: (context, url, error) => Container(
                          width: AppDimens.thumbnailLarge,
                          height: AppDimens.thumbnailLarge,
                          color: MainScreenColors.getSurfaceColor(
                            isDarkMode,
                          ).withValues(alpha: 0.5),
                          child: Icon(
                            Icons.library_music,
                            color: accentColor,
                            size: AppDimens.iconXxl,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimens.paddingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlist['name'],
                              style: AppTextStyles.titleSm(
                                isDarkMode: isDarkMode,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${songCount} songs • Created ${_formatDate(playlist['created'])}',
                              style: AppTextStyles.caption(
                                isDarkMode: isDarkMode,
                                color: MainScreenColors.getTextColor(
                                  isDarkMode,
                                ).withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: MainScreenColors.getTextColor(isDarkMode),
                      ),
                      color: MainScreenColors.getSurfaceColor(isDarkMode),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deletePlaylist(playlist);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text(
                            'delete_playlist'.tr(),
                            style: AppTextStyles.bodyMd(isDarkMode: isDarkMode),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSavedContentGrid(
    List<Map<String, dynamic>> contents,
    bool isDarkMode,
    Color accentColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 32;
        final crossAxisCount = max(2, (availableWidth / 200).floor());
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: contents.length,
          itemBuilder: (context, index) {
            final content = {
              ...contents[index],

              'playlistId':
                  contents[index]['playlistId'] ??
                  contents[index]['albumId'] ??
                  contents[index]['id'] ??
                  '',
            };
            return GestureDetector(
              onTap: () => _openContentDetail(content),
              child: Container(
                decoration: BoxDecoration(
                  color: MainScreenColors.getSurfaceColor(isDarkMode),
                  borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppDimens.radiusXl),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: content['thumbnail'] ?? '',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorWidget: (context, url, error) => Icon(
                            Icons.library_music,
                            color: accentColor,
                            size: AppDimens.iconHero,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppDimens.paddingMd),
                      child: Text(
                        content['name'] ?? content['title'] ?? '',
                        style: AppTextStyles.titleSm(isDarkMode: isDarkMode),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSavedContentList(
    List<Map<String, dynamic>> contents,
    bool isDarkMode,
    Color accentColor,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: contents.length,
      itemBuilder: (context, index) {
        final content = {
          ...contents[index],
          'playlistId':
              contents[index]['playlistId'] ??
              contents[index]['albumId'] ??
              contents[index]['id'] ??
              '',
        };
        return GestureDetector(
          onTap: () => _openContentDetail(content),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppDimens.spacingLg),
            decoration: BoxDecoration(
              color: MainScreenColors.getSurfaceColor(isDarkMode),
              borderRadius: BorderRadius.circular(AppDimens.radiusXl),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppDimens.radiusXl),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: content['thumbnail'] ?? '',
                    fit: BoxFit.cover,
                    width: AppDimens.thumbnailLarge,
                    height: AppDimens.thumbnailLarge,
                    errorWidget: (context, url, error) => Container(
                      width: AppDimens.thumbnailLarge,
                      height: AppDimens.thumbnailLarge,
                      color: MainScreenColors.getSurfaceColor(
                        isDarkMode,
                      ).withValues(alpha: 0.5),
                      child: Icon(
                        Icons.library_music,
                        color: accentColor,
                        size: AppDimens.iconXxl,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimens.paddingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content['name'] ?? content['title'] ?? '',
                          style: AppTextStyles.titleSm(isDarkMode: isDarkMode),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          content['contentType'] == 'Album'
                              ? 'Album by ${content['artist'] ?? 'Unknown'}'
                              : 'Playlist',
                          style: AppTextStyles.caption(
                            isDarkMode: isDarkMode,
                            color: MainScreenColors.getTextColor(
                              isDarkMode,
                            ).withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openContentDetail(Map<String, dynamic> content) {
    final formattedContent = content['contentType'] == 'Album'
        ? AlbumDetailed(
            playlistId: content['playlistId'] ?? '',
            name: content['name'] ?? content['title'] ?? '',
            artist: ArtistBasic(name: content['artist'] ?? ''),
            thumbnails: [
              ThumbnailFull(
                url: content['thumbnail'] ?? '',
                width: 1280,
                height: 720,
              ),
            ],

            type: (content['contentType'] as String?) ?? 'Album',
            albumId: content['playlistId'] ?? '',
          )
        : PlaylistDetailed(
            playlistId: content['playlistId'] ?? '',
            name: content['name'] ?? content['title'] ?? '',
            artist: ArtistBasic(name: ''),
            thumbnails: [
              ThumbnailFull(
                url: content['thumbnail'] ?? '',
                width: 1280,
                height: 720,
              ),
            ],

            type: (content['contentType'] as String?) ?? 'Playlist',
          );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistAlbumContent(content: formattedContent),
      ),
    );
  }

  Future<int> _getSongCountForPlaylist(String playlistName) async {
    final provider = Provider.of<PlaylistAlbumLibraryProvider>(
      context,
      listen: false,
    );
    return await provider.getSongCountForPlaylist(playlistName);
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _playPlaylist(Map<String, dynamic> playlist) async {
    try {
      final provider = Provider.of<PlaylistAlbumLibraryProvider>(
        context,
        listen: false,
      );
      final songs = await provider.getPlaylistSongs(playlist['name']);

      if (songs.isEmpty) {
        if (!mounted) return;
        AppSnackBar.showWarning(context, 'No songs in this playlist');
        return;
      }

      final songInfoList = songs
          .map(
            (song) => SongInfo(
              videoId: song['id'],
              name: song['title'],
              artists: song['artists'] != null
                  ? (song['artists'] as List)
                        .map((a) => Artist(name: a['name'], id: a['id']))
                        .toList()
                  : [
                      Artist(
                        name: song['artist'] ?? '',
                        id: song['artistId'] ?? '',
                      ),
                    ],
              thumbnails: [
                Thumbnail(url: song['thumbnail'], width: 1280, height: 720),
              ],
              duration: Duration(seconds: song['duration']),
            ),
          )
          .toList();

      final playerProvider = Provider.of<PlayerProvider>(
        context,
        listen: false,
      );
      final queueProvider = Provider.of<QueueProvider>(context, listen: false);
      final contentDetailsService = ContentDetailsService();

      await contentDetailsService.playSong(
        songInfoList.first,
        playerProvider,
        queueProvider,
        songInfoList,
        playlistId: playlist['name'],
      );

      if (!mounted) return;
    } catch (e) {
      print('Error playing playlist: $e');
      if (!mounted) return;
      AppSnackBar.showError(context, 'Error playing playlist');
    }
  }

  void _showPlaylistDetails(Map<String, dynamic> playlist) async {
    final provider = Provider.of<PlaylistAlbumLibraryProvider>(
      context,
      listen: false,
    );
    final songs = await provider.getPlaylistSongs(playlist['name']);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PlaylistDetailsScreen(playlist: playlist, songs: songs),
      ),
    );
  }
}
