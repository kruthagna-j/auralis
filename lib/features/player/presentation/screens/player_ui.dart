import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart' hide RepeatMode;

import 'package:provider/provider.dart';

import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../../core/utils/content_router.dart';
import '../../../../shared/components/player_more_song_bottomsheet.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/download_provider.dart';
import '../../../../core/providers/favorite_song_provider.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/queued_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/services/player_service.dart';
import '../../../../shared/animations/animation_1.dart';
import '../../../../shared/animations/animation_2.dart';
import '../../../../shared/animations/animation_3.dart';
import '../../../../shared/animations/animation_4.dart';
import '../../../../shared/animations/animation_5.dart';
import '../../../equalizer/presentation/screens/equalizer_screen.dart';
import '../widgets/lyrics_display.dart';
import '../widgets/player_components.dart';
import '../widgets/player_controls.dart';
import '../widgets/queued_bottomsheet.dart';
import '../widgets/sleep_timer_bottomsheet.dart';
import '../widgets/volume_bottomsheet.dart';
import '../widgets/video_mode_dialog.dart';
import '../../../../shared/components/app_snackbar.dart';

class PlayerUI extends StatefulWidget {
  final bool showFullScreen;
  final bool isBottomSheet;
  final bool isEmbedded;
  final VoidCallback onMinimize;
  final VoidCallback onExpand;

  const PlayerUI({
    Key? key,
    this.showFullScreen = false,
    this.isBottomSheet = false,
    this.isEmbedded = false,
    required this.onMinimize,
    required this.onExpand,
  }) : super(key: key);

  @override
  PlayerUIState createState() => PlayerUIState();
}

