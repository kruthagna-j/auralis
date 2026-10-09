import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/playlist_album_library_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Thumbnail;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/song_model.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/queued_provider.dart';
import '../../../../core/services/content_details_service.dart';
import '../../../../shared/components/app_snackbar.dart';

class PlaylistDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> playlist;
  final List<Map<String, dynamic>> songs;

  const PlaylistDetailsScreen({
    Key? key,
    required this.playlist,
    required this.songs,
  }) : super(key: key);

  @override
  PlaylistDetailsScreenState createState() => PlaylistDetailsScreenState();
}

class PlaylistDetailsScreenState extends State<PlaylistDetailsScreen> {
  late List<Map<String, dynamic>> _songs;
  final YoutubeExplode _yt = YoutubeExplode();

  @override
  void initState() {
    super.initState();
    _songs = widget.songs;
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${duration.inHours}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }

  void _removeSongFromPlaylist(Map<String, dynamic> song) async {
    final provider = Provider.of<PlaylistAlbumLibraryProvider>(
      context,
      listen: false,
    );
    await provider.removeSongFromPlaylist(
      widget.playlist['name'],
      song['id'].toString(),
    );
    final updated = await provider.getPlaylistSongs(widget.playlist['name']);
    setState(() {
      _songs = updated;
    });
  }

  Future<void> _refreshPlaylist() async {
    final provider = Provider.of<PlaylistAlbumLibraryProvider>(
      context,
      listen: false,
    );
    final updated = await provider.getPlaylistSongs(widget.playlist['name']);
    setState(() {
      _songs = updated;
    });
  }

  Future<void> _playSong(Map<String, dynamic> song) async {
    try {
      final playerProvider = Provider.of<PlayerProvider>(
        context,
        listen: false,
      );
      final queueProvider = Provider.of<QueueProvider>(context, listen: false);

      final songInfoList = _songs
          .map(
            (s) => SongInfo(
              videoId: s['id'],
              name: s['title'],
              artists: [
                Artist(name: song['artist'] ?? '', id: song['artistId'] ?? ''),
              ],
              thumbnails: [
                Thumbnail(url: s['thumbnail'], width: 1280, height: 720),
              ],
              duration: Duration(seconds: s['duration']),
            ),
          )
          .toList();

      final songInfo = SongInfo(
        videoId: song['id'],
        name: song['title'],
        artists: [
          Artist(name: song['artist'] ?? '', id: song['artistId'] ?? ''),
        ],
        thumbnails: [
          Thumbnail(url: song['thumbnail'], width: 1280, height: 720),
        ],
        duration: Duration(seconds: song['duration']),
      );

      final contentDetailsService = ContentDetailsService();
      await contentDetailsService.playSong(
        songInfo,
        playerProvider,
        queueProvider,
        songInfoList,
        playlistId: widget.playlist['name'],
      );

      if (!mounted) return;
    } catch (e) {
      print('Error playing song: $e');
      if (!mounted) return;
      AppSnackBar.showError(context, 'Error playing song');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: MainScreenColors.getBackgroundColor(isDarkMode),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.playlist['name'],
            style: AppTextStyles.appBarTitle(isDarkMode: isDarkMode),
          ),
        ),
        body: Consumer<PlayerProvider>(
          builder: (context, playerProvider, _) {
            final hasPlayer =
                playerProvider.currentSong != null ||
                playerProvider.lastPlayedSong != null;
            final settingsProvider = Provider.of<SettingsProvider>(context);
            final accentColor = settingsProvider.accentColor;

            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshPlaylist,
                    color: MainScreenColors.getSecondaryColor(isDarkMode),
                    backgroundColor: MainScreenColors.getSurfaceColor(
                      isDarkMode,
                    ),
                    child: _songs.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.4,
                                child: Center(
                                  child: Text(
                                    'No songs in this playlist',
                                    style: AppTextStyles.titleSm(
                                      isDarkMode: isDarkMode,
                                      color: MainScreenColors.getTextColor(
                                        isDarkMode,
                                      ).withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _songs.length,
                            itemBuilder: (context, index) {
                              final song = _songs[index];
                              final isCurrentSong =
                                  playerProvider.currentSong?.videoId ==
                                  song['id'];
                              return ListTile(
                                onTap: () => _playSong(song),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppDimens.radiusSm,
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: song['thumbnail'],
                                    width: AppDimens.thumbnailDefault,
                                    height: AppDimens.thumbnailDefault,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                title: Text(
                                  song['title'],
                                  style: isCurrentSong
                                      ? AppTextStyles.queueItemPlaying(
                                          isDarkMode: isDarkMode,
                                          accentColor: accentColor,
                                        )
                                      : AppTextStyles.queueItem(
                                          isDarkMode: isDarkMode,
                                        ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        song['artist'],
                                        style: AppTextStyles.bodyMd(
                                          isDarkMode: isDarkMode,
                                          color: isCurrentSong
                                              ? accentColor.withValues(
                                                  alpha: 0.7,
                                                )
                                              : MainScreenColors.getTextColor(
                                                  isDarkMode,
                                                ).withValues(alpha: 0.7),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(song['duration']),
                                      style: AppTextStyles.caption(
                                        isDarkMode: isDarkMode,
                                        color: isCurrentSong
                                            ? accentColor.withValues(alpha: 0.7)
                                            : MainScreenColors.getTextColor(
                                                isDarkMode,
                                              ).withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.remove_circle_outline,
                                    color: isCurrentSong
                                        ? accentColor
                                        : Colors.redAccent,
                                  ),
                                  onPressed: () =>
                                      _removeSongFromPlaylist(song),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
