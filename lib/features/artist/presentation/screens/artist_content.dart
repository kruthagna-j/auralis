import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../widgets/album_list.dart';
import '../widgets/artist_song_list_tile.dart';
import '../../../../shared/components/content_details_shimmer.dart';
import '../widgets/artist_content_shimmer.dart';
import '../../../../core/providers/favorite_artist_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/song_model.dart';
import '../../../../core/services/content_details_service.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/queued_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import 'popular_songs_list_screen.dart';
import '../../../../shared/components/app_snackbar.dart';

class ArtistContent extends StatefulWidget {
  final ArtistDetailed artist;

  const ArtistContent({Key? key, required this.artist}) : super(key: key);

  @override
  State<ArtistContent> createState() => _ArtistContentState();
}

class _ArtistContentState extends State<ArtistContent>
    with SingleTickerProviderStateMixin {
  final ContentDetailsService _contentService = ContentDetailsService();
  late TabController _tabController;
  static const double _desktopBreakpoint = 800.0;

  late Future<ArtistDetailed> _artistInfoFuture;
  late Future<Map<String, dynamic>> _songsFuture;
  late Future<Map<String, dynamic>> _albumsFuture;
  late Future<Map<String, dynamic>> _singlesFuture;
  late Future<List<ArtistInfo>> _similarArtistsFuture;

  String _contentDescription = '';
  ArtistDetailed? _artistInfo;

  List<dynamic> _songs = [];
  List<dynamic> _allSongs = [];
  List<dynamic> _albums = [];
  List<dynamic> _allAlbums = [];
  List<dynamic> _singles = [];
  List<dynamic> _allSingles = [];
  List<ArtistInfo> _similarArtists = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadArtistDetailsAndContent();
  }

  Future<void> _loadArtistDetailsAndContent() async {
    final artistDetailsAndSimilarFuture = _contentService
        .getArtistDetailsAndSimilar(widget.artist.artistId);

    _artistInfoFuture = artistDetailsAndSimilarFuture.then(
      (data) => data['artistInfo'],
    );
    _similarArtistsFuture = artistDetailsAndSimilarFuture.then(
      (data) => data['similarArtists'],
    );

    _songsFuture = _contentService.loadArtistSongs(widget.artist.artistId);
    _albumsFuture = _contentService.loadArtistAlbums(widget.artist.artistId);
    _singlesFuture = _contentService.loadArtistSingles(widget.artist.artistId);

    _artistInfoFuture
        .then((artistDetailed) {
          if (!mounted) return;
          setState(() {
            _artistInfo = artistDetailed;
            _contentDescription = 'Artist • ${_artistInfo?.type ?? ''}';
          });
        })
        .catchError((e) {
          debugPrint('Error loading artist details: $e');
        });

    _songsFuture
        .then((songsData) {
          if (!mounted) return;
          setState(() {
            _songs = songsData['songs'];
            _allSongs = songsData['allSongs'];
          });
        })
        .catchError((e) {
          debugPrint('Error loading songs: $e');
        });

    _albumsFuture
        .then((albumsData) {
          if (!mounted) return;
          setState(() {
            _albums = albumsData['albums'];
            _allAlbums = albumsData['allAlbums'];
          });
        })
        .catchError((e) {
          debugPrint('Error loading albums: $e');
        });

    _singlesFuture
        .then((singlesData) {
          if (!mounted) return;
          setState(() {
            _singles = singlesData['singles'];
            _allSingles = singlesData['allSingles'];
          });
        })
        .catchError((e) {
          debugPrint('Error loading singles: $e');
        });

    _similarArtistsFuture
        .then((similarArtistsData) {
          if (!mounted) return;
          setState(() {
            _similarArtists = similarArtistsData;
          });
        })
        .catchError((e) {
          debugPrint('Error loading similar artists: $e');
        });
  }

  Widget _buildHeader({bool isDesktop = false}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    final imageSize = isDesktop
        ? (AppDimens.headerImageMd + AppDimens.spacingXxl)
        : (isSmallScreen
              ? (AppDimens.thumbnailLarge + AppDimens.spacingSm)
              : AppDimens.headerImageSm);
    final margin = AppDimens.spacingLg;
    final padding = isDesktop ? AppDimens.paddingXl : AppDimens.paddingLg;

    Widget headerContent;
    if (isDesktop) {
      headerContent = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Hero(
            tag: 'artist-image-${widget.artist.name}',
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
                  imageUrl: widget.artist.thumbnails.last.url,
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
                      child: CircularProgressIndicator(
                        strokeWidth: AppDimens.progressStroke,
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
            widget.artist.name,
            style: AppTextStyles.headingLg(
              isDarkMode: isDarkMode,
            ).copyWith(height: AppTextStyles.lineHeightDefault),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimens.spacingS),
          Text(
            _contentDescription,
            style: AppTextStyles.subtitle(isDarkMode: isDarkMode).copyWith(
              color: MainScreenColors.getTextColor(
                isDarkMode,
              ).withValues(alpha: 0.7),
              height: AppTextStyles.lineHeightBody,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimens.spacingXl),
          _buildActionButtons(context, false, isDesktop: true),
        ],
      );
    } else {
      headerContent = Stack(
        children: [
          Container(
            height:
                AppDimens.headerImageSm +
                AppDimens.spacingMd +
                (isSmallScreen ? AppDimens.spacingSm : AppDimens.spacingMd),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.radiusXl),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  MainScreenColors.getPrimaryColor(
                    isDarkMode,
                  ).withValues(alpha: 0.2),
                  Provider.of<SettingsProvider>(
                    context,
                  ).accentColor.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'artist-image-${widget.artist.name}',
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
                        imageUrl: widget.artist.thumbnails.last.url,
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.cover,
                        memCacheWidth: (imageSize * 2).toInt(),
                        memCacheHeight: (imageSize * 2).toInt(),
                        placeholder: (context, url) => Container(
                          color: Colors.grey[850],
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: AppDimens.progressStroke,
                            ),
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
                SizedBox(width: AppDimens.spacingLg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.artist.name,
                        style: AppTextStyles.titleSm(
                          isDarkMode: isDarkMode,
                        ).copyWith(height: AppTextStyles.lineHeightDefault),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppDimens.spacingXs),
                      Text(
                        _contentDescription,
                        style: AppTextStyles.caption(isDarkMode: isDarkMode)
                            .copyWith(
                              color: MainScreenColors.getTextColor(
                                isDarkMode,
                              ).withValues(alpha: 0.7),
                              height: AppTextStyles.lineHeightBody,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppDimens.spacingMd),
                      _buildActionButtons(context, isSmallScreen),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

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
      child: isDesktop
          ? Padding(padding: EdgeInsets.all(padding), child: headerContent)
          : headerContent,
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    bool isSmallScreen, {
    bool isDesktop = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Provider.of<SettingsProvider>(context).accentColor;

    if (isDesktop) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _songs.isEmpty ? null : () => _playSong(_songs.first),
              icon: const Icon(Icons.play_arrow, color: Colors.black),
              label: Text(
                'play'.tr(),
                style: AppTextStyles.bodyLg(isDarkMode: false).copyWith(
                  fontWeight: AppTextStyles.weightSemiBold,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: AppDimens.spacingMdLg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusXxxl),
                ),
                elevation: 4,
              ),
            ),
          ),
          SizedBox(height: AppDimens.spacingLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Consumer<FavoriteArtistProvider>(
                builder: (context, provider, child) {
                  final isFavorite = provider.favoriteArtists.any(
                    (artist) => artist['artistId'] == widget.artist.artistId,
                  );
                  return _buildIconButton(
                    icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                    onPressed: () async {
                      await provider.toggleFavorite(widget.artist);
                      if (!context.mounted) return;
                      AppSnackBar.showInfo(
                        context,
                        isFavorite
                            ? 'removed_from_favorites'.tr()
                            : 'added_to_favorites'.tr(),
                        duration: const Duration(seconds: 2),
                      );
                    },
                    tooltip: isFavorite ? 'unfollow'.tr() : 'follow'.tr(),
                    color: isFavorite
                        ? Colors.red
                        : MainScreenColors.getTextColor(isDarkMode),
                    isDarkMode: isDarkMode,
                    isSmallScreen: false,
                  );
                },
              ),
              _buildIconButton(
                icon: Icons.share,
                onPressed: _shareArtist,
                tooltip: 'share'.tr(),
                isDarkMode: isDarkMode,
                isSmallScreen: false,
              ),
            ],
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _songs.isEmpty ? null : () => _playSong(_songs.first),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen
                    ? AppDimens.spacingSm
                    : AppDimens.spacingMd,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusXxxl),
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_arrow,
                  size: isSmallScreen ? AppDimens.iconSm : AppDimens.iconMd,
                ),
                SizedBox(width: AppDimens.spacingXs),
                Text('play'.tr(), style: AppTextStyles.button()),
              ],
            ),
          ),
        ),
        SizedBox(
          width: isSmallScreen ? AppDimens.spacingSm : AppDimens.spacingMd,
        ),
        Consumer<FavoriteArtistProvider>(
          builder: (context, provider, child) {
            final isFavorite = provider.favoriteArtists.any(
              (artist) => artist['artistId'] == widget.artist.artistId,
            );
            return _buildIconButton(
              icon: isFavorite ? Icons.favorite : Icons.favorite_border,
              onPressed: () async {
                await provider.toggleFavorite(widget.artist);
                if (!context.mounted) return;
                AppSnackBar.showInfo(
                  context,
                  isFavorite
                      ? 'removed_from_favorites'.tr()
                      : 'added_to_favorites'.tr(),
                  duration: const Duration(seconds: 2),
                );
              },
              tooltip: isFavorite ? 'unfollow'.tr() : 'follow'.tr(),
              color: isFavorite
                  ? Colors.red
                  : MainScreenColors.getTextColor(isDarkMode),
              isDarkMode: isDarkMode,
              isSmallScreen: isSmallScreen,
            );
          },
        ),
        _buildIconButton(
          icon: Icons.share,
          onPressed: _shareArtist,
          tooltip: 'share'.tr(),
          isDarkMode: isDarkMode,
          isSmallScreen: isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    Color? color,
    required bool isDarkMode,
    required bool isSmallScreen,
  }) {
    return Container(
      margin: EdgeInsets.only(
        right: isSmallScreen ? AppDimens.spacingXs : AppDimens.paddingSm,
      ),
      decoration: BoxDecoration(
        color: MainScreenColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: color ?? MainScreenColors.getTextColor(isDarkMode),
        ),
        tooltip: tooltip,
        iconSize: isSmallScreen ? AppDimens.iconSm : AppDimens.iconMd,
        padding: EdgeInsets.all(
          isSmallScreen ? AppDimens.spacingS : AppDimens.paddingSm,
        ),
        constraints: BoxConstraints(
          minWidth: isSmallScreen
              ? AppDimens.buttonSizeCompact
              : AppDimens.buttonSizeDefault,
          minHeight: isSmallScreen
              ? AppDimens.buttonSizeCompact
              : AppDimens.buttonSizeDefault,
        ),
      ),
    );
  }

  SongInfo _convertSongDetailedToSongInfo(SongDetailed songDetailed) {
    return SongInfo(
      videoId: songDetailed.videoId,
      name: songDetailed.name,
      artists: [
        Artist(
          name: songDetailed.artist.name,
          id: songDetailed.artist.artistId ?? '',
        ),
      ],
      thumbnails: songDetailed.thumbnails
          .map(
            (thumbnail) => Thumbnail(
              url: thumbnail.url,
              width: thumbnail.width,
              height: thumbnail.height,
            ),
          )
          .toList(),
      duration: songDetailed.duration != null
          ? Duration(seconds: songDetailed.duration!)
          : Duration.zero,
    );
  }

  Future<void> _playSong(dynamic song) async {
    if (!mounted) return;

    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final queueProvider = Provider.of<QueueProvider>(context, listen: false);

    SongInfo songInfo;
    if (song is SongDetailed) {
      songInfo = _convertSongDetailedToSongInfo(song);
    } else if (song is SongInfo) {
      songInfo = song;
    } else {
      throw Exception('Invalid song type: ${song.runtimeType}');
    }

    final List<SongInfo> convertedSongs = _songs.map((s) {
      if (s is SongDetailed) {
        return _convertSongDetailedToSongInfo(s);
      } else if (s is SongInfo) {
        return s;
      } else {
        throw Exception('Invalid song type in list: ${s.runtimeType}');
      }
    }).toList();

    try {
      await _contentService.playSong(
        songInfo,
        playerProvider,
        queueProvider,
        convertedSongs,
        playlistName: widget.artist.name,
      );
      await queueProvider.saveQueue();
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error playing song');
      AppSnackBar.showError(context, 'failed_to_play_song_error'.tr());
    }
  }

  void _shareArtist() {
    final shareText =
        'Check out this artist: ${widget.artist.name} \n'
        'on YouTube Music!\n'
        'https://music.youtube.com/channel/${widget.artist.artistId}';
    SharePlus.instance.share(ShareParams(text: shareText));
  }

  Widget _buildPopularSongsSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_songs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'popular_songs'.tr(),
          onMoreTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SongListScreen(title: 'popular_songs'.tr(), songs: _allSongs),
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: min(5, _songs.length),
          itemBuilder: (context, index) {
            final song = _songs[index];
            final isCurrentlyPlaying =
                Provider.of<PlayerProvider>(context).currentSong?.videoId ==
                song.videoId;
            return ArtistSongListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
              song: song,
              isPlaying: isCurrentlyPlaying,
              onPlay: () => _playSong(song),
              isDarkMode: isDarkMode,
            );
          },
        ),
      ],
    );
  }

  Widget _buildAlbumsSection({bool isDesktop = false}) {
    if (_albums.isEmpty) return const SizedBox.shrink();

    final albumHeight = isDesktop
        ? AppDimens.chartHeight
        : AppDimens.shimmerSection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'albums'.tr(),
          onMoreTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AlbumListScreen(title: 'albums'.tr(), albums: _allAlbums),
            ),
          ),
        ),
        SizedBox(
          height: albumHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: AppDimens.spacingLg),
            itemCount: _albums.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(right: AppDimens.spacingMd),
              child: AlbumCard(album: _albums[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSinglesSection({bool isDesktop = false}) {
    if (_singles.isEmpty) return const SizedBox.shrink();

    final singleHeight = isDesktop
        ? AppDimens.chartHeight
        : AppDimens.shimmerSection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'singles'.tr(),
          onMoreTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AlbumListScreen(title: 'singles'.tr(), albums: _allSingles),
            ),
          ),
        ),
        SizedBox(
          height: singleHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: AppDimens.spacingLg),
            itemCount: _singles.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(right: AppDimens.spacingMd),
              child: AlbumCard(album: _singles[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarArtistsSection() {
    if (_similarArtists.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'similar_artists'.tr()),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            int crossAxisCount = 2;
            if (width >= 1200) {
              crossAxisCount = 5;
            } else if (width >= 1000) {
              crossAxisCount = 4;
            } else if (width >= 700) {
              crossAxisCount = 3;
            }

            final childAspectRatio = width >= 700 ? 1.6 : 1.4;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: AppDimens.spacingMd,
                mainAxisSpacing: AppDimens.spacingMd,
              ),
              itemCount: _similarArtists.length,
              itemBuilder: (context, index) => ArtistCard(
                artist: _similarArtists[index],
                onTap: () => Navigator.pushNamed(
                  context,
                  '/content',
                  arguments: {
                    'contentId': _similarArtists[index].id,
                    'contentType': 'artist',
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onMoreTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.spacingLg,
        AppDimens.spacingXxl,
        AppDimens.spacingLg,
        AppDimens.spacingXxl,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.titleLg(isDarkMode: isDarkMode).copyWith(
              color: Provider.of<SettingsProvider>(context).accentColor,
            ),
          ),
          if (onMoreTap != null)
            TextButton(
              onPressed: onMoreTap,
              child: Text(
                'more'.tr(),
                style: AppTextStyles.bodyMd(isDarkMode: isDarkMode).copyWith(
                  color: MainScreenColors.getTextColor(
                    isDarkMode,
                  ).withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionsContent(
    PlayerProvider playerProvider,
    bool isDarkMode, {
    bool isDesktop = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: _songsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ContentShimmer.buildSectionHeaderShimmer(
                    context,
                    'popular_songs'.tr(),
                  ),
                  ContentShimmer.buildSongListShimmer(context, 5),
                ],
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              _songs = snapshot.data!['songs'];
              _allSongs = snapshot.data!['allSongs'];
              return _buildPopularSongsSection();
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
        FutureBuilder<Map<String, dynamic>>(
          future: _albumsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ContentShimmer.buildSectionHeaderShimmer(
                    context,
                    'albums'.tr(),
                  ),
                  ContentShimmer.buildHorizontalListShimmer(context),
                ],
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              _albums = snapshot.data!['albums'];
              _allAlbums = snapshot.data!['allAlbums'];
              return _buildAlbumsSection(isDesktop: isDesktop);
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
        FutureBuilder<Map<String, dynamic>>(
          future: _singlesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ContentShimmer.buildSectionHeaderShimmer(
                    context,
                    'singles'.tr(),
                  ),
                  ContentShimmer.buildHorizontalListShimmer(context),
                ],
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              _singles = snapshot.data!['singles'];
              _allSingles = snapshot.data!['allSingles'];
              return _buildSinglesSection(isDesktop: isDesktop);
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
        FutureBuilder<List<ArtistInfo>>(
          future: _similarArtistsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ContentShimmer.buildSectionHeaderShimmer(
                    context,
                    'similar_artists'.tr(),
                  ),
                  ContentShimmer.buildGridShimmer(context),
                ],
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              _similarArtists = snapshot.data!;
              return _buildSimilarArtistsSection();
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ],
    );
  }

  Widget _buildDesktopLeftPanel(bool isDarkMode) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: AppDimens.miniPlayerHeight + AppDimens.spacingXs,
      ),
      child: FutureBuilder<ArtistDetailed>(
        future: _artistInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ArtistContentShimmer.headerShimmer(context);
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            _artistInfo = snapshot.data;
            _contentDescription = 'Artist • ${_artistInfo?.type ?? ''}';
            return _buildHeader(isDesktop: true);
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildContent(PlayerProvider playerProvider, bool isDarkMode) {
    final hasPlayer =
        playerProvider.currentSong != null ||
        playerProvider.lastPlayedSong != null;

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
                width: AppDimens.borderWidthThin,
                height: double.infinity,
                color: MainScreenColors.getTextColor(
                  isDarkMode,
                ).withValues(alpha: 0.1),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: AppDimens.miniPlayerHeight + AppDimens.spacingXs,
                  ),
                  child: _buildSectionsContent(
                    playerProvider,
                    isDarkMode,
                    isDesktop: true,
                  ),
                ),
              ),
            ],
          );
        }
        return Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<ArtistDetailed>(
                      future: _artistInfoFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return ArtistContentShimmer.headerShimmer(context);
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        } else if (snapshot.hasData) {
                          _artistInfo = snapshot.data;
                          _contentDescription =
                              'Artist • ${_artistInfo?.type ?? ''}';
                          return _buildHeader();
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                    _buildSectionsContent(playerProvider, isDarkMode),
                    SizedBox(
                      height: hasPlayer
                          ? 75 + MediaQuery.of(context).padding.bottom + 5
                          : 0,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: ThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: MainScreenColors.getBackgroundColor(
          isDarkMode,
        ),
        cardColor: MainScreenColors.getSurfaceColor(isDarkMode),
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
              ),
              body: _buildContent(playerProvider, isDarkMode),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class ArtistCard extends StatelessWidget {
  final ArtistInfo artist;
  final VoidCallback onTap;

  const ArtistCard({Key? key, required this.artist, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        final artistDetailed = ArtistDetailed(
          artistId: artist.id,
          name: artist.name,
          thumbnails: [
            ThumbnailFull(url: artist.thumbnailUrl, width: 0, height: 0),
          ],
          type: '',
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArtistContent(artist: artistDetailed),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: MainScreenColors.getSurfaceColor(isDarkMode),
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppDimens.radiusLg),
                ),
                child: CachedNetworkImage(
                  imageUrl: artist.thumbnailUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                    child: Center(
                      child: Icon(
                        Icons.music_note,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                    child: Icon(
                      Icons.error,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.paddingSm),
              child: Text(
                artist.name,
                style: AppTextStyles.queueItem(isDarkMode: isDarkMode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
