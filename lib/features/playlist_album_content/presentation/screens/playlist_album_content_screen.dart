import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/song_model.dart';
import '../widgets/playlist_album_content_shimmer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/components/song_list_tile.dart';
import '../../../playlists/data/providers/playlist_album_library_provider.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/queued_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/download_provider.dart' as dp;
import '../../data/providers/playlist_album_content_provider.dart';
import '../widgets/search_song_delegate.dart';
import '../../../../shared/components/app_snackbar.dart';

class PlaylistAlbumContent extends StatefulWidget {
  final dynamic content;

  const PlaylistAlbumContent({Key? key, required this.content})
    : super(key: key);

  @override
  State<PlaylistAlbumContent> createState() => _PlaylistAlbumContentState();
}

class _PlaylistAlbumContentState extends State<PlaylistAlbumContent> {
  final ScrollController _scrollController = ScrollController();
  late PlaylistAlbumContentProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = PlaylistAlbumContentProvider();
    _provider.addListener(() => setState(() {}));
    _provider.loadContent(widget.content);
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final libraryProvider = Provider.of<PlaylistAlbumLibraryProvider>(
      context,
      listen: false,
    );
    await _provider.checkIfSaved(widget.content, libraryProvider);
  }

  Future<void> _addToLibrary() async {
    final libraryProvider = Provider.of<PlaylistAlbumLibraryProvider>(
      context,
      listen: false,
    );
    final message = await _provider.addToLibrary(
      widget.content,
      _provider.contentDescription,
      _provider.totalDuration,
      libraryProvider,
    );
    setState(() {});
    AppSnackBar.showInfo(
      context,
      message,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _removeFromLibrary() async {
    final libraryProvider = Provider.of<PlaylistAlbumLibraryProvider>(
      context,
      listen: false,
    );
    final message = await _provider.removeFromLibrary(
      widget.content,
      _provider.contentDescription,
      libraryProvider,
    );
    setState(() {});
    AppSnackBar.showInfo(
      context,
      message,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _playSong(dynamic song) async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final queueProvider = Provider.of<QueueProvider>(context, listen: false);
    try {
      await _provider.playSong(
        song,
        playerProvider,
        queueProvider,
        _provider.allSongs,
        widget.content.playlistId,
      );
    } catch (e) {
      print('Error playing song: $e');
      AppSnackBar.showError(context, 'Error playing song');
    }
  }

  void _shareContent() {
    _provider.shareContent(widget.content, _provider.contentDescription);
  }

  Future<void> _downloadPlaylist() async {
    final downloadProvider = Provider.of<dp.DownloadProvider>(
      context,
      listen: false,
    );
    try {
      await _provider.downloadPlaylist(downloadProvider);
      AppSnackBar.showSuccess(
        context,
        'All songs added to download queue',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      AppSnackBar.showError(
        context,
        'Failed to add songs to download queue: $e',
      );
    }
  }

  Future<void> _loadMoreSongs() async {
    await _provider.loadMoreSongs();
  }

  static const double _desktopBreakpoint = AppDimens.breakpointDesktop;

  bool _isDesktopLayout(BuildContext context) {
    return MediaQuery.of(context).size.width >= _desktopBreakpoint;
  }

  Widget _buildHeader({bool isDesktop = false}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final double effectiveWidth = isDesktop ? screenWidth * 0.45 : screenWidth;

    final imageSize = isDesktop
        ? AppDimens.headerImageMd
        : (effectiveWidth < AppDimens.breakpointMobile
              ? AppDimens.headerImageSm
              : AppDimens.headerImageMd);

    final TextStyle titleStyle = isDesktop
        ? AppTextStyles.display()
        : (effectiveWidth < AppDimens.breakpointMobile
              ? AppTextStyles.titleLg()
              : AppTextStyles.headingLg());

    final TextStyle subtitleStyle = isDesktop
        ? AppTextStyles.subtitle()
        : (effectiveWidth < AppDimens.breakpointMobile
              ? AppTextStyles.bodyLg()
              : AppTextStyles.subtitle());

    final padding = isDesktop
        ? AppDimens.paddingXl
        : (effectiveWidth < AppDimens.breakpointMobile
              ? AppDimens.paddingMd
              : AppDimens.paddingLg);
    final margin = isDesktop
        ? AppDimens.spacingLg
        : (effectiveWidth < AppDimens.breakpointMobile
              ? AppDimens.spacingSm
              : AppDimens.spacingLg);

    Widget headerContent = Column(
      crossAxisAlignment: isDesktop
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDesktop) ...[
          Hero(
            tag: 'content-image-${widget.content.name}',
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                child: CachedNetworkImage(
                  imageUrl: widget.content.thumbnails.last.url,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                  memCacheWidth: (imageSize * 2).toInt(),
                  memCacheHeight: (imageSize * 2).toInt(),
                  placeholder: (context, url) => Container(
                    width: imageSize,
                    height: imageSize,
                    color: Colors.grey[850],
                    child: const Center(
                      child: Icon(
                        Icons.my_library_music,
                        size: AppDimens.iconHero,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: imageSize,
                    height: imageSize,
                    color: Colors.grey[850],
                    child: const Icon(Icons.error, size: AppDimens.iconHero),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: AppDimens.spacingXl),
          Text(
            widget.content.name,
            style: titleStyle.copyWith(
              color: MainScreenColors.getTextColor(isDarkMode),
              height: 1.2,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimens.spacingS),
          Text(
            _provider.contentDescription,
            style: subtitleStyle.copyWith(
              color: MainScreenColors.getTextColor(
                isDarkMode,
              ).withValues(alpha: 0.7),
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimens.spacingXs),
          Text(
            '${_provider.songs.length} songs • ${_provider.formatTotalDuration()}',
            style: subtitleStyle.copyWith(
              color: MainScreenColors.getTextColor(
                isDarkMode,
              ).withValues(alpha: 0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimens.spacingXl),
          _buildActionButtons(isDarkMode, isDesktop: true),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'content-image-${widget.content.name}',
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    child: CachedNetworkImage(
                      imageUrl: widget.content.thumbnails.last.url,
                      width: imageSize,
                      height: imageSize,
                      fit: BoxFit.cover,
                      memCacheWidth: (imageSize * 2).toInt(),
                      memCacheHeight: (imageSize * 2).toInt(),
                      placeholder: (context, url) => Container(
                        color: Colors.grey[850],
                        child: const Center(
                          child: Icon(Icons.my_library_music),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[850],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: effectiveWidth < AppDimens.breakpointMobile
                    ? AppDimens.spacingMd
                    : AppDimens.spacingLg,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.content.name,
                      style: titleStyle.copyWith(
                        color: MainScreenColors.getTextColor(isDarkMode),
                        height: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(
                      height: effectiveWidth < AppDimens.breakpointMobile
                          ? AppDimens.spacingXxs
                          : AppDimens.paddingXs,
                    ),
                    Text(
                      _provider.contentDescription,
                      style: subtitleStyle.copyWith(
                        color: MainScreenColors.getTextColor(
                          isDarkMode,
                        ).withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(
                      height: effectiveWidth < AppDimens.breakpointMobile
                          ? AppDimens.spacingXxs
                          : AppDimens.paddingXs,
                    ),
                    Text(
                      '${_provider.songs.length} songs • ${_provider.formatTotalDuration()}',
                      style: subtitleStyle.copyWith(
                        color: MainScreenColors.getTextColor(
                          isDarkMode,
                        ).withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: effectiveWidth < AppDimens.breakpointMobile
                ? AppDimens.spacingMd
                : AppDimens.spacingLg,
          ),
          _buildActionButtons(isDarkMode),
        ],
      ],
    );

    return Container(
      margin: EdgeInsets.all(margin),
      decoration: BoxDecoration(
        color: MainScreenColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: EdgeInsets.all(padding), child: headerContent),
    );
  }

  Widget _buildActionButtons(bool isDarkMode, {bool isDesktop = false}) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final accentColor = settingsProvider.accentColor;
    final screenWidth = MediaQuery.of(context).size.width;
    if (isDesktop) {
      final double buttonPadding = AppDimens.spacingSmMd;
      final double buttonSize = AppDimens.buttonSizeLg;
      final double iconSize = AppDimens.iconMdLg;

      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _provider.songs.isEmpty
                  ? null
                  : () => _playSong(_provider.songs.first),
              icon: const Icon(Icons.play_arrow, color: Colors.black),
              label: Text(
                'Play All',
                style: AppTextStyles.bodyLg(
                  color: Colors.white,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: AppDimens.spacingMdLg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
                ),
              ),
            ),
          ),
          SizedBox(height: AppDimens.spacingLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildResponsiveIconButton(
                icon: Icons.queue_music,
                onPressed: () {
                  final queueProvider = Provider.of<QueueProvider>(
                    context,
                    listen: false,
                  );
                  if (queueProvider.hasLocalSongsInQueue) {
                    AppSnackBar.showError(
                      context,
                      'cannot_add_songs_to_queue'.tr(),
                    );
                    return;
                  }
                  queueProvider.addAllToQueue(
                    _provider.allSongs.cast<SongInfo>(),
                  );
                  AppSnackBar.showInfo(
                    context,
                    'added_all_songs_to_queue'.tr(),
                    duration: const Duration(seconds: 2),
                  );
                },
                tooltip: 'add_to_queue'.tr(),
                isDarkMode: isDarkMode,
                size: buttonSize,
                iconSize: iconSize,
                padding: buttonPadding,
              ),
              _buildResponsiveIconButton(
                icon: _provider.isSaved
                    ? Icons.library_add_check
                    : Icons.library_add,
                onPressed: _provider.isSaved
                    ? _removeFromLibrary
                    : _addToLibrary,
                tooltip: _provider.isSaved
                    ? 'remove_from_library'.tr()
                    : 'add_to_library'.tr(),
                isDarkMode: isDarkMode,
                size: buttonSize,
                iconSize: iconSize,
                padding: buttonPadding,
              ),
              _buildResponsiveIconButton(
                icon: Icons.download,
                onPressed: _provider.allSongs.isEmpty
                    ? null
                    : () => _downloadPlaylist(),
                tooltip: 'download_all'.tr(),
                isDarkMode: isDarkMode,
                size: buttonSize,
                iconSize: iconSize,
                padding: buttonPadding,
              ),
              _buildResponsiveIconButton(
                icon: Icons.share,
                onPressed: _shareContent,
                tooltip: 'share'.tr(),
                isDarkMode: isDarkMode,
                size: buttonSize,
                iconSize: iconSize,
                padding: buttonPadding,
              ),
            ],
          ),
        ],
      );
    }
    final isVerySmall = screenWidth < 400;
    final double buttonPadding = isVerySmall
        ? AppDimens.paddingXs
        : (screenWidth < AppDimens.breakpointMobile
              ? AppDimens.spacingS
              : AppDimens.paddingSm);
    final double buttonSize = isVerySmall
        ? AppDimens.buttonSizeCompact
        : (screenWidth < AppDimens.breakpointMobile
              ? AppDimens.buttonSizeCompact
              : AppDimens.buttonSizeDefault);
    final double iconSize = isVerySmall
        ? AppDimens.iconXs
        : (screenWidth < AppDimens.breakpointMobile
              ? AppDimens.iconSm
              : AppDimens.iconMd);

    final TextStyle playButtonStyle = isVerySmall
        ? AppTextStyles.finePrint()
        : (screenWidth < AppDimens.breakpointMobile
              ? AppTextStyles.caption()
              : AppTextStyles.button());

    final EdgeInsets playButtonPadding = isVerySmall
        ? const EdgeInsets.symmetric(
            vertical: AppDimens.spacingS,
            horizontal: AppDimens.paddingXs,
          )
        : (screenWidth < AppDimens.breakpointMobile
              ? const EdgeInsets.symmetric(
                  vertical: AppDimens.paddingSm,
                  horizontal: AppDimens.spacingMd,
                )
              : const EdgeInsets.symmetric(
                  vertical: AppDimens.paddingMd,
                  horizontal: AppDimens.paddingLg,
                ));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildResponsiveIconButton(
          icon: Icons.queue_music,
          onPressed: () {
            final queueProvider = Provider.of<QueueProvider>(
              context,
              listen: false,
            );
            if (queueProvider.hasLocalSongsInQueue) {
              AppSnackBar.showError(context, 'cannot_add_songs_to_queue'.tr());
              return;
            }
            queueProvider.addAllToQueue(_provider.allSongs.cast<SongInfo>());
            AppSnackBar.showInfo(
              context,
              'added_all_songs_to_queue'.tr(),
              duration: const Duration(seconds: 2),
            );
          },
          tooltip: 'add_to_queue'.tr(),
          isDarkMode: isDarkMode,
          size: buttonSize,
          iconSize: iconSize,
          padding: buttonPadding,
        ),
        _buildResponsiveIconButton(
          icon: _provider.isSaved ? Icons.library_add_check : Icons.library_add,
          onPressed: _provider.isSaved ? _removeFromLibrary : _addToLibrary,
          tooltip: _provider.isSaved
              ? 'remove_from_library'.tr()
              : 'add_to_library'.tr(),
          isDarkMode: isDarkMode,
          size: buttonSize,
          iconSize: iconSize,
          padding: buttonPadding,
        ),
        SizedBox(
          width: isVerySmall ? screenWidth * 0.25 : screenWidth * 0.3,
          child: ElevatedButton(
            onPressed: _provider.songs.isEmpty
                ? null
                : () => _playSong(_provider.songs.first),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: playButtonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusMdLg),
              ),
            ),
            child: Center(
              child: Text(
                'play_all'.tr(),
                style: playButtonStyle.copyWith(color: Colors.black),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        _buildResponsiveIconButton(
          icon: Icons.download,
          onPressed: _provider.allSongs.isEmpty
              ? null
              : () => _downloadPlaylist(),
          tooltip: 'download'.tr(),
          isDarkMode: isDarkMode,
          size: buttonSize,
          iconSize: iconSize,
          padding: buttonPadding,
        ),
        _buildResponsiveIconButton(
          icon: Icons.share,
          onPressed: _shareContent,
          tooltip: 'share'.tr(),
          isDarkMode: isDarkMode,
          size: buttonSize,
          iconSize: iconSize,
          padding: buttonPadding,
        ),
      ],
    );
  }

  Widget _buildResponsiveIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    required bool isDarkMode,
    required double size,
    required double iconSize,
    required double padding,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: MainScreenColors.getTextColor(isDarkMode).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        tooltip: tooltip,
        iconSize: iconSize,
        color: MainScreenColors.getTextColor(isDarkMode),
        padding: EdgeInsets.all(padding),
        constraints: BoxConstraints(minWidth: size, minHeight: size),
      ),
    );
  }

  Widget _buildLoadMoreButton(bool isDarkMode) {
    final bool hasMoreSongs =
        _provider.songs.length < _provider.allSongs.length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.spacingLg),
        child: ElevatedButton(
          onPressed: hasMoreSongs ? _loadMoreSongs : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: MainScreenColors.getTextColor(
              isDarkMode,
            ).withValues(alpha: 0.1),
            foregroundColor: MainScreenColors.getTextColor(isDarkMode),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spacingXxl,
              vertical: AppDimens.paddingMd,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
            ),
          ),
          child: Text(
            hasMoreSongs ? 'load_more_songs'.tr() : 'no_more_songs'.tr(),
            style: AppTextStyles.bodyMd().copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: ThemeData(
        scaffoldBackgroundColor: MainScreenColors.getBackgroundColor(
          isDarkMode,
        ),
        cardColor: MainScreenColors.getSurfaceColor(isDarkMode),
        popupMenuTheme: PopupMenuThemeData(
          color: MainScreenColors.getSurfaceColor(isDarkMode),
        ),
      ),
      child: Consumer<PlayerProvider>(
        builder: (context, playerProvider, child) {
          return SafeArea(
            top: false,
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: isDarkMode
                    ? Colors.transparent
                    : MainScreenColors.getSurfaceColor(false),
                elevation: 0,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(AppDimens.paddingSm),
                    decoration: BoxDecoration(
                      color: MainScreenColors.getSurfaceColor(isDarkMode),
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: MainScreenColors.getTextColor(isDarkMode),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () => showSearch(
                      context: context,
                      delegate: SongSearchDelegate(
                        songs: _provider.songs,
                        onPlay: _playSong,
                      ),
                    ),
                  ),
                ],
              ),
              body: Stack(
                children: [_buildContent(playerProvider, isDarkMode)],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSongList(PlayerProvider playerProvider, bool isDarkMode) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingLg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == _provider.songs.length) {
                return _buildLoadMoreButton(isDarkMode);
              }
              final song = _provider.songs[index];
              final settingsProvider = Provider.of<SettingsProvider>(
                context,
                listen: false,
              );
              final accentColor = settingsProvider.accentColor;

              return Builder(
                builder: (context) {
                  final isCurrentlyPlaying = context
                      .select<PlayerProvider, bool>(
                        (p) => p.currentSong?.videoId == song.videoId,
                      );
                  return Container(
                    decoration: BoxDecoration(
                      color: isCurrentlyPlaying
                          ? accentColor.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    ),
                    child: SongListTile(
                      key: ValueKey('${song.name}_$index'),
                      song: song,
                      isPlaying: isCurrentlyPlaying,
                      onPlay: () => _playSong(song),
                      isDarkMode: isDarkMode,
                    ),
                  );
                },
              );
            }, childCount: _provider.songs.length + 1),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(context).padding.bottom +
                AppDimens.miniPlayerHeightWide,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLeftPanel(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: _buildHeader(isDesktop: true),
    );
  }

  Widget _buildContent(PlayerProvider playerProvider, bool isDarkMode) {
    if (_provider.isLoading) {
      return PlaylistAlbumContentShimmer.buildShimmer(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= _desktopBreakpoint;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: constraints.maxWidth * 0.38,
                child: _buildDesktopLeftPanel(isDarkMode),
              ),
              Container(
                width: 1,
                height: double.infinity,
                color: MainScreenColors.getTextColor(
                  isDarkMode,
                ).withValues(alpha: 0.1),
              ),
              Expanded(child: _buildSongList(playerProvider, isDarkMode)),
            ],
          );
        }
        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.spacingLg,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index == _provider.songs.length) {
                    return _buildLoadMoreButton(isDarkMode);
                  }
                  final song = _provider.songs[index];
                  final settingsProvider = Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  );
                  final accentColor = settingsProvider.accentColor;

                  return Builder(
                    builder: (context) {
                      final isCurrentlyPlaying = context
                          .select<PlayerProvider, bool>(
                            (p) => p.currentSong?.videoId == song.videoId,
                          );
                      return Container(
                        decoration: BoxDecoration(
                          color: isCurrentlyPlaying
                              ? accentColor.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusLg,
                          ),
                        ),
                        child: SongListTile(
                          key: ValueKey('${song.name}_$index'),
                          song: song,
                          isPlaying: isCurrentlyPlaying,
                          onPlay: () => _playSong(song),
                          isDarkMode: isDarkMode,
                        ),
                      );
                    },
                  );
                }, childCount: _provider.songs.length + 1),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).padding.bottom +
                    AppDimens.miniPlayerHeightWide,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _provider.removeListener(() => setState(() {}));
    _scrollController.dispose();
    super.dispose();
  }
}
