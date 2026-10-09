import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:metadata_god/metadata_god.dart';
import '../../../../shared/components/marquee_text.dart';
import '../../../../core/services/local_songs_service.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/models/song_model.dart';
import '../../../../core/providers/download_provider.dart' as dp;
import 'songs_options_bottomsheet_library.dart';
import 'local_song_options_bottomsheet.dart';

class LibrarySongListTile extends StatelessWidget {
  final Map<String, dynamic> song;
  final VoidCallback onPlay;
  final VoidCallback? onTap;
  final bool isPlaying;
  final bool isDarkMode;
  final Color accentColor;
  final EdgeInsets? contentPadding;

  const LibrarySongListTile({
    Key? key,
    required this.song,
    required this.onPlay,
    this.onTap,
    this.isPlaying = false,
    required this.isDarkMode,
    required this.accentColor,
    this.contentPadding,
  }) : super(key: key);

  String _formatDuration(dynamic duration) {
    if (duration == null) return '';

    if (duration is int) {
      int minutes = (duration / 60).floor();
      int seconds = duration % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    if (duration is String) {
      return duration;
    }

    return '';
  }

  String _getArtistDisplayName() {
    String display;
    if (song['artists'] != null && song['artists'] is List) {
      final artists = song['artists'] as List;
      if (artists.isNotEmpty) {
        display = artists.map((a) => a['name'] ?? '').join(', ');
      } else {
        display = song['artist'] ?? song['artistName'] ?? 'Unknown Artist';
      }
    } else {
      display = song['artist'] ?? song['artistName'] ?? 'Unknown Artist';
    }

    return display
        .replaceAll(RegExp(r'\\s*&\\s*more', caseSensitive: false), '')
        .trim();
  }

  Widget buildArtwork(double uiScale) {
    final double size = AppDimens.thumbnailDefault * uiScale;
    if (song['isLocal'] == true) {
      if (Platform.isWindows || Platform.isLinux) {
        return LocalArtworkWidget(song: song, uiScale: uiScale);
      } else {
        return _AndroidArtworkWidget(
          id: int.parse(song['id']),
          size: size,
          uiScale: uiScale,
        );
      }
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusSm * uiScale),
        child: CachedNetworkImage(
          imageUrl: song['thumbnail'] ?? 'assets/default_artwork.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: (AppDimens.thumbnailDefault * 2 * uiScale).toInt(),
          memCacheHeight: (AppDimens.thumbnailDefault * 2 * uiScale).toInt(),
          placeholder: (context, url) => Image.asset(
            'assets/default_artwork.png',
            height: size,
            width: size,
            fit: BoxFit.cover,
          ),
          errorWidget: (context, url, error) => Image.asset(
            'assets/default_artwork.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = MainScreenColors.getTextColor(isDarkMode);

    final double _textScale = MediaQuery.of(context).textScaleFactor;
    final double uiScale = _textScale > 1.0
        ? (1.0 / _textScale).clamp(0.85, 1.0).toDouble()
        : 1.0;
    final double marqueeSpeed = 120.0;

    final videoId = song['id'] ?? song['videoId'];
    final downloadProgress = context
        .select<dp.DownloadProvider, dp.DownloadProgress?>(
          (provider) => provider.progressMap[videoId],
        );
    final isPreparing = context.select<dp.DownloadProvider, bool>(
      (provider) => provider.preparing.contains(videoId),
    );
    final isDownloaded = context.select<dp.DownloadProvider, bool>(
      (provider) => provider.downloadedSongs.any((s) => s['id'] == videoId),
    );

    final EdgeInsets tilePadding = contentPadding ?? EdgeInsets.zero;
    final _mq = MediaQuery.of(context);
    final _enforcedTextScale = _mq.textScaleFactor > 1.0
        ? 1.0
        : _mq.textScaleFactor;

    return MediaQuery(
      data: _mq.copyWith(textScaleFactor: _enforcedTextScale),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: tilePadding,
          leading: Stack(
            alignment: Alignment.center,
            children: [
              Hero(
                tag: 'song-thumbnail-${song['id'] ?? song['videoId']}',
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      AppDimens.radiusSm * uiScale,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: AppDimens.elevationMedium * uiScale,
                        offset: Offset(0, AppDimens.spacingXxs * uiScale),
                      ),
                    ],
                  ),
                  child: buildArtwork(uiScale),
                ),
              ),
              if (isPlaying)
                Container(
                  width: AppDimens.thumbnailDefault * uiScale,
                  height: AppDimens.thumbnailDefault * uiScale,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(
                      AppDimens.radiusSm * uiScale,
                    ),
                  ),
                  child: Icon(
                    Icons.equalizer,
                    color: accentColor,
                    size: AppDimens.iconLg * uiScale,
                  ),
                ),
            ],
          ),
          title: MarqueeText(
            text: song['title'] ?? song['name'] ?? 'Unknown Title',
            style: AppTextStyles.bodyLg(
              isDarkMode: isDarkMode,
              color: isPlaying ? accentColor : textColor,
            ).copyWith(height: AppTextStyles.lineHeightDefault),
            speedPxPerSecond: marqueeSpeed,
            pauseDuration: const Duration(milliseconds: 300),
          ),
          subtitle: Row(
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                  ),
                  child: MarqueeText(
                    text: _getArtistDisplayName(),
                    style: AppTextStyles.body2(
                      isDarkMode: isDarkMode,
                      color: isPlaying
                          ? accentColor.withValues(alpha: 0.7)
                          : textColor.withValues(alpha: 0.7),
                    ).copyWith(height: AppTextStyles.lineHeightDefault),
                    speedPxPerSecond: marqueeSpeed,
                    pauseDuration: const Duration(milliseconds: 300),
                  ),
                ),
              ),
              SizedBox(width: AppDimens.spacingSm),
              Text(
                _formatDuration(song['duration']),
                style: AppTextStyles.caption(isDarkMode: isDarkMode).copyWith(
                  color: isPlaying
                      ? accentColor.withValues(alpha: 0.7)
                      : textColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (song['isLocal'] == true)
                const SizedBox.shrink()
              else if (isDownloaded)
                SizedBox(
                  width: AppDimens.iconMd * uiScale,
                  height: AppDimens.iconMd * uiScale,
                  child: Icon(
                    Icons.check_circle,
                    color: accentColor,
                    size: AppDimens.iconMd * uiScale,
                  ),
                )
              else if (isPreparing)
                SizedBox(
                  width: AppDimens.iconMd * uiScale,
                  height: AppDimens.iconMd * uiScale,
                  child: CircularProgressIndicator(
                    strokeWidth: AppDimens.progressStroke * uiScale,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                )
              else if (downloadProgress != null &&
                  downloadProgress.progress < 1.0)
                SizedBox(
                  width: AppDimens.iconXxl * uiScale,
                  height: AppDimens.iconXxl * uiScale,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: downloadProgress.progress,
                        strokeWidth: AppDimens.progressStroke * uiScale,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        backgroundColor: textColor.withValues(alpha: 0.3),
                      ),
                      Text(
                        '${(downloadProgress.progress * 100).toInt()}%',
                        style: AppTextStyles.badge(
                          isDarkMode: isDarkMode,
                        ).copyWith(color: textColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: AppDimens.iconMd * uiScale,
                  height: AppDimens.iconMd * uiScale,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(
                      width: AppDimens.iconMd * uiScale,
                      height: AppDimens.iconMd * uiScale,
                    ),
                    icon: Icon(
                      Icons.download,
                      color: textColor,
                      size: AppDimens.iconMd * uiScale,
                    ),
                    onPressed: () async {
                      final songInfo = SongInfo(
                        videoId: song['id'],
                        name: song['title'],
                        artists:
                            song['artists'] != null && song['artists'] is List
                            ? (song['artists'] as List)
                                  .map(
                                    (a) => Artist(
                                      name: a['name'] ?? '',
                                      id: a['id'] ?? '',
                                    ),
                                  )
                                  .toList()
                            : [Artist(name: song['artist'] ?? '', id: '')],
                        thumbnails: [
                          Thumbnail(
                            url: song['thumbnail'] ?? '',
                            width: 0,
                            height: 0,
                          ),
                        ],
                        duration: Duration(milliseconds: song['duration'] ?? 0),
                      );
                      await context.read<dp.DownloadProvider>().downloadSong(
                        songInfo,
                      );
                    },
                  ),
                ),
              if (song['isLocal'] == true)
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: textColor,
                    size: AppDimens.iconMd * uiScale,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => SafeArea(
                        top: false,
                        child: LocalSongOptionsBottomSheet(
                          song: song,
                          isDarkMode: isDarkMode,
                          onPlay: onPlay,
                        ),
                      ),
                    );
                  },
                )
              else
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: textColor,
                    size: AppDimens.iconMd * uiScale,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => SafeArea(
                        top: false,
                        child: SongOptionsBottomSheetlibrary(
                          song: song,
                          isPlaying: isPlaying,
                          isDarkMode: isDarkMode,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          onTap: onTap ?? onPlay,
        ),
      ),
    );
  }
}