class PlayerUIState extends State<PlayerUI>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _miniPlayerOpacityAnimation;
  late Animation<double> _fullPlayerOpacityAnimation;
  late PlayerProvider _playerProvider;
  late PlayerService _playerService;
  double _dragOffset = 0.0;
  double _fullDragOffset = 0.0;

  late FavoriteSongProvider _favoriteSongProvider;

  late QueueProvider _queueProvider;
  bool _isVideoMode = false;
  bool _hasShownVideoDialog = false;
  double _volume = 1.0;

  final GlobalKey _artistKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializePlayer();
    _favoriteSongProvider = Provider.of<FavoriteSongProvider>(
      context,
      listen: false,
    );
    _setupPlayerListeners();
    _initVolume();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _favoriteSongProvider.setCurrentSong(_playerProvider.currentSong);
      }
    });
  }

  void _initVolume() {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    _volume = playerProvider.playerService.volume;
  }

  void _setVolume(double value) {
    setState(() {
      _volume = value;
      _playerService.setVolume(value);
    });
  }

  Color _volumeColor(double value) {
    if (value <= 0.6) return Colors.green;
    if (value <= 1.0) return Colors.amber;
    return Colors.red;
  }

  String? _lastBgColorSongId;

  void _setupPlayerListeners() {
    _playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    _playerService = _playerProvider.playerService;
    _queueProvider = Provider.of<QueueProvider>(context, listen: false);

    _playerService.playerStateStream.listen((playerState) {
      if (!mounted) return;
      final currentSong = _playerProvider.currentSong;
      if (currentSong != null) {
        final songId = currentSong.videoId;
        if (_lastBgColorSongId != songId) {
          _lastBgColorSongId = songId;
          _playerService.updateBackgroundColor(
            currentSong.thumbnails.first.url,
          );
          _favoriteSongProvider.setCurrentSong(currentSong);
        }
      }
    });

    _playerService.isFetchingStreamUrlNotifier.addListener(
      _onFetchingStreamUrlChanged,
    );
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _miniPlayerOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _fullPlayerOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  void _initializePlayer() {
    _playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    _playerService = _playerProvider.playerService;
    if (widget.showFullScreen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final accentColor = settingsProvider.accentColor;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ValueListenableBuilder<Color>(
          valueListenable: _playerService.backgroundColorNotifier,
          builder: (context, backgroundColor, child) {
            if (widget.isEmbedded) {
              return Opacity(
                opacity: _miniPlayerOpacityAnimation.value,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      _dragOffset += details.primaryDelta!;
                      _dragOffset = _dragOffset.clamp(-25.0, 0.0);
                    });
                  },
                  onVerticalDragEnd: (details) {
                    if (_dragOffset < -20) {
                      widget.onExpand();
                    }
                    setState(() {
                      _dragOffset = 0.0;
                    });
                  },
                  child: Transform.translate(
                    offset: Offset(0, _dragOffset),
                    child: _buildMiniPlayer(accentColor),
                  ),
                ),
              );
            }

            return Stack(
              children: [
                if (_fullPlayerOpacityAnimation.value > 0)
                  Positioned.fill(
                    child: Opacity(
                      opacity: _fullPlayerOpacityAnimation.value,
                      child: _buildFullPlayer(
                        true,
                        accentColor,
                        backgroundColor,
                      ),
                    ),
                  ),
                if (!widget.isBottomSheet)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Opacity(
                      opacity: _miniPlayerOpacityAnimation.value,
                      child: GestureDetector(
                        onVerticalDragUpdate: (details) {
                          setState(() {
                            _dragOffset += details.primaryDelta!;
                            _dragOffset = _dragOffset.clamp(-25.0, 0.0);
                          });
                        },
                        onVerticalDragEnd: (details) {
                          if (_dragOffset < -20) {
                            widget.onExpand();
                          }
                          setState(() {
                            _dragOffset = 0.0;
                          });
                        },
                        child: Transform.translate(
                          offset: Offset(0, _dragOffset),
                          child: _buildMiniPlayer(accentColor),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFullPlayer(
    bool isDarkMode,
    Color accentColor,
    Color BackgroundColor,
  ) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: true,
    );
    final isDefaultAnimation = settingsProvider.animationType == 'Default';

    Widget _buildAnimatedBackground(bool isAnimating) {
      final effectiveBackgroundColor = BackgroundColor.withValues(alpha: 0.6);
      switch (settingsProvider.animationType) {
        case 'Animation 1':
          return Animation1(
            backgroundColor: effectiveBackgroundColor,
            accentColor: accentColor,
            isAnimating: isAnimating,
          );
        case 'Animation 2':
          return Animation2(
            backgroundColor: effectiveBackgroundColor,
            accentColor: accentColor,
            isAnimating: isAnimating,
          );
        case 'Animation 3':
          return Animation3(
            backgroundColor: effectiveBackgroundColor,
            accentColor: accentColor,
            isAnimating: isAnimating,
          );
        case 'Animation 4':
          return Animation4(
            backgroundColor: effectiveBackgroundColor,
            accentColor: accentColor,
            isAnimating: isAnimating,
          );
        case 'Animation 5':
          return Animation5(
            backgroundColor: effectiveBackgroundColor,
            accentColor: accentColor,
            isAnimating: isAnimating,
          );
        case 'Default':
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BackgroundColor.withValues(alpha: 0.35),
                  BackgroundColor.withValues(alpha: 0.18),
                  Colors.black.withValues(alpha: AppDimens.opacityHigh),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          );
        case 'static':
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: AppDimens.opacityHigh),
                  effectiveBackgroundColor,
                  effectiveBackgroundColor,
                  accentColor.withValues(alpha: AppDimens.opacityMedium),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          );
        default:
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [effectiveBackgroundColor, Colors.black],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          );
      }
    }

    Widget _buildPlayerGlassOverlay() {
      if (!isDefaultAnimation) {
        return Container(color: Colors.white.withValues(alpha: 0.08));
      }

      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.white.withValues(alpha: 0.06)),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > AppDimens.breakpointWideScreen;
    final maxContentWidth = AppDimens.maxContentWidth;

    if (widget.isBottomSheet) {
      return Stack(
        children: [
          Positioned.fill(
            child: _buildAnimatedBackground(
              _fullPlayerOpacityAnimation.value > 0,
            ),
          ),
          Positioned.fill(child: _buildPlayerGlassOverlay()),
          SafeArea(
            top: false,
            child: Column(
              children: [
                SizedBox(
                  height: Platform.isWindows || Platform.isLinux ? 20 : 50,
                ),
                PlayerComponents.buildFullPlayerAppBar(
                  context,
                  isDarkMode,
                  _isVideoMode,
                  widget.onMinimize,
                  _toggleVideoMode,
                  _buildOptionsMenu,
                  accentColor,
                  isLocalSong: _playerProvider.currentLocalSong != null,
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: isWideScreen
                          ? _buildWideFullPlayer(isDarkMode, accentColor)
                          : _buildNarrowFullPlayer(isDarkMode, accentColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Transform.translate(
      offset: Offset(0, _fullDragOffset),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: (details) {
          if (Platform.isAndroid || Platform.isIOS) {
            setState(() {
              _fullDragOffset += details.primaryDelta!;
              _fullDragOffset = _fullDragOffset.clamp(
                0.0,
                AppDimens.dragOffsetMax,
              );
            });
          }
        },
        onVerticalDragEnd: (details) {
          if (_fullDragOffset > 80 ||
              (details.primaryVelocity != null &&
                  details.primaryVelocity! > 700)) {
            widget.onMinimize();
          }
          setState(() {
            _fullDragOffset = 0.0;
          });
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: _buildAnimatedBackground(
                _fullPlayerOpacityAnimation.value > 0,
              ),
            ),
            Positioned.fill(child: _buildPlayerGlassOverlay()),
            SafeArea(
              top: false,
              child: Column(
                children: [
                  SizedBox(
                    height: Platform.isWindows || Platform.isLinux ? 20 : 50,
                  ),
                  PlayerComponents.buildFullPlayerAppBar(
                    context,
                    isDarkMode,
                    _isVideoMode,
                    widget.onMinimize,
                    _toggleVideoMode,
                    _buildOptionsMenu,
                    accentColor,
                    isLocalSong: _playerProvider.currentLocalSong != null,
                  ),
                  const SizedBox(height: AppDimens.spacingXs),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContentWidth),
                        child: isWideScreen
                            ? _buildWideFullPlayer(isDarkMode, accentColor)
                            : _buildNarrowFullPlayer(isDarkMode, accentColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideFullPlayer(bool isDarkMode, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingXxl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.paddingLg),
              child: PlayerComponents.buildMediaPlayer(
                isDarkMode,
                _isVideoMode,
                _playerProvider,
                _playerService,
                context,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.spacingXxl),
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: AppDimens.spacingLg),
                  Consumer2<DownloadProvider, FavoriteSongProvider>(
                    builder:
                        (
                          context,
                          downloadProvider,
                          favoriteSongProvider,
                          child,
                        ) {
                          final videoId = _playerProvider.currentSong?.videoId;
                          return PlayerComponents.buildSongInfo(
                            isMini: false,
                            isDarkMode: true,
                            context: context,
                            playerProvider: _playerProvider,
                            accentColor: accentColor,
                            isDownloading:
                                videoId != null &&
                                (downloadProvider.preparing.contains(videoId) ||
                                    downloadProvider.progressMap.containsKey(
                                      videoId,
                                    )),
                            isLiked: favoriteSongProvider.isCurrentSongLiked,
                            toggleLike: favoriteSongProvider.toggleLike,
                            isLocalSong:
                                _playerProvider.currentLocalSong != null,
                            onMorePressed: () => _showShareBottomSheet(),
                            onArtistTap:
                                _playerProvider.currentLocalSong == null
                                ? () => _handleArtistTap()
                                : null,
                            onVolumePressed: _showVolumeBottomSheet,
                            onEqualizerPressed: _openEqualizer,
                            artistKey: _artistKey,
                          );
                        },
                  ),
                  const SizedBox(height: AppDimens.spacingXl),
                  PlayerControls.buildProgressBar(
                    context: context,
                    isDarkMode: true,
                    accentColor: accentColor,
                    playerService: _playerService,
                  ),
                  const SizedBox(height: AppDimens.spacingXl),
                  PlayerControls.buildFullPlayerControls(
                    isDarkMode: true,
                    accentColor: accentColor,
                    queueProvider: _queueProvider,
                    playerService: _playerService,
                    handlePrevious: _handlePrevious,
                    handlePlayPause: _handlePlayPause,
                    handleNext: _handleNext,
                  ),
                  if (!_isVideoMode) ...[
                    const SizedBox(height: AppDimens.spacingXxl),
                    Consumer<DownloadProvider>(
                      builder: (context, downloadProvider, child) {
                        final videoId = _playerProvider.currentSong?.videoId;
                        final downloadProgressObj = videoId != null
                            ? downloadProvider.progressMap[videoId]
                            : null;
                        final downloadProgress = downloadProgressObj?.progress;
                        final isDownloaded =
                            videoId != null &&
                            downloadProvider.downloadedSongs.any(
                              (s) => s['id'] == videoId,
                            );

                        return PlayerComponents.buildPlayerActionRow(
                          context: context,
                          isDarkMode: isDarkMode,
                          accentColor: accentColor,
                          onShowSleepTimer: _showSleepTimerBottomSheet,
                          onShowLyrics: _showLyricsBottomSheet,
                          onShowQueue: _showQueueBottomSheet,
                          onDownload: videoId != null
                              ? () => downloadProvider.downloadSong(
                                  _playerProvider.currentSong!,
                                )
                              : null,
                          onToggleShuffle: () => _queueProvider.toggleShuffle(),
                          onToggleRepeat: () => _queueProvider.toggleRepeat(),
                          downloadProgress: downloadProgress,
                          isDownloaded: isDownloaded,
                          isPreparing:
                              videoId != null &&
                              downloadProvider.preparing.contains(videoId),
                          isShuffleActive: _queueProvider.isShuffleEnabled,
                          repeatMode: _queueProvider.repeatMode,
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowFullPlayer(bool isDarkMode, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingSmMd),
      child: Column(
        children: [
          SizedBox(
            height: Platform.isWindows || Platform.isLinux
                ? AppDimens.spacingSmMd
                : AppDimens.spacingXl,
          ),
          Expanded(
            child: PlayerComponents.buildMediaPlayer(
              isDarkMode,
              _isVideoMode,
              _playerProvider,
              _playerService,
              context,
            ),
          ),
          SizedBox(
            height: Platform.isWindows || Platform.isLinux
                ? AppDimens.spacingMd
                : AppDimens.spacingXl,
          ),
          Consumer2<DownloadProvider, FavoriteSongProvider>(
            builder: (context, downloadProvider, favoriteSongProvider, child) {
              final videoId = _playerProvider.currentSong?.videoId;
              return PlayerComponents.buildSongInfo(
                isMini: false,
                isDarkMode: true,
                context: context,
                playerProvider: _playerProvider,
                accentColor: accentColor,
                isDownloading:
                    videoId != null &&
                    (downloadProvider.preparing.contains(videoId) ||
                        downloadProvider.progressMap.containsKey(videoId)),
                isLiked: favoriteSongProvider.isCurrentSongLiked,
                toggleLike: favoriteSongProvider.toggleLike,
                isLocalSong: _playerProvider.currentLocalSong != null,
                onMorePressed: () => _showShareBottomSheet(),
                onArtistTap: _playerProvider.currentLocalSong == null
                    ? () => _handleArtistTap()
                    : null,
                onVolumePressed: _showVolumeBottomSheet,
                onEqualizerPressed: _openEqualizer,
                artistKey: _artistKey,
              );
            },
          ),
          SizedBox(
            height: Platform.isWindows || Platform.isLinux
                ? AppDimens.spacingMd
                : AppDimens.spacingXl,
          ),
          PlayerControls.buildProgressBar(
            context: context,
            isDarkMode: true,
            accentColor: accentColor,
            playerService: _playerService,
          ),
          SizedBox(height: Platform.isWindows || Platform.isLinux ? 12 : 22),
          PlayerControls.buildFullPlayerControls(
            isDarkMode: true,
            accentColor: accentColor,
            queueProvider: _queueProvider,
            playerService: _playerService,
            handlePrevious: _handlePrevious,
            handlePlayPause: _handlePlayPause,
            handleNext: _handleNext,
          ),
          if (!_isVideoMode) ...[
            SizedBox(
              height: Platform.isWindows || Platform.isLinux
                  ? AppDimens.spacingXs
                  : AppDimens.spacingXxxl,
            ),
            Consumer<DownloadProvider>(
              builder: (context, downloadProvider, child) {
                final videoId = _playerProvider.currentSong?.videoId;
                final downloadProgressObj = videoId != null
                    ? downloadProvider.progressMap[videoId]
                    : null;
                final downloadProgress = downloadProgressObj?.progress;
                final isDownloaded =
                    videoId != null &&
                    downloadProvider.downloadedSongs.any(
                      (s) => s['id'] == videoId,
                    );

                return PlayerComponents.buildPlayerActionRow(
                  context: context,
                  isDarkMode: isDarkMode,
                  accentColor: accentColor,
                  onShowSleepTimer: _showSleepTimerBottomSheet,
                  onShowLyrics: _showLyricsBottomSheet,
                  onShowQueue: _showQueueBottomSheet,
                  onDownload: videoId != null
                      ? () => downloadProvider.downloadSong(
                          _playerProvider.currentSong!,
                        )
                      : null,
                  onToggleShuffle: () => _queueProvider.toggleShuffle(),
                  onToggleRepeat: () => _queueProvider.toggleRepeat(),
                  downloadProgress: downloadProgress,
                  isDownloaded: isDownloaded,
                  isPreparing:
                      videoId != null &&
                      downloadProvider.preparing.contains(videoId),
                  isShuffleActive: _queueProvider.isShuffleEnabled,
                  repeatMode: _queueProvider.repeatMode,
                );
              },
            ),
          ],
          SizedBox(
            height: Platform.isWindows || Platform.isLinux
                ? AppDimens.spacingSmMd
                : AppDimens.spacingXl,
          ),
        ],
      ),
    );
  }

  void _handleArtistTap() {
    final song = _playerProvider.currentSong;
    if (song != null) {
      if (song.artists.length == 1) {
        final artist = song.artists.first;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContentRouter(
              content: ArtistDetailed(
                artistId: artist.id,
                name: artist.name,
                thumbnails: [
                  ThumbnailFull(
                    url: song.thumbnails.first.url,
                    width: 0,
                    height: 0,
                  ),
                ],
                type: '',
              ),
            ),
          ),
        );
      } else {
        final RenderBox renderBox =
            _artistKey.currentContext!.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            position.dx,
            position.dy - size.height,
            position.dx + size.width,
            position.dy,
          ),
          items: song.artists.map((artist) {
            return PopupMenuItem(value: artist, child: Text(artist.name));
          }).toList(),
        ).then((selectedArtist) {
          if (selectedArtist != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ContentRouter(
                  content: ArtistDetailed(
                    artistId: selectedArtist.id,
                    name: selectedArtist.name,
                    thumbnails: [
                      ThumbnailFull(
                        url: song.thumbnails.first.url,
                        width: 0,
                        height: 0,
                      ),
                    ],
                    type: '',
                  ),
                ),
              ),
            );
          }
        });
      }
    }
  }

  Widget _buildMiniPlayer(Color accentColor) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: true,
    );
    final isDarkMode =
        settingsProvider.theme == 'Dark' ||
        (settingsProvider.theme == 'System Default' &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > AppDimens.breakpointWideScreen;
    final isCompact = screenWidth < AppDimens.breakpointSmallMobile;
    final miniPlayerHeight = isWideScreen
        ? AppDimens.miniPlayerHeightWide
        : (isCompact
              ? AppDimens.miniPlayerHeightCompact
              : AppDimens.miniPlayerHeight);
    final thumbnailSize = isWideScreen
        ? AppDimens.thumbnailLarge
        : (isCompact ? AppDimens.thumbnailMini : AppDimens.thumbnailDefault);
    const miniPlayerBorderRadius = BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
    );

    return GestureDetector(
      onTap: widget.onExpand,
      child: Center(
        child: ClipRRect(
          borderRadius: miniPlayerBorderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              height: miniPlayerHeight,
              constraints: const BoxConstraints(
                maxWidth: AppDimens.maxModalWidth,
              ),
              decoration: BoxDecoration(
                borderRadius: miniPlayerBorderRadius,
                gradient: LinearGradient(
                  colors: [
                    MainScreenColors.getSurfaceColor(
                      isDarkMode,
                    ).withValues(alpha: 0.78),
                    MainScreenColors.getSurfaceColor(
                      isDarkMode,
                    ).withValues(alpha: 0.56),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: widget.isEmbedded
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: AppDimens.opacityMedium,
                          ),
                          blurRadius: AppDimens.elevationHigh,
                          offset: Offset(0, AppDimens.shadowOffsetSmall),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        PlayerComponents.buildThumbnail(
                          isMini: true,
                          isDarkMode: isDarkMode,
                          playerProvider: _playerProvider,
                          playerService: _playerService,
                          thumbnailSize: thumbnailSize,
                        ),
                        if (isWideScreen)
                          SizedBox(
                            width: AppDimens.songInfoCompactWidth,
                            child: PlayerComponents.buildSongInfo(
                              isMini: true,
                              isDarkMode: isDarkMode,
                              context: context,
                              playerProvider: _playerProvider,
                              expand: false,
                            ),
                          )
                        else
                          PlayerComponents.buildSongInfo(
                            isMini: true,
                            isDarkMode: isDarkMode,
                            context: context,
                            playerProvider: _playerProvider,
                          ),
                        if (isWideScreen) const Spacer(),
                        if (isWideScreen)
                          SizedBox(
                            width:
                                screenWidth *
                                AppDimens.widePlayerProgressWidthFactor,
                            child: PlayerControls.buildProgressBar(
                              context: context,
                              isMini: false,
                              isDarkMode: isDarkMode,
                              accentColor: accentColor,
                              playerService: _playerService,
                            ),
                          ),
                        if (isWideScreen) const Spacer(),
                        PlayerControls.buildMiniControls(
                          isDarkMode: isDarkMode,
                          accentColor: accentColor,
                          queueProvider: _queueProvider,
                          playerService: _playerService,
                          handlePrevious: _handlePrevious,
                          handlePlayPause: _handlePlayPause,
                          handleNext: _handleNext,
                        ),
                        if (_playerProvider.currentLocalSong == null)
                          Consumer<FavoriteSongProvider>(
                            builder: (context, favoriteSongProvider, child) {
                              return PlayerControls.buildFavoriteButton(
                                isMini: true,
                                isDarkMode: isDarkMode,
                                accentColor: accentColor,
                                isLiked:
                                    favoriteSongProvider.isCurrentSongLiked,
                                toggleLike: favoriteSongProvider.toggleLike,
                              );
                            },
                          ),
                        if (isWideScreen) ...[
                          const SizedBox(width: AppDimens.spacingXs),
                          IconButton(
                            icon: Icon(
                              Icons.queue_music,
                              color: MainScreenColors.getTextColor(isDarkMode),
                              size: AppDimens.iconLg,
                            ),
                            onPressed: _showQueueBottomSheet,
                            tooltip: 'Queue',
                          ),
                          Icon(
                            _volume == 0
                                ? Icons.volume_off
                                : (_volume < 0.5
                                      ? Icons.volume_down
                                      : Icons.volume_up),
                            color: MainScreenColors.getTextColor(isDarkMode),
                            size: AppDimens.iconMd,
                          ),
                          SizedBox(
                            width: AppDimens.inlineSliderWidth,
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: AppDimens.sliderTrackHeight,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: AppDimens.thumbRadius,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: AppDimens.overlayRadius,
                                ),
                                activeTrackColor: _volumeColor(_volume),
                                inactiveTrackColor:
                                    MainScreenColors.getTextColor(
                                      isDarkMode,
                                    ).withValues(
                                      alpha: AppDimens.opacityMedium,
                                    ),
                                thumbColor: _volumeColor(_volume),
                              ),
                              child: Slider(
                                value: _volume,
                                onChanged: _setVolume,
                                min: 0.0,
                                max: 1.5,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: AppDimens.spacingSm),
                      ],
                    ),
                  ),
                  if (!isWideScreen)
                    PlayerControls.buildProgressBar(
                      context: context,
                      isMini: true,
                      isDarkMode: isDarkMode,
                      accentColor: accentColor,
                      playerService: _playerService,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handlePlayPause() async {
    try {
      final isPlaying = _playerService.isPlaying;
      if (isPlaying) {
        await _playerService.pause();
      } else {
        if (_playerProvider.currentSong != null ||
            _playerProvider.currentLocalSong != null) {
          await _playerService.play();
        } else {
          if (_queueProvider.queue.isNotEmpty &&
              _queueProvider.currentIndex >= 0 &&
              _queueProvider.currentIndex < _queueProvider.queue.length) {
            final currentQueueSong =
                _queueProvider.queue[_queueProvider.currentIndex];
            await _playerService.playSong(currentQueueSong);
          } else if (_playerProvider.lastPlayedSong != null) {
            final lastSong = _playerProvider.lastPlayedSong!;
            _queueProvider.addToQueue(lastSong);
            _queueProvider.setCurrentIndex(_queueProvider.queue.length - 1);
            await _playerService.playSong(lastSong);
          }
        }
      }
    } catch (e) {
      AppSnackBar.showError(context, 'Error during playback');
    }
  }

  void _openEqualizer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height * AppDimens.sheetHeightFactor,
      ),
      backgroundColor: Colors.transparent,
      builder: (context) =>
          const SafeArea(child: EqualizerScreen(openedFromPlayer: true)),
    );
  }

  void _handleNext() async {
    if (_playerProvider.currentLocalSong != null) {
      _playerService.playNext();
      return;
    }

    final nextSong = _queueProvider.getNextSong();
    if (nextSong != null) {
      await _playerService.playSong(nextSong);
    }
  }

  void _handlePrevious() async {
    if (_playerProvider.currentLocalSong != null) {
      _playerService.playPrevious();
      return;
    }

    final previousSong = _queueProvider.getPreviousSong();
    if (previousSong != null) {
      await _playerService.playSong(previousSong);
    }
  }

  void _showQueueBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 700),
      ),
      builder: (context) => const SafeArea(child: QueueBottomSheet()),
    );
  }

  void _showLyricsBottomSheet() {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktopOrLargeScreen =
        Platform.isWindows ||
        Platform.isMacOS ||
        Platform.isLinux ||
        screenWidth > AppDimens.breakpointWideScreen;

    final maxHeight = isDesktopOrLargeScreen
        ? MediaQuery.of(context).size.height
        : MediaQuery.of(context).size.height * AppDimens.sheetHeightFactor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: isDesktopOrLargeScreen,
      constraints: BoxConstraints(maxHeight: maxHeight),
      builder: (context) => SafeArea(
        child: LyricsDisplay(
          positionStream: _playerService.positionStream,
          onClose: () => Navigator.pop(context),
          onSeek: (position) => _playerService.seek(position),
        ),
      ),
    );
  }

  void _toggleVideoMode() async {
    final switchingToVideo = !_isVideoMode;
    if (switchingToVideo && _playerService.isPlaying) {
      try {
        await _playerService.pause();
      } catch (_) {
        if (mounted) {
          AppSnackBar.showError(context, 'Error pausing playback');
        }
      }
    }

    if (!mounted) return;

    setState(() {
      _isVideoMode = !_isVideoMode;
      if (_isVideoMode && !_hasShownVideoDialog) {
        _hasShownVideoDialog = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final accentColor = Provider.of<SettingsProvider>(
            context,
            listen: false,
          ).accentColor;
          VideoModeDialog.show(context, accentColor: accentColor);
        });
      }
    });
  }

  void _showSleepTimerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SafeArea(child: SleepTimerBottomSheet()),
    );
  }

  void _showVolumeBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SafeArea(child: VolumeBottomSheet()),
    );
  }

  Widget _buildOptionsMenu(bool isDarkMode) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final accentColor = settingsProvider.accentColor;

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < AppDimens.breakpointSmallMobile;
    final btnSize = isCompact
        ? AppDimens.buttonSizeCompact
        : AppDimens.buttonSizeLg;
    final margin = EdgeInsets.only(
      right: isCompact ? AppDimens.spacingS : AppDimens.spacingSm,
    );
    final iconSize = isCompact ? AppDimens.iconSm : AppDimens.iconLg;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: margin,
          width: btnSize,
          height: btnSize,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: AppDimens.opacitySemi),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: accentColor,
              size: iconSize,
            ),
            onPressed: () {
              _showShareBottomSheet();
            },
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ),
      ],
    );
  }

  void _showShareBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height * AppDimens.sheetHeightFactor,
      ),
      isScrollControlled: true,
      builder: (context) => const SafeArea(child: PlayerMoreSongBottomSheet()),
    );
  }

  @override
  void didUpdateWidget(PlayerUI oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showFullScreen != widget.showFullScreen) {
      if (widget.showFullScreen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _playerProvider = Provider.of<PlayerProvider>(context, listen: true);
    _queueProvider = Provider.of<QueueProvider>(context, listen: true);
    _favoriteSongProvider = Provider.of<FavoriteSongProvider>(
      context,
      listen: true,
    );
    _queueProvider.addListener(_onQueueChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _playerProvider.currentSong != null) {
        _favoriteSongProvider.setCurrentSong(_playerProvider.currentSong);
      }
    });
  }

  void _onQueueChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_playerProvider.currentSong != null) {
          _favoriteSongProvider.setCurrentSong(_playerProvider.currentSong);
        } else {
          _favoriteSongProvider.setCurrentSong(null);
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _queueProvider.removeListener(_onQueueChanged);
    _playerService.isFetchingStreamUrlNotifier.removeListener(
      _onFetchingStreamUrlChanged,
    );
    super.dispose();
  }

  void _onFetchingStreamUrlChanged() {
    if (mounted) {
      setState(() {});
    }
  }
}
