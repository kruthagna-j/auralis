import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/providers/video_info_provider.dart';

import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../main_screen/presentation/screens/full_player_screen.dart';
import '../../../player/presentation/screens/player_ui.dart';
import '../../../../shared/components/song_list_tile.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/models/song_model.dart';
import '../../../../core/providers/download_provider.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/queued_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/services/content_details_service.dart';
import '../../../../shared/components/app_snackbar.dart';

enum SortOption {
  titleAsc,
  titleDesc,
  artistAsc,
  artistDesc,
  dateAsc,
  dateDesc,
}

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  _DownloadsScreenState createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  Set<String> _selectedSongs = {};
  bool _isSelectionMode = false;

  late TabController _tabController;
  final videoInfoProvider = GetIt.I<VideoInfoProvider>();

  SortOption _currentSort = SortOption.titleAsc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChange);
  }

  void _onTabChange() {
    setState(() {});
  }

  List<Map<String, dynamic>> _sortSongs(List<Map<String, dynamic>> songs) {
    final sorted = List<Map<String, dynamic>>.from(songs);
    sorted.sort((a, b) {
      switch (_currentSort) {
        case SortOption.titleAsc:
          return (a['title'] as String).toLowerCase().compareTo(
            (b['title'] as String).toLowerCase(),
          );
        case SortOption.titleDesc:
          return (b['title'] as String).toLowerCase().compareTo(
            (a['title'] as String).toLowerCase(),
          );
        case SortOption.artistAsc:
          return (a['artist'] as String).toLowerCase().compareTo(
            (b['artist'] as String).toLowerCase(),
          );
        case SortOption.artistDesc:
          return (b['artist'] as String).toLowerCase().compareTo(
            (a['artist'] as String).toLowerCase(),
          );
        case SortOption.dateAsc:
          return _getSongTimestamp(a).compareTo(_getSongTimestamp(b));
        case SortOption.dateDesc:
          return _getSongTimestamp(b).compareTo(_getSongTimestamp(a));
      }
    });
    return sorted;
  }

  int _getSongTimestamp(Map<String, dynamic> song) {
    try {
      final downloadedAt = song['downloadedAt'];
      if (downloadedAt is int) return downloadedAt;
      if (downloadedAt is String) {
        final parsedInt = int.tryParse(downloadedAt);
        if (parsedInt != null) return parsedInt;
        final parsedDate = DateTime.tryParse(downloadedAt);
        if (parsedDate != null) return parsedDate.millisecondsSinceEpoch;
      }

      final path = song['localPath'] ?? song['filePath'];
      if (path != null && path is String) {
        final file = File(path);
        if (file.existsSync()) {
          return file.lastModifiedSync().millisecondsSinceEpoch;
        }
      }
    } catch (_) {}
    return 0;
  }

  Widget _buildDownloadQueueItem(
    Map<String, dynamic> song,
    Color accentColor,
    bool isDarkMode,
  ) {
    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, _) {
        final progress = downloadProvider.progressMap[song['id']];

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingLg,
            vertical: AppDimens.spacingSm,
          ),
          decoration: BoxDecoration(
            color: MainScreenColors.getSurfaceColor(isDarkMode),
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.all(AppDimens.paddingSm),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                child: _buildThumbnail(song['thumbnail'], isDarkMode),
              ),
              title: Text(
                song['title'],
                style: AppTextStyles.queueItem(isDarkMode: isDarkMode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song['artist'],
                    style: AppTextStyles.settingsSubtitle(isDarkMode: isDarkMode),
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: AppDimens.spacingSm),
                    LinearProgressIndicator(
                      value: progress.progress,
                      backgroundColor: isDarkMode
                          ? Colors.grey[800]
                          : Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      borderRadius: BorderRadius.circular(AppDimens.radiusXxs),
                    ),
                    const SizedBox(height: AppDimens.spacingXs),
                    Text(
                      '${(progress.progress * 100).toInt()}%',
                      style: AppTextStyles.caption(isDarkMode: isDarkMode)
                          .copyWith(
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                    ),
                  ],
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (progress == null)
                    IconButton(
                      icon: Icon(
                        Icons.download,
                        color: MainScreenColors.getTextColor(isDarkMode),
                      ),
                      onPressed: () =>
                          downloadProvider.startQueuedDownload(song['id']),
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: MainScreenColors.getTextColor(isDarkMode),
                    ),
                    onPressed: () => downloadProvider.removeDownload(song),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDownloadedSongItem(Map<String, dynamic> song, bool isDarkMode) {
    final songInfo = _convertToSongInfo(song);
    final playerProvider = Provider.of<PlayerProvider>(context);
    final bool isPlaying =
        playerProvider.currentSong?.videoId == songInfo.videoId ||
        playerProvider.lastPlayedSong?.videoId == songInfo.videoId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingSm),
      decoration: BoxDecoration(
        color: _selectedSongs.contains(song['id'])
            ? MainScreenColors.primaryPurple.withValues(alpha: 0.2)
            : (isPlaying
                  ? MainScreenColors.primaryPurple.withValues(alpha: 0.12)
                  : MainScreenColors.getBackgroundColor(isDarkMode)),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: SongListTile(
        song: songInfo,
        isPlaying: isPlaying,
        isDarkMode: isDarkMode,
        contentPadding: const EdgeInsets.all(AppDimens.paddingSm),
        selectionMode: _isSelectionMode,
        isSelected: _selectedSongs.contains(song['id']),
        onSelectionChanged: (bool? value) {
          setState(() {
            if (value ?? false) {
              _selectedSongs.add(song['id']);
            } else {
              _selectedSongs.remove(song['id']);
              if (_selectedSongs.isEmpty) _isSelectionMode = false;
            }
          });
        },
        onPlay: () {
          final downloadProvider = Provider.of<DownloadProvider>(
            context,
            listen: false,
          );
          final playerProvider = Provider.of<PlayerProvider>(
            context,
            listen: false,
          );
          final queueProvider = Provider.of<QueueProvider>(
            context,
            listen: false,
          );

          _playSong(song, downloadProvider, playerProvider, queueProvider);
        },
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (_selectedSongs.contains(song['id'])) {
                _selectedSongs.remove(song['id']);
                if (_selectedSongs.isEmpty) _isSelectionMode = false;
              } else {
                _selectedSongs.add(song['id']);
              }
            });
          } else {
            final downloadProvider = Provider.of<DownloadProvider>(
              context,
              listen: false,
            );
            final playerProvider = Provider.of<PlayerProvider>(
              context,
              listen: false,
            );
            final queueProvider = Provider.of<QueueProvider>(
              context,
              listen: false,
            );

            _playSong(song, downloadProvider, playerProvider, queueProvider);
          }
        },
        onLongPress: () {
          setState(() {
            _isSelectionMode = true;
            _selectedSongs.add(song['id']);
          });
        },
      ),
    );
  }

  void _toggleSelectAll(DownloadProvider downloadProvider) {
    final allSongIds = downloadProvider.downloadedSongs
        .map((song) => song['id'] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toSet();
    final isAllSelected =
        allSongIds.isNotEmpty &&
        _selectedSongs.containsAll(allSongIds) &&
        _selectedSongs.length == allSongIds.length;

    setState(() {
      if (isAllSelected) {
        _selectedSongs.clear();
        _isSelectionMode = false;
      } else {
        _selectedSongs = allSongIds;
        if (allSongIds.isNotEmpty) _isSelectionMode = true;
      }
    });
  }

  Widget _buildThumbnail(String thumbnailUrl, bool isDarkMode) {
    return CachedNetworkImage(
      imageUrl: thumbnailUrl,
      width: AppDimens.thumbnailDefault,
      height: AppDimens.thumbnailDefault,
      fit: BoxFit.cover,
      placeholder: (context, url) => Image.asset(
        'assets/default_artwork.png',
        width: AppDimens.thumbnailDefault,
        height: AppDimens.thumbnailDefault,
        fit: BoxFit.cover,
      ),
      errorWidget: (context, url, error) => Container(
        width: AppDimens.thumbnailDefault,
        height: AppDimens.thumbnailDefault,
        color: isDarkMode ? Colors.grey[850] : Colors.grey[300],
        child: const Icon(Icons.error),
      ),
    );
  }

  Widget _buildEmptyState(String message, {required bool isDarkMode}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spacingXxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_download_outlined,
              size: AppDimens.iconSplash,
              color: Colors.grey[600],
            ),
            const SizedBox(height: AppDimens.spacingLg),
            Text(
              message,
              style: AppTextStyles.heading(
                isDarkMode: isDarkMode,
              ).copyWith(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueList(bool isDarkMode, Color accentColor) {
    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, _) {
        return RefreshIndicator(
          color: accentColor,
          onRefresh: downloadProvider.loadDownloadQueue,
          child: downloadProvider.downloadQueue.isEmpty
              ? _buildEmptyState(
                  'no_songs_in_queue'.tr(),
                  isDarkMode: isDarkMode,
                )
              : ListView(
                  children: downloadProvider.downloadQueue
                      .map(
                        (song) => _buildDownloadQueueItem(
                          song,
                          accentColor,
                          isDarkMode,
                        ),
                      )
                      .toList(),
                ),
        );
      },
    );
  }

  Widget _buildDownloadedList(bool isDarkMode, Color accentColor) {
    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, _) {
        final sorted = _sortSongs(downloadProvider.downloadedSongs);
        return RefreshIndicator(
          color: accentColor,
          onRefresh: downloadProvider.loadDownloadedSongs,
          child: sorted.isEmpty
              ? _buildEmptyState(
                  'no_songs_in_downloads'.tr(),
                  isDarkMode: isDarkMode,
                )
              : ListView(
                  children: sorted
                      .map((song) => _buildDownloadedSongItem(song, isDarkMode))
                      .toList(),
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = settingsProvider.theme == 'Dark';
    final accentColor = settingsProvider.accentColor;
    final isDesktopLayout = !AppDimens.isMobile(context);
    final textColor = MainScreenColors.getTextColor(isDarkMode);

    return WillPopScope(
      onWillPop: () async {
        if (_isSelectionMode) {
          setState(() {
            _selectedSongs.clear();
            _isSelectionMode = false;
          });
          return false;
        }
        return true;
      },
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: MainScreenColors.getBackgroundColor(isDarkMode),
          appBar: AppBar(
            title: Text(
              _isSelectionMode
                  ? '${_selectedSongs.length} selected'
                  : 'downloads'.tr(),
              style: AppTextStyles.appBarTitle(isDarkMode: isDarkMode),
            ),
            backgroundColor: MainScreenColors.getBackgroundColor(isDarkMode),
            elevation: 0,
            iconTheme: IconThemeData(
              color: MainScreenColors.getTextColor(isDarkMode),
            ),
            actions: [
              Consumer<DownloadProvider>(
                builder: (context, downloadProvider, _) {
                  if (_isSelectionMode ||
                      downloadProvider.downloadQueue.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final isPaused = downloadProvider.isPaused;
                  return IconButton(
                    icon: Icon(
                      isPaused ? Icons.play_arrow : Icons.pause,
                      color: MainScreenColors.getTextColor(isDarkMode),
                    ),
                    tooltip: isPaused
                        ? 'resume_downloads'.tr()
                        : 'pause_downloads'.tr(),
                    onPressed: () async {
                      if (isPaused) {
                        await downloadProvider.resumeAllDownloads();
                        AppSnackBar.showInfo(context, 'resumed_downloads'.tr());
                      } else {
                        await downloadProvider.pauseAllDownloads();
                        AppSnackBar.showInfo(context, 'paused_downloads'.tr());
                      }
                    },
                  );
                },
              ),
              if (_isSelectionMode) ...[
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: isDarkMode
                              ? MainScreenColors.darkSurfaceColor
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Text(
                            'delete_songs'.tr(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          content: Text(
                            'are_you_sure_you_want_to_delete_selected_songs'.tr(
                              args: [_selectedSongs.length.toString()],
                            ),
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.black87,
                            ),
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: Text(
                                'cancel'.tr(),
                                style: TextStyle(color: textColor),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                            ),
                            TextButton(
                              child: Text(
                                'delete'.tr(),
                                style: const TextStyle(color: Colors.red),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmed == true) {
                      final downloadProvider = Provider.of<DownloadProvider>(
                        context,
                        listen: false,
                      );
                      for (final songId in _selectedSongs) {
                        await downloadProvider.deleteDownloadedSong(songId);
                      }

                      if (mounted) {
                        AppSnackBar.showInfo(
                          context,
                          'removed_from_downloads'.tr(),
                        );
                      }

                      setState(() {
                        _selectedSongs.clear();
                        _isSelectionMode = false;
                      });
                    }
                  },
                ),
                Consumer<DownloadProvider>(
                  builder: (context, downloadProvider, _) {
                    final allSongIds = downloadProvider.downloadedSongs
                        .map((song) => song['id'] as String?)
                        .where((id) => id != null && id.isNotEmpty)
                        .cast<String>()
                        .toSet();
                    final isAllSelected =
                        allSongIds.isNotEmpty &&
                        _selectedSongs.containsAll(allSongIds) &&
                        _selectedSongs.length == allSongIds.length;

                    return IconButton(
                      icon: Icon(
                        isAllSelected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: MainScreenColors.getTextColor(isDarkMode),
                      ),
                      tooltip: isAllSelected
                          ? 'unselect_all'.tr()
                          : 'select_all'.tr(),
                      onPressed: () => _toggleSelectAll(downloadProvider),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedSongs.clear();
                      _isSelectionMode = false;
                    });
                  },
                ),
              ] else if (!isDesktopLayout && _tabController.index == 1)
                PopupMenuButton<SortOption>(
                  icon: Icon(Icons.sort),
                  onSelected: (SortOption value) {
                    setState(() {
                      _currentSort = value;
                    });
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<SortOption>>[
                        PopupMenuItem<SortOption>(
                          value: SortOption.titleAsc,
                          child: Text('sort_title_az'.tr()),
                        ),
                        PopupMenuItem<SortOption>(
                          value: SortOption.titleDesc,
                          child: Text('sort_title_za'.tr()),
                        ),
                        PopupMenuItem<SortOption>(
                          value: SortOption.artistAsc,
                          child: Text('sort_artist_az'.tr()),
                        ),
                        PopupMenuItem<SortOption>(
                          value: SortOption.artistDesc,
                          child: Text('sort_artist_za'.tr()),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem<SortOption>(
                          value: SortOption.dateDesc,
                          child: Text('sort_date_newest_first'.tr()),
                        ),
                        PopupMenuItem<SortOption>(
                          value: SortOption.dateAsc,
                          child: Text('sort_date_oldest_first'.tr()),
                        ),
                      ],
                ),
            ],
            bottom: isDesktopLayout
                ? null
                : TabBar(
                    controller: _tabController,
                    indicatorColor: accentColor,
                    labelColor: accentColor,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: AppTextStyles.subtitle(isDarkMode: isDarkMode),
                    tabs: [
                      Tab(text: 'queue'.tr()),
                      Tab(text: 'downloaded'.tr()),
                    ],
                  ),
          ),
          body: Consumer<PlayerProvider>(
            builder: (context, playerProvider, _) {
              final hasPlayer =
                  playerProvider.currentSong != null ||
                  playerProvider.lastPlayedSong != null;

              final mq = MediaQuery.of(context);
              final double navIconScale = mq.textScaleFactor > 1.0
                  ? (1.0 / mq.textScaleFactor).clamp(0.75, 1.0).toDouble()
                  : 1.0;

              return Stack(
                children: [
                  isDesktopLayout
                      ? Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppDimens.paddingLg,
                                      vertical: AppDimens.spacingSm,
                                    ),
                                    child: Text(
                                      'Queue',
                                      style: AppTextStyles.titleSm(
                                        isDarkMode: isDarkMode,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildQueueList(
                                      isDarkMode,
                                      accentColor,
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppDimens.paddingLg,
                                      vertical: AppDimens.spacingSm,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Downloaded',
                                          style: AppTextStyles.titleSm(
                                            isDarkMode: isDarkMode,
                                          ),
                                        ),
                                        if (!_isSelectionMode)
                                          PopupMenuButton<SortOption>(
                                            icon: Icon(
                                              Icons.sort,
                                              color:
                                                  MainScreenColors.getTextColor(
                                                    isDarkMode,
                                                  ),
                                            ),
                                            onSelected: (SortOption value) {
                                              setState(() {
                                                _currentSort = value;
                                              });
                                            },
                                            itemBuilder: (BuildContext context) =>
                                                <PopupMenuEntry<SortOption>>[
                                                  PopupMenuItem<SortOption>(
                                                    value: SortOption.titleAsc,
                                                    child: Text(
                                                      'sort_title_az'.tr(),
                                                    ),
                                                  ),
                                                  PopupMenuItem<SortOption>(
                                                    value: SortOption.titleDesc,
                                                    child: Text(
                                                      'sort_title_za'.tr(),
                                                    ),
                                                  ),
                                                  PopupMenuItem<SortOption>(
                                                    value: SortOption.artistAsc,
                                                    child: Text(
                                                      'sort_artist_az'.tr(),
                                                    ),
                                                  ),
                                                  PopupMenuItem<SortOption>(
                                                    value:
                                                        SortOption.artistDesc,
                                                    child: Text(
                                                      'sort_artist_za'.tr(),
                                                    ),
                                                  ),
                                                  const PopupMenuDivider(),
                                                  PopupMenuItem<SortOption>(
                                                    value: SortOption.dateDesc,
                                                    child: Text(
                                                      'sort_date_newest_first'
                                                          .tr(),
                                                    ),
                                                  ),
                                                  PopupMenuItem<SortOption>(
                                                    value: SortOption.dateAsc,
                                                    child: Text(
                                                      'sort_date_oldest_first'
                                                          .tr(),
                                                    ),
                                                  ),
                                                ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildDownloadedList(
                                      isDarkMode,
                                      accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Padding(
                          padding: EdgeInsets.only(
                            bottom: hasPlayer
                                ? AppDimens.miniPlayerHeight * navIconScale
                                : 0,
                          ),
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildQueueList(isDarkMode, accentColor),
                              _buildDownloadedList(isDarkMode, accentColor),
                            ],
                          ),
                        ),

                  if (!isDesktopLayout && hasPlayer)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).appBarTheme.backgroundColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppDimens.radiusMd),
                          ),
                        ),
                        child: SizedBox(
                          height: AppDimens.miniPlayerHeight * navIconScale,
                          child: PlayerUI(
                            showFullScreen: false,
                            isEmbedded: true,
                            onMinimize: () {},
                            onExpand: () => _showFullPlayerBottomSheet(context),
                          ),
                        ),
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

  void _showFullPlayerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => const FullPlayerScreen(),
    );
  }

  void _playSong(
    Map<String, dynamic> song,
    DownloadProvider downloadProvider,
    PlayerProvider playerProvider,
    QueueProvider queueProvider,
  ) async {
    try {
      final songInfo = _convertToSongInfo(song);

      final allDownloadedSongs = downloadProvider.downloadedSongs
          .map((downloadedSong) => _convertToSongInfo(downloadedSong))
          .toList();

      final contentDetailsService = ContentDetailsService();
      await contentDetailsService.playSong(
        songInfo,
        playerProvider,
        queueProvider,
        allDownloadedSongs,
        playlistId: 'downloads',
        playlistName: 'Downloads',
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'failed_to_play_song_error'.tr());
      }
    }
  }

  SongInfo _convertToSongInfo(Map<String, dynamic> song) {
    return SongInfo(
      videoId: song['id'] ?? '',
      name: song['title'] ?? '',
      artists: [Artist(name: song['artist'] ?? '', id: song['artistId'] ?? '')],
      thumbnails: [
        Thumbnail(url: song['thumbnail'] ?? '', width: 480, height: 360),
      ],
      duration: Duration(seconds: song['duration'] ?? 0),
    );
  }
}