class LocalArtworkWidget extends StatefulWidget {
  final Map<String, dynamic> song;
  final double uiScale;

  const LocalArtworkWidget({
    Key? key,
    required this.song,
    required this.uiScale,
  }) : super(key: key);

  @override
  State<LocalArtworkWidget> createState() => _LocalArtworkWidgetState();
}

class _LocalArtworkWidgetState extends State<LocalArtworkWidget> {
  Picture? _picture;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  Future<void> _loadArtwork() async {
    try {
      final path =
          widget.song['localPath'] ??
          widget.song['data'] ??
          widget.song['path'];
      if (path != null && File(path).existsSync()) {
        final metadata = await MetadataGod.readMetadata(file: path);
        if (mounted) {
          setState(() {
            _picture = metadata.picture;
            _isLoading = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Error reading metadata picture: $e');
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double size = AppDimens.thumbnailDefault * widget.uiScale;
    if (_isLoading) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(
          AppDimens.radiusSm * widget.uiScale,
        ),
        child: Image.asset(
          'assets/default_artwork.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    if (_picture != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(
          AppDimens.radiusSm * widget.uiScale,
        ),
        child: Image.memory(
          _picture!.data,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radiusSm * widget.uiScale),
      child: Image.asset(
        'assets/default_artwork.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _AndroidArtworkWidget extends StatefulWidget {
  final int id;
  final double size;
  final double uiScale;

  const _AndroidArtworkWidget({
    Key? key,
    required this.id,
    required this.size,
    required this.uiScale,
  }) : super(key: key);

  @override
  State<_AndroidArtworkWidget> createState() => _AndroidArtworkWidgetState();
}

class _AndroidArtworkWidgetState extends State<_AndroidArtworkWidget> {
  Uint8List? _artworkBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  Future<void> _loadArtwork() async {
    try {
      final bytes = await LocalSongsService().queryArtwork(widget.id);
      if (mounted) {
        setState(() {
          _artworkBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallback = ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radiusSm * widget.uiScale),
      child: Image.asset(
        'assets/default_artwork.png',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
      ),
    );

    if (_isLoading) return fallback;

    if (_artworkBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(
          AppDimens.radiusSm * widget.uiScale,
        ),
        child: Image.memory(
          _artworkBytes!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        ),
      );
    }

    return fallback;
  }
}
