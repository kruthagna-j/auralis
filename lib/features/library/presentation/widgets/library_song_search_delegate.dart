import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

import '../../../../core/models/song_model.dart' as yt;
import 'library_song_list_tile.dart';
import '../../../../shared/components/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/models/song_model.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/queued_provider.dart';
import '../../../../core/services/content_details_service.dart';
import '../../../../core/services/local_songs_service.dart';

final ContentDetailsService _contentService = ContentDetailsService();

class LibrarySongSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, dynamic>> _likedSongs;
  final List<Map<String, dynamic>> _downloadedSongs;
  final List<Map<String, dynamic>> _lastPlayed;
  final List<Map<String, dynamic>> _localSongs;
  final Color accentColor;

  LibrarySongSearchDelegate(
    this._likedSongs,
    this._downloadedSongs,
    this._lastPlayed,
    this._localSongs,
    this.accentColor,
  );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ThemeData(
      scaffoldBackgroundColor: MainScreenColors.getBackgroundColor(isDarkMode),
      appBarTheme: AppBarTheme(
        backgroundColor: MainScreenColors.getSurfaceColor(isDarkMode),
        elevation: AppDimens.elevationNone,
        iconTheme: IconThemeData(
          color: MainScreenColors.getSecondaryColor(isDarkMode),
        ),
        titleTextStyle: AppTextStyles.titleSm(isDarkMode: isDarkMode),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: AppTextStyles.subtitle(
          isDarkMode: isDarkMode,
        ).copyWith(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accentColor,
        selectionColor: accentColor.withValues(alpha: 0.4),
        selectionHandleColor: accentColor,
      ),
      textTheme: TextTheme(
        titleLarge: AppTextStyles.subtitle(isDarkMode: isDarkMode),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear, color: accentColor),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: accentColor),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _searchSongs(query);
    return SafeArea(child: _buildSongList(results, context));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = _searchSongs(query);
    return SafeArea(child: _buildSongList(suggestions, context));
  }

  List<Map<String, dynamic>> _searchSongs(String query) {
    final allSongs = [
      ..._likedSongs,
      ..._downloadedSongs,
      ..._lastPlayed,
      ..._localSongs,
    ];
    return allSongs
        .where(
          (song) => (song['title']?.toString() ?? '').toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();
  }

  List<yt.Artist> _getArtistsFromSongData(Map<String, dynamic> song) {
    if (song['artists'] != null && song['artists'] is List) {
      final artists = song['artists'] as List;
      return artists
          .map((a) => yt.Artist(name: a['name'] ?? '', id: a['id'] ?? ''))
          .toList();
    } else {
      return [
        yt.Artist(
          name: song['artist']?.toString() ?? '',
          id: song['artistId']?.toString() ?? '',
        ),
      ];
    }
  }

  Widget _buildSongList(
    List<Map<String, dynamic>> songs,
    BuildContext context,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final playerProvider = Provider.of<PlayerProvider>(context, listen: true);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];

              bool isPlaying = false;
              if (playerProvider.currentSong != null &&
                  playerProvider.currentSong!.videoId ==
                      song['id'].toString()) {
                isPlaying = true;
              } else if (playerProvider.currentLocalSong != null &&
                  playerProvider.currentLocalSong!['id'].toString() ==
                      song['id'].toString()) {
                isPlaying = true;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingLg,
                  vertical: AppDimens.spacingXs,
                ),
                child: LibrarySongListTile(
                  song: song,
                  onPlay: () => _playSong(song, context, songs),
                  isPlaying: isPlaying,
                  isDarkMode: isDarkMode,
                  accentColor: accentColor,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _playSong(
    Map<String, dynamic> song,
    BuildContext context,
    List<Map<String, dynamic>> currentSearchResults,
  ) async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final queueProvider = Provider.of<QueueProvider>(context, listen: false);

    String tabName = 'search';

    if (_likedSongs.any((s) => s['id'] == song['id'])) {
      tabName = 'favorites';
    } else if (_downloadedSongs.any((s) => s['id'] == song['id'])) {
      tabName = 'downloads';
    } else if (_lastPlayed.any((s) => s['id'] == song['id'])) {
      tabName = 'recently_played';
    } else if (_localSongs.any((s) => s['id'] == song['id'])) {
      tabName = 'local_music';
    }

    try {
      if (tabName == 'favorites' ||
          tabName == 'recently_played' ||
          tabName == 'downloads') {
        List<Map<String, dynamic>> sourceList;
        if (tabName == 'favorites') {
          sourceList = _likedSongs;
        } else if (tabName == 'downloads') {
          sourceList = _downloadedSongs;
        } else {
          sourceList = _lastPlayed;
        }

        final songList = sourceList
            .map(
              (s) => SongInfo(
                videoId: s['id']?.toString() ?? '',
                name: s['title']?.toString() ?? '',
                artists: _getArtistsFromSongData(s),
                thumbnails: [
                  Thumbnail(
                    url: s['thumbnail']?.toString() ?? '',
                    width: 0,
                    height: 0,
                  ),
                ],
                duration: Duration(milliseconds: s['duration'] ?? 0),
              ),
            )
            .toList();

        final currentSongInfo = songList.firstWhere(
          (s) => s.videoId == song['id']?.toString(),
        );

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
      } else if (tabName == 'local_music' && song['isLocal'] == true) {
        final localPath = song['localPath'];
        if (localPath != null) {
          final songsWithArt = List<Map<String, dynamic>>.from(
            currentSearchResults,
          );
          final songIndex = songsWithArt.indexWhere(
            (s) => s['id'] == song['id'],
          );

          for (var i = 0; i < songsWithArt.length; i++) {
            final artUri = await _getArtworkUri(songsWithArt[i]);
            if (artUri.scheme == 'file') {
              songsWithArt[i]['thumbnail'] = artUri.toFilePath();
            } else {
              songsWithArt[i]['thumbnail'] = artUri.toString();
            }
          }

          try {
            await playerProvider.playerService.playLocalAudioWithQueue(
              localPath,
              songsWithArt[songIndex],
              songsWithArt,
              songIndex,
            );
          } catch (e) {
            AppSnackBar.showError(context, 'Failed to play song');
            playerProvider.playerService.playNext();
          }
        }
      } else {
        final songInfo = SongInfo(
          videoId: song['id']?.toString() ?? '',
          name: song['title']?.toString() ?? '',
          artists: _getArtistsFromSongData(song),
          thumbnails: [
            Thumbnail(
              url: song['thumbnail']?.toString() ?? '',
              width: 0,
              height: 0,
            ),
          ],
          duration: Duration(milliseconds: song['duration'] ?? 0),
        );

        await playerProvider.playerService.playSong(songInfo);
      }
    } catch (e) {
      print('Error playing song: $e');
      AppSnackBar.showError(context, 'failed_to_play_song_error'.tr());
    }
  }

  Future<Uri> _getArtworkUri(Map<String, dynamic> song) async {
    final service = LocalSongsService();

    try {
      final artworkFile = await service.queryArtwork(
        int.parse(song['id']),
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
}
