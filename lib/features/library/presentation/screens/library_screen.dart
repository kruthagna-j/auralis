import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:metadata_god/metadata_god.dart';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

import '../../../favorite_artist/presentation/screens/favorite_artist_screen.dart';
import '../widgets/library_song_list_tile.dart';
import '../../../../shared/components/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/services/content_details_service.dart';
import '../../../../core/services/local_songs_service.dart';
import '../../../../core/models/song_model.dart';
import '../../data/providers/library_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/download_provider.dart';
import '../../../../core/providers/favorite_song_provider.dart';
import '../../../../core/providers/favorite_artist_provider.dart';
import '../../../../core/providers/queued_provider.dart';
import '../widgets/library_song_search_delegate.dart';
import '../../../local_folder/presentation/screens/local_folder_management_screen.dart';
import '../../../../core/utils/content_router.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _selectedFilter = 'All';
  bool _isSelectionMode = false;
  final Set<String> _selectedSongs = {};
  String _currentTab = 'favorites';
  String _favoritesFilter = 'Songs';
  final ContentDetailsService _contentService = ContentDetailsService();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final accentColor = settingsProvider.accentColor;
    return DefaultTabController(
      length: 4,
      child: Theme(
        data: ThemeData(
          scaffoldBackgroundColor: MainScreenColors.getBackgroundColor(
            isDarkMode,
          ),
        ),
        child: Scaffold(
          floatingActionButton: FloatingActionButton(
            heroTag: 'library_search_button',

            backgroundColor: accentColor,
            child: Icon(Icons.search, color: Colors.black),
            onPressed: () {
              showSearch(
                context: context,
                delegate: LibrarySongSearchDelegate(
                  libraryProvider.likedSongs,
                  libraryProvider.downloadedSongs,
                  libraryProvider.lastPlayed,
                  libraryProvider.localSongs,
                  accentColor,
                ),
              );
            },
          ),
          body: Column(
            children: [
              TabBar(
                physics: _isSelectionMode
                    ? const NeverScrollableScrollPhysics()
                    : null,
                onTap: _isSelectionMode
                    ? null
                    : (index) {
                        setState(() {
                          _isSelectionMode = false;
                          _selectedSongs.clear();
                          switch (index) {
                            case 0:
                              _currentTab = 'favorites';
                              break;
                            case 1:
                              _currentTab = 'downloads';
                              break;
                            case 2:
                              _currentTab = 'recently_played';
                              break;
                            case 3:
                              _currentTab = 'local_music';
                              break;
                          }
                        });
                      },
                tabs: [
                  Tab(text: 'favorites'.tr()),
                  Tab(text: 'downloads'.tr()),
                  Tab(text: 'recently_played'.tr()),
                  Tab(text: 'local_music'.tr()),
                ],
                indicatorColor: accentColor,
                labelStyle: AppTextStyles.bodyMd(
                  isDarkMode: isDarkMode,
                  color: accentColor,
                ).copyWith(fontWeight: AppTextStyles.weightBold),
                labelColor: accentColor,
                unselectedLabelStyle: AppTextStyles.bodyMd(
                  isDarkMode: isDarkMode,
                ),
                isScrollable: true,
              ),
              if (_isSelectionMode)
                _buildSelectionMenu(accentColor, isDarkMode),
              Expanded(
                child: libraryProvider.isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: accentColor),
                      )
                    : TabBarView(
                        physics: _isSelectionMode
                            ? const NeverScrollableScrollPhysics()
                            : null,
                        children: [
                          _buildFavoritesTab(
                            libraryProvider,
                            isDarkMode,
                            accentColor,
                          ),
                          _buildSongList(
                            libraryProvider.downloadedSongs,
                            isDarkMode,
                            'downloads',
                            libraryProvider,
                            accentColor,
                          ),
                          _buildSongList(
                            libraryProvider.lastPlayed,
                            isDarkMode,
                            'recently_played',
                            libraryProvider,
                            accentColor,
                          ),
                          _buildLocalMusicTab(
                            libraryProvider,
                            isDarkMode,
                            accentColor,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesTab(
    LibraryProvider libraryProvider,
    bool isDarkMode,
    Color accentColor,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingSm),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingLg,
                  ),
                  child: Row(
                    children: [
                      _buildFavoritesFilterButton(
                        'Songs',
                        accentColor,
                        isDarkMode,
                      ),
                      SizedBox(width: AppDimens.spacingSm),
                      _buildFavoritesFilterButton(
                        'Artists',
                        accentColor,
                        isDarkMode,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _favoritesFilter == 'Songs'
              ? _buildSongList(
                  libraryProvider.likedSongs,
                  isDarkMode,
                  'favorites',
                  libraryProvider,
                  accentColor,
                )
              : _buildArtistList(isDarkMode, accentColor),
        ),
      ],
    );
  }

  Widget _buildFavoritesFilterButton(
    String title,
    Color accentColor,
    bool isDarkMode,
  ) {
    final isSelected = _favoritesFilter == title;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _favoritesFilter = title;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? accentColor
            : (isDarkMode ? Colors.transparent : Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
          side: BorderSide(color: accentColor),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingSm,
          vertical: AppDimens.spacingXs,
        ),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        title,
        style: AppTextStyles.caption(
          isDarkMode: isDarkMode,
          color: isSelected
              ? (isDarkMode ? Colors.white : Colors.black)
              : accentColor,
        ),
      ),
    );
  }

  Widget _buildSongList(
    List<Map<String, dynamic>> songs,
    bool isDarkMode,
    String tabName,
    LibraryProvider libraryProvider,
    Color accentColor,
  ) {
    if (songs.isEmpty) {
      return RefreshIndicator(
        onRefresh: libraryProvider.refreshLibraryData,
        color: accentColor,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints viewportConstraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: viewportConstraints.maxHeight,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimens.paddingLg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_note,
                          size: AppDimens.iconHero,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        SizedBox(height: AppDimens.spacingLg),
                        Text(
                          'no_songs_in_$tabName'.tr(),
                          style: AppTextStyles.subtitle(
                            isDarkMode: isDarkMode,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: libraryProvider.refreshLibraryData,
      color: accentColor,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: AppDimens.miniPlayerHeight),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return Builder(
            builder: (innerContext) {
              final isPlaying = innerContext.select<PlayerProvider, bool>((p) {
                final idStr = song['id'].toString();
                if (p.currentSong != null && p.currentSong!.videoId == idStr) {
                  return true;
                }
                if (p.currentLocalSong != null &&
                    p.currentLocalSong!['id'].toString() == idStr) {
                  return true;
                }

                return false;
              });

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingLg,
                  vertical: AppDimens.spacingXs,
                ),
                child: GestureDetector(
                  onLongPress: () {
                    if (tabName != 'local_music') {
                      setState(() {
                        _isSelectionMode = true;
                        _selectedSongs.add(song['id'].toString());
                      });
                    }
                  },
                  onTap: () {
                    if (_isSelectionMode) {
                      setState(() {
                        if (_selectedSongs.contains(song['id'].toString())) {
                          _selectedSongs.remove(song['id'].toString());
                        } else {
                          _selectedSongs.add(song['id'].toString());
                        }
                        if (_selectedSongs.isEmpty) {
                          _isSelectionMode = false;
                        }
                      });
                    } else {
                      _playSong(song, context, tabName, songs);
                    }
                  },
                  child: Container(
                    color: _selectedSongs.contains(song['id'].toString())
                        ? accentColor.withValues(alpha: 0.3)
                        : Colors.transparent,
                    child: LibrarySongListTile(
                      song: song,
                      onPlay: () {
                        if (_isSelectionMode) {
                          setState(() {
                            if (_selectedSongs.contains(
                              song['id'].toString(),
                            )) {
                              _selectedSongs.remove(song['id'].toString());
                            } else {
                              _selectedSongs.add(song['id'].toString());
                            }
                            if (_selectedSongs.isEmpty) {
                              _isSelectionMode = false;
                            }
                          });
                        } else {
                          _playSong(song, context, tabName, songs);
                        }
                      },
                      isPlaying: isPlaying,
                      isDarkMode: isDarkMode,
                      accentColor: accentColor,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildArtistList(bool isDarkMode, Color accentColor) {
    return Consumer<FavoriteArtistProvider>(
      builder: (context, favoriteArtistProvider, child) {
        final artists = favoriteArtistProvider.favoriteArtists;

        if (artists.isEmpty) {
          return RefreshIndicator(
            onRefresh: favoriteArtistProvider.loadFavoriteArtists,
            color: accentColor,
            child: LayoutBuilder(
              builder:
                  (BuildContext context, BoxConstraints viewportConstraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: viewportConstraints.maxHeight,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppDimens.paddingLg),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: AppDimens.iconHero,
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                                SizedBox(height: AppDimens.spacingLg),
                                Text(
                                  'no_favorite_artists'.tr(),
                                  style: AppTextStyles.subtitle(
                                    isDarkMode: isDarkMode,
                                    color: isDarkMode ? Colors.white70 : Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: AppDimens.spacingXxl),
                                ElevatedButton.icon(
                                  icon: Icon(
                                    Icons.add,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                  label: Text(
                                    'Add Favorite Artist',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentColor,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppDimens.paddingXxl,
                                      vertical: AppDimens.paddingMd,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FavoriteArtistsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: favoriteArtistProvider.loadFavoriteArtists,
          color: accentColor,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: AppDimens.miniPlayerHeight),
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingLg,
                  vertical: AppDimens.spacingXs,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: artist['thumbnailUrl'] != null
                        ? CachedNetworkImageProvider(artist['thumbnailUrl'])
                        : null,
                    backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    child: artist['thumbnailUrl'] == null
                        ? Icon(Icons.person, color: accentColor)
                        : null,
                  ),
                  title: Text(
                    artist['name'],
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContentRouter(
                          content: ArtistDetailed(
                            artistId: artist['artistId'],
                            name: artist['name'],
                            thumbnails: [
                              ThumbnailFull(
                                url: artist['thumbnailUrl'] ?? '',
                                width: 0,
                                height: 0,
                              ),
                            ],
                            type: '',
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLocalMusicTab(
    LibraryProvider libraryProvider,
    bool isDarkMode,
    Color accentColor,
  ) {
    if (!Platform.isWindows && !Platform.isLinux) {
      final status = libraryProvider.localPermissionStatus;
      if (status == LocalPermissionStatus.unknown) {
        return Center(child: CircularProgressIndicator(color: accentColor));
      }
      if (status == LocalPermissionStatus.denied ||
          status == LocalPermissionStatus.permanentlyDenied) {
        return RefreshIndicator(
          onRefresh: libraryProvider.refreshLibraryData,
          color: accentColor,
          child: LayoutBuilder(
            builder:
                (BuildContext context, BoxConstraints viewportConstraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: viewportConstraints.maxHeight,
                      ),
                      child: _buildPermissionRequired(
                        isDarkMode: isDarkMode,
                        accentColor: accentColor,
                        isPermanentlyDenied:
                            status == LocalPermissionStatus.permanentlyDenied,
                        libraryProvider: libraryProvider,
                      ),
                    ),
                  );
                },
          ),
        );
      }
    }

    if (libraryProvider.isLoadingLocalSongs) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final includedFolders = settingsProvider.includedFolders;
    List<Map<String, dynamic>> songs = libraryProvider.localSongs;

    if (_selectedFilter == 'Download') {
      if (Platform.isWindows || Platform.isLinux) {
        songs = songs
            .where(
              (song) => (song['localPath'] as String).toLowerCase().contains(
                'download',
              ),
            )
            .toList();
      } else {
        songs = songs
            .where(
              (song) => (song['localPath'] as String).contains(
                '/storage/emulated/0/Download',
              ),
            )
            .toList();
      }
    } else if (_selectedFilter == 'Music') {
      if (Platform.isWindows || Platform.isLinux) {
        songs = songs
            .where(
              (song) =>
                  (song['localPath'] as String).toLowerCase().contains('music'),
            )
            .toList();
      } else {
        songs = songs
            .where(
              (song) => (song['localPath'] as String).contains(
                '/storage/emulated/0/Music',
              ),
            )
            .toList();
      }
    } else if (_selectedFilter != 'All') {
      songs = songs
          .where(
            (song) => (song['localPath'] as String).startsWith(_selectedFilter),
          )
          .toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingSm),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingLg,
                  ),
                  child: Row(
                    children: [
                      _buildFilterButton('All', accentColor, isDarkMode),
                      SizedBox(width: AppDimens.spacingSm),
                      _buildFilterButton('Download', accentColor, isDarkMode),
                      SizedBox(width: AppDimens.spacingSm),
                      _buildFilterButton('Music', accentColor, isDarkMode),
                      ...includedFolders.map((folder) {
                        final folderName = folder.split('/').last;
                        return Padding(
                          padding: const EdgeInsets.only(
                            left: AppDimens.spacingSm,
                          ),
                          child: _buildFilterButton(
                            folderName,
                            accentColor,
                            isDarkMode,
                            fullPath: folder,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LocalFolderManagementScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildSongList(
            songs,
            isDarkMode,
            'local_music',
            libraryProvider,
            accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionRequired({
    required bool isDarkMode,
    required Color accentColor,
    required bool isPermanentlyDenied,
    required LibraryProvider libraryProvider,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingXl,
          vertical: AppDimens.paddingLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_note_rounded,
              size: 72,
              color: accentColor.withValues(alpha: 0.7),
            ),
            const SizedBox(height: AppDimens.spacingMd),
            Text(
              'local_music_permission_required'.tr(),
              style: AppTextStyles.titleSm(
                isDarkMode: isDarkMode,
                color: accentColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.spacingSm),
            Text(
              'local_music_permission_description'.tr(),
              style: AppTextStyles.bodyMd(isDarkMode: isDarkMode),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.spacingLg),
            ElevatedButton(
              onPressed: () => libraryProvider.requestLocalPermission(),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingXl,
                  vertical: AppDimens.paddingMd,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
                ),
              ),
              child: Text(
                isPermanentlyDenied ? 'Open Settings' : 'continue'.tr(),
                style: AppTextStyles.bodyMd(
                  isDarkMode: false,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    String title,
    Color accentColor,
    bool isDarkMode, {
    String? fullPath,
  }) {
    final filterValue = fullPath ?? title;
    final isSelected = _selectedFilter == filterValue;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedFilter = filterValue;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? accentColor
            : (isDarkMode ? Colors.transparent : Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
          side: BorderSide(color: accentColor),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingSm,
          vertical: AppDimens.spacingXs,
        ),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        title,
        style: AppTextStyles.caption(
          isDarkMode: isDarkMode,
          color: isSelected
              ? (isDarkMode ? Colors.white : Colors.black)
              : accentColor,
        ),
      ),
    );
  }

  List<Artist> _getArtistsFromSongData(Map<String, dynamic> song) {
    if (song['artists'] != null && song['artists'] is List) {
      final artists = song['artists'] as List;
      return artists
          .map((a) => Artist(name: a['name'] ?? '', id: a['id'] ?? ''))
          .toList();
    } else {
      return [Artist(name: song['artist'] ?? '', id: song['artistId'] ?? '')];
    }
  }

  Future<void> _playSong(
    Map<String, dynamic> song,
    BuildContext context,
    String tabName,
    List<Map<String, dynamic>> songs,
  ) async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final queueProvider = Provider.of<QueueProvider>(context, listen: false);

    try {
      if (tabName == 'favorites' ||
          tabName == 'recently_played' ||
          tabName == 'downloads') {
        final songList = songs
            .map(
              (s) => SongInfo(
                videoId: s['id'],
                name: s['title'],
                artists: _getArtistsFromSongData(s),
                thumbnails: [
                  Thumbnail(url: s['thumbnail'], width: 0, height: 0),
                ],
                duration: Duration(milliseconds: s['duration']),
              ),
            )
            .toList();

        final currentSongInfo = songList.firstWhere(
          (s) => s.videoId == song['id'],
        );
        final songIndex = songList.indexWhere((s) => s.videoId == song['id']);

        final playlistId = tabName;

        await _contentService.playSong(
          currentSongInfo,
          playerProvider,
          queueProvider,
          songList,
          playlistId: playlistId,
          playlistName: tabName,
        );
        await queueProvider.saveQueue();
      } else if (tabName == 'local_music' ||
          song['isLocal'] == true ||
          song['localPath'] != null ||
          int.tryParse(song['id'].toString()) != null) {
        final localPath = song['localPath'];
        if (localPath != null) {
          final songIndex = songs.indexWhere((s) => s['id'] == song['id']);

          // Start local playback immediately. Artwork generation used to query
          // every local song in the queue before opening the selected file,
          // which made local playback feel slow. Local artwork is already
          // loaded on demand by LibrarySongListTile, so it is not required
          // before the player can start.
          await playerProvider.playerService.playLocalAudioWithQueue(
            localPath,
            song,
            songs,
            songIndex,
          );
        }
      } else {
        final songInfo = SongInfo(
          videoId: song['id'],
          name: song['title'],
          artists: [Artist(name: song['artist'], id: '')],
          thumbnails: [Thumbnail(url: song['thumbnail'], width: 0, height: 0)],
          duration: Duration(milliseconds: song['duration']),
        );

        await playerProvider.playerService.playSong(songInfo);
      }
    } catch (e) {
      AppSnackBar.showError(context, 'failed_to_play_song_error'.tr());
      if (tabName == 'local_music' ||
          song['isLocal'] == true ||
          song['localPath'] != null ||
          int.tryParse(song['id'].toString()) != null) {
        playerProvider.playerService.playNext();
      }
    }
  }

  Future<Uri> _getArtworkUri(Map<String, dynamic> song) async {
    if (Platform.isWindows || Platform.isLinux) {
      try {
        final metadata = await MetadataGod.readMetadata(
          file: song['localPath'],
        );
        if (metadata.picture != null) {
          final picture = metadata.picture!;
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/artwork_${song['id']}.jpg');
          await tempFile.writeAsBytes(picture.data);
          return Uri.file(tempFile.path);
        }
      } catch (e) {
        debugPrint('Error getting artwork from metadata: $e');
      }
    } else {
      final service = LocalSongsService();

      try {
        final artworkFile = await service.queryArtwork(
          int.parse(song['id'].toString()),
          size: 500,
        );

        if (artworkFile != null) {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/artwork_${song['id']}.jpg');

          await tempFile.writeAsBytes(artworkFile);
          return Uri.file(tempFile.path);
        }
      } catch (e) {
        debugPrint('Error getting artwork: $e');
      }
    }

    try {
      final byteData = await rootBundle.load('assets/default_artwork.png');
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/default_artwork.png');

      await tempFile.writeAsBytes(byteData.buffer.asUint8List());
      return Uri.file(tempFile.path);
    } catch (e) {
      return Uri.parse(
        'https://dummyimage.com/600x400/ff0000/ffffff&text=Artwork',
      );
    }
  }

  void _playSelectedSongs() {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    List<Map<String, dynamic>> songsToPlay = [];

    List<Map<String, dynamic>> currentSongList;
    switch (_currentTab) {
      case 'favorites':
        currentSongList = libraryProvider.likedSongs;
        break;
      case 'downloads':
        currentSongList = libraryProvider.downloadedSongs;
        break;
      case 'recently_played':
        currentSongList = libraryProvider.lastPlayed;
        break;
      case 'local_music':
        currentSongList = libraryProvider.localSongs;
        break;
      default:
        currentSongList = [];
    }

    for (final song in currentSongList) {
      if (_selectedSongs.contains(song['id'].toString())) {
        songsToPlay.add(song);
      }
    }

    if (songsToPlay.isNotEmpty) {
      _playSong(songsToPlay.first, context, _currentTab, songsToPlay);
    }
  }

  Widget _buildSelectionMenu(Color accentColor, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingLg,
        vertical: AppDimens.paddingSm,
      ),
      color: accentColor.withValues(alpha: 0.15),
      child: Row(
        children: [
          Text(
            '${_selectedSongs.length} selected',
            style: AppTextStyles.bodyMd(
              isDarkMode: isDarkMode,
              color: accentColor,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Play selected',
            icon: Icon(Icons.play_arrow, color: accentColor),
            onPressed: _playSelectedSongs,
          ),
          IconButton(
            tooltip: 'Clear selection',
            icon: Icon(
              Icons.close,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {
              setState(() {
                _selectedSongs.clear();
                _isSelectionMode = false;
              });
            },
          ),
        ],
      ),
    );
  }
}
