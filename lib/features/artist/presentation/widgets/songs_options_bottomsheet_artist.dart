import 'package:cached_network_image/cached_network_image.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/song_model.dart';
import '../../../../core/providers/favorite_song_provider.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/queued_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/download_provider.dart';
import '../../../../core/services/content_details_service.dart';
import '../../../../shared/components/add_to_playlist_bottomsheet.dart';
import '../../../../shared/components/app_snackbar.dart';
import '../../../../core/utils/content_router.dart';

class SongOptionsBottomSheetArtist extends StatefulWidget {
  final dynamic song;
  final bool isDarkMode;

  const SongOptionsBottomSheetArtist({
    Key? key,
    required this.song,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<SongOptionsBottomSheetArtist> createState() =>
      _SongOptionsBottomSheetArtistState();
}

class _SongOptionsBottomSheetArtistState
    extends State<SongOptionsBottomSheetArtist> {
  late FavoriteSongProvider _favoriteSongProvider;
  late QueueProvider _queueProvider;
  late DownloadProvider _downloadProvider;
  late SongInfo _songInfo;

  @override
  void initState() {
    super.initState();
    _favoriteSongProvider = context.read<FavoriteSongProvider>();
    _queueProvider = context.read<QueueProvider>();
    _downloadProvider = context.read<DownloadProvider>();

    if (widget.song is SongInfo) {
      _songInfo = widget.song as SongInfo;
    } else if (widget.song is SongDetailed) {
      final sd = widget.song as SongDetailed;
      _songInfo = SongInfo(
        videoId: sd.videoId,
        name: sd.name,
        artists: [Artist(name: sd.artist.name, id: sd.artist.artistId ?? '')],
        thumbnails: sd.thumbnails
            .map((t) => Thumbnail(url: t.url, width: t.width, height: t.height))
            .toList(),
        duration: sd.duration != null
            ? Duration(seconds: sd.duration!)
            : Duration.zero,
      );
    } else {
      throw ArgumentError('Unsupported song type');
    }
  }

  Future<void> _playNext() async {
    if (_queueProvider.hasLocalSongsInQueue) {
      AppSnackBar.showError(context, 'cannot_add_songs_to_queue'.tr());
      return;
    }
    _queueProvider.addToQueueNext(_songInfo);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _addToQueue() async {
    if (_queueProvider.hasLocalSongsInQueue) {
      AppSnackBar.showError(context, 'cannot_add_songs_to_queue'.tr());
      return;
    }
    _queueProvider.addToQueue(_songInfo);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _toggleLike() async {
    if (_songInfo.duration.inSeconds == 0) {
      try {
        final resolved = await ContentDetailsService.resolveSongInfoDuration(
          _songInfo,
        );
        if (mounted && resolved.duration.inSeconds > 0) {
          _songInfo = resolved;
        }
      } catch (e) {
        debugPrint('Error resolving song duration for like: $e');
      }
    }
    await _favoriteSongProvider.toggleLikeForSong(_songInfo);
  }

  Future<void> _downloadSong() async {
    try {
      final videoId = _songInfo.videoId;

      if (_downloadProvider.downloadedSongs.any((s) => s['id'] == videoId) ||
          _downloadProvider.progressMap.containsKey(videoId) ||
          _downloadProvider.preparing.contains(videoId)) {
        if (context.mounted) {
          AppSnackBar.showInfo(
            context,
            'song_already_downloaded_or_in_queue'.tr(),
          );
        }
        return;
      }

      await _downloadProvider.downloadSong(_songInfo);
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'download_failed'.tr());
        Navigator.pop(context);
      }
    }
  }

  void _viewArtist(Artist artist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContentRouter(
          content: ArtistDetailed(
            artistId: artist.id,
            name: artist.name,
            thumbnails: [
              ThumbnailFull(
                url: _songInfo.thumbnails.isNotEmpty
                    ? _songInfo.thumbnails.first.url
                    : '',
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

  String _getArtistsText() {
    if (_songInfo.artists.isEmpty) return 'unknown_artist'.tr();
    if (_songInfo.artists.length == 1) return _songInfo.artists[0].name;
    return '${_songInfo.artists[0].name} & ${_songInfo.artists.length - 1} more';
  }

  List<Widget> _buildArtistOptions(Color textColor) {
    if (_songInfo.artists.isEmpty) {
      return [
        _buildOption(
          icon: Icons.person,
          text: 'view_artist'.tr() + ' (${'unknown_artist'.tr()})',
          onTap: () {},
          textColor: textColor.withValues(alpha: 0.5),
        ),
      ];
    }

    return _songInfo.artists.map((artist) {
      final isArtistIdNull = artist.id.isEmpty;
      return _buildOption(
        icon: Icons.person,
        text: 'view_artist'.tr() + ' (${artist.name})',
        onTap: isArtistIdNull ? () {} : () => _viewArtist(artist),
        textColor: isArtistIdNull
            ? textColor.withValues(alpha: 0.5)
            : textColor,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = MainScreenColors.getSurfaceColor(widget.isDarkMode);
    final textColor = MainScreenColors.getTextColor(widget.isDarkMode);
    final secondaryColor = MainScreenColors.getSecondaryColor(
      widget.isDarkMode,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXxl),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context, textColor),
                _buildAllOptions(context, textColor, secondaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color textColor) {
    return Container(
      padding: EdgeInsets.all(AppDimens.paddingLg),
      child: Column(
        children: [
          Container(
            width: AppDimens.spacing4Xl,
            height: AppDimens.dragHandleHeight,
            margin: EdgeInsets.only(bottom: AppDimens.spacingLg),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppDimens.radiusXxs),
            ),
          ),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                child: CachedNetworkImage(
                  imageUrl: _songInfo.thumbnails.isNotEmpty
                      ? _songInfo.thumbnails.first.url
                      : '',
                  width: AppDimens.thumbnailDefault,
                  height: AppDimens.thumbnailDefault,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: widget.isDarkMode
                        ? Colors.grey[850]
                        : Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Image.asset(
                    'assets/default_artwork.png',
                    width: AppDimens.thumbnailLarge,
                    height: AppDimens.thumbnailLarge,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: AppDimens.spacingLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _songInfo.name,
                      style: AppTextStyles.subtitle(
                        isDarkMode: widget.isDarkMode,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _getArtistsText(),
                      style: AppTextStyles.bodyMd(
                        isDarkMode: widget.isDarkMode,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppDimens.spacingSm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer<FavoriteSongProvider>(
                    builder: (context, provider, child) {
                      final isLiked = provider.isSongLiked(_songInfo.videoId);
                      return IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : textColor,
                          size: AppDimens.iconLg,
                        ),
                        onPressed: _toggleLike,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Consumer<DownloadProvider>(
                    builder: (context, provider, child) {
                      final accentColor = context.select(
                        (SettingsProvider settings) => settings.accentColor,
                      );
                      final isDownloaded = provider.downloadedSongs.any(
                        (s) => s['id'] == _songInfo.videoId,
                      );
                      final progress = provider.progressMap[_songInfo.videoId];
                      final isPreparing = provider.preparing.contains(
                        _songInfo.videoId,
                      );

                      if (isDownloaded) {
                        return IconButton(
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: AppDimens.iconLg,
                          ),
                          onPressed: null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        );
                      }

                      if (progress != null && progress.progress < 1.0) {
                        return SizedBox(
                          width: AppDimens.iconLg,
                          height: AppDimens.iconLg,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: progress.progress,
                                strokeWidth: AppDimens.progressStroke,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  accentColor,
                                ),
                              ),
                              Text(
                                '${(progress.progress * 100).round()}',
                                style: AppTextStyles.badge(color: textColor),
                              ),
                            ],
                          ),
                        );
                      } else if (isPreparing) {
                        return SizedBox(
                          width: AppDimens.iconLg,
                          height: AppDimens.iconLg,
                          child: CircularProgressIndicator(
                            strokeWidth: AppDimens.progressStroke,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              accentColor,
                            ),
                          ),
                        );
                      }

                      return IconButton(
                        icon: Icon(
                          Icons.download,
                          color: textColor,
                          size: AppDimens.iconLg,
                        ),
                        onPressed: _downloadSong,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllOptions(
    BuildContext context,
    Color textColor,
    Color secondaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer<PlayerProvider>(
          builder: (context, player, child) {
            final isSame = player.currentSong?.videoId == _songInfo.videoId;
            if (isSame) return const SizedBox.shrink();
            return _buildOption(
              icon: Icons.playlist_play,
              text: 'play_next'.tr(),
              onTap: _playNext,
              textColor: textColor,
            );
          },
        ),
        _buildOption(
          icon: Icons.queue_music,
          text: 'add_to_queue'.tr(),
          onTap: _addToQueue,
          textColor: textColor,
        ),
        _buildOption(
          icon: Icons.playlist_add,
          text: 'add_to_playlist'.tr(),
          onTap: () => _showPlaylistDialog(context, textColor, secondaryColor),
          textColor: textColor,
        ),
        Consumer<DownloadProvider>(
          builder: (context, provider, child) {
            final isDownloaded = provider.downloadedSongs.any(
              (s) => s['id'] == _songInfo.videoId,
            );

            if (isDownloaded) {
              return _buildOption(
                icon: Icons.delete,
                text: 'remove_from_downloads'.tr(),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: widget.isDarkMode
                            ? MainScreenColors.darkSurfaceColor
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(
                          'delete_songs'.tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.isDarkMode
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        content: Text(
                          'are_you_sure_you_want_to_delete_selected_songs'.tr(
                            args: ['1'],
                          ),
                          style: TextStyle(
                            color: widget.isDarkMode
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
                    await provider.deleteDownloadedSong(_songInfo.videoId);
                    if (context.mounted) {
                      AppSnackBar.showInfo(
                        context,
                        'removed_from_downloads'.tr(),
                      );
                      Navigator.pop(context);
                    }
                  }
                },
                textColor: Colors.red,
              );
            }

            return const SizedBox.shrink();
          },
        ),
        _buildOpenInOptions(context, textColor),
        ..._buildArtistOptions(textColor),
        _buildOption(
          icon: Icons.share,
          text: 'share'.tr(),
          onTap: () {
            final youtubeUrl = 'https://youtu.be/${_songInfo.videoId}';
            final artistsText = _songInfo.artists.isNotEmpty
                ? _songInfo.artists.map((a) => a.name).join(', ')
                : 'Unknown Artist';
            SharePlus.instance.share(
              ShareParams(
                text: 'Check out this song: $youtubeUrl by $artistsText',
              ),
            );
            Navigator.pop(context);
          },
          textColor: textColor,
        ),
      ],
    );
  }

  Future<void> _showPlaylistDialog(
    BuildContext context,
    Color textColor,
    Color secondaryColor,
  ) async {
    final songData = {
      'id': _songInfo.videoId,
      'title': _songInfo.name,
      'artistId': _songInfo.artists.isNotEmpty ? _songInfo.artists[0].id : '',
      'duration': _songInfo.duration.inSeconds,
      'thumbnail': _songInfo.thumbnails.isNotEmpty
          ? _songInfo.thumbnails.first.url
          : '',
      'artist': _getArtistsText(),
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddToPlaylistBottomSheet(song: songData),
    );
  }

  Widget _buildOpenInOptions(BuildContext context, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.paddingLg,
        vertical: AppDimens.spacingXxs,
      ),
      child: Row(
        children: [
          Icon(Icons.open_in_new, color: textColor, size: AppDimens.iconLg),
          SizedBox(width: AppDimens.spacingSm),
          Text(
            'open_in'.tr(),
            style: AppTextStyles.bodyMd(
              isDarkMode: widget.isDarkMode,
              color: textColor,
            ),
          ),
          SizedBox(width: AppDimens.spacingLg),
          const Spacer(),
          IconButton(
            icon: Container(
              width: AppDimens.iconXl,
              height: AppDimens.iconXl,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(AppDimens.radiusXs),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: AppDimens.iconMd,
              ),
            ),
            onPressed: () async {
              final youtubeUrl = 'https://youtu.be/${_songInfo.videoId}';
              if (await canLaunchUrl(Uri.parse(youtubeUrl))) {
                await launchUrl(Uri.parse(youtubeUrl));
              }
            },
            tooltip: 'open_in_youtube'.tr(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          SizedBox(width: AppDimens.spacingLg),
          IconButton(
            icon: Icon(
              Icons.play_circle_outline,
              color: Colors.red[700],
              size: AppDimens.iconXl,
            ),
            onPressed: () async {
              final youtubeMusicUrl =
                  'https://music.youtube.com/watch?v=${_songInfo.videoId}';
              if (await canLaunchUrl(Uri.parse(youtubeMusicUrl))) {
                await launchUrl(Uri.parse(youtubeMusicUrl));
              }
            },
            tooltip: 'open_in_youtube_music'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color? textColor,
    Widget? trailing,
  }) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(
        icon,
        color: textColor ?? Colors.white,
        size: AppDimens.iconLg,
      ),
      title: Text(
        text,
        style: AppTextStyles.bodyLg(color: textColor ?? Colors.white),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: AppDimens.paddingLg),
    );
  }
}
