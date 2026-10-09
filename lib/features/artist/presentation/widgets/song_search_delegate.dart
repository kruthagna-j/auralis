import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/song_model.dart';
import '../../../../core/services/content_details_service.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/queued_provider.dart';
import 'artist_song_list_tile.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import '../../../../shared/components/app_snackbar.dart';

class SongSearchDelegate extends SearchDelegate<SongInfo?> {
  final List<dynamic> songs;
  final bool isDarkMode;
  final Color accentColor;

  SongSearchDelegate({
    required this.songs,
    required this.isDarkMode,
    required this.accentColor,
  });

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: MainScreenColors.getSurfaceColor(isDarkMode),
        elevation: AppDimens.elevationNone,
        iconTheme: IconThemeData(color: accentColor),
        titleTextStyle: AppTextStyles.appBarTitle(isDarkMode: isDarkMode),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: AppTextStyles.bodyMd(isDarkMode: isDarkMode).copyWith(
          color: MainScreenColors.getTextColor(
            isDarkMode,
          ).withValues(alpha: 0.6),
        ),
        border: InputBorder.none,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accentColor,
        selectionColor: accentColor.withValues(alpha: 0.3),
        selectionHandleColor: accentColor,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear, color: accentColor),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: accentColor),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = songs.where((song) {
      final songName = (song is SongDetailed ? song.name : song.name as String)
          .toLowerCase();
      final queryLower = query.toLowerCase();
      final artistMatch = song is SongDetailed
          ? song.artist.name.toLowerCase().contains(queryLower)
          : (song as SongInfo).artists.any(
              (artist) => artist.name.toLowerCase().contains(queryLower),
            );
      return songName.contains(queryLower) || artistMatch;
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Text(
          'no_songs_found_for_query'.tr(args: [query]),
          style: AppTextStyles.subtitle(
            isDarkMode: isDarkMode,
          ).copyWith(color: MainScreenColors.getTextColor(isDarkMode)),
        ),
      );
    }

    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final hasPlayer =
            playerProvider.currentSong != null ||
            playerProvider.lastPlayedSong != null;
        return SafeArea(
          top: false,
          child: Stack(
            children: [
              ListView.builder(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: hasPlayer ? 116 : 16,
                ),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final song = results[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: AppDimens.spacingSm),
                    decoration: BoxDecoration(
                      color: MainScreenColors.getSurfaceColor(isDarkMode),
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: AppDimens.elevationLow * 2,
                          offset: Offset(0, AppDimens.elevationLow),
                        ),
                      ],
                    ),
                    child: ArtistSongListTile(
                      song: song,
                      onPlay: () async {
                        final playerProvider = Provider.of<PlayerProvider>(
                          context,
                          listen: false,
                        );
                        final queueProvider = Provider.of<QueueProvider>(
                          context,
                          listen: false,
                        );

                        SongInfo songInfo;
                        if (song is SongDetailed) {
                          songInfo = _convertSongDetailedToSongInfo(song);
                        } else if (song is SongInfo) {
                          songInfo = song;
                        } else {
                          throw Exception(
                            'Invalid song type: ${song.runtimeType}',
                          );
                        }

                        final List<SongInfo> convertedSongs = results.map((s) {
                          if (s is SongDetailed) {
                            return _convertSongDetailedToSongInfo(s);
                          } else if (s is SongInfo) {
                            return s;
                          } else {
                            throw Exception(
                              'Invalid song type in list: ${s.runtimeType}',
                            );
                          }
                        }).toList();

                        try {
                          await ContentDetailsService().playSong(
                            songInfo,
                            playerProvider,
                            queueProvider,
                            convertedSongs,
                          );
                          await queueProvider.saveQueue();

                          close(context, songInfo);
                        } catch (e) {
                          AppSnackBar.showError(
                            context,
                            'failed_to_play_song_error'.tr(),
                          );
                        }
                      },
                      isDarkMode: isDarkMode,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = songs.where((song) {
      final songName = (song is SongDetailed ? song.name : song.name as String)
          .toLowerCase();
      final queryLower = query.toLowerCase();
      final artistMatch = song is SongDetailed
          ? song.artist.name.toLowerCase().contains(queryLower)
          : (song as SongInfo).artists.any(
              (artist) => artist.name.toLowerCase().contains(queryLower),
            );
      return songName.contains(queryLower) || artistMatch;
    }).toList();

    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final hasPlayer =
            playerProvider.currentSong != null ||
            playerProvider.lastPlayedSong != null;
        return SafeArea(
          top: false,
          child: Stack(
            children: [
              ListView.builder(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: hasPlayer ? 116 : 16,
                ),
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final song = suggestions[index];
                  final isCurrentlyPlaying =
                      playerProvider.currentSong?.videoId == song.videoId;
                  return Container(
                    margin: EdgeInsets.only(bottom: AppDimens.spacingSm),
                    decoration: BoxDecoration(
                      color: isCurrentlyPlaying
                          ? accentColor.withValues(alpha: 0.2)
                          : MainScreenColors.getSurfaceColor(isDarkMode),
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: AppDimens.elevationLow * 2,
                          offset: Offset(0, AppDimens.elevationLow),
                        ),
                      ],
                    ),
                    child: ArtistSongListTile(
                      song: song,
                      isPlaying: isCurrentlyPlaying,
                      onPlay: () async {
                        final playerProvider = Provider.of<PlayerProvider>(
                          context,
                          listen: false,
                        );
                        final queueProvider = Provider.of<QueueProvider>(
                          context,
                          listen: false,
                        );

                        SongInfo songInfo;
                        if (song is SongDetailed) {
                          songInfo = _convertSongDetailedToSongInfo(song);
                        } else if (song is SongInfo) {
                          songInfo = song;
                        } else {
                          throw Exception(
                            'Invalid song type: ${song.runtimeType}',
                          );
                        }

                        final List<SongInfo> convertedSongs = suggestions.map((
                          s,
                        ) {
                          if (s is SongDetailed) {
                            return _convertSongDetailedToSongInfo(s);
                          } else if (s is SongInfo) {
                            return s;
                          } else {
                            throw Exception(
                              'Invalid song type in list: ${s.runtimeType}',
                            );
                          }
                        }).toList();

                        try {
                          await ContentDetailsService().playSong(
                            songInfo,
                            playerProvider,
                            queueProvider,
                            convertedSongs,
                          );
                          await queueProvider.saveQueue();

                          close(context, songInfo);
                        } catch (e) {
                          AppSnackBar.showError(
                            context,
                            'failed_to_play_song_error'.tr(),
                          );
                        }
                      },
                      isDarkMode: isDarkMode,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
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
}
