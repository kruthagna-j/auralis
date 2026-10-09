import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import 'package:provider/provider.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import '../widgets/artist_song_list_tile.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/song_model.dart';
import '../../../../core/services/content_details_service.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/queued_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../widgets/song_search_delegate.dart';
import '../../../../shared/components/app_snackbar.dart';

class SongListScreen extends StatelessWidget {
  final String title;
  final List<dynamic> songs;

  const SongListScreen({Key? key, required this.title, required this.songs})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final settingsProvider = Provider.of<SettingsProvider>(context);
    final accentColor = settingsProvider.accentColor;

    return Theme(
      data: ThemeData(
        scaffoldBackgroundColor: MainScreenColors.getBackgroundColor(
          isDarkMode,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: MainScreenColors.getSurfaceColor(isDarkMode),
          elevation: AppDimens.elevationNone,
          iconTheme: IconThemeData(color: accentColor),
          titleTextStyle: AppTextStyles.appBarTitle(isDarkMode: isDarkMode),
        ),
      ),
      child: Consumer<PlayerProvider>(
        builder: (context, playerProvider, child) {
          final hasPlayer =
              playerProvider.currentSong != null ||
              playerProvider.lastPlayedSong != null;

          return SafeArea(
            top: false,
            child: Scaffold(
              appBar: AppBar(
                title: Text(title),
                leading: IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(AppDimens.paddingSm),
                    decoration: BoxDecoration(
                      color: MainScreenColors.getSurfaceColor(isDarkMode),
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    ),
                    child: Icon(Icons.arrow_back, color: accentColor),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  Container(
                    margin: EdgeInsets.only(right: AppDimens.spacingSm),
                    decoration: BoxDecoration(
                      color: MainScreenColors.getSurfaceColor(isDarkMode),
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.search, color: accentColor),
                      onPressed: () {
                        showSearch(
                          context: context,
                          delegate: SongSearchDelegate(
                            songs: songs,
                            isDarkMode: isDarkMode,
                            accentColor: accentColor,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              body: Stack(
                children: [
                  ListView.builder(
                    padding: EdgeInsets.only(
                      left: AppDimens.paddingLg,
                      right: AppDimens.paddingLg,
                      top: AppDimens.paddingLg,
                      bottom: hasPlayer
                          ? (AppDimens.miniPlayerHeightWide +
                                AppDimens.spacingXxxl)
                          : AppDimens.paddingLg,
                    ),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final isCurrentlyPlaying =
                          playerProvider.currentSong?.videoId == song.videoId;
                      return Container(
                        decoration: BoxDecoration(
                          color: isCurrentlyPlaying
                              ? accentColor.withValues(alpha: 0.2)
                              : Colors.transparent,

                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusLg,
                          ),
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

                            final List<SongInfo> convertedSongs = songs.map((
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
                            } catch (e) {
                              if (!context.mounted) return;
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
            ),
          );
        },
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
}
